package Microsoft::AdCenter::V6::CustomerManagementService::Test::CardInvoiceResponseMsg;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V6::CustomerManagementService;
use Microsoft::AdCenter::V6::CustomerManagementService::CardInvoiceResponseMsg;

sub test_can_create_card_invoice_response_msg_and_set_all_fields : Test(2) {
    my $card_invoice_response_msg = Microsoft::AdCenter::V6::CustomerManagementService::CardInvoiceResponseMsg->new
        ->CardInvoice('card invoice')
    ;

    ok($card_invoice_response_msg);

    is($card_invoice_response_msg->CardInvoice, 'card invoice', 'can get card invoice');
};

1;
