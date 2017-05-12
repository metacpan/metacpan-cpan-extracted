package Microsoft::AdCenter::V8::CampaignManagementService::Test::GetNegativeSitesByAdGroupIdsResponse;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::CampaignManagementService;
use Microsoft::AdCenter::V8::CampaignManagementService::GetNegativeSitesByAdGroupIdsResponse;

sub test_can_create_get_negative_sites_by_ad_group_ids_response_and_set_all_fields : Test(2) {
    my $get_negative_sites_by_ad_group_ids_response = Microsoft::AdCenter::V8::CampaignManagementService::GetNegativeSitesByAdGroupIdsResponse->new
        ->AdGroupNegativeSites('ad group negative sites')
    ;

    ok($get_negative_sites_by_ad_group_ids_response);

    is($get_negative_sites_by_ad_group_ids_response->AdGroupNegativeSites, 'ad group negative sites', 'can get ad group negative sites');
};

1;
