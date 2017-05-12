package Microsoft::AdCenter::V8::CampaignManagementService::Test::CityTargetBid;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::CampaignManagementService;
use Microsoft::AdCenter::V8::CampaignManagementService::CityTargetBid;

sub test_can_create_city_target_bid_and_set_all_fields : Test(3) {
    my $city_target_bid = Microsoft::AdCenter::V8::CampaignManagementService::CityTargetBid->new
        ->City('city')
        ->IncrementalBid('incremental bid')
    ;

    ok($city_target_bid);

    is($city_target_bid->City, 'city', 'can get city');
    is($city_target_bid->IncrementalBid, 'incremental bid', 'can get incremental bid');
};

1;
