package Microsoft::AdCenter::V8::CampaignManagementService::Test::GetCampaignAdExtensionsResponse;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::CampaignManagementService;
use Microsoft::AdCenter::V8::CampaignManagementService::GetCampaignAdExtensionsResponse;

sub test_can_create_get_campaign_ad_extensions_response_and_set_all_fields : Test(2) {
    my $get_campaign_ad_extensions_response = Microsoft::AdCenter::V8::CampaignManagementService::GetCampaignAdExtensionsResponse->new
        ->AdExtensions('ad extensions')
    ;

    ok($get_campaign_ad_extensions_response);

    is($get_campaign_ad_extensions_response->AdExtensions, 'ad extensions', 'can get ad extensions');
};

1;
