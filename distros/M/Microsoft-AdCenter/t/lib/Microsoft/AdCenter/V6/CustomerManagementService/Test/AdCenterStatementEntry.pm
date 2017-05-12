package Microsoft::AdCenter::V6::CustomerManagementService::Test::AdCenterStatementEntry;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V6::CustomerManagementService;
use Microsoft::AdCenter::V6::CustomerManagementService::AdCenterStatementEntry;

sub test_can_create_ad_center_statement_entry_and_set_all_fields : Test(6) {
    my $ad_center_statement_entry = Microsoft::AdCenter::V6::CustomerManagementService::AdCenterStatementEntry->new
        ->Detail('detail')
        ->DetailCode('detail code')
        ->InvoiceEndDate('2010-05-31T12:23:34')
        ->InvoiceNumber('invoice number')
        ->InvoiceStartDate('2010-06-01T12:23:34')
    ;

    ok($ad_center_statement_entry);

    is($ad_center_statement_entry->Detail, 'detail', 'can get detail');
    is($ad_center_statement_entry->DetailCode, 'detail code', 'can get detail code');
    is($ad_center_statement_entry->InvoiceEndDate, '2010-05-31T12:23:34', 'can get 2010-05-31T12:23:34');
    is($ad_center_statement_entry->InvoiceNumber, 'invoice number', 'can get invoice number');
    is($ad_center_statement_entry->InvoiceStartDate, '2010-06-01T12:23:34', 'can get 2010-06-01T12:23:34');
};

1;
