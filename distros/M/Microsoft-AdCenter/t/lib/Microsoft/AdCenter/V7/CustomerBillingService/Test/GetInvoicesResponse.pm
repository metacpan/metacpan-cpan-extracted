package Microsoft::AdCenter::V7::CustomerBillingService::Test::GetInvoicesResponse;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V7::CustomerBillingService;
use Microsoft::AdCenter::V7::CustomerBillingService::GetInvoicesResponse;

sub test_can_create_get_invoices_response_and_set_all_fields : Test(2) {
    my $get_invoices_response = Microsoft::AdCenter::V7::CustomerBillingService::GetInvoicesResponse->new
        ->Invoices('invoices')
    ;

    ok($get_invoices_response);

    is($get_invoices_response->Invoices, 'invoices', 'can get invoices');
};

1;
