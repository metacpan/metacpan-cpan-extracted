package Microsoft::AdCenter::V8::CampaignManagementService::Test::SetAdExtensionsToCampaignsResponse;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::CampaignManagementService;
use Microsoft::AdCenter::V8::CampaignManagementService::SetAdExtensionsToCampaignsResponse;

sub test_can_create_set_ad_extensions_to_campaigns_response_and_set_all_fields : Test(1) {
    my $set_ad_extensions_to_campaigns_response = Microsoft::AdCenter::V8::CampaignManagementService::SetAdExtensionsToCampaignsResponse->new
    ;

    ok($set_ad_extensions_to_campaigns_response);

};

1;
