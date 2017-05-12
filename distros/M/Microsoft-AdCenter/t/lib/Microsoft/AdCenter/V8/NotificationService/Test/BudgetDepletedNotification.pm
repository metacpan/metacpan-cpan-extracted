package Microsoft::AdCenter::V8::NotificationService::Test::BudgetDepletedNotification;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::NotificationService;
use Microsoft::AdCenter::V8::NotificationService::BudgetDepletedNotification;

sub test_can_create_budget_depleted_notification_and_set_all_fields : Test(3) {
    my $budget_depleted_notification = Microsoft::AdCenter::V8::NotificationService::BudgetDepletedNotification->new
        ->AccountName('account name')
        ->AffectedCampaigns('affected campaigns')
    ;

    ok($budget_depleted_notification);

    is($budget_depleted_notification->AccountName, 'account name', 'can get account name');
    is($budget_depleted_notification->AffectedCampaigns, 'affected campaigns', 'can get affected campaigns');
};

1;
