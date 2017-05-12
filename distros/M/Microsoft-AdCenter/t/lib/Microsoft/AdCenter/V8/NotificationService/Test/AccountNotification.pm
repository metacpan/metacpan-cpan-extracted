package Microsoft::AdCenter::V8::NotificationService::Test::AccountNotification;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::NotificationService;
use Microsoft::AdCenter::V8::NotificationService::AccountNotification;

sub test_can_create_account_notification_and_set_all_fields : Test(3) {
    my $account_notification = Microsoft::AdCenter::V8::NotificationService::AccountNotification->new
        ->AccountId('account id')
        ->AccountNumber('account number')
    ;

    ok($account_notification);

    is($account_notification->AccountId, 'account id', 'can get account id');
    is($account_notification->AccountNumber, 'account number', 'can get account number');
};

1;
