use strict;
use warnings;

use Test::More;
use Test::Exception;
use GDPR::IAB::TCFv2;
use GDPR::IAB::TCFv2::Validator;
use GDPR::IAB::TCFv2::Validator::Reason qw<:all>;
use MIME::Base64                        qw(decode_base64 encode_base64);

# TCF_V23_DEADLINE is 1772236800 (2026-02-28)

# Helper to construct a minimal Policy 2 core segment with a specific 'created' date
sub make_tc_core {
  my ($created, $policy_version) = @_;

  # We'll use a template from a known string and just overwrite the bits.
  my $tc_base = "COwAdDhOwAdDhN4ABAENAPCgAAQAAv___wAAAFP_AAp_4AI6ACACAA";
  my $bin     = $tc_base;
  $bin =~ tr/-_/+ /;
  $bin = decode_base64($bin);

  # Created is bits 6-41 (offset 6, 36 bits)
  # Policy Version is bits 132-137 (offset 132, 6 bits)

  # We'll use a very crude way to set these bits for testing purposes
  # if we don't want to bring in BitUtils packing logic here.
  # Actually, BitUtils doesn't have a 'set' helper, only 'get'.

  # Let's just use the string's created date in the test.
  # 1772236800 is Feb 28 2026.
  # 1583781091 is Mar 09 2020.

  return $tc_base;
}

subtest "Pre-deadline string" => sub {

  # Created: 2020, Policy: 2
  my $tc_old = "COwAdDhOwAdDhN4ABAENAPCgAAQAAv___wAAAFP_AAp_4AI6ACACAA";
  my $c      = GDPR::IAB::TCFv2->Parse($tc_old, strict => 1);
  is $c->policy_version, 2, "Policy 2";
  ok !$c->is_v23, "Not v2.3 because it was created before the deadline";
  lives_ok { GDPR::IAB::TCFv2->Parse($tc_old, strict => 1) } "Passes strict mode (old string)";
};

subtest "Policy 5 string" => sub {

  # Policy 5 string, even if created in the past, is v2.3
  my $tc_v23
    = 'CP188cAQKFpAAAHABBENBSFsAP_gAEPgAAiQKqNX_H__bW9r8X73aft0eY1P9_j77uQxBhfJE-4FzLvW_JwXx2ExNA36tqIKmRIEu3bBIQNlHJHUTVigaogVryHMak2cpTNKJ6BkiFMRM2dYCF5vm4tj-QKY5_r993dx2D-t_dv83dzyz81Hn3f5_2e0eLCdQ5-tDfv9bROb-9IPd_78v4v8_l_rk2_eT1n_tevr7D_-ft8__XW_9_fff_9Pn_-uB_-_3_vf_EFUwCTDQqIA-wJCQg0DCKBACoKwgIoFAQAAJA0QEAJgwKdgYALrCRACAFAAMEAIAAQZAAgAAAgAQiACQAoEAAEAgUAAYAEAwEABAwAAgAsBAIAAQHQMUwIIFAsIEjMioUwIQoEggJbKhBICgQVwhCLPAIgERMFAAgAAAVgACAsFgcSSAlQkECXUG0AABAAgFEIFQgk9MAAwJmy1B4MG0ZWmAYPmCRDTAMgCIIyEAAAA.f_wACHwAAAAA';

  # This string has Policy 5 but NO Disclosed Vendors segment (segment type is 2).
  # So strict Parse will fail.
  my $c = GDPR::IAB::TCFv2->Parse($tc_v23);
  is $c->policy_version, 5, "Policy 5";
  ok $c->is_v23, "Is v2.3 (policy 5)";

  throws_ok { GDPR::IAB::TCFv2->Parse($tc_v23, strict => 1) }
  qr/Disclosed Vendors segment is mandatory/, "Strict parse fails for Policy 5 without DV segment";
};

subtest "Post-deadline simulation via reference_time" => sub {

  # String created in 2020, Policy 2.
  my $tc_old = "COwAdDhOwAdDhN4ABAENAPCgAAQAAv___wAAAFP_AAp_4AI6ACACAA";

  # If we parse with reference_time < deadline, it remains NOT v2.3.
  my $c_past = GDPR::IAB::TCFv2->Parse($tc_old, reference_time => 1600000000);
  ok !$c_past->is_v23, "Historical reference_time maintains non-v2.3 status";

  # Note: currently is_v23 ONLY checks created date vs deadline if policy < 5.
  # So even if reference_time > deadline, a 2020 string is still NOT v2.3.
  # This is correct: it's a valid old string.
  my $c_now = GDPR::IAB::TCFv2->Parse($tc_old, reference_time => 1800000000);
  ok !$c_now->is_v23, "Parsing an old string TODAY does not force it to be v2.3";
};

subtest "Mandatory Disclosed Vendors segment (v2.3 logic)" => sub {

  # TCF v2.3 string missing Disclosed Vendors segment
  my $tc_v23_no_dv
    = 'CP188cAQKFpAAAHABBENBSFsAP_gAEPgAAiQKqNX_H__bW9r8X73aft0eY1P9_j77uQxBhfJE-4FzLvW_JwXx2ExNA36tqIKmRIEu3bBIQNlHJHUTVigaogVryHMak2cpTNKJ6BkiFMRM2dYCF5vm4tj-QKY5_r993dx2D-t_dv83dzyz81Hn3f5_2e0eLCdQ5-tDfv9bROb-9IPd_78v4v8_l_rk2_eT1n_tevr7D_-ft8__XW_9_fff_9Pn_-uB_-_3_vf_EFUwCTDQqIA-wJCQg0DCKBACoKwgIoFAQAAJA0QEAJgwKdgYALrCRACAFAAMEAIAAQZAAgAAAgAQiACQAoEAAEAgUAAYAEAwEABAwAAgAsBAIAAQHQMUwIIFAsIEjMioUwIQoEggJbKhBICgQVwhCLPAIgERMFAAgAAAVgACAsFgcSSAlQkECXUG0AABAAgFEIFQgk9MAAwJmy1B4MG0ZWmAYPmCRDTAMgCIIyEAAAA.f_wACHwAAAAA';

  # 1. Normal parsing: OK
  lives_ok { GDPR::IAB::TCFv2->Parse($tc_v23_no_dv) } "Lenient parse OK for v2.3 missing DV";

  # 2. Strict parsing: SHOULD FAIL because it is v2.3 (policy 5)
  throws_ok { GDPR::IAB::TCFv2->Parse($tc_v23_no_dv, strict => 1) }
  qr/Disclosed Vendors segment is mandatory/, "Strict parse fails for v2.3 missing DV";

  # 3. Simulation: If we backdate it using reference_time < Deadline.
  # Wait, policy 5 is ALWAYS v2.3 in my current implementation.
  # Should it be?
  # If policy is 5, it means it's FOLLOWING v2.3 spec.
  # Even if created in 2024 (unlikely, but possible for testing), it should be v2.3.
  # But if we use reference_time < Deadline, maybe we should allow it?

  # Actually, my implementation of is_v23 says:
  # return 1 if $self->policy_version >= 5;
  # if (reference_time < deadline) return 0;

  # Let's check this.
  my $c_sim = GDPR::IAB::TCFv2->Parse(
    $tc_v23_no_dv,
    strict         => 1,
    reference_time => 1700000000    # 2023, pre-deadline
  );
  ok !$c_sim->is_v23, "Reference time < Deadline disables v2.3 logic even for Policy 5 (historical simulation)";
  ok defined $c_sim,  "Parsed successfully in strict mode because v2.3 check was bypassed";
};

subtest "validator auto-enforces v2.3 after the deadline (date-based)" => sub {

  # No bit-exact post-deadline TC string exists in the fixtures, so drive the
  # deadline rule directly with a lightweight stub exposing the three accessors
  # it consults. This keeps the date-based gate deterministic.
  {

    package TCStub;
    sub new                   { my ($c, %a) = @_; return bless {%a}, $c }
    sub created               { return $_[0]->{created} }
    sub policy_version        { return $_[0]->{policy_version} }
    sub has_vendor_disclosure { return $_[0]->{has_dv} }
  }

  my $deadline = 1772236800;                                         # 2026-02-28T00:00:00Z
  my $v        = GDPR::IAB::TCFv2::Validator->new(vendor_id => 1);

  # Post-deadline (strictly after, matching Go .After()), policy 2, no DV =>
  # both gates fire. The date-based rule is split across the two Go-aligned
  # gates: the policy gate emits PolicyVersionTooLow, the disclosed gate emits
  # MissingDisclosedVendors.
  my @f;
  my $post = TCStub->new(created => $deadline + 1, policy_version => 2, has_dv => 0);
  $v->_check_policy_version($post, undef, \@f);
  $v->_check_disclosed($post, 1, 0, undef, \@f);
  my %c = map { $_->code => 1 } @f;
  ok $c{ReasonPolicyVersionTooLow()},     "post-deadline policy<5 => PolicyVersionTooLow";
  ok $c{ReasonMissingDisclosedVendors()}, "post-deadline no DV => MissingDisclosedVendors";

  # Pre-deadline, policy 5, no DV, no floor => date-based rule does NOT fire.
  @f = ();
  my $pre = TCStub->new(created => $deadline - 1, policy_version => 5, has_dv => 0);
  $v->_check_policy_version($pre, undef, \@f);
  $v->_check_disclosed($pre, 1, 0, undef, \@f);
  is scalar(@f), 0, "pre-deadline string is not subject to date-based v2.3 enforcement";
};

done_testing;
