package Microsoft::AdCenter::V8::CampaignManagementService::Test::LocationExclusion;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::CampaignManagementService;
use Microsoft::AdCenter::V8::CampaignManagementService::LocationExclusion;

sub test_can_create_location_exclusion_and_set_all_fields : Test(3) {
    my $location_exclusion = Microsoft::AdCenter::V8::CampaignManagementService::LocationExclusion->new
        ->ExcludedGeoTargets('excluded geo targets')
        ->ExcludedRadiusTarget('excluded radius target')
    ;

    ok($location_exclusion);

    is($location_exclusion->ExcludedGeoTargets, 'excluded geo targets', 'can get excluded geo targets');
    is($location_exclusion->ExcludedRadiusTarget, 'excluded radius target', 'can get excluded radius target');
};

1;
