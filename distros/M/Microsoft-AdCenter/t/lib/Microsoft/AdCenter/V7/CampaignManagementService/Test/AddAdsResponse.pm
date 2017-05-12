package Microsoft::AdCenter::V7::CampaignManagementService::Test::AddAdsResponse;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V7::CampaignManagementService;
use Microsoft::AdCenter::V7::CampaignManagementService::AddAdsResponse;

sub test_can_create_add_ads_response_and_set_all_fields : Test(2) {
    my $add_ads_response = Microsoft::AdCenter::V7::CampaignManagementService::AddAdsResponse->new
        ->AdIds('ad ids')
    ;

    ok($add_ads_response);

    is($add_ads_response->AdIds, 'ad ids', 'can get ad ids');
};

1;
