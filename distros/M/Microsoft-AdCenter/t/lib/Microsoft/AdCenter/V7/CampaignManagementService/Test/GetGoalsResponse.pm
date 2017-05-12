package Microsoft::AdCenter::V7::CampaignManagementService::Test::GetGoalsResponse;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V7::CampaignManagementService;
use Microsoft::AdCenter::V7::CampaignManagementService::GetGoalsResponse;

sub test_can_create_get_goals_response_and_set_all_fields : Test(2) {
    my $get_goals_response = Microsoft::AdCenter::V7::CampaignManagementService::GetGoalsResponse->new
        ->Goals('goals')
    ;

    ok($get_goals_response);

    is($get_goals_response->Goals, 'goals', 'can get goals');
};

1;
