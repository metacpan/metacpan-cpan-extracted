package Microsoft::AdCenter::V8::OptimizerService::Test::BudgetOpportunity;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::OptimizerService;
use Microsoft::AdCenter::V8::OptimizerService::BudgetOpportunity;

sub test_can_create_budget_opportunity_and_set_all_fields : Test(10) {
    my $budget_opportunity = Microsoft::AdCenter::V8::OptimizerService::BudgetOpportunity->new
        ->BudgetDepletionDate('2010-05-31T12:23:34')
        ->BudgetType('budget type')
        ->CampaignId('campaign id')
        ->CurrentBudget('current budget')
        ->IncreaseInClicks('increase in clicks')
        ->IncreaseInImpressions('increase in impressions')
        ->PercentageIncreaseInClicks('percentage increase in clicks')
        ->PercentageIncreaseInImpressions('percentage increase in impressions')
        ->RecommendedBudget('recommended budget')
    ;

    ok($budget_opportunity);

    is($budget_opportunity->BudgetDepletionDate, '2010-05-31T12:23:34', 'can get 2010-05-31T12:23:34');
    is($budget_opportunity->BudgetType, 'budget type', 'can get budget type');
    is($budget_opportunity->CampaignId, 'campaign id', 'can get campaign id');
    is($budget_opportunity->CurrentBudget, 'current budget', 'can get current budget');
    is($budget_opportunity->IncreaseInClicks, 'increase in clicks', 'can get increase in clicks');
    is($budget_opportunity->IncreaseInImpressions, 'increase in impressions', 'can get increase in impressions');
    is($budget_opportunity->PercentageIncreaseInClicks, 'percentage increase in clicks', 'can get percentage increase in clicks');
    is($budget_opportunity->PercentageIncreaseInImpressions, 'percentage increase in impressions', 'can get percentage increase in impressions');
    is($budget_opportunity->RecommendedBudget, 'recommended budget', 'can get recommended budget');
};

1;
