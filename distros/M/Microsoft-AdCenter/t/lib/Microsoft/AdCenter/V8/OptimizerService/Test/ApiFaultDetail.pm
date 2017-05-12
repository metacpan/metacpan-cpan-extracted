package Microsoft::AdCenter::V8::OptimizerService::Test::ApiFaultDetail;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::OptimizerService;
use Microsoft::AdCenter::V8::OptimizerService::ApiFaultDetail;

sub test_can_create_api_fault_detail_and_set_all_fields : Test(3) {
    my $api_fault_detail = Microsoft::AdCenter::V8::OptimizerService::ApiFaultDetail->new
        ->BatchErrors('batch errors')
        ->OperationErrors('operation errors')
    ;

    ok($api_fault_detail);

    is($api_fault_detail->BatchErrors, 'batch errors', 'can get batch errors');
    is($api_fault_detail->OperationErrors, 'operation errors', 'can get operation errors');
};

1;
