package Microsoft::AdCenter::V7::CustomerManagementService::Test::GetCustomerResponse;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V7::CustomerManagementService;
use Microsoft::AdCenter::V7::CustomerManagementService::GetCustomerResponse;

sub test_can_create_get_customer_response_and_set_all_fields : Test(2) {
    my $get_customer_response = Microsoft::AdCenter::V7::CustomerManagementService::GetCustomerResponse->new
        ->Customer('customer')
    ;

    ok($get_customer_response);

    is($get_customer_response->Customer, 'customer', 'can get customer');
};

1;
