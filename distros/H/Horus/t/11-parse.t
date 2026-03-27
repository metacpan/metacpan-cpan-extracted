use 5.008003;
use strict;
use warnings;
use Test::More tests => 9;
use Horus qw(:all);

# Generate a reference UUID
my $ref_bin = uuid_v4(UUID_FMT_BINARY);
my $ref_str = uuid_convert($ref_bin, UUID_FMT_STR);

# Parse each format back to binary and verify identity
my $from_str = uuid_parse($ref_str);
is($from_str, $ref_bin, 'parse STR -> binary roundtrip');

my $from_hex = uuid_parse(uuid_convert($ref_bin, UUID_FMT_HEX));
is($from_hex, $ref_bin, 'parse HEX -> binary roundtrip');

my $from_braces = uuid_parse(uuid_convert($ref_bin, UUID_FMT_BRACES));
is($from_braces, $ref_bin, 'parse BRACES -> binary roundtrip');

my $from_urn = uuid_parse(uuid_convert($ref_bin, UUID_FMT_URN));
is($from_urn, $ref_bin, 'parse URN -> binary roundtrip');

my $from_b64 = uuid_parse(uuid_convert($ref_bin, UUID_FMT_BASE64));
is($from_b64, $ref_bin, 'parse BASE64 -> binary roundtrip');

my $from_binary = uuid_parse($ref_bin);
is($from_binary, $ref_bin, 'parse BINARY -> binary roundtrip');

my $from_upper = uuid_parse(uuid_convert($ref_bin, UUID_FMT_UPPER_STR));
is($from_upper, $ref_bin, 'parse UPPER_STR -> binary roundtrip');

my $from_upper_hex = uuid_parse(uuid_convert($ref_bin, UUID_FMT_UPPER_HEX));
is($from_upper_hex, $ref_bin, 'parse UPPER_HEX -> binary roundtrip');

# Parse error for invalid input
eval { uuid_parse('not-a-uuid') };
like($@, qr/cannot parse/, 'parse rejects invalid input');
