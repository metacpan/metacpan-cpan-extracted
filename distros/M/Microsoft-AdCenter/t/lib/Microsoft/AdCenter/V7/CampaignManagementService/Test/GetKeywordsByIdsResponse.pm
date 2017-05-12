package Microsoft::AdCenter::V7::CampaignManagementService::Test::GetKeywordsByIdsResponse;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V7::CampaignManagementService;
use Microsoft::AdCenter::V7::CampaignManagementService::GetKeywordsByIdsResponse;

sub test_can_create_get_keywords_by_ids_response_and_set_all_fields : Test(2) {
    my $get_keywords_by_ids_response = Microsoft::AdCenter::V7::CampaignManagementService::GetKeywordsByIdsResponse->new
        ->Keywords('keywords')
    ;

    ok($get_keywords_by_ids_response);

    is($get_keywords_by_ids_response->Keywords, 'keywords', 'can get keywords');
};

1;
