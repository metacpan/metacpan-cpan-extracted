package Microsoft::AdCenter::V6::CampaignManagementService::Test::AddKeywordsResponse;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V6::CampaignManagementService;
use Microsoft::AdCenter::V6::CampaignManagementService::AddKeywordsResponse;

sub test_can_create_add_keywords_response_and_set_all_fields : Test(2) {
    my $add_keywords_response = Microsoft::AdCenter::V6::CampaignManagementService::AddKeywordsResponse->new
        ->KeywordIds('keyword ids')
    ;

    ok($add_keywords_response);

    is($add_keywords_response->KeywordIds, 'keyword ids', 'can get keyword ids');
};

1;
