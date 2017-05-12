package Microsoft::AdCenter::V7::CustomerManagementService::Test::SignupCustomerResponse;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V7::CustomerManagementService;
use Microsoft::AdCenter::V7::CustomerManagementService::SignupCustomerResponse;

sub test_can_create_signup_customer_response_and_set_all_fields : Test(7) {
    my $signup_customer_response = Microsoft::AdCenter::V7::CustomerManagementService::SignupCustomerResponse->new
        ->AccountId('account id')
        ->AccountNumber('account number')
        ->CreateTime('2010-05-31T12:23:34')
        ->CustomerId('customer id')
        ->CustomerNumber('customer number')
        ->UserId('user id')
    ;

    ok($signup_customer_response);

    is($signup_customer_response->AccountId, 'account id', 'can get account id');
    is($signup_customer_response->AccountNumber, 'account number', 'can get account number');
    is($signup_customer_response->CreateTime, '2010-05-31T12:23:34', 'can get 2010-05-31T12:23:34');
    is($signup_customer_response->CustomerId, 'customer id', 'can get customer id');
    is($signup_customer_response->CustomerNumber, 'customer number', 'can get customer number');
    is($signup_customer_response->UserId, 'user id', 'can get user id');
};

1;
