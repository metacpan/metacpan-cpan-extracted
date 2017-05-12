package Microsoft::AdCenter::V6::NotificationManagementService::Test::AccountClosedNotification;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V6::NotificationManagementService;
use Microsoft::AdCenter::V6::NotificationManagementService::AccountClosedNotification;

sub test_can_create_account_closed_notification_and_set_all_fields : Test(5) {
    my $account_closed_notification = Microsoft::AdCenter::V6::NotificationManagementService::AccountClosedNotification->new
        ->AccountId('account id')
        ->AccountNumber('account number')
        ->CustomerName('customer name')
        ->StatusDate('2010-05-31T12:23:34')
    ;

    ok($account_closed_notification);

    is($account_closed_notification->AccountId, 'account id', 'can get account id');
    is($account_closed_notification->AccountNumber, 'account number', 'can get account number');
    is($account_closed_notification->CustomerName, 'customer name', 'can get customer name');
    is($account_closed_notification->StatusDate, '2010-05-31T12:23:34', 'can get 2010-05-31T12:23:34');
};

1;
