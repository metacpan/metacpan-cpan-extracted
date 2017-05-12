package Microsoft::AdCenter::V6::CustomerManagementService::Test::GetCardInvoiceResponse;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V6::CustomerManagementService;
use Microsoft::AdCenter::V6::CustomerManagementService::GetCardInvoiceResponse;

sub test_can_create_get_card_invoice_response_and_set_all_fields : Test(2) {
    my $get_card_invoice_response = Microsoft::AdCenter::V6::CustomerManagementService::GetCardInvoiceResponse->new
        ->GetCardInvoiceResult('get card invoice result')
    ;

    ok($get_card_invoice_response);

    is($get_card_invoice_response->GetCardInvoiceResult, 'get card invoice result', 'can get get card invoice result');
};

1;
