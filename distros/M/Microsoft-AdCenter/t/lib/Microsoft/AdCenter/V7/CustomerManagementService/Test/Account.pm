package Microsoft::AdCenter::V7::CustomerManagementService::Test::Account;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V7::CustomerManagementService;
use Microsoft::AdCenter::V7::CustomerManagementService::Account;

sub test_can_create_account_and_set_all_fields : Test(19) {
    my $account = Microsoft::AdCenter::V7::CustomerManagementService::Account->new
        ->AccountType('account type')
        ->BillToCustomerId('bill to customer id')
        ->CountryCode('country code')
        ->CurrencyType('currency type')
        ->FinancialStatus('financial status')
        ->Id('id')
        ->Language('language')
        ->LastModifiedByUserId('last modified by user id')
        ->LastModifiedTime('2010-05-31T12:23:34')
        ->Name('name')
        ->Number('number')
        ->ParentCustomerId('parent customer id')
        ->PaymentMethodId('payment method id')
        ->PaymentMethodType('payment method type')
        ->PrimaryUserId('primary user id')
        ->Status('status')
        ->TimeStamp('time stamp')
        ->TimeZone('time zone')
    ;

    ok($account);

    is($account->AccountType, 'account type', 'can get account type');
    is($account->BillToCustomerId, 'bill to customer id', 'can get bill to customer id');
    is($account->CountryCode, 'country code', 'can get country code');
    is($account->CurrencyType, 'currency type', 'can get currency type');
    is($account->FinancialStatus, 'financial status', 'can get financial status');
    is($account->Id, 'id', 'can get id');
    is($account->Language, 'language', 'can get language');
    is($account->LastModifiedByUserId, 'last modified by user id', 'can get last modified by user id');
    is($account->LastModifiedTime, '2010-05-31T12:23:34', 'can get 2010-05-31T12:23:34');
    is($account->Name, 'name', 'can get name');
    is($account->Number, 'number', 'can get number');
    is($account->ParentCustomerId, 'parent customer id', 'can get parent customer id');
    is($account->PaymentMethodId, 'payment method id', 'can get payment method id');
    is($account->PaymentMethodType, 'payment method type', 'can get payment method type');
    is($account->PrimaryUserId, 'primary user id', 'can get primary user id');
    is($account->Status, 'status', 'can get status');
    is($account->TimeStamp, 'time stamp', 'can get time stamp');
    is($account->TimeZone, 'time zone', 'can get time zone');
};

1;
