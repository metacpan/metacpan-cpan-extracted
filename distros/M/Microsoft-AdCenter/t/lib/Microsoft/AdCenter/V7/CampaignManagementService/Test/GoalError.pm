package Microsoft::AdCenter::V7::CampaignManagementService::Test::GoalError;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V7::CampaignManagementService;
use Microsoft::AdCenter::V7::CampaignManagementService::GoalError;

sub test_can_create_goal_error_and_set_all_fields : Test(4) {
    my $goal_error = Microsoft::AdCenter::V7::CampaignManagementService::GoalError->new
        ->BatchErrors('batch errors')
        ->Index('index')
        ->StepErrors('step errors')
    ;

    ok($goal_error);

    is($goal_error->BatchErrors, 'batch errors', 'can get batch errors');
    is($goal_error->Index, 'index', 'can get index');
    is($goal_error->StepErrors, 'step errors', 'can get step errors');
};

1;
