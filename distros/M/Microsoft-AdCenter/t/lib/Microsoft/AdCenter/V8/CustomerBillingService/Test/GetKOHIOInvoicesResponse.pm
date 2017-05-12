package Microsoft::AdCenter::V8::CustomerBillingService::Test::GetKOHIOInvoicesResponse;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::CustomerBillingService;
use Microsoft::AdCenter::V8::CustomerBillingService::GetKOHIOInvoicesResponse;

sub test_can_create_get_kohioinvoices_response_and_set_all_fields : Test(2) {
    my $get_kohioinvoices_response = Microsoft::AdCenter::V8::CustomerBillingService::GetKOHIOInvoicesResponse->new
        ->Invoices('invoices')
    ;

    ok($get_kohioinvoices_response);

    is($get_kohioinvoices_response->Invoices, 'invoices', 'can get invoices');
};

1;
