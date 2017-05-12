package Microsoft::AdCenter::V8::NotificationService::Test::LowBudgetBalanceNotification;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::NotificationService;
use Microsoft::AdCenter::V8::NotificationService::LowBudgetBalanceNotification;

sub test_can_create_low_budget_balance_notification_and_set_all_fields : Test(4) {
    my $low_budget_balance_notification = Microsoft::AdCenter::V8::NotificationService::LowBudgetBalanceNotification->new
        ->AccountName('account name')
        ->AffectedCampaigns('affected campaigns')
        ->CustomerId('customer id')
    ;

    ok($low_budget_balance_notification);

    is($low_budget_balance_notification->AccountName, 'account name', 'can get account name');
    is($low_budget_balance_notification->AffectedCampaigns, 'affected campaigns', 'can get affected campaigns');
    is($low_budget_balance_notification->CustomerId, 'customer id', 'can get customer id');
};

1;
