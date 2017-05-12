package Microsoft::AdCenter::V8::CustomerManagementService::Test::FindAccountsOrCustomersInfoResponse;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::CustomerManagementService;
use Microsoft::AdCenter::V8::CustomerManagementService::FindAccountsOrCustomersInfoResponse;

sub test_can_create_find_accounts_or_customers_info_response_and_set_all_fields : Test(2) {
    my $find_accounts_or_customers_info_response = Microsoft::AdCenter::V8::CustomerManagementService::FindAccountsOrCustomersInfoResponse->new
        ->AccountInfoWithCustomerData('account info with customer data')
    ;

    ok($find_accounts_or_customers_info_response);

    is($find_accounts_or_customers_info_response->AccountInfoWithCustomerData, 'account info with customer data', 'can get account info with customer data');
};

1;
