use strict;
use warnings;
use Test::More;

# Phase 3: TCF v2.3 spec-aligned long-form aliases for the established
# short-form Purpose and SpecialFeature constants.  Both names must
# resolve to the same integer and must be exported via :all.

use GDPR::IAB::TCFv2::Constants::Purpose        qw<:all>;
use GDPR::IAB::TCFv2::Constants::SpecialFeature qw<:all>;

subtest 'Purpose aliases resolve to the canonical integers' => sub {

  # Use parens on the LHS to force constant-call interpretation; the fat
  # comma `=>` would otherwise auto-quote the bareword to a string.
  my @pairs = (
    [InfoStorageAccess(),        StoreAndOrAccessInformationOnDevice()],
    [BasicAdserving(),           UseLimitedDataToSelectAdvertising()],
    [PersonalizationProfile(),   CreateProfilesForPersonalisedAdvertising()],
    [PersonalizationSelection(), UseProfilesToSelectPersonalisedAdvertising()],
    [ContentProfile(),           CreateProfilesToPersonaliseContent()],
    [ContentSelection(),         UseProfilesToSelectPersonalisedContent()],
    [AdPerformance(),            MeasureAdvertisingPerformance()],
    [ContentPerformance(),       MeasureContentPerformance()],
    [MarketResearch(),           UnderstandAudiences()],
    [DevelopImprove(),           DevelopAndImproveServices()],
    [SelectContent(),            UseLimitedDataToSelectContent()],
  );

  for my $pair (@pairs) {
    is($pair->[0], $pair->[1], "Purpose alias resolves to id $pair->[0]");
  }
  is(scalar @pairs, 11, 'all 11 purposes have an alias');
};

subtest 'SpecialFeature aliases resolve to the canonical integers' => sub {
  is(Geolocation, UsePreciseGeolocationData(),                          'SpecialFeature 1 alias resolves to id 1');
  is(DeviceScan,  ActivelyScanDeviceCharacteristicsForIdentification(), 'SpecialFeature 2 alias resolves to id 2');
};

subtest 'aliases work as drop-in replacements in the parser API' => sub {
  require GDPR::IAB::TCFv2;

  my $tc_string = 'CLcVDxRMWfGmWAVAHCENAXCkAKDAADnAABRgA5mdfCKZuYJez-NQm0TBMYA4oCAAGQYIAAAAAAEAIAEgAA';
  my $consent   = GDPR::IAB::TCFv2->Parse($tc_string);

  # Whatever the consent says about purpose 1, both names must agree.
  is(
    !!$consent->is_purpose_consent_allowed(InfoStorageAccess),
    !!$consent->is_purpose_consent_allowed(StoreAndOrAccessInformationOnDevice),
    'is_purpose_consent_allowed accepts the alias for purpose 1'
  );
  is(
    !!$consent->is_special_feature_opt_in(Geolocation),
    !!$consent->is_special_feature_opt_in(UsePreciseGeolocationData),
    'is_special_feature_opt_in accepts the alias for special feature 1'
  );
};

done_testing;
