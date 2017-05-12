package Microsoft::AdCenter::V6::CustomerManagementService::Test::CustomerSignUpResponseMsg;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V6::CustomerManagementService;
use Microsoft::AdCenter::V6::CustomerManagementService::CustomerSignUpResponseMsg;

sub test_can_create_customer_sign_up_response_msg_and_set_all_fields : Test(4) {
    my $customer_sign_up_response_msg = Microsoft::AdCenter::V6::CustomerManagementService::CustomerSignUpResponseMsg->new
        ->AccountId('account id')
        ->CustomerId('customer id')
        ->UserId('user id')
    ;

    ok($customer_sign_up_response_msg);

    is($customer_sign_up_response_msg->AccountId, 'account id', 'can get account id');
    is($customer_sign_up_response_msg->CustomerId, 'customer id', 'can get customer id');
    is($customer_sign_up_response_msg->UserId, 'user id', 'can get user id');
};

1;
