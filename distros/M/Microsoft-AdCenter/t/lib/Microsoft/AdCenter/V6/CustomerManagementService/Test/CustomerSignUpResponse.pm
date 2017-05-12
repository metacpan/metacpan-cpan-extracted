package Microsoft::AdCenter::V6::CustomerManagementService::Test::CustomerSignUpResponse;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V6::CustomerManagementService;
use Microsoft::AdCenter::V6::CustomerManagementService::CustomerSignUpResponse;

sub test_can_create_customer_sign_up_response_and_set_all_fields : Test(2) {
    my $customer_sign_up_response = Microsoft::AdCenter::V6::CustomerManagementService::CustomerSignUpResponse->new
        ->CustomerSignUpResult('customer sign up result')
    ;

    ok($customer_sign_up_response);

    is($customer_sign_up_response->CustomerSignUpResult, 'customer sign up result', 'can get customer sign up result');
};

1;
