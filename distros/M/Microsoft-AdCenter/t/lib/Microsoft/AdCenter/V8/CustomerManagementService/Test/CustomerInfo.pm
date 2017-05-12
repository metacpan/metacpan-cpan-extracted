package Microsoft::AdCenter::V8::CustomerManagementService::Test::CustomerInfo;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::CustomerManagementService;
use Microsoft::AdCenter::V8::CustomerManagementService::CustomerInfo;

sub test_can_create_customer_info_and_set_all_fields : Test(3) {
    my $customer_info = Microsoft::AdCenter::V8::CustomerManagementService::CustomerInfo->new
        ->Id('id')
        ->Name('name')
    ;

    ok($customer_info);

    is($customer_info->Id, 'id', 'can get id');
    is($customer_info->Name, 'name', 'can get name');
};

1;
