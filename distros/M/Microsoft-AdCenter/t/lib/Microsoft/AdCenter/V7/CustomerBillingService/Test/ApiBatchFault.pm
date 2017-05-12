package Microsoft::AdCenter::V7::CustomerBillingService::Test::ApiBatchFault;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V7::CustomerBillingService;
use Microsoft::AdCenter::V7::CustomerBillingService::ApiBatchFault;

sub test_can_create_api_batch_fault_and_set_all_fields : Test(2) {
    my $api_batch_fault = Microsoft::AdCenter::V7::CustomerBillingService::ApiBatchFault->new
        ->BatchErrors('batch errors')
    ;

    ok($api_batch_fault);

    is($api_batch_fault->BatchErrors, 'batch errors', 'can get batch errors');
};

1;
