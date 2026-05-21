use strict;
use warnings;

use Test::More;
use Test::Exception;
use Test::Warn;

use GDPR::IAB::TCFv2;
use GDPR::IAB::TCFv2::Validator;
use GDPR::IAB::TCFv2::Constants::Purpose qw<:all>;

subtest "Validator basic usage" => sub {
  my $tc_string = 'COwAdDhOwAdDhN4ABAENAPCgAAQAAv___wAAAFP_AAp_4AI6ACACAA';

  my $validator = GDPR::IAB::TCFv2::Validator->new(
    vendor_id           => 1,
    consent_purpose_ids => [6],    # Allowed
  );

  my $result = $validator->validate($tc_string);
  ok $result, 'validation should pass';
  is $result->is_valid, 1,  'is_valid should be 1';
  is "$result",         '', 'stringification should be empty for valid result';
};

subtest "Validator failures" => sub {
  my $tc_string = 'COwAdDhOwAdDhN4ABAENAPCgAAQAAv___wAAAFP_AAp_4AI6ACACAA';

  my $validator = GDPR::IAB::TCFv2::Validator->new(
    vendor_id           => 1,
    consent_purpose_ids => [1, 6],    # 1 is missing consent bit, 6 is OK
  );

  subtest "validate (first failure)" => sub {
    my $result = $validator->validate($tc_string);
    ok !$result, 'validation should fail';
    is scalar($result->reasons), 1, 'should have 1 reason';
    like "$result", qr/not allowed for purpose 1/, 'should have correct reason';
  };

  subtest "validate_all (all failures)" => sub {
    my $validator2 = GDPR::IAB::TCFv2::Validator->new(
      vendor_id           => 1,
      consent_purpose_ids => [1, 7],    # Both fail: P1=0, P7=0
    );
    my $result = $validator2->validate_all($tc_string);
    ok !$result, 'validation should fail';
    is scalar($result->reasons), 2, 'should have 2 reasons';

    {
      local $\ = " | ";
      like "$result", qr/purpose 1.*\Q | \E.*purpose 7/, 'should join reasons with ORS';
    }
  };
};

subtest "Validator overrides" => sub {
  my $tc_string = 'COwAdDhOwAdDhN4ABAENAPCgAAQAAv___wAAAFP_AAp_4AI6ACACAA';

  my $validator = GDPR::IAB::TCFv2::Validator->new(vendor_id => 1, consent_purpose_ids => [6],);

  ok $validator->validate($tc_string),                   'pass for vendor 1';
  ok !$validator->validate($tc_string, vendor_id => 99), 'fail for vendor 99 (missing bits)';
};

subtest "Validator with Disclosed Vendors" => sub {
  my $tc_v23
    = 'COwAdDhOwAdDhN4ABAENAPCgAAQAAv___wAAAFP_AAp_4AI6ACACAA.ILrtR_G__bXlv-bb36ftkeYxf9_hr7sQxBgbJs24FzLvW7JwX32E7NEzatqYKmRIAu3TBIQNtHJjURVChKIgVrzDsaEyUoTtKJ-BkiHMRY2NYCFxvm4tjWQCZ5vr_91d9mT-N7dr-2dzyy7hnv3a9_-S1WJidKYetHfv8bBKT-_IU9_x-_4v4_N7pE2-eS1v_tGvt639-4vP_dpvxt-7yffz____73_e7X__d_______Xf_7____________4AAA';

  my $validator = GDPR::IAB::TCFv2::Validator->new(vendor_id => 284, verify_disclosed_vendors => 1,);

  ok $validator->validate($tc_v23), 'pass for disclosed vendor 284';

  my $result = $validator->validate($tc_v23, vendor_id => 9999);
  ok !$result, 'fail for non-disclosed vendor 9999';
  like "$result", qr/not disclosed/, 'correct failure reason';

  subtest "Missing disclosed vendors segment logic (Go alignment)" => sub {

    # TC string without disclosed vendors segment (v2.0)
    my $tc_v20 = 'COwAdDhOwAdDhN4ABAENAPCgAAQAAv___wAAAFP_AAp_4AI6ACACAA';

    # 1. No min_tcf_policy_version set (defaults to undef/<5) -> Silently pass
    my $v1 = GDPR::IAB::TCFv2::Validator->new(vendor_id => 1, verify_disclosed_vendors => 1,);
    ok $v1->validate($tc_v20), 'missing segment passes when min_tcf_policy_version is not set';

    # 2. min_tcf_policy_version < 5 -> Silently pass
    my $v2
      = GDPR::IAB::TCFv2::Validator->new(vendor_id => 1, verify_disclosed_vendors => 1, min_tcf_policy_version => 2,);
    ok $v2->validate($tc_v20), 'missing segment passes when min_tcf_policy_version < 5';

    # 3. min_tcf_policy_version >= 5 -> Failure
    my $v3
      = GDPR::IAB::TCFv2::Validator->new(vendor_id => 1, verify_disclosed_vendors => 1, min_tcf_policy_version => 5,);
    my $r3 = $v3->validate_all($tc_v20);
    ok !$r3, 'missing segment fails when min_tcf_policy_version >= 5';
    like "$r3", qr/missing disclosed vendors segment/, 'correct failure reason';
  };
};

subtest "Validator accepts a pre-parsed GDPR::IAB::TCFv2 object" => sub {
  my $tc_string = 'COwAdDhOwAdDhN4ABAENAPCgAAQAAv___wAAAFP_AAp_4AI6ACACAA';
  my $consent   = GDPR::IAB::TCFv2->Parse($tc_string);

  my $validator = GDPR::IAB::TCFv2::Validator->new(vendor_id => 1, consent_purpose_ids => [6],);

  my $result = $validator->validate($consent);
  ok $result, 'passes when given a parsed consent object';
  is $result->is_valid, 1, 'is_valid is 1 for the parsed-object input';
};

subtest "Validator without vendor_id" => sub {
  my $tc_string = 'COwAdDhOwAdDhN4ABAENAPCgAAQAAv___wAAAFP_AAp_4AI6ACACAA';

  my $validator = GDPR::IAB::TCFv2::Validator->new(consent_purpose_ids => [6],);

  throws_ok { $validator->validate($tc_string) }
  qr/missing vendor_id/, 'validate croaks when vendor_id is missing in both ctor and override';

  ok $validator->validate($tc_string, vendor_id => 1), 'override fills the missing vendor_id and validation proceeds';
};

subtest "Validator legitimate_interest_purpose_ids" => sub {
  my $tc_string = 'COwAdDhOwAdDhN4ABAENAPCgAAQAAv___wAAAFP_AAp_4AI6ACACAA';

  # Vendor 2 has LI for Purpose 2 in this fixture.
  my $validator_pass = GDPR::IAB::TCFv2::Validator->new(vendor_id => 2, legitimate_interest_purpose_ids => [2],);
  ok $validator_pass->validate($tc_string), 'pass for vendor 2 / LI purpose 2';

  # Purpose 1 LI is forbidden by spec regardless of the bit, so this fails.
  my $validator_fail = GDPR::IAB::TCFv2::Validator->new(vendor_id => 1, legitimate_interest_purpose_ids => [1],);
  my $result         = $validator_fail->validate($tc_string);
  ok !$result, 'fail for purpose 1 LI (spec forbids LI for Purpose 1 always)';
  like "$result", qr/legitimate interest not permitted for purpose 1/, 'reason names the carve-out rule (Phase 6.3)';
};

subtest "Validator min_tcf_policy_version" => sub {

  # The 'COwAdDh...' fixture is policy_version 2 (TCF v2.0).
  my $tc_v20 = 'COwAdDhOwAdDhN4ABAENAPCgAAQAAv___wAAAFP_AAp_4AI6ACACAA';

  # No min_tcf_policy_version set: no check, normal behaviour.
  my $v_default = GDPR::IAB::TCFv2::Validator->new(vendor_id => 1, consent_purpose_ids => [6],);
  ok $v_default->validate($tc_v20), 'no min_tcf_policy_version set: passes for v2.0 string';

  # min_tcf_policy_version satisfied (v2.0 string with min=2).
  my $v_satisfied
    = GDPR::IAB::TCFv2::Validator->new(vendor_id => 1, consent_purpose_ids => [6], min_tcf_policy_version => 2,);
  ok $v_satisfied->validate($tc_v20), 'min_tcf_policy_version=2 passes for v2.0 string';

  # min_tcf_policy_version not satisfied (v2.0 string with min=5).
  my $v_too_old
    = GDPR::IAB::TCFv2::Validator->new(vendor_id => 1, consent_purpose_ids => [6], min_tcf_policy_version => 5,);
  my $result = $v_too_old->validate($tc_v20);
  ok !$result, 'min_tcf_policy_version=5 fails for v2.0 string';
  like "$result", qr/TC string policy version 2 is below required minimum 5/,
    'reason names the actual and required versions';

  # In fail-fast mode, the version check must run FIRST and short-circuit.
  # Even though consent_purpose_ids includes a deliberately-failing purpose,
  # only one reason is reported -- the version mismatch.
  my $v_short_circuit = GDPR::IAB::TCFv2::Validator->new(
    vendor_id              => 1,
    consent_purpose_ids    => [1],    # would also fail
    min_tcf_policy_version => 5,
  );
  my $r_first = $v_short_circuit->validate($tc_v20);
  is scalar($r_first->reasons), 1, 'fail-fast stops after the version-check reason';
  like "$r_first", qr/policy version/, 'first reason is the version-check failure';

  # In --all mode, the version check still runs first but the other
  # rules continue accumulating.
  my $r_all = $v_short_circuit->validate_all($tc_v20);
  is scalar($r_all->reasons), 2, 'validate_all accumulates version + consent failures';
  like(($r_all->reasons)[0], qr/policy version/, 'version reason comes first');
};

subtest "Validator coherence checks at construction time" => sub {

  # A purpose can't be in both consent_purpose_ids and
  # legitimate_interest_purpose_ids — the GVL schema treats those as
  # mutually exclusive declarations.
  throws_ok {
    GDPR::IAB::TCFv2::Validator->new(
      vendor_id                       => 1,
      consent_purpose_ids             => [3],
      legitimate_interest_purpose_ids => [3],
    );
  }
  qr/purpose 3 cannot be in both consent_purpose_ids and legitimate_interest_purpose_ids/,
    'croaks when a purpose is listed under both bases';

  # A flexible purpose must be listed under one of the two bases —
  # otherwise no default can be derived.
  throws_ok {
    GDPR::IAB::TCFv2::Validator->new(vendor_id => 1, flexible_purpose_ids => [5],);
  }
  qr/flexible purpose 5 must also appear in consent_purpose_ids or legitimate_interest_purpose_ids/,
    'croaks when a flexible purpose has no derivable default basis';

  # Sanity: a properly-coherent config still constructs.
  lives_ok {
    GDPR::IAB::TCFv2::Validator->new(
      vendor_id                       => 1,
      consent_purpose_ids             => [1, 6],
      legitimate_interest_purpose_ids => [2, 10],
      flexible_purpose_ids            => [6, 2],
    );
  }
  'coherent configuration constructs without error';
};

subtest "flexible_purpose_ids derives default basis from membership" => sub {
  my $tc_string = 'COwAdDhOwAdDhN4ABAENAPCgAAQAAv___wAAAFP_AAp_4AI6ACACAA';

  # Vendor 1, Purpose 6: consent=1, LI=1.  P6 is in consent_purpose_ids
  # AND flexible_purpose_ids -> flexible with default consent.  Passes.
  my $v_consent_default
    = GDPR::IAB::TCFv2::Validator->new(vendor_id => 1, consent_purpose_ids => [6], flexible_purpose_ids => [6],);
  ok $v_consent_default->validate($tc_string),
    'flexible P6 with default consent (because P6 is in consent_purpose_ids) passes';

  # Vendor 2, Purpose 2: consent=0, LI=1.  P2 is in
  # legitimate_interest_purpose_ids AND flexible_purpose_ids -> flexible
  # with default LI.  Passes (LI bit is set).
  my $v_li_default = GDPR::IAB::TCFv2::Validator->new(
    vendor_id                       => 2,
    legitimate_interest_purpose_ids => [2],
    flexible_purpose_ids            => [2],
  );
  ok $v_li_default->validate($tc_string),
    'flexible P2 with default LI (because P2 is in legitimate_interest_purpose_ids) passes';

  # P2 in consent_purpose_ids AND flexible_purpose_ids -> default consent.
  # Vendor 2 has consent=0 for P2 -> fails.
  my $v_p2_consent_flex
    = GDPR::IAB::TCFv2::Validator->new(vendor_id => 2, consent_purpose_ids => [2], flexible_purpose_ids => [2],);
  ok !$v_p2_consent_flex->validate($tc_string), 'flexible P2 with default consent fails for vendor 2 (no consent bit)';
};

subtest "Validator strict_legal_basis mode override" => sub {
  my $tc_string = 'COwAdDhOwAdDhN4ABAENAPCgAAQAAv___wAAAFP_AAp_4AI6ACACAA';

  # Out-of-range purpose ID 25.
  my $validator = GDPR::IAB::TCFv2::Validator->new(vendor_id => 1, consent_purpose_ids => [25],);

  # Without strict_legal_basis (the default): the underlying parser warns and returns 0,
  # so the validator reports a normal failure.  Use Test::Warn to swallow
  # the warning while asserting on its content.
  my $result;
  warning_like {
    $result = $validator->validate($tc_string);
  }
  qr/invalid purpose id 25/, 'underlying parser warns about the invalid id without strict_legal_basis';
  ok !$result, 'invalid purpose id without strict_legal_basis yields a failed result';

  # With strict_legal_basis=1: the underlying parser croaks, and that propagates up
  # through the validator unchanged.
  throws_ok {
    $validator->validate($tc_string, strict_legal_basis => 1);
  }
  qr/invalid purpose id 25/, 'invalid purpose id with strict_legal_basis=1 propagates the parser croak';
};

subtest "Validator validate_all accumulates across rule families" => sub {
  my $tc_string = 'COwAdDhOwAdDhN4ABAENAPCgAAQAAv___wAAAFP_AAp_4AI6ACACAA';

  # Vendor 99 is out of range for this fixture's bitfields (max=10), so
  # every rule fails uniformly.  Three rules, three reasons:
  #   - Consent rule:  P1/V99 -> "(consent)"
  #   - Consent rule:  P6/V99, via flexible default consent -> "(consent)"
  #   - LI rule:       P10/V99 -> "(legitimate interest)"
  my $validator = GDPR::IAB::TCFv2::Validator->new(
    vendor_id                       => 99,
    consent_purpose_ids             => [1, 6],
    legitimate_interest_purpose_ids => [10],
    flexible_purpose_ids            => [6],
  );

  my $result = $validator->validate_all($tc_string);
  ok !$result, 'all-fail validation reports failure';
  is scalar($result->reasons), 3, 'three reasons accumulated across consent + LI rules';

  my $joined = join '|', $result->reasons;
  like $joined, qr/\(consent\)/,             'has the consent rule reason';
  like $joined, qr/\(legitimate interest\)/, 'has the LI rule reason';
  like $joined, qr/purpose 6 \(consent\)/,   'flexible P6 with default consent reports as a consent failure';
};

subtest "Validator per-call list overrides" => sub {
  my $tc_string = 'COwAdDhOwAdDhN4ABAENAPCgAAQAAv___wAAAFP_AAp_4AI6ACACAA';

  subtest "consent_purpose_ids per-call override" => sub {

    # Constructor list [1] would fail (V1 P1 consent=0). Per-call
    # override [6] passes (V1 P6 consent=1) -- proves the override
    # replaces, not merges with, the constructor list.
    my $validator = GDPR::IAB::TCFv2::Validator->new(vendor_id => 1, consent_purpose_ids => [1],);

    ok !$validator->validate($tc_string), 'baseline fails with constructor consent=[1]';

    ok $validator->validate($tc_string, consent_purpose_ids => [6]), 'per-call consent=[6] passes';

    my $result = $validator->validate($tc_string, consent_purpose_ids => [1, 6]);
    ok !$result, 'per-call [1,6] still fails on P1';
    like "$result", qr/purpose 1/, 'reason mentions P1';

    ok $validator->validate($tc_string, consent_purpose_ids => []), 'per-call empty consent list passes vacuously';
  };

  subtest "legitimate_interest_purpose_ids per-call override" => sub {

    # Constructor list [10] passes (V1 P10 LI=1, policy v2 -> no
    # carve-out for P10). Per-call switches to [1] which always
    # triggers the LI carve-out reason (P1 forbidden for LI).
    my $validator = GDPR::IAB::TCFv2::Validator->new(vendor_id => 1, legitimate_interest_purpose_ids => [10],);

    ok $validator->validate($tc_string), 'baseline passes with constructor LI=[10]';

    my $result = $validator->validate($tc_string, legitimate_interest_purpose_ids => [1],);
    ok !$result, 'per-call LI=[1] fails (carve-out)';
    like "$result", qr/legitimate interest not permitted for purpose 1/, 'failure is the LI carve-out reason';

    ok $validator->validate($tc_string, legitimate_interest_purpose_ids => [7],),
      'per-call LI=[7] passes (V1 P7 LI=1, no carve-out at policy v2)';
  };

  subtest "flexible_purpose_ids per-call override -- orphan drop" => sub {

    # Constructor's _check_coherence would croak on flex=[99] because
    # 99 is not in consent or LI. The per-call path skips that check:
    # the rule loops only iterate over the consent/LI lists, so an
    # orphan flex pid is unreachable and silently ignored at runtime.
    my $validator = GDPR::IAB::TCFv2::Validator->new(vendor_id => 1, consent_purpose_ids => [6],);

    my $result;
    lives_ok {
      $result = $validator->validate($tc_string, flexible_purpose_ids => [99],);
    }
    'per-call orphan flexible pid does not croak';
    ok $result, 'orphan flex pid does not affect validation outcome';
  };

  subtest "all three list overrides simultaneously" => sub {

    # Constructor: a passing static policy.
    my $validator = GDPR::IAB::TCFv2::Validator->new(vendor_id => 1, consent_purpose_ids => [6],);
    ok $validator->validate($tc_string), 'baseline passes';

    # Per-call: replace all three lists at once.
    # consent=[6] (passes), LI=[10] (passes), flex=[6,10] (no PR so
    # flex API mirrors basis-direct -- still passes).
    my $result = $validator->validate(
      $tc_string,
      consent_purpose_ids             => [6],
      legitimate_interest_purpose_ids => [10],
      flexible_purpose_ids            => [6, 10],
    );
    ok $result, 'all-three override passes when each list is satisfiable';
  };

  subtest "validate_all with per-call list overrides" => sub {

    # Vendor 99 fails uniformly (out of range). Override all three
    # lists per call and confirm validate_all reports a reason for
    # each rule that fails.
    my $validator = GDPR::IAB::TCFv2::Validator->new(vendor_id => 99, consent_purpose_ids => [6],);

    my $result
      = $validator->validate_all($tc_string, consent_purpose_ids => [7, 8], legitimate_interest_purpose_ids => [9],);
    ok !$result, 'validate_all reports failure under overrides';
    is scalar($result->reasons), 3, 'three reasons accumulated (two consent + one LI)';
  };
};

done_testing;
