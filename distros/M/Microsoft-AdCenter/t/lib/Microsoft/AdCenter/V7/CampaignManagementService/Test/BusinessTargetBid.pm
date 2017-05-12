package Microsoft::AdCenter::V7::CampaignManagementService::Test::BusinessTargetBid;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V7::CampaignManagementService;
use Microsoft::AdCenter::V7::CampaignManagementService::BusinessTargetBid;

sub test_can_create_business_target_bid_and_set_all_fields : Test(4) {
    my $business_target_bid = Microsoft::AdCenter::V7::CampaignManagementService::BusinessTargetBid->new
        ->BusinessId('business id')
        ->IncrementalBid('incremental bid')
        ->Radius('radius')
    ;

    ok($business_target_bid);

    is($business_target_bid->BusinessId, 'business id', 'can get business id');
    is($business_target_bid->IncrementalBid, 'incremental bid', 'can get incremental bid');
    is($business_target_bid->Radius, 'radius', 'can get radius');
};

1;
