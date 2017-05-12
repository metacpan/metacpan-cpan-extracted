package Microsoft::AdCenter::V6::CampaignManagementService::Test::GetAdGroupsInfoByCampaignIdResponse;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V6::CampaignManagementService;
use Microsoft::AdCenter::V6::CampaignManagementService::GetAdGroupsInfoByCampaignIdResponse;

sub test_can_create_get_ad_groups_info_by_campaign_id_response_and_set_all_fields : Test(2) {
    my $get_ad_groups_info_by_campaign_id_response = Microsoft::AdCenter::V6::CampaignManagementService::GetAdGroupsInfoByCampaignIdResponse->new
        ->AdGroupsInfo('ad groups info')
    ;

    ok($get_ad_groups_info_by_campaign_id_response);

    is($get_ad_groups_info_by_campaign_id_response->AdGroupsInfo, 'ad groups info', 'can get ad groups info');
};

1;
