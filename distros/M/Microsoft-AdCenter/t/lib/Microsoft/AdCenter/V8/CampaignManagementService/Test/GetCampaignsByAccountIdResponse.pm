package Microsoft::AdCenter::V8::CampaignManagementService::Test::GetCampaignsByAccountIdResponse;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::CampaignManagementService;
use Microsoft::AdCenter::V8::CampaignManagementService::GetCampaignsByAccountIdResponse;

sub test_can_create_get_campaigns_by_account_id_response_and_set_all_fields : Test(2) {
    my $get_campaigns_by_account_id_response = Microsoft::AdCenter::V8::CampaignManagementService::GetCampaignsByAccountIdResponse->new
        ->Campaigns('campaigns')
    ;

    ok($get_campaigns_by_account_id_response);

    is($get_campaigns_by_account_id_response->Campaigns, 'campaigns', 'can get campaigns');
};

1;
