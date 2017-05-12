package Microsoft::AdCenter::V7::CustomerManagementService::Test::GetUsersInfoResponse;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V7::CustomerManagementService;
use Microsoft::AdCenter::V7::CustomerManagementService::GetUsersInfoResponse;

sub test_can_create_get_users_info_response_and_set_all_fields : Test(2) {
    my $get_users_info_response = Microsoft::AdCenter::V7::CustomerManagementService::GetUsersInfoResponse->new
        ->UsersInfo('users info')
    ;

    ok($get_users_info_response);

    is($get_users_info_response->UsersInfo, 'users info', 'can get users info');
};

1;
