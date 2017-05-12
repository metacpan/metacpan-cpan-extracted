package Microsoft::AdCenter::V7::CampaignManagementService::Test::GetAdsByAdGroupIdResponse;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V7::CampaignManagementService;
use Microsoft::AdCenter::V7::CampaignManagementService::GetAdsByAdGroupIdResponse;

sub test_can_create_get_ads_by_ad_group_id_response_and_set_all_fields : Test(2) {
    my $get_ads_by_ad_group_id_response = Microsoft::AdCenter::V7::CampaignManagementService::GetAdsByAdGroupIdResponse->new
        ->Ads('ads')
    ;

    ok($get_ads_by_ad_group_id_response);

    is($get_ads_by_ad_group_id_response->Ads, 'ads', 'can get ads');
};

1;
