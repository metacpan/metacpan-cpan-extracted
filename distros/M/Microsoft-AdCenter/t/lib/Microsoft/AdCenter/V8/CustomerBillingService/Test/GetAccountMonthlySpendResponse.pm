package Microsoft::AdCenter::V8::CustomerBillingService::Test::GetAccountMonthlySpendResponse;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::CustomerBillingService;
use Microsoft::AdCenter::V8::CustomerBillingService::GetAccountMonthlySpendResponse;

sub test_can_create_get_account_monthly_spend_response_and_set_all_fields : Test(2) {
    my $get_account_monthly_spend_response = Microsoft::AdCenter::V8::CustomerBillingService::GetAccountMonthlySpendResponse->new
        ->Amount('amount')
    ;

    ok($get_account_monthly_spend_response);

    is($get_account_monthly_spend_response->Amount, 'amount', 'can get amount');
};

1;
