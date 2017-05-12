package Microsoft::AdCenter::V8::CampaignManagementService::Test::GetAdExtensionsByCampaignIdsResponse;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::CampaignManagementService;
use Microsoft::AdCenter::V8::CampaignManagementService::GetAdExtensionsByCampaignIdsResponse;

sub test_can_create_get_ad_extensions_by_campaign_ids_response_and_set_all_fields : Test(2) {
    my $get_ad_extensions_by_campaign_ids_response = Microsoft::AdCenter::V8::CampaignManagementService::GetAdExtensionsByCampaignIdsResponse->new
        ->CampaignAdExtensionCollection('campaign ad extension collection')
    ;

    ok($get_ad_extensions_by_campaign_ids_response);

    is($get_ad_extensions_by_campaign_ids_response->CampaignAdExtensionCollection, 'campaign ad extension collection', 'can get campaign ad extension collection');
};

1;
