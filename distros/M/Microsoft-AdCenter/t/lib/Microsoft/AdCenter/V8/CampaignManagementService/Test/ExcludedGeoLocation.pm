package Microsoft::AdCenter::V8::CampaignManagementService::Test::ExcludedGeoLocation;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::CampaignManagementService;
use Microsoft::AdCenter::V8::CampaignManagementService::ExcludedGeoLocation;

sub test_can_create_excluded_geo_location_and_set_all_fields : Test(3) {
    my $excluded_geo_location = Microsoft::AdCenter::V8::CampaignManagementService::ExcludedGeoLocation->new
        ->LocationName('location name')
        ->LocationType('location type')
    ;

    ok($excluded_geo_location);

    is($excluded_geo_location->LocationName, 'location name', 'can get location name');
    is($excluded_geo_location->LocationType, 'location type', 'can get location type');
};

1;
