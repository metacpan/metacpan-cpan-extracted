package Microsoft::AdCenter::V6::CustomerManagementService::Test::AdCenterCardInvoice;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V6::CustomerManagementService;
use Microsoft::AdCenter::V6::CustomerManagementService::AdCenterCardInvoice;

sub test_can_create_ad_center_card_invoice_and_set_all_fields : Test(3) {
    my $ad_center_card_invoice = Microsoft::AdCenter::V6::CustomerManagementService::AdCenterCardInvoice->new
        ->HeaderDetail('header detail')
        ->InvoiceEntries('invoice entries')
    ;

    ok($ad_center_card_invoice);

    is($ad_center_card_invoice->HeaderDetail, 'header detail', 'can get header detail');
    is($ad_center_card_invoice->InvoiceEntries, 'invoice entries', 'can get invoice entries');
};

1;
