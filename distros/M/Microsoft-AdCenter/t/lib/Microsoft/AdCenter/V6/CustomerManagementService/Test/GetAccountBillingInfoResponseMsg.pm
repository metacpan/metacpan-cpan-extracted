package Microsoft::AdCenter::V6::CustomerManagementService::Test::GetAccountBillingInfoResponseMsg;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V6::CustomerManagementService;
use Microsoft::AdCenter::V6::CustomerManagementService::GetAccountBillingInfoResponseMsg;

sub test_can_create_get_account_billing_info_response_msg_and_set_all_fields : Test(2) {
    my $get_account_billing_info_response_msg = Microsoft::AdCenter::V6::CustomerManagementService::GetAccountBillingInfoResponseMsg->new
        ->AccountBilling('account billing')
    ;

    ok($get_account_billing_info_response_msg);

    is($get_account_billing_info_response_msg->AccountBilling, 'account billing', 'can get account billing');
};

1;
