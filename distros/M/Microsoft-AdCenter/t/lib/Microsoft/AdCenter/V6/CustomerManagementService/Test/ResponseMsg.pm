package Microsoft::AdCenter::V6::CustomerManagementService::Test::ResponseMsg;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V6::CustomerManagementService;
use Microsoft::AdCenter::V6::CustomerManagementService::ResponseMsg;

sub test_can_create_response_msg_and_set_all_fields : Test(2) {
    my $response_msg = Microsoft::AdCenter::V6::CustomerManagementService::ResponseMsg->new
        ->opResult('op result')
    ;

    ok($response_msg);

    is($response_msg->opResult, 'op result', 'can get op result');
};

1;
