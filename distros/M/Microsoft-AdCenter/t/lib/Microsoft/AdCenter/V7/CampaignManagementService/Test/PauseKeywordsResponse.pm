package Microsoft::AdCenter::V7::CampaignManagementService::Test::PauseKeywordsResponse;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V7::CampaignManagementService;
use Microsoft::AdCenter::V7::CampaignManagementService::PauseKeywordsResponse;

sub test_can_create_pause_keywords_response_and_set_all_fields : Test(1) {
    my $pause_keywords_response = Microsoft::AdCenter::V7::CampaignManagementService::PauseKeywordsResponse->new
    ;

    ok($pause_keywords_response);

};

1;
