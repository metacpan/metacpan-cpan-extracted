package Microsoft::AdCenter::V7::CampaignManagementService::Test::UpdateGoalsResponse;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V7::CampaignManagementService;
use Microsoft::AdCenter::V7::CampaignManagementService::UpdateGoalsResponse;

sub test_can_create_update_goals_response_and_set_all_fields : Test(2) {
    my $update_goals_response = Microsoft::AdCenter::V7::CampaignManagementService::UpdateGoalsResponse->new
        ->GoalResults('goal results')
    ;

    ok($update_goals_response);

    is($update_goals_response->GoalResults, 'goal results', 'can get goal results');
};

1;
