package Microsoft::AdCenter::V6::NotificationManagementService::Test::UnableToChargeCreditCardNotification;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V6::NotificationManagementService;
use Microsoft::AdCenter::V6::NotificationManagementService::UnableToChargeCreditCardNotification;

sub test_can_create_unable_to_charge_credit_card_notification_and_set_all_fields : Test(8) {
    my $unable_to_charge_credit_card_notification = Microsoft::AdCenter::V6::NotificationManagementService::UnableToChargeCreditCardNotification->new
        ->AccountFinancialStatus('account financial status')
        ->AccountId('account id')
        ->AccountNumber('account number')
        ->BalanceAmount('balance amount')
        ->CreditCardLastFour('credit card last four')
        ->CreditCardTypeName('credit card type name')
        ->PreferredCurrencyCode('preferred currency code')
    ;

    ok($unable_to_charge_credit_card_notification);

    is($unable_to_charge_credit_card_notification->AccountFinancialStatus, 'account financial status', 'can get account financial status');
    is($unable_to_charge_credit_card_notification->AccountId, 'account id', 'can get account id');
    is($unable_to_charge_credit_card_notification->AccountNumber, 'account number', 'can get account number');
    is($unable_to_charge_credit_card_notification->BalanceAmount, 'balance amount', 'can get balance amount');
    is($unable_to_charge_credit_card_notification->CreditCardLastFour, 'credit card last four', 'can get credit card last four');
    is($unable_to_charge_credit_card_notification->CreditCardTypeName, 'credit card type name', 'can get credit card type name');
    is($unable_to_charge_credit_card_notification->PreferredCurrencyCode, 'preferred currency code', 'can get preferred currency code');
};

1;
