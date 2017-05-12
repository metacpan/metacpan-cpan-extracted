package Microsoft::AdCenter::V8::CustomerManagementService::Test::UpdateUserResponse;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::CustomerManagementService;
use Microsoft::AdCenter::V8::CustomerManagementService::UpdateUserResponse;

sub test_can_create_update_user_response_and_set_all_fields : Test(2) {
    my $update_user_response = Microsoft::AdCenter::V8::CustomerManagementService::UpdateUserResponse->new
        ->LastModifiedTime('2010-05-31T12:23:34')
    ;

    ok($update_user_response);

    is($update_user_response->LastModifiedTime, '2010-05-31T12:23:34', 'can get 2010-05-31T12:23:34');
};

1;
