package Microsoft::AdCenter::V6::CampaignManagementService::Test::GetNegativeKeywordsByAdGroupIdsResponse;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V6::CampaignManagementService;
use Microsoft::AdCenter::V6::CampaignManagementService::GetNegativeKeywordsByAdGroupIdsResponse;

sub test_can_create_get_negative_keywords_by_ad_group_ids_response_and_set_all_fields : Test(2) {
    my $get_negative_keywords_by_ad_group_ids_response = Microsoft::AdCenter::V6::CampaignManagementService::GetNegativeKeywordsByAdGroupIdsResponse->new
        ->AdGroupNegativeKeywords('ad group negative keywords')
    ;

    ok($get_negative_keywords_by_ad_group_ids_response);

    is($get_negative_keywords_by_ad_group_ids_response->AdGroupNegativeKeywords, 'ad group negative keywords', 'can get ad group negative keywords');
};

1;
