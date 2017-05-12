package Microsoft::AdCenter::V8::CampaignManagementService::Test::PauseAdGroupsResponse;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::CampaignManagementService;
use Microsoft::AdCenter::V8::CampaignManagementService::PauseAdGroupsResponse;

sub test_can_create_pause_ad_groups_response_and_set_all_fields : Test(1) {
    my $pause_ad_groups_response = Microsoft::AdCenter::V8::CampaignManagementService::PauseAdGroupsResponse->new
    ;

    ok($pause_ad_groups_response);

};

1;
