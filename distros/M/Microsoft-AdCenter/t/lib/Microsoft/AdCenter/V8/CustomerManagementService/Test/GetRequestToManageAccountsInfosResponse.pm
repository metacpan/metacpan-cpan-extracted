package Microsoft::AdCenter::V8::CustomerManagementService::Test::GetRequestToManageAccountsInfosResponse;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::CustomerManagementService;
use Microsoft::AdCenter::V8::CustomerManagementService::GetRequestToManageAccountsInfosResponse;

sub test_can_create_get_request_to_manage_accounts_infos_response_and_set_all_fields : Test(2) {
    my $get_request_to_manage_accounts_infos_response = Microsoft::AdCenter::V8::CustomerManagementService::GetRequestToManageAccountsInfosResponse->new
        ->ManageAccountsRequestInfos('manage accounts request infos')
    ;

    ok($get_request_to_manage_accounts_infos_response);

    is($get_request_to_manage_accounts_infos_response->ManageAccountsRequestInfos, 'manage accounts request infos', 'can get manage accounts request infos');
};

1;
