package Microsoft::AdCenter::V6::CampaignManagementService::Test::AddSegmentsResponse;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V6::CampaignManagementService;
use Microsoft::AdCenter::V6::CampaignManagementService::AddSegmentsResponse;

sub test_can_create_add_segments_response_and_set_all_fields : Test(2) {
    my $add_segments_response = Microsoft::AdCenter::V6::CampaignManagementService::AddSegmentsResponse->new
        ->SegmentIds('segment ids')
    ;

    ok($add_segments_response);

    is($add_segments_response->SegmentIds, 'segment ids', 'can get segment ids');
};

1;
