package Microsoft::AdCenter::V8::CustomerBillingService::Test::InvoiceInfo;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::CustomerBillingService;
use Microsoft::AdCenter::V8::CustomerBillingService::InvoiceInfo;

sub test_can_create_invoice_info_and_set_all_fields : Test(8) {
    my $invoice_info = Microsoft::AdCenter::V8::CustomerBillingService::InvoiceInfo->new
        ->AccountId('account id')
        ->AccountName('account name')
        ->AccountNumber('account number')
        ->Amount('amount')
        ->CurrencyCode('currency code')
        ->InvoiceDate('2010-05-31T12:23:34')
        ->InvoiceId('invoice id')
    ;

    ok($invoice_info);

    is($invoice_info->AccountId, 'account id', 'can get account id');
    is($invoice_info->AccountName, 'account name', 'can get account name');
    is($invoice_info->AccountNumber, 'account number', 'can get account number');
    is($invoice_info->Amount, 'amount', 'can get amount');
    is($invoice_info->CurrencyCode, 'currency code', 'can get currency code');
    is($invoice_info->InvoiceDate, '2010-05-31T12:23:34', 'can get 2010-05-31T12:23:34');
    is($invoice_info->InvoiceId, 'invoice id', 'can get invoice id');
};

1;
