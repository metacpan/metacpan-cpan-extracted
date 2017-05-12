package Microsoft::AdCenter::V8::CustomerManagementService::Test::AccountInfo;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::CustomerManagementService;
use Microsoft::AdCenter::V8::CustomerManagementService::AccountInfo;

sub test_can_create_account_info_and_set_all_fields : Test(6) {
    my $account_info = Microsoft::AdCenter::V8::CustomerManagementService::AccountInfo->new
        ->AccountLifeCycleStatus('account life cycle status')
        ->Id('id')
        ->Name('name')
        ->Number('number')
        ->PauseReason('pause reason')
    ;

    ok($account_info);

    is($account_info->AccountLifeCycleStatus, 'account life cycle status', 'can get account life cycle status');
    is($account_info->Id, 'id', 'can get id');
    is($account_info->Name, 'name', 'can get name');
    is($account_info->Number, 'number', 'can get number');
    is($account_info->PauseReason, 'pause reason', 'can get pause reason');
};

1;
