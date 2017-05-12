package Microsoft::AdCenter::V7::CampaignManagementService::Test::BehavioralTargetBid;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V7::CampaignManagementService;
use Microsoft::AdCenter::V7::CampaignManagementService::BehavioralTargetBid;

sub test_can_create_behavioral_target_bid_and_set_all_fields : Test(3) {
    my $behavioral_target_bid = Microsoft::AdCenter::V7::CampaignManagementService::BehavioralTargetBid->new
        ->BehavioralName('behavioral name')
        ->IncrementalBid('incremental bid')
    ;

    ok($behavioral_target_bid);

    is($behavioral_target_bid->BehavioralName, 'behavioral name', 'can get behavioral name');
    is($behavioral_target_bid->IncrementalBid, 'incremental bid', 'can get incremental bid');
};

1;
