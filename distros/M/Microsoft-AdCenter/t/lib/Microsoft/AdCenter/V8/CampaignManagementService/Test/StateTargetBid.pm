package Microsoft::AdCenter::V8::CampaignManagementService::Test::StateTargetBid;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::CampaignManagementService;
use Microsoft::AdCenter::V8::CampaignManagementService::StateTargetBid;

sub test_can_create_state_target_bid_and_set_all_fields : Test(3) {
    my $state_target_bid = Microsoft::AdCenter::V8::CampaignManagementService::StateTargetBid->new
        ->IncrementalBid('incremental bid')
        ->State('state')
    ;

    ok($state_target_bid);

    is($state_target_bid->IncrementalBid, 'incremental bid', 'can get incremental bid');
    is($state_target_bid->State, 'state', 'can get state');
};

1;
