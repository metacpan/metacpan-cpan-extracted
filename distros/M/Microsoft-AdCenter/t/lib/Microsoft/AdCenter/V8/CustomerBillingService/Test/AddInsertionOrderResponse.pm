package Microsoft::AdCenter::V8::CustomerBillingService::Test::AddInsertionOrderResponse;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::CustomerBillingService;
use Microsoft::AdCenter::V8::CustomerBillingService::AddInsertionOrderResponse;

sub test_can_create_add_insertion_order_response_and_set_all_fields : Test(3) {
    my $add_insertion_order_response = Microsoft::AdCenter::V8::CustomerBillingService::AddInsertionOrderResponse->new
        ->CreateTime('2010-05-31T12:23:34')
        ->InsertionOrderId('insertion order id')
    ;

    ok($add_insertion_order_response);

    is($add_insertion_order_response->CreateTime, '2010-05-31T12:23:34', 'can get 2010-05-31T12:23:34');
    is($add_insertion_order_response->InsertionOrderId, 'insertion order id', 'can get insertion order id');
};

1;
