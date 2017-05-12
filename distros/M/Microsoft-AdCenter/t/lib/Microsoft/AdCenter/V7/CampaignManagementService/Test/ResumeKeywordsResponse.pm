package Microsoft::AdCenter::V7::CampaignManagementService::Test::ResumeKeywordsResponse;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V7::CampaignManagementService;
use Microsoft::AdCenter::V7::CampaignManagementService::ResumeKeywordsResponse;

sub test_can_create_resume_keywords_response_and_set_all_fields : Test(1) {
    my $resume_keywords_response = Microsoft::AdCenter::V7::CampaignManagementService::ResumeKeywordsResponse->new
    ;

    ok($resume_keywords_response);

};

1;
