package Microsoft::AdCenter::V8::CustomerManagementService::Test::SendRequestToStopManagingAccountsResponse;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::CustomerManagementService;
use Microsoft::AdCenter::V8::CustomerManagementService::SendRequestToStopManagingAccountsResponse;

sub test_can_create_send_request_to_stop_managing_accounts_response_and_set_all_fields : Test(2) {
    my $send_request_to_stop_managing_accounts_response = Microsoft::AdCenter::V8::CustomerManagementService::SendRequestToStopManagingAccountsResponse->new
        ->RequestId('request id')
    ;

    ok($send_request_to_stop_managing_accounts_response);

    is($send_request_to_stop_managing_accounts_response->RequestId, 'request id', 'can get request id');
};

1;
