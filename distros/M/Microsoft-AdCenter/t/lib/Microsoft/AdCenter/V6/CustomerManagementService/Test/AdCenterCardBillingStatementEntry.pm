package Microsoft::AdCenter::V6::CustomerManagementService::Test::AdCenterCardBillingStatementEntry;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V6::CustomerManagementService;
use Microsoft::AdCenter::V6::CustomerManagementService::AdCenterCardBillingStatementEntry;

sub test_can_create_ad_center_card_billing_statement_entry_and_set_all_fields : Test(6) {
    my $ad_center_card_billing_statement_entry = Microsoft::AdCenter::V6::CustomerManagementService::AdCenterCardBillingStatementEntry->new
        ->Amount('amount')
        ->Balance('balance')
        ->BillingInvoiceHandle('billing invoice handle')
        ->Charge('charge')
        ->Credit('credit')
    ;

    ok($ad_center_card_billing_statement_entry);

    is($ad_center_card_billing_statement_entry->Amount, 'amount', 'can get amount');
    is($ad_center_card_billing_statement_entry->Balance, 'balance', 'can get balance');
    is($ad_center_card_billing_statement_entry->BillingInvoiceHandle, 'billing invoice handle', 'can get billing invoice handle');
    is($ad_center_card_billing_statement_entry->Charge, 'charge', 'can get charge');
    is($ad_center_card_billing_statement_entry->Credit, 'credit', 'can get credit');
};

1;
