package Microsoft::AdCenter::V6::CustomerManagementService::Test::AdCenterAccount;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V6::CustomerManagementService;
use Microsoft::AdCenter::V6::CustomerManagementService::AdCenterAccount;

sub test_can_create_ad_center_account_and_set_all_fields : Test(12) {
    my $ad_center_account = Microsoft::AdCenter::V6::CustomerManagementService::AdCenterAccount->new
        ->AccountId('account id')
        ->AccountName('account name')
        ->AccountNumber('account number')
        ->AgencyContactName('agency contact name')
        ->BillToCustomerId('bill to customer id')
        ->CreditCard('credit card')
        ->PaymentOptionsType('payment options type')
        ->PreferredCurrencyType('preferred currency type')
        ->PreferredLanguageType('preferred language type')
        ->SalesHouseCustomerId('sales house customer id')
        ->Status('status')
    ;

    ok($ad_center_account);

    is($ad_center_account->AccountId, 'account id', 'can get account id');
    is($ad_center_account->AccountName, 'account name', 'can get account name');
    is($ad_center_account->AccountNumber, 'account number', 'can get account number');
    is($ad_center_account->AgencyContactName, 'agency contact name', 'can get agency contact name');
    is($ad_center_account->BillToCustomerId, 'bill to customer id', 'can get bill to customer id');
    is($ad_center_account->CreditCard, 'credit card', 'can get credit card');
    is($ad_center_account->PaymentOptionsType, 'payment options type', 'can get payment options type');
    is($ad_center_account->PreferredCurrencyType, 'preferred currency type', 'can get preferred currency type');
    is($ad_center_account->PreferredLanguageType, 'preferred language type', 'can get preferred language type');
    is($ad_center_account->SalesHouseCustomerId, 'sales house customer id', 'can get sales house customer id');
    is($ad_center_account->Status, 'status', 'can get status');
};

1;
