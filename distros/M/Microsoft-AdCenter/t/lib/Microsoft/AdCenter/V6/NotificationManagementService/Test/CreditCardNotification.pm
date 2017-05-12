package Microsoft::AdCenter::V6::NotificationManagementService::Test::CreditCardNotification;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V6::NotificationManagementService;
use Microsoft::AdCenter::V6::NotificationManagementService::CreditCardNotification;

sub test_can_create_credit_card_notification_and_set_all_fields : Test(7) {
    my $credit_card_notification = Microsoft::AdCenter::V6::NotificationManagementService::CreditCardNotification->new
        ->AccountId('account id')
        ->AccountNumber('account number')
        ->CreditCardExpirationDate('2010-05-31T12:23:34')
        ->CreditCardLastFour('credit card last four')
        ->CreditCardTypeName('credit card type name')
        ->NoticeNumber('notice number')
    ;

    ok($credit_card_notification);

    is($credit_card_notification->AccountId, 'account id', 'can get account id');
    is($credit_card_notification->AccountNumber, 'account number', 'can get account number');
    is($credit_card_notification->CreditCardExpirationDate, '2010-05-31T12:23:34', 'can get 2010-05-31T12:23:34');
    is($credit_card_notification->CreditCardLastFour, 'credit card last four', 'can get credit card last four');
    is($credit_card_notification->CreditCardTypeName, 'credit card type name', 'can get credit card type name');
    is($credit_card_notification->NoticeNumber, 'notice number', 'can get notice number');
};

1;
