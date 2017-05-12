package Microsoft::AdCenter::V8::CustomerManagementService::Test::GetUserResponse;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::CustomerManagementService;
use Microsoft::AdCenter::V8::CustomerManagementService::GetUserResponse;

sub test_can_create_get_user_response_and_set_all_fields : Test(5) {
    my $get_user_response = Microsoft::AdCenter::V8::CustomerManagementService::GetUserResponse->new
        ->Accounts('accounts')
        ->Customers('customers')
        ->Roles('roles')
        ->User('user')
    ;

    ok($get_user_response);

    is($get_user_response->Accounts, 'accounts', 'can get accounts');
    is($get_user_response->Customers, 'customers', 'can get customers');
    is($get_user_response->Roles, 'roles', 'can get roles');
    is($get_user_response->User, 'user', 'can get user');
};

1;
