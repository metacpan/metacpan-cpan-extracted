package Microsoft::AdCenter::V8::CustomerManagementService::Test::ManageAccountsRequestInfo;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::CustomerManagementService;
use Microsoft::AdCenter::V8::CustomerManagementService::ManageAccountsRequestInfo;

sub test_can_create_manage_accounts_request_info_and_set_all_fields : Test(7) {
    my $manage_accounts_request_info = Microsoft::AdCenter::V8::CustomerManagementService::ManageAccountsRequestInfo->new
        ->AdvertiserAccountNumbers('advertiser account numbers')
        ->AgencyCustomerNumber('agency customer number')
        ->EffectiveDate('effective date')
        ->Id('id')
        ->RequestDate('2010-05-31T12:23:34')
        ->Status('status')
    ;

    ok($manage_accounts_request_info);

    is($manage_accounts_request_info->AdvertiserAccountNumbers, 'advertiser account numbers', 'can get advertiser account numbers');
    is($manage_accounts_request_info->AgencyCustomerNumber, 'agency customer number', 'can get agency customer number');
    is($manage_accounts_request_info->EffectiveDate, 'effective date', 'can get effective date');
    is($manage_accounts_request_info->Id, 'id', 'can get id');
    is($manage_accounts_request_info->RequestDate, '2010-05-31T12:23:34', 'can get 2010-05-31T12:23:34');
    is($manage_accounts_request_info->Status, 'status', 'can get status');
};

1;
