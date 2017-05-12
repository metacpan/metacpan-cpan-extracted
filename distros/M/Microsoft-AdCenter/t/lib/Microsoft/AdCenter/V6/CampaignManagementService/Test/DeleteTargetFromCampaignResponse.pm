package Microsoft::AdCenter::V6::CampaignManagementService::Test::DeleteTargetFromCampaignResponse;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V6::CampaignManagementService;
use Microsoft::AdCenter::V6::CampaignManagementService::DeleteTargetFromCampaignResponse;

sub test_can_create_delete_target_from_campaign_response_and_set_all_fields : Test(1) {
    my $delete_target_from_campaign_response = Microsoft::AdCenter::V6::CampaignManagementService::DeleteTargetFromCampaignResponse->new
    ;

    ok($delete_target_from_campaign_response);

};

1;
