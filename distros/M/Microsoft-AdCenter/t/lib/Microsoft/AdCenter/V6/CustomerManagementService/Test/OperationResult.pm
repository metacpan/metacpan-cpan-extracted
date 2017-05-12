package Microsoft::AdCenter::V6::CustomerManagementService::Test::OperationResult;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V6::CustomerManagementService;
use Microsoft::AdCenter::V6::CustomerManagementService::OperationResult;

sub test_can_create_operation_result_and_set_all_fields : Test(3) {
    my $operation_result = Microsoft::AdCenter::V6::CustomerManagementService::OperationResult->new
        ->opErrors('op errors')
        ->opStatus('op status')
    ;

    ok($operation_result);

    is($operation_result->opErrors, 'op errors', 'can get op errors');
    is($operation_result->opStatus, 'op status', 'can get op status');
};

1;
