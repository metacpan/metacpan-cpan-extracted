package Microsoft::AdCenter::V6::CampaignManagementService::Test::LocationTarget;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V6::CampaignManagementService;
use Microsoft::AdCenter::V6::CampaignManagementService::LocationTarget;

sub test_can_create_location_target_and_set_all_fields : Test(8) {
    my $location_target = Microsoft::AdCenter::V6::CampaignManagementService::LocationTarget->new
        ->BusinessTarget('business target')
        ->CityTarget('city target')
        ->CountryTarget('country target')
        ->MetroAreaTarget('metro area target')
        ->RadiusTarget('radius target')
        ->StateTarget('state target')
        ->TargetAllLocations('target all locations')
    ;

    ok($location_target);

    is($location_target->BusinessTarget, 'business target', 'can get business target');
    is($location_target->CityTarget, 'city target', 'can get city target');
    is($location_target->CountryTarget, 'country target', 'can get country target');
    is($location_target->MetroAreaTarget, 'metro area target', 'can get metro area target');
    is($location_target->RadiusTarget, 'radius target', 'can get radius target');
    is($location_target->StateTarget, 'state target', 'can get state target');
    is($location_target->TargetAllLocations, 'target all locations', 'can get target all locations');
};

1;
