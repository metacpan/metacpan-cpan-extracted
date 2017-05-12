package Microsoft::AdCenter::V7::CampaignManagementService::Test::GoalResult;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V7::CampaignManagementService;
use Microsoft::AdCenter::V7::CampaignManagementService::GoalResult;

sub test_can_create_goal_result_and_set_all_fields : Test(3) {
    my $goal_result = Microsoft::AdCenter::V7::CampaignManagementService::GoalResult->new
        ->GoalId('goal id')
        ->StepIds('step ids')
    ;

    ok($goal_result);

    is($goal_result->GoalId, 'goal id', 'can get goal id');
    is($goal_result->StepIds, 'step ids', 'can get step ids');
};

1;
