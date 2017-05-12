package Microsoft::AdCenter::V8::CustomerManagementService::Test::FindAccountsResponse;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::CustomerManagementService;
use Microsoft::AdCenter::V8::CustomerManagementService::FindAccountsResponse;

sub test_can_create_find_accounts_response_and_set_all_fields : Test(2) {
    my $find_accounts_response = Microsoft::AdCenter::V8::CustomerManagementService::FindAccountsResponse->new
        ->AccountsInfo('accounts info')
    ;

    ok($find_accounts_response);

    is($find_accounts_response->AccountsInfo, 'accounts info', 'can get accounts info');
};

1;
