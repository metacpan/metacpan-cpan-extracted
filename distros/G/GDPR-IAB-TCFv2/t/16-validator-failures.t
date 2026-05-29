use strict;
use warnings;
use Test::More;
use FindBin;
use File::Spec;
use lib 'lib';

use GDPR::IAB::TCFv2::Validator;
use GDPR::IAB::TCFv2::Validator::Failure;
use GDPR::IAB::TCFv2::Validator::Reason qw<:all>;

# A known-valid TC string from elsewhere in the test suite. CMP id 21,
# vendor consents include 32. Used as the baseline for failure-injecting
# variations below.
my $tc_string = 'CLcVDxRMWfGmWAVAHCENAXCkAKDAADnAABRgA5mdfCKZuYJez-NQm0TBMYA4oCAAGQYIAAAAAAEAIAEgAA';

subtest 'Validator::Failure: round-trip and stringification' => sub {
  my $f = GDPR::IAB::TCFv2::Validator::Failure->new(
    code             => ReasonPublisherRestrictionNotAllowed,
    message          => "publisher restriction: not allowed (purpose 5)",
    purpose_id       => 5,
    vendor_id        => 284,
    restriction_type => 0,
  );

  is($f->code,             ReasonPublisherRestrictionNotAllowed,             'code accessor');
  is($f->message,          "publisher restriction: not allowed (purpose 5)", 'message accessor');
  is($f->purpose_id,       5,                                                'purpose_id accessor');
  is($f->vendor_id,        284,                                              'vendor_id accessor');
  is($f->restriction_type, 0,                                                'restriction_type accessor');
  is($f->cmp_id,           undef,                                            'cmp_id is undef when not set');

  is("$f", "publisher restriction: not allowed (purpose 5)", 'stringification returns message');
};

subtest 'Validator::Failure: unset structured fields are undef' => sub {
  my $f = GDPR::IAB::TCFv2::Validator::Failure->new(code => ReasonVendorNotAllowed, message => "vendor not allowed",);

  is($f->purpose_id,       undef, 'purpose_id defaults to undef');
  is($f->vendor_id,        undef, 'vendor_id defaults to undef');
  is($f->restriction_type, undef, 'restriction_type defaults to undef');
  is($f->cmp_id,           undef, 'cmp_id defaults to undef');
};

subtest 'Validator::Result: passing result has no failures' => sub {

  # Vendor 21 has a vendor-level consent bit in the fixture, so it clears the
  # global vendor gate; with no purposes configured the result is a clean pass.
  my $validator = GDPR::IAB::TCFv2::Validator->new(vendor_id => 21);
  my $result    = $validator->validate($tc_string);

  ok($result,           'result is truthy when validation passes');
  ok($result->is_valid, 'is_valid is true when validation passes');

  my @failures = $result->failures;
  is(scalar @failures, 0, 'no failures on a passing result');

  my @codes = $result->reason_codes;
  is(scalar @codes, 0, 'no reason codes on a passing result');

  my @reasons = $result->reasons;
  is(scalar @reasons, 0, 'no reason strings on a passing result');

  is("$result", '', 'stringifies to empty on success');
};

subtest 'Validator::Result: failing result exposes failures + codes + reasons' => sub {

  # Vendor 21 has a vendor-level consent bit (clears the global gate), but
  # purposes 2 and 6 lack purpose-level consent in this fixture, so each
  # required purpose fails with ReasonVendorNotAllowedConsent.
  my $validator = GDPR::IAB::TCFv2::Validator->new(vendor_id => 21, consent_purpose_ids => [2, 6],);
  my $result    = $validator->validate_all($tc_string);

  ok(!$result,           'result is falsy on failure');
  ok(!$result->is_valid, 'is_valid is false on failure');

  my @failures = $result->failures;
  cmp_ok(scalar @failures, '>=', 1, 'at least one failure recorded');

  isa_ok $failures[0], 'GDPR::IAB::TCFv2::Validator::Failure', 'each entry is a Failure object';

  my @codes   = $result->reason_codes;
  my @reasons = $result->reasons;
  is(scalar @codes,   scalar @failures, 'reason_codes count matches');
  is(scalar @reasons, scalar @failures, 'reasons count matches');

  # All consent-purpose failures should carry the consent code and
  # the offending vendor + purpose ids.
  for my $f (@failures) {
    is($f->code,      ReasonVendorNotAllowedConsent, 'consent-path failures use ReasonVendorNotAllowedConsent');
    is($f->vendor_id, 21,                            'vendor_id is set on the failure');
    ok(defined $f->purpose_id, 'purpose_id is set on the failure');
  }

  # Stringified result is the failure messages joined per the
  # output-record-separator overload (legacy contract).
  like("$result", qr/vendor 21 not allowed for purpose/, 'stringification includes failure messages');
};

subtest 'Validator::Result: min_tcf_policy_version failure carries correct code' => sub {

  # The fixture TC string uses TCF policy version 2 (pre v2.3).
  # A floor of 5 forces a ReasonPolicyVersionTooLow failure on the
  # first rule, before any vendor/purpose check.
  my $validator = GDPR::IAB::TCFv2::Validator->new(vendor_id => 32, min_tcf_policy_version => 5,);
  my $result    = $validator->validate($tc_string);

  ok(!$result, 'result is falsy when policy version is too low');

  my @failures = $result->failures;
  is(scalar @failures, 1, 'fail-fast yields exactly one failure');

  is($failures[0]->code, ReasonPolicyVersionTooLow, 'code is ReasonPolicyVersionTooLow');
  like(
    $failures[0]->message,
    qr/policy version \d+ is below required minimum 5/,
    'message describes the policy-version mismatch'
  );
};

subtest 'Validator::Result: P1 LI carve-out emits ReasonLegitimateInterestNotPermittedForPurpose' => sub {

  # Policy version 2 fixture; vendor 1 has the LI bit but the spec
  # forbids LI for Purpose 1 regardless of the bit. The validator
  # detects this *before* delegating to the parser, so the failure
  # carries the carve-out code and not the generic LI vendor code.
  my $validator = GDPR::IAB::TCFv2::Validator->new(vendor_id => 1, legitimate_interest_purpose_ids => [1],);
  my $result    = $validator->validate($tc_string);

  ok(!$result, 'P1 LI is rejected at any policy version');

  my @failures = $result->failures;
  is(scalar @failures, 1, 'fail-fast yields exactly one failure');

  is(
    $failures[0]->code,
    ReasonLegitimateInterestNotPermittedForPurpose,
    'code is ReasonLegitimateInterestNotPermittedForPurpose'
  );
  is($failures[0]->purpose_id, 1,                                                 'purpose_id is 1');
  is($failures[0]->vendor_id,  1,                                                 'vendor_id is set on the failure');
  is($failures[0]->message,    'legitimate interest not permitted for purpose 1', 'message describes the carve-out');
};

subtest 'Validator::Result: P3 LI carve-out only fires on TCF v2.2+ (policy >= 4)' => sub {

  # Policy version 5 fixture (TCF v2.2+). Vendor 32 has both consent
  # and LI bits, but the spec forbids LI for Purposes 3-6 at this
  # policy version regardless of the bit.
  my $tc_v22
    = 'CP188cAQKFpAAAHABBENBSFsAP_gAEPgAAiQKqNX_H__bW9r8X73aft0eY1P9_j77uQxBhfJE-4FzLvW_JwXx2ExNA36tqIKmRIEu3bBIQNlHJHUTVigaogVryHMak2cpTNKJ6BkiFMRM2dYCF5vm4tj-QKY5_r993dx2D-t_dv83dzyz81Hn3f5_2e0eLCdQ5-tDfv9bROb-9IPd_78v4v8_l_rk2_eT1n_tevr7D_-ft8__XW_9_fff_9Pn_-uB_-_3_vf_EFUwCTDQqIA-wJCQg0DCKBACoKwgIoFAQAAJA0QEAJgwKdgYALrCRACAFAAMEAIAAQZAAgAAAgAQiACQAoEAAEAgUAAYAEAwEABAwAAgAsBAIAAQHQMUwIIFAsIEjMioUwIQoEggJbKhBICgQVwhCLPAIgERMFAAgAAAVgACAsFgcSSAlQkECXUG0AABAAgFEIFQgk9MAAwJmy1B4MG0ZWmAYPmCRDTAMgCIIyEAAAA.f_wACHwAAAAA';

  my $validator_v22 = GDPR::IAB::TCFv2::Validator->new(vendor_id => 32, legitimate_interest_purpose_ids => [3],);
  my $result_v22    = $validator_v22->validate($tc_v22);

  ok(!$result_v22, 'P3 LI rejected at policy 5');
  my @f22 = $result_v22->failures;
  is($f22[0]->code,       ReasonLegitimateInterestNotPermittedForPurpose, 'P3 at policy 5 → carve-out reason');
  is($f22[0]->purpose_id, 3,                                              'purpose_id is 3');

  # Same purpose ID against the policy-2 fixture: carve-out does NOT
  # apply (P3-6 carve-out only kicks in at policy >= 4). Vendor 1 has
  # both purpose 3 LI and vendor LI in this fixture, so this should
  # actually pass — confirming the carve-out is policy-version gated.
  my $validator_v20 = GDPR::IAB::TCFv2::Validator->new(vendor_id => 1, legitimate_interest_purpose_ids => [3],);
  my $result_v20    = $validator_v20->validate($tc_string);

  ok($result_v20, 'P3 LI passes at policy 2 (carve-out does not apply)');
};

subtest 'Validator::Result: NotAllowed publisher restriction emits ReasonPublisherRestrictionNotAllowed' => sub {

  # Under the global vendor gate, a NotAllowed restriction reason is only
  # reachable for a vendor that also holds a vendor-level bit (a bit-less
  # vendor is rejected by the gate first). No fixture in the corpus pairs a
  # NotAllowed restriction with a bit-bearing vendor, so the restriction ->
  # reason mapping is exercised directly against the helper, with a stub TC
  # that reports a type-0 (NotAllowed) restriction. (RequireConsent and
  # RequireLegitimateInterest are covered end-to-end below.)
  {

    package PRStubNotAllowed;
    sub new { return bless {}, shift }

    # NotAllowed == 0; report it for any (purpose, vendor) pair.
    sub check_publisher_restriction { my (undef, undef, $type) = @_; return $type == 0 ? 1 : 0 }
  }

  my $validator = GDPR::IAB::TCFv2::Validator->new(vendor_id => 7);
  my $failure   = $validator->_publisher_restriction_failure(PRStubNotAllowed->new, 7, 1, 0);

  ok($failure, 'a publisher-restriction failure is returned');
  is($failure->code,             ReasonPublisherRestrictionNotAllowed, 'code is ReasonPublisherRestrictionNotAllowed');
  is($failure->restriction_type, 0,                                    'restriction_type is 0 (NotAllowed)');
  is($failure->purpose_id,       1,                                    'purpose_id is 1');
  is($failure->vendor_id,        7,                                    'vendor_id is 7');
  like($failure->message, qr/purpose 1 not allowed/, 'message names the restriction');
};

subtest 'Validator::Result: RequireConsent restriction on LI basis emits ReasonPublisherRestrictionRequireConsent' =>
  sub {

  # CQa0zs... (policy 5) has a RequireConsent restriction for vendor 2 /
  # purpose 8. Vendor 2 holds a vendor-level consent bit (so it clears the
  # global gate); configuring purpose 8 under legitimate_interest is a
  # contradiction the validator must surface as the restriction-driven reason
  # rather than the generic LI-vendor reason.
  my $tc_with_consent_pr
    = 'CQa0zsAQa0zsAAHABBENCEFsAP_AAELgAAAoLstR_G__bXlr8bb3aftkeYxf9_hr7sQhBgbJk24FzLvW7JwXx2E7JAzatqIKmRIAu3BBIQNlHIDURVCgKIgFryDMaEyUoTtKJ6BkiFMRA2NYCExvi4pjWQCY5vr99ld1mR-J7dr82dzyy6hHv3a5_2S1UJCdIYctBfvsZBKT-9AE9_x8v4v4_F5pE2-eS1n_pGvp6jd-YnM_dBmxt-bSffTKn93rl_e7XvuZ_n37u94VX77v___vf6-7_u92C7CAZho1U0ZZOmgUKDxBAiIUFcQIUCAMAAEwbICBMyaFOQMAt9hMgBACgAGCBkQAIMUAQEASQAYVARQIQiAESIQ6AAMACAYCAKgZAAxEWIgEABID4OLYEEAkWICVnVUbYE4BCQSdtlY8sAwIa8QrFngFECYmCgDARgAKAgAAeHyFJNwWsyCiLiO6QIAgAATyzAiRSl2EMKw3RaB8DTqMjTANXzhMlp0mwBsFZCabMJ_QmHmmqIUEuTuzSzV3AGIQAYAAgu8VAAwABBd4eABgACC7xMADAAEF3goAGAAILvFwAMAAQXeA';

  my $validator = GDPR::IAB::TCFv2::Validator->new(vendor_id => 2, legitimate_interest_purpose_ids => [8],);
  my $result    = $validator->validate($tc_with_consent_pr);

  ok(!$result, 'RequireConsent restriction rejects LI purpose');

  my @failures = $result->failures;
  is(scalar @failures,   1,                                        'fail-fast yields exactly one failure');
  is($failures[0]->code, ReasonPublisherRestrictionRequireConsent, 'code is ReasonPublisherRestrictionRequireConsent');
  is($failures[0]->restriction_type, 1,                            'restriction_type is 1 (RequireConsent)');
  is($failures[0]->purpose_id,       8,                            'purpose_id is 8');
  is($failures[0]->vendor_id,        2,                            'vendor_id is 2');
  };

subtest 'Validator::Result: RequireLegitimateInterest restriction on consent basis emits matching reason' => sub {

  # gdpr_subset corpus row CQa0zsAQa0zsAAHABBENCEFsAP_AAELgA...
  # (policy 5) has a RequireLegitimateInterest (type 2) restriction
  # for vendor 2 / purpose 2. Vendor 2 has consent + purpose-consent
  # set, so the failure can only be coming from the restriction.
  my $tc_with_li_pr
    = 'CQa0zsAQa0zsAAHABBENCEFsAP_AAELgAAAoLstR_G__bXlr8bb3aftkeYxf9_hr7sQhBgbJk24FzLvW7JwXx2E7JAzatqIKmRIAu3BBIQNlHIDURVCgKIgFryDMaEyUoTtKJ6BkiFMRA2NYCExvi4pjWQCY5vr99ld1mR-J7dr82dzyy6hHv3a5_2S1UJCdIYctBfvsZBKT-9AE9_x8v4v4_F5pE2-eS1n_pGvp6jd-YnM_dBmxt-bSffTKn93rl_e7XvuZ_n37u94VX77v___vf6-7_u92C7CAZho1U0ZZOmgUKDxBAiIUFcQIUCAMAAEwbICBMyaFOQMAt9hMgBACgAGCBkQAIMUAQEASQAYVARQIQiAESIQ6AAMACAYCAKgZAAxEWIgEABID4OLYEEAkWICVnVUbYE4BCQSdtlY8sAwIa8QrFngFECYmCgDARgAKAgAAeHyFJNwWsyCiLiO6QIAgAATyzAiRSl2EMKw3RaB8DTqMjTANXzhMlp0mwBsFZCabMJ_QmHmmqIUEuTuzSzV3AGIQAYAAgu8VAAwABBd4eABgACC7xMADAAEF3goAGAAILvFwAMAAQXeA';

  my $validator = GDPR::IAB::TCFv2::Validator->new(vendor_id => 2, consent_purpose_ids => [2],);
  my $result    = $validator->validate($tc_with_li_pr);

  ok(!$result, 'RequireLegitimateInterest restriction rejects consent purpose');

  my @failures = $result->failures;
  is(scalar @failures, 1, 'fail-fast yields exactly one failure');
  is(
    $failures[0]->code,
    ReasonPublisherRestrictionRequireLegitimateInterest,
    'code is ReasonPublisherRestrictionRequireLegitimateInterest'
  );
  is($failures[0]->restriction_type, 2, 'restriction_type is 2 (RequireLegitimateInterest)');
  is($failures[0]->purpose_id,       2, 'purpose_id is 2');
  is($failures[0]->vendor_id,        2, 'vendor_id is 2');
};

subtest 'global vendor gate short-circuits per-purpose checks' => sub {

  # A vendor with neither consent nor LI at the vendor level must fail with
  # ReasonVendorNotAllowed and stop before per-purpose checks.
  my $v     = GDPR::IAB::TCFv2::Validator->new(vendor_id => 9999, consent_purpose_ids => [1, 3],);
  my @codes = $v->validate_all($tc_string)->reason_codes;
  my %seen  = map { $_ => 1 } @codes;

  ok $seen{ReasonVendorNotAllowed()},         "absent vendor => ReasonVendorNotAllowed";
  ok !$seen{ReasonVendorNotAllowedConsent()}, "per-purpose consent check is short-circuited";
};

subtest 'Validator::Result: unknown CMP carries ReasonCMPUnknown' => sub {
  require GDPR::IAB::TCFv2::CMPValidator;

  my $cmp_file = File::Spec->catfile($FindBin::Bin, 'corpus', 'cmp-list.json');

  # CMP 888 is not in the fixture; this TC string carries it.
  my $tc_unknown_cmp = 'COwAdDhOwAdDhN4ABAENAPCgAAQAAv___wAAAFP_AAp_4AI6ACACAA';

  my $validator
    = GDPR::IAB::TCFv2::Validator->new(vendor_id => 1, cmp_validator => {file => $cmp_file, now => 1776254400},);
  my $result = $validator->validate($tc_unknown_cmp);

  ok(!$result, 'unknown CMP fails validation');

  my @failures = $result->failures;
  is(scalar @failures, 1, 'fail-fast yields exactly one failure');

  is($failures[0]->code,   ReasonCMPUnknown, 'code is ReasonCMPUnknown');
  is($failures[0]->cmp_id, 888,              'cmp_id is set to the CMP from the consent string');
};

subtest 'Validator::Result: deleted CMP carries ReasonCMPDeleted' => sub {
  require GDPR::IAB::TCFv2::CMPValidator;

  # Baseline string carries CMP 21; mark it deleted in an inline registry.
  my $validator = GDPR::IAB::TCFv2::Validator->new(
    vendor_id     => 32,
    cmp_validator => {now => 1776254400, data => '{"cmps":{"21":{"id":21,"deletedDate":"2020-01-01T00:00:00Z"}}}',},
  );
  my @failures = $validator->validate_all($tc_string)->failures;

  ok((grep { $_->code == ReasonCMPDeleted } @failures), 'deleted CMP => ReasonCMPDeleted');
};

done_testing;
