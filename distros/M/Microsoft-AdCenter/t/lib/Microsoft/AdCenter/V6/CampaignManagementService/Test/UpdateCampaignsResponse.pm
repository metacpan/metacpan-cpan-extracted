package Microsoft::AdCenter::V6::CampaignManagementService::Test::UpdateCampaignsResponse;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V6::CampaignManagementService;
use Microsoft::AdCenter::V6::CampaignManagementService::UpdateCampaignsResponse;

sub test_can_create_update_campaigns_response_and_set_all_fields : Test(1) {
    my $update_campaigns_response = Microsoft::AdCenter::V6::CampaignManagementService::UpdateCampaignsResponse->new
    ;

    ok($update_campaigns_response);

};

1;
