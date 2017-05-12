package Microsoft::AdCenter::V6::NotificationManagementService::Test::AccountSignupPaymentReceiptNotification;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V6::NotificationManagementService;
use Microsoft::AdCenter::V6::NotificationManagementService::AccountSignupPaymentReceiptNotification;

sub test_can_create_account_signup_payment_receipt_notification_and_set_all_fields : Test(10) {
    my $account_signup_payment_receipt_notification = Microsoft::AdCenter::V6::NotificationManagementService::AccountSignupPaymentReceiptNotification->new
        ->AccountId('account id')
        ->AccountName('account name')
        ->AccountNumber('account number')
        ->AccountSetupFee('account setup fee')
        ->CreditCardLastFour('credit card last four')
        ->CreditCardName('credit card name')
        ->CreditCardTypeName('credit card type name')
        ->PreferredCurrencyCode('preferred currency code')
        ->PreferredUserName('preferred user name')
    ;

    ok($account_signup_payment_receipt_notification);

    is($account_signup_payment_receipt_notification->AccountId, 'account id', 'can get account id');
    is($account_signup_payment_receipt_notification->AccountName, 'account name', 'can get account name');
    is($account_signup_payment_receipt_notification->AccountNumber, 'account number', 'can get account number');
    is($account_signup_payment_receipt_notification->AccountSetupFee, 'account setup fee', 'can get account setup fee');
    is($account_signup_payment_receipt_notification->CreditCardLastFour, 'credit card last four', 'can get credit card last four');
    is($account_signup_payment_receipt_notification->CreditCardName, 'credit card name', 'can get credit card name');
    is($account_signup_payment_receipt_notification->CreditCardTypeName, 'credit card type name', 'can get credit card type name');
    is($account_signup_payment_receipt_notification->PreferredCurrencyCode, 'preferred currency code', 'can get preferred currency code');
    is($account_signup_payment_receipt_notification->PreferredUserName, 'preferred user name', 'can get preferred user name');
};

1;
