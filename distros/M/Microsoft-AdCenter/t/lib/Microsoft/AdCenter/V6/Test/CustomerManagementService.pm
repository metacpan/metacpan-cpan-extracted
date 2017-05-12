package Microsoft::AdCenter::V6::Test::CustomerManagementService;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V6::CustomerManagementService;

sub test_can_create_v6_customer_management_service_and_set_all_fields : Test(5) {
    my $v6_customer_management_service = Microsoft::AdCenter::V6::CustomerManagementService->new
        ->EndPoint('http://some.where.that/does/not/exists')
        ->Password('password')
        ->UserAccessKey('user access key')
        ->UserName('user name')
    ;

    ok($v6_customer_management_service);

    is($v6_customer_management_service->EndPoint, 'http://some.where.that/does/not/exists', 'can get end point');
    is($v6_customer_management_service->Password, 'password', 'can get password');
    is($v6_customer_management_service->UserAccessKey, 'user access key', 'can get user access key');
    is($v6_customer_management_service->UserName, 'user name', 'can get user name');
};

1;
