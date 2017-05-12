package Microsoft::AdCenter::V6::CampaignManagementService::Test::SegmentTargetBid;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V6::CampaignManagementService;
use Microsoft::AdCenter::V6::CampaignManagementService::SegmentTargetBid;

sub test_can_create_segment_target_bid_and_set_all_fields : Test(9) {
    my $segment_target_bid = Microsoft::AdCenter::V6::CampaignManagementService::SegmentTargetBid->new
        ->CashBackInfo('cash back info')
        ->IncrementalBid('incremental bid')
        ->Param1('param1')
        ->Param2('param2')
        ->Param3('param3')
        ->SegmentId('segment id')
        ->SegmentParam1('segment param1')
        ->SegmentParam2('segment param2')
    ;

    ok($segment_target_bid);

    is($segment_target_bid->CashBackInfo, 'cash back info', 'can get cash back info');
    is($segment_target_bid->IncrementalBid, 'incremental bid', 'can get incremental bid');
    is($segment_target_bid->Param1, 'param1', 'can get param1');
    is($segment_target_bid->Param2, 'param2', 'can get param2');
    is($segment_target_bid->Param3, 'param3', 'can get param3');
    is($segment_target_bid->SegmentId, 'segment id', 'can get segment id');
    is($segment_target_bid->SegmentParam1, 'segment param1', 'can get segment param1');
    is($segment_target_bid->SegmentParam2, 'segment param2', 'can get segment param2');
};

1;
