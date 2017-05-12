package Microsoft::AdCenter::V6::CampaignManagementService::Test::GetKeywordEstimatesByBidsResponse;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V6::CampaignManagementService;
use Microsoft::AdCenter::V6::CampaignManagementService::GetKeywordEstimatesByBidsResponse;

sub test_can_create_get_keyword_estimates_by_bids_response_and_set_all_fields : Test(2) {
    my $get_keyword_estimates_by_bids_response = Microsoft::AdCenter::V6::CampaignManagementService::GetKeywordEstimatesByBidsResponse->new
        ->KeywordEstimates('keyword estimates')
    ;

    ok($get_keyword_estimates_by_bids_response);

    is($get_keyword_estimates_by_bids_response->KeywordEstimates, 'keyword estimates', 'can get keyword estimates');
};

1;
