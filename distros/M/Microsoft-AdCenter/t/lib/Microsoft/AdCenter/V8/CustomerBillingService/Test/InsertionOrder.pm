package Microsoft::AdCenter::V8::CustomerBillingService::Test::InsertionOrder;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::CustomerBillingService;
use Microsoft::AdCenter::V8::CustomerBillingService::InsertionOrder;

sub test_can_create_insertion_order_and_set_all_fields : Test(13) {
    my $insertion_order = Microsoft::AdCenter::V8::CustomerBillingService::InsertionOrder->new
        ->AccountId('account id')
        ->BalanceAmount('balance amount')
        ->BookingCountryCode('booking country code')
        ->Comment('comment')
        ->EndDate('2010-05-31T12:23:34')
        ->InsertionOrderId('insertion order id')
        ->LastModifiedByUserId('last modified by user id')
        ->LastModifiedTime('2010-06-01T12:23:34')
        ->NotificationThreshold('notification threshold')
        ->ReferenceId('reference id')
        ->SpendCapAmount('spend cap amount')
        ->StartDate('2010-06-02T12:23:34')
    ;

    ok($insertion_order);

    is($insertion_order->AccountId, 'account id', 'can get account id');
    is($insertion_order->BalanceAmount, 'balance amount', 'can get balance amount');
    is($insertion_order->BookingCountryCode, 'booking country code', 'can get booking country code');
    is($insertion_order->Comment, 'comment', 'can get comment');
    is($insertion_order->EndDate, '2010-05-31T12:23:34', 'can get 2010-05-31T12:23:34');
    is($insertion_order->InsertionOrderId, 'insertion order id', 'can get insertion order id');
    is($insertion_order->LastModifiedByUserId, 'last modified by user id', 'can get last modified by user id');
    is($insertion_order->LastModifiedTime, '2010-06-01T12:23:34', 'can get 2010-06-01T12:23:34');
    is($insertion_order->NotificationThreshold, 'notification threshold', 'can get notification threshold');
    is($insertion_order->ReferenceId, 'reference id', 'can get reference id');
    is($insertion_order->SpendCapAmount, 'spend cap amount', 'can get spend cap amount');
    is($insertion_order->StartDate, '2010-06-02T12:23:34', 'can get 2010-06-02T12:23:34');
};

1;
