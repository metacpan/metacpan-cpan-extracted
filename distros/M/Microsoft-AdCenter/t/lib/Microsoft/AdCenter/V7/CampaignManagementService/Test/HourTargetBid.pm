package Microsoft::AdCenter::V7::CampaignManagementService::Test::HourTargetBid;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V7::CampaignManagementService;
use Microsoft::AdCenter::V7::CampaignManagementService::HourTargetBid;

sub test_can_create_hour_target_bid_and_set_all_fields : Test(3) {
    my $hour_target_bid = Microsoft::AdCenter::V7::CampaignManagementService::HourTargetBid->new
        ->Hour('hour')
        ->IncrementalBid('incremental bid')
    ;

    ok($hour_target_bid);

    is($hour_target_bid->Hour, 'hour', 'can get hour');
    is($hour_target_bid->IncrementalBid, 'incremental bid', 'can get incremental bid');
};

1;
