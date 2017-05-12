package Microsoft::AdCenter::V7::CampaignManagementService::Test::SetNetworksToAdGroupsResponse;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V7::CampaignManagementService;
use Microsoft::AdCenter::V7::CampaignManagementService::SetNetworksToAdGroupsResponse;

sub test_can_create_set_networks_to_ad_groups_response_and_set_all_fields : Test(1) {
    my $set_networks_to_ad_groups_response = Microsoft::AdCenter::V7::CampaignManagementService::SetNetworksToAdGroupsResponse->new
    ;

    ok($set_networks_to_ad_groups_response);

};

1;
