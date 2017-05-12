package Microsoft::AdCenter::V6::CampaignManagementService::Test::MetroAreaTargetBid;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V6::CampaignManagementService;
use Microsoft::AdCenter::V6::CampaignManagementService::MetroAreaTargetBid;

sub test_can_create_metro_area_target_bid_and_set_all_fields : Test(3) {
    my $metro_area_target_bid = Microsoft::AdCenter::V6::CampaignManagementService::MetroAreaTargetBid->new
        ->IncrementalBid('incremental bid')
        ->MetroArea('metro area')
    ;

    ok($metro_area_target_bid);

    is($metro_area_target_bid->IncrementalBid, 'incremental bid', 'can get incremental bid');
    is($metro_area_target_bid->MetroArea, 'metro area', 'can get metro area');
};

1;
