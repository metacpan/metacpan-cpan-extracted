use strict;
use warnings;

use Test::More;
use Test::Exception;
use Test::Warn;

use GDPR::IAB::TCFv2;
use GDPR::IAB::TCFv2::Constants::RestrictionType qw<:all>;

subtest "is_vendor_consent_allowed" => sub {
  my $tc_string = 'COwAdDhOwAdDhN4ABAENAPCgAAQAAv___wAAAFP_AAp_4AI6ACACAA';
  my $consent   = GDPR::IAB::TCFv2->Parse($tc_string);

# Purpose 6: consent allowed, LI allowed. Vendor 1: consent allowed, LI allowed.
# No restriction for P6, V1.
  ok $consent->is_vendor_consent_allowed(1, 6), 'vendor 1 allowed for purpose 6 (consent)';

# Purpose 7: consent NOT allowed, LI allowed. Vendor 1: consent allowed, LI allowed.
  ok !$consent->is_vendor_consent_allowed(1, 7), 'vendor 1 NOT allowed for purpose 7 (consent bit is 0)';

# Purpose 1: consent NOT allowed, LI allowed. Vendor 1: consent allowed, LI allowed.
  ok !$consent->is_vendor_consent_allowed(1, 1), 'vendor 1 NOT allowed for purpose 1 (consent bit is 0)';

  # Restriction check: P7, V32 has restriction RequireConsent (1).
  # Even if bits were set, RequireLegitimateInterest restriction would block it.
  # In this string, P7, V32 does NOT have consent bits anyway.
};

subtest "is_vendor_legitimate_interest_allowed" => sub {
  my $tc_string = 'COwAdDhOwAdDhN4ABAENAPCgAAQAAv___wAAAFP_AAp_4AI6ACACAA';
  my $consent   = GDPR::IAB::TCFv2->Parse($tc_string);

# Purpose 2: consent NOT allowed, LI allowed. Vendor 2: consent allowed, LI allowed.
  ok $consent->is_vendor_legitimate_interest_allowed(2, 2), 'vendor 2 allowed for purpose 2 (LI)';

  # Restriction check: P7, V32 has restriction RequireConsent (1).
  # This should block LI check even if bits are set.
  ok !$consent->is_vendor_legitimate_interest_allowed(32, 7),
    'vendor 32 NOT allowed for purpose 7 (LI) due to RequireConsent restriction';
};

subtest "is_vendor_allowed_for_flexible_purpose" => sub {
  my $tc_string = 'COwAdDhOwAdDhN4ABAENAPCgAAQAAv___wAAAFP_AAp_4AI6ACACAA';
  my $consent   = GDPR::IAB::TCFv2->Parse($tc_string);

  # P6, V1: No restrictions. Consent=1, LI=1.
  ok $consent->is_vendor_allowed_for_flexible_purpose(1, 6, 0), 'flexible P6, V1 (default consent) -> OK';
  ok $consent->is_vendor_allowed_for_flexible_purpose(1, 6, 1), 'flexible P6, V1 (default LI) -> OK';

  # P2, V2: No restrictions. Consent=0, LI=1.
  ok !$consent->is_vendor_allowed_for_flexible_purpose(2, 2, 0), 'flexible P2, V2 (default consent) -> NOT OK';
  ok $consent->is_vendor_allowed_for_flexible_purpose(2,  2, 1), 'flexible P2, V2 (default LI) -> OK';

  # P7, V32: Restriction RequireConsent (1). Consent=0, LI=1.
  # It MUST check consent bit (which is 0).
  ok !$consent->is_vendor_allowed_for_flexible_purpose(32, 7, 1),
    'flexible P7, V32 (default LI) -> NOT OK due to RequireConsent restriction';
};

subtest "strictness" => sub {
  my $tc_string = 'COwAdDhOwAdDhN4ABAENAPCgAAQAAv___wAAAFP_AAp_4AI6ACACAA';

  subtest "default (non-strict)" => sub {
    my $consent = GDPR::IAB::TCFv2->Parse($tc_string);
    my $val;
    warning_like {
      $val = $consent->is_vendor_consent_allowed(1, 25);
    }
    qr/invalid purpose id 25/, 'should warn for invalid purpose id';
    is $val, 0, 'should return 0';
  };

  subtest "explicit non-strict" => sub {
    my $consent = GDPR::IAB::TCFv2->Parse($tc_string);
    my $val;
    warning_like {
      $val = $consent->is_vendor_consent_allowed(1, 0, strict => 0);
    }
    qr/invalid purpose id 0/, 'should warn for invalid purpose id';
    is $val, 0, 'should return 0';
  };

  subtest "strict mode (constructor)" => sub {
    my $consent = GDPR::IAB::TCFv2->Parse($tc_string, strict => 1);
    throws_ok {
      $consent->is_vendor_consent_allowed(1, 25);
    }
    qr/invalid purpose id 25/, 'should croak for invalid purpose id';
  };

  subtest "strict mode (override)" => sub {
    my $consent = GDPR::IAB::TCFv2->Parse($tc_string);
    throws_ok {
      $consent->is_vendor_consent_allowed(1, 25, strict => 1);
    }
    qr/invalid purpose id 25/, 'should croak for invalid purpose id';
  };
};

done_testing;
