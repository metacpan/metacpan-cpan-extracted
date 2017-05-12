package Microsoft::AdCenter::V7::CustomerManagementService::Test::GetCustomersInfoResponse;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V7::CustomerManagementService;
use Microsoft::AdCenter::V7::CustomerManagementService::GetCustomersInfoResponse;

sub test_can_create_get_customers_info_response_and_set_all_fields : Test(2) {
    my $get_customers_info_response = Microsoft::AdCenter::V7::CustomerManagementService::GetCustomersInfoResponse->new
        ->CustomersInfo('customers info')
    ;

    ok($get_customers_info_response);

    is($get_customers_info_response->CustomersInfo, 'customers info', 'can get customers info');
};

1;
