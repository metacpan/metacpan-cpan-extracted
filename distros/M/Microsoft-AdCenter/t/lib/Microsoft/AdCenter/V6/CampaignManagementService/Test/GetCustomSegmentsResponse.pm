package Microsoft::AdCenter::V6::CampaignManagementService::Test::GetCustomSegmentsResponse;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V6::CampaignManagementService;
use Microsoft::AdCenter::V6::CampaignManagementService::GetCustomSegmentsResponse;

sub test_can_create_get_custom_segments_response_and_set_all_fields : Test(2) {
    my $get_custom_segments_response = Microsoft::AdCenter::V6::CampaignManagementService::GetCustomSegmentsResponse->new
        ->CustomSegments('custom segments')
    ;

    ok($get_custom_segments_response);

    is($get_custom_segments_response->CustomSegments, 'custom segments', 'can get custom segments');
};

1;
