package Microsoft::AdCenter::V6::CustomerManagementService::Test::CreditCardInfoUpdateResponseMsg;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V6::CustomerManagementService;
use Microsoft::AdCenter::V6::CustomerManagementService::CreditCardInfoUpdateResponseMsg;

sub test_can_create_credit_card_info_update_response_msg_and_set_all_fields : Test(1) {
    my $credit_card_info_update_response_msg = Microsoft::AdCenter::V6::CustomerManagementService::CreditCardInfoUpdateResponseMsg->new
    ;

    ok($credit_card_info_update_response_msg);

};

1;
