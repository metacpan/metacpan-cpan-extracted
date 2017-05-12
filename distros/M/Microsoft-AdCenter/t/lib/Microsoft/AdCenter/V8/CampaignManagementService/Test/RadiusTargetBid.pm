package Microsoft::AdCenter::V8::CampaignManagementService::Test::RadiusTargetBid;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::CampaignManagementService;
use Microsoft::AdCenter::V8::CampaignManagementService::RadiusTargetBid;

sub test_can_create_radius_target_bid_and_set_all_fields : Test(7) {
    my $radius_target_bid = Microsoft::AdCenter::V8::CampaignManagementService::RadiusTargetBid->new
        ->Id('id')
        ->IncrementalBid('incremental bid')
        ->LatitudeDegrees('latitude degrees')
        ->LongitudeDegrees('longitude degrees')
        ->Name('name')
        ->Radius('radius')
    ;

    ok($radius_target_bid);

    is($radius_target_bid->Id, 'id', 'can get id');
    is($radius_target_bid->IncrementalBid, 'incremental bid', 'can get incremental bid');
    is($radius_target_bid->LatitudeDegrees, 'latitude degrees', 'can get latitude degrees');
    is($radius_target_bid->LongitudeDegrees, 'longitude degrees', 'can get longitude degrees');
    is($radius_target_bid->Name, 'name', 'can get name');
    is($radius_target_bid->Radius, 'radius', 'can get radius');
};

1;
