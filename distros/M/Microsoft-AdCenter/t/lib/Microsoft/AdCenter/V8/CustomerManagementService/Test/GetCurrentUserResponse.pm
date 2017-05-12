package Microsoft::AdCenter::V8::CustomerManagementService::Test::GetCurrentUserResponse;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::CustomerManagementService;
use Microsoft::AdCenter::V8::CustomerManagementService::GetCurrentUserResponse;

sub test_can_create_get_current_user_response_and_set_all_fields : Test(2) {
    my $get_current_user_response = Microsoft::AdCenter::V8::CustomerManagementService::GetCurrentUserResponse->new
        ->User('user')
    ;

    ok($get_current_user_response);

    is($get_current_user_response->User, 'user', 'can get user');
};

1;
