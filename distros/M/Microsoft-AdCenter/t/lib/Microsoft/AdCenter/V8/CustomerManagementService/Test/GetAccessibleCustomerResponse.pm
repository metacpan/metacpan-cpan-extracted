package Microsoft::AdCenter::V8::CustomerManagementService::Test::GetAccessibleCustomerResponse;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::CustomerManagementService;
use Microsoft::AdCenter::V8::CustomerManagementService::GetAccessibleCustomerResponse;

sub test_can_create_get_accessible_customer_response_and_set_all_fields : Test(3) {
    my $get_accessible_customer_response = Microsoft::AdCenter::V8::CustomerManagementService::GetAccessibleCustomerResponse->new
        ->AccessibleCustomer('accessible customer')
        ->ValidFields('valid fields')
    ;

    ok($get_accessible_customer_response);

    is($get_accessible_customer_response->AccessibleCustomer, 'accessible customer', 'can get accessible customer');
    is($get_accessible_customer_response->ValidFields, 'valid fields', 'can get valid fields');
};

1;
