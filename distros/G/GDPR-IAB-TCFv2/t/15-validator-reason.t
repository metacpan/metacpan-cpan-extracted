use strict;
use warnings;
use Test::More;

# Phase 6.1: machine-readable reason codes for the Validator. These
# constants and the reason_string() helper are the public vocabulary
# every later structured-failure consumer will speak.

use GDPR::IAB::TCFv2::Validator::Reason qw<:all>;

subtest 'all reason codes are distinct non-negative integers' => sub {
  my @codes = (
    ReasonNone(),                                     ReasonMissingDisclosedVendors(),
    ReasonVendorNotDisclosed(),                       ReasonVendorNotAllowed(),
    ReasonPurposeNotAllowed(),                        ReasonPublisherRestrictionNotAllowed(),
    ReasonPublisherRestrictionRequireConsent(),       ReasonPublisherRestrictionRequireLegitimateInterest(),
    ReasonVendorNotAllowedConsent(),                  ReasonVendorNotAllowedLegitimateInterest(),
    ReasonLegitimateInterestNotPermittedForPurpose(), ReasonPolicyVersionTooLow(),
    ReasonDecodeError(),                              ReasonInvalidCMP(),
  );

  is(scalar(@codes), 14, 'all 14 reason codes accounted for');

  is(ReasonNone, 0, 'ReasonNone is zero (sentinel for success)');

  my %seen;
  for my $code (@codes) {
    like($code, qr/^\d+$/, "code $code is a non-negative integer");
    ok(!$seen{$code}++, "code $code is unique");
  }
};

subtest 'reason_string returns the canonical description for each code' => sub {

  # Each pair is [ code, expected description ]. The descriptions are
  # the strings reason_string() returns for known codes; they mirror
  # the Go validator's Reason.String() output.
  my @cases = (
    [ReasonNone(),                                          "no failure"],
    [ReasonMissingDisclosedVendors(),                       "missing disclosed vendors"],
    [ReasonVendorNotDisclosed(),                            "vendor not disclosed"],
    [ReasonVendorNotAllowed(),                              "vendor not allowed"],
    [ReasonPurposeNotAllowed(),                             "purpose not allowed"],
    [ReasonPublisherRestrictionNotAllowed(),                "publisher restriction: not allowed"],
    [ReasonPublisherRestrictionRequireConsent(),            "publisher restriction: requires consent"],
    [ReasonPublisherRestrictionRequireLegitimateInterest(), "publisher restriction: requires legitimate interest"],
    [ReasonVendorNotAllowedConsent(),                       "vendor not allowed for purpose (consent)"],
    [ReasonVendorNotAllowedLegitimateInterest(),            "vendor not allowed for purpose (legitimate interest)"],
    [ReasonLegitimateInterestNotPermittedForPurpose(),      "legitimate interest not permitted for purpose"],
    [ReasonPolicyVersionTooLow(),                           "tcf policy version too low"],
    [ReasonDecodeError(),                                   "decode error"],
    [ReasonInvalidCMP(),                                    "invalid cmp id"],
  );

  for my $case (@cases) {
    my ($code, $expected) = @{$case};
    is(reason_string($code), $expected, "reason_string($code) -> $expected");
  }
};

subtest 'reason_string falls back for unknown or undefined codes' => sub {
  is(reason_string(255),   "unknown validation failure", 'unknown integer code falls back to a generic message');
  is(reason_string(undef), "unknown validation failure", 'undef code falls back to a generic message');
  is(reason_string(-1),    "unknown validation failure", 'negative code falls back to a generic message');
};

subtest 'ReasonDescription hashref is keyed by constant name' => sub {

  # Auto-quoted bareword keys: ReasonDescription->{ReasonNone} reads as
  # the string "ReasonNone", matching the Perl convention used by
  # RestrictionTypeDescription / SpecialFeatureDescription elsewhere
  # in this distribution.
  is(ReasonDescription->{ReasonNone},             "no failure",         'ReasonDescription->{ReasonNone}');
  is(ReasonDescription->{ReasonVendorNotAllowed}, "vendor not allowed", 'ReasonDescription->{ReasonVendorNotAllowed}');
  is(
    ReasonDescription->{ReasonLegitimateInterestNotPermittedForPurpose},
    "legitimate interest not permitted for purpose",
    'ReasonDescription->{ReasonLegitimateInterestNotPermittedForPurpose}'
  );

  is(ReasonDescription->{NotAReason}, undef, 'unknown name returns undef');
};

done_testing;
