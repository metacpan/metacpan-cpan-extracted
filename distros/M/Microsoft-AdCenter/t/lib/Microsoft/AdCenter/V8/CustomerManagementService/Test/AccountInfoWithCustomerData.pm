package Microsoft::AdCenter::V8::CustomerManagementService::Test::AccountInfoWithCustomerData;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::CustomerManagementService;
use Microsoft::AdCenter::V8::CustomerManagementService::AccountInfoWithCustomerData;

sub test_can_create_account_info_with_customer_data_and_set_all_fields : Test(8) {
    my $account_info_with_customer_data = Microsoft::AdCenter::V8::CustomerManagementService::AccountInfoWithCustomerData->new
        ->AccountId('account id')
        ->AccountLifeCycleStatus('account life cycle status')
        ->AccountName('account name')
        ->AccountNumber('account number')
        ->CustomerId('customer id')
        ->CustomerName('customer name')
        ->PauseReason('pause reason')
    ;

    ok($account_info_with_customer_data);

    is($account_info_with_customer_data->AccountId, 'account id', 'can get account id');
    is($account_info_with_customer_data->AccountLifeCycleStatus, 'account life cycle status', 'can get account life cycle status');
    is($account_info_with_customer_data->AccountName, 'account name', 'can get account name');
    is($account_info_with_customer_data->AccountNumber, 'account number', 'can get account number');
    is($account_info_with_customer_data->CustomerId, 'customer id', 'can get customer id');
    is($account_info_with_customer_data->CustomerName, 'customer name', 'can get customer name');
    is($account_info_with_customer_data->PauseReason, 'pause reason', 'can get pause reason');
};

1;
