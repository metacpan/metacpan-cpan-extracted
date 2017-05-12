package Microsoft::AdCenter::V8::NotificationService::Test::BudgetDepletedCampaignInfo;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::NotificationService;
use Microsoft::AdCenter::V8::NotificationService::BudgetDepletedCampaignInfo;

sub test_can_create_budget_depleted_campaign_info_and_set_all_fields : Test(3) {
    my $budget_depleted_campaign_info = Microsoft::AdCenter::V8::NotificationService::BudgetDepletedCampaignInfo->new
        ->BudgetDepletedDate('2010-05-31T12:23:34')
        ->CurrencyCode('currency code')
    ;

    ok($budget_depleted_campaign_info);

    is($budget_depleted_campaign_info->BudgetDepletedDate, '2010-05-31T12:23:34', 'can get 2010-05-31T12:23:34');
    is($budget_depleted_campaign_info->CurrencyCode, 'currency code', 'can get currency code');
};

1;
