use strict;
use warnings;

use Test::More;
use Test::Exception;
use Scalar::Util qw(looks_like_number);

use GDPR::IAB::TCFv2;
use GDPR::IAB::TCFv2::BitUtils;

# These flags decide whether the BitUtils helpers take the fast
# pack 'S>' / 'Q>' path or the Math::BigInt fallback.  On modern
# Perls both flags are true; on older Perls (before our 5.10.0 baseline)
# the fallback was the only path.
#
# Forcing both flags off here exercises the fallback unconditionally
# so the regression is testable on any Perl.
#
# Regression: the fallback used to return raw Math::BigInt blessed
# objects, which then propagated into TO_JSON output and made any
# JSON encoder without `convert_blessed` croak with
# "encountered object 'Math::BigInt=HASH(...)'...".

my $tc_string = 'CLcVDxRMWfGmWAVAHCENAXCkAKDAADnAABRgA5mdfCKZuYJez-NQm0TBMYA4oCAAGQYIAAAAAAEAIAEgAA';

subtest 'fallback path returns plain scalars (no blessed Math::BigInt)' => sub {
  local $GDPR::IAB::TCFv2::BitUtils::CAN_PACK_QUADS       = 0;
  local $GDPR::IAB::TCFv2::BitUtils::CAN_FORCE_BIG_ENDIAN = 0;

  my $consent;
  lives_ok { $consent = GDPR::IAB::TCFv2->Parse($tc_string) }
  'Parse succeeds with both fast paths disabled';

  for my $accessor (qw< cmp_id cmp_version vendor_list_version policy_version
    max_vendor_id_consent max_vendor_id_legitimate_interest
    created last_updated >)
  {
    my $value = $consent->$accessor;
    is ref($value), '', "$accessor returns a plain scalar (got " . (ref($value) || 'scalar') . ')';
  }
};

subtest 'fallback path returns correct 36-bit timestamp values' => sub {

  # Regression for CPAN Testers report 3e3e8fca-4988-11f1-843a-...
  # on armv6l-linux (Perl 5.42.2 with use64bitint=undef, ivsize=4).
  #
  # TCF v2 stores Created/LastUpdated as a 36-bit deciseconds-since-epoch
  # field, which doesn't fit in a 32-bit signed IV.  When the BigInt
  # fallback is in use, get_uint36 returns the value as an NV via
  # Math::BigInt->numify -- but the file-level `use integer` in
  # GDPR::IAB::TCFv2 was forcing the subsequent `/ 10` and `% 10` to
  # coerce that NV back to a 32-bit IV, overflowing and producing
  # `created => 0` and `nanoseconds => -100000000` on armv6l.
  #
  # This subtest forces the fallback path on every Perl so the bug is
  # caught on 64-bit smokers too.

  local $GDPR::IAB::TCFv2::BitUtils::CAN_PACK_QUADS       = 0;
  local $GDPR::IAB::TCFv2::BitUtils::CAN_FORCE_BIG_ENDIAN = 0;

  my $consent = GDPR::IAB::TCFv2->Parse($tc_string);

  is $consent->created,      1228644257, 'created returns the correct epoch in scalar context';
  is $consent->last_updated, 1326215413, 'last_updated returns the correct epoch in scalar context';

  {
    my ($sec, $nsec) = $consent->created;
    is $sec,  1228644257, 'created seconds in list context';
    is $nsec, 700000000,  'created nanoseconds in list context';
  }
  {
    my ($sec, $nsec) = $consent->last_updated;
    is $sec,  1326215413, 'last_updated seconds in list context';
    is $nsec, 400000000,  'last_updated nanoseconds in list context';
  }
};

subtest 'fallback values JSON-encode without convert_blessed' => sub {
  local $GDPR::IAB::TCFv2::BitUtils::CAN_PACK_QUADS       = 0;
  local $GDPR::IAB::TCFv2::BitUtils::CAN_FORCE_BIG_ENDIAN = 0;

  my $json_class = eval { require JSON; 1 } ? 'JSON' : eval { require JSON::PP; 1 } ? 'JSON::PP' : undef;
  plan skip_all => 'no JSON encoder available' unless $json_class;

  my $consent = GDPR::IAB::TCFv2->Parse($tc_string);

  # Deliberately do NOT enable convert_blessed.  A blessed Math::BigInt
  # leaking through TO_JSON would croak here.
  my $encoder = $json_class->new;
  my $output;
  lives_ok { $output = $encoder->encode($consent->TO_JSON) }
  'TO_JSON encodes cleanly without convert_blessed';

  # Decode and assert structurally.  The previous regex-on-JSON form
  # (qr/"cmp_id"\s*:\s*\d+/) made the test sensitive to encoder
  # whitespace and number-vs-string serialization quirks across
  # JSON::XS / JSON::PP / Perl versions.
  my $decoded = $encoder->decode($output);
  ok(looks_like_number($decoded->{cmp_id}),              'cmp_id round-trips as a JSON number');
  ok(looks_like_number($decoded->{vendor_list_version}), 'vendor_list_version round-trips as a JSON number');
};

done_testing;
