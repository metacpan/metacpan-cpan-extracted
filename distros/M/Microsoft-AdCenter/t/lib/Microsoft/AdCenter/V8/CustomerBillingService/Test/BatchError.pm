package Microsoft::AdCenter::V8::CustomerBillingService::Test::BatchError;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::CustomerBillingService;
use Microsoft::AdCenter::V8::CustomerBillingService::BatchError;

sub test_can_create_batch_error_and_set_all_fields : Test(5) {
    my $batch_error = Microsoft::AdCenter::V8::CustomerBillingService::BatchError->new
        ->Code('code')
        ->Details('details')
        ->Index('index')
        ->Message('message')
    ;

    ok($batch_error);

    is($batch_error->Code, 'code', 'can get code');
    is($batch_error->Details, 'details', 'can get details');
    is($batch_error->Index, 'index', 'can get index');
    is($batch_error->Message, 'message', 'can get message');
};

1;
