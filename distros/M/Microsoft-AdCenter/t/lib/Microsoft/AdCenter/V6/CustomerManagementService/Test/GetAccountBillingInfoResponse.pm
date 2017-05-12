package Microsoft::AdCenter::V6::CustomerManagementService::Test::GetAccountBillingInfoResponse;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V6::CustomerManagementService;
use Microsoft::AdCenter::V6::CustomerManagementService::GetAccountBillingInfoResponse;

sub test_can_create_get_account_billing_info_response_and_set_all_fields : Test(2) {
    my $get_account_billing_info_response = Microsoft::AdCenter::V6::CustomerManagementService::GetAccountBillingInfoResponse->new
        ->GetAccountBillingInfoResult('get account billing info result')
    ;

    ok($get_account_billing_info_response);

    is($get_account_billing_info_response->GetAccountBillingInfoResult, 'get account billing info result', 'can get get account billing info result');
};

1;
