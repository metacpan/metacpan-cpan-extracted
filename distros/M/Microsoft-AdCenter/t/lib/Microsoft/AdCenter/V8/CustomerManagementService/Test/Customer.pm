package Microsoft::AdCenter::V8::CustomerManagementService::Test::Customer;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::CustomerManagementService;
use Microsoft::AdCenter::V8::CustomerManagementService::Customer;

sub test_can_create_customer_and_set_all_fields : Test(14) {
    my $customer = Microsoft::AdCenter::V8::CustomerManagementService::Customer->new
        ->CustomerAddress('customer address')
        ->CustomerFinancialStatus('customer financial status')
        ->CustomerLifeCycleStatus('customer life cycle status')
        ->Id('id')
        ->Industry('industry')
        ->LastModifiedByUserId('last modified by user id')
        ->LastModifiedTime('2010-05-31T12:23:34')
        ->MarketCountry('market country')
        ->MarketLanguage('market language')
        ->Name('name')
        ->Number('number')
        ->ServiceLevel('service level')
        ->TimeStamp('time stamp')
    ;

    ok($customer);

    is($customer->CustomerAddress, 'customer address', 'can get customer address');
    is($customer->CustomerFinancialStatus, 'customer financial status', 'can get customer financial status');
    is($customer->CustomerLifeCycleStatus, 'customer life cycle status', 'can get customer life cycle status');
    is($customer->Id, 'id', 'can get id');
    is($customer->Industry, 'industry', 'can get industry');
    is($customer->LastModifiedByUserId, 'last modified by user id', 'can get last modified by user id');
    is($customer->LastModifiedTime, '2010-05-31T12:23:34', 'can get 2010-05-31T12:23:34');
    is($customer->MarketCountry, 'market country', 'can get market country');
    is($customer->MarketLanguage, 'market language', 'can get market language');
    is($customer->Name, 'name', 'can get name');
    is($customer->Number, 'number', 'can get number');
    is($customer->ServiceLevel, 'service level', 'can get service level');
    is($customer->TimeStamp, 'time stamp', 'can get time stamp');
};

1;
