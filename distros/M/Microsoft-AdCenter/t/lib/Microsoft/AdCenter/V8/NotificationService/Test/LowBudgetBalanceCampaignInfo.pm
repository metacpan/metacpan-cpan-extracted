package Microsoft::AdCenter::V8::NotificationService::Test::LowBudgetBalanceCampaignInfo;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::NotificationService;
use Microsoft::AdCenter::V8::NotificationService::LowBudgetBalanceCampaignInfo;

sub test_can_create_low_budget_balance_campaign_info_and_set_all_fields : Test(3) {
    my $low_budget_balance_campaign_info = Microsoft::AdCenter::V8::NotificationService::LowBudgetBalanceCampaignInfo->new
        ->EstimatedBudgetBalance('estimated budget balance')
        ->EstimatedImpressions('estimated impressions')
    ;

    ok($low_budget_balance_campaign_info);

    is($low_budget_balance_campaign_info->EstimatedBudgetBalance, 'estimated budget balance', 'can get estimated budget balance');
    is($low_budget_balance_campaign_info->EstimatedImpressions, 'estimated impressions', 'can get estimated impressions');
};

1;
