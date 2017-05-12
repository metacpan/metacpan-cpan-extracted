package Microsoft::AdCenter::V8::CustomerManagementService::Test::CancelRequestToManageAccountsResponse;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::CustomerManagementService;
use Microsoft::AdCenter::V8::CustomerManagementService::CancelRequestToManageAccountsResponse;

sub test_can_create_cancel_request_to_manage_accounts_response_and_set_all_fields : Test(1) {
    my $cancel_request_to_manage_accounts_response = Microsoft::AdCenter::V8::CustomerManagementService::CancelRequestToManageAccountsResponse->new
    ;

    ok($cancel_request_to_manage_accounts_response);

};

1;
