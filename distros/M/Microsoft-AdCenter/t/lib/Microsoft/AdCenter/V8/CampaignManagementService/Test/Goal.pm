package Microsoft::AdCenter::V8::CampaignManagementService::Test::Goal;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::CampaignManagementService;
use Microsoft::AdCenter::V8::CampaignManagementService::Goal;

sub test_can_create_goal_and_set_all_fields : Test(8) {
    my $goal = Microsoft::AdCenter::V8::CampaignManagementService::Goal->new
        ->CostModel('cost model')
        ->DaysApplicableForConversion('days applicable for conversion')
        ->Id('id')
        ->Name('name')
        ->RevenueModel('revenue model')
        ->Steps('steps')
        ->YEventId('yevent id')
    ;

    ok($goal);

    is($goal->CostModel, 'cost model', 'can get cost model');
    is($goal->DaysApplicableForConversion, 'days applicable for conversion', 'can get days applicable for conversion');
    is($goal->Id, 'id', 'can get id');
    is($goal->Name, 'name', 'can get name');
    is($goal->RevenueModel, 'revenue model', 'can get revenue model');
    is($goal->Steps, 'steps', 'can get steps');
    is($goal->YEventId, 'yevent id', 'can get yevent id');
};

1;
