package Microsoft::AdCenter::V6::CampaignManagementService::Test::ResumeBehavioralBidsResponse;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V6::CampaignManagementService;
use Microsoft::AdCenter::V6::CampaignManagementService::ResumeBehavioralBidsResponse;

sub test_can_create_resume_behavioral_bids_response_and_set_all_fields : Test(1) {
    my $resume_behavioral_bids_response = Microsoft::AdCenter::V6::CampaignManagementService::ResumeBehavioralBidsResponse->new
    ;

    ok($resume_behavioral_bids_response);

};

1;
