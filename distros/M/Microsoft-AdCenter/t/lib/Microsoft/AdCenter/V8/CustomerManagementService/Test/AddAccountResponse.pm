package Microsoft::AdCenter::V8::CustomerManagementService::Test::AddAccountResponse;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::CustomerManagementService;
use Microsoft::AdCenter::V8::CustomerManagementService::AddAccountResponse;

sub test_can_create_add_account_response_and_set_all_fields : Test(4) {
    my $add_account_response = Microsoft::AdCenter::V8::CustomerManagementService::AddAccountResponse->new
        ->AccountId('account id')
        ->AccountNumber('account number')
        ->CreateTime('2010-05-31T12:23:34')
    ;

    ok($add_account_response);

    is($add_account_response->AccountId, 'account id', 'can get account id');
    is($add_account_response->AccountNumber, 'account number', 'can get account number');
    is($add_account_response->CreateTime, '2010-05-31T12:23:34', 'can get 2010-05-31T12:23:34');
};

1;
