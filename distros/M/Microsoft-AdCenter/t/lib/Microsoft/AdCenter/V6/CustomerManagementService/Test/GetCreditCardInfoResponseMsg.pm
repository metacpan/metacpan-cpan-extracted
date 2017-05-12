package Microsoft::AdCenter::V6::CustomerManagementService::Test::GetCreditCardInfoResponseMsg;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V6::CustomerManagementService;
use Microsoft::AdCenter::V6::CustomerManagementService::GetCreditCardInfoResponseMsg;

sub test_can_create_get_credit_card_info_response_msg_and_set_all_fields : Test(2) {
    my $get_credit_card_info_response_msg = Microsoft::AdCenter::V6::CustomerManagementService::GetCreditCardInfoResponseMsg->new
        ->CreditCards('credit cards')
    ;

    ok($get_credit_card_info_response_msg);

    is($get_credit_card_info_response_msg->CreditCards, 'credit cards', 'can get credit cards');
};

1;
