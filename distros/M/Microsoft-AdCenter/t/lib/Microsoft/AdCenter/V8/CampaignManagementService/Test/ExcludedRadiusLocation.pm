package Microsoft::AdCenter::V8::CampaignManagementService::Test::ExcludedRadiusLocation;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::CampaignManagementService;
use Microsoft::AdCenter::V8::CampaignManagementService::ExcludedRadiusLocation;

sub test_can_create_excluded_radius_location_and_set_all_fields : Test(6) {
    my $excluded_radius_location = Microsoft::AdCenter::V8::CampaignManagementService::ExcludedRadiusLocation->new
        ->Id('id')
        ->LatitudeDegrees('latitude degrees')
        ->LongitudeDegrees('longitude degrees')
        ->Name('name')
        ->Radius('radius')
    ;

    ok($excluded_radius_location);

    is($excluded_radius_location->Id, 'id', 'can get id');
    is($excluded_radius_location->LatitudeDegrees, 'latitude degrees', 'can get latitude degrees');
    is($excluded_radius_location->LongitudeDegrees, 'longitude degrees', 'can get longitude degrees');
    is($excluded_radius_location->Name, 'name', 'can get name');
    is($excluded_radius_location->Radius, 'radius', 'can get radius');
};

1;
