package Microsoft::AdCenter::V8::CampaignManagementService::Test::GetNegativeSitesByCampaignIdsResponse;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::CampaignManagementService;
use Microsoft::AdCenter::V8::CampaignManagementService::GetNegativeSitesByCampaignIdsResponse;

sub test_can_create_get_negative_sites_by_campaign_ids_response_and_set_all_fields : Test(2) {
    my $get_negative_sites_by_campaign_ids_response = Microsoft::AdCenter::V8::CampaignManagementService::GetNegativeSitesByCampaignIdsResponse->new
        ->CampaignNegativeSites('campaign negative sites')
    ;

    ok($get_negative_sites_by_campaign_ids_response);

    is($get_negative_sites_by_campaign_ids_response->CampaignNegativeSites, 'campaign negative sites', 'can get campaign negative sites');
};

1;
