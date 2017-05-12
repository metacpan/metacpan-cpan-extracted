package Microsoft::AdCenter::V7::CampaignManagementService::Test::GetSegmentsByIdsResponse;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V7::CampaignManagementService;
use Microsoft::AdCenter::V7::CampaignManagementService::GetSegmentsByIdsResponse;

sub test_can_create_get_segments_by_ids_response_and_set_all_fields : Test(2) {
    my $get_segments_by_ids_response = Microsoft::AdCenter::V7::CampaignManagementService::GetSegmentsByIdsResponse->new
        ->Segments('segments')
    ;

    ok($get_segments_by_ids_response);

    is($get_segments_by_ids_response->Segments, 'segments', 'can get segments');
};

1;
