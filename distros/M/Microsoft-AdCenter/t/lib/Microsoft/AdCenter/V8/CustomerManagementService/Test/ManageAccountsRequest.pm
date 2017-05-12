package Microsoft::AdCenter::V8::CustomerManagementService::Test::ManageAccountsRequest;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::CustomerManagementService;
use Microsoft::AdCenter::V8::CustomerManagementService::ManageAccountsRequest;

sub test_can_create_manage_accounts_request_and_set_all_fields : Test(18) {
    my $manage_accounts_request = Microsoft::AdCenter::V8::CustomerManagementService::ManageAccountsRequest->new
        ->AdvertiserAccountNumbers('advertiser account numbers')
        ->AgencyCustomerNumber('agency customer number')
        ->EffectiveDate('effective date')
        ->Id('id')
        ->LastModifiedByUserId('last modified by user id')
        ->LastModifiedDateTime('2010-05-31T12:23:34')
        ->Notes('notes')
        ->PaymentMethodId('payment method id')
        ->RequestDate('2010-06-01T12:23:34')
        ->RequestStatus('request status')
        ->RequestStatusDetails('request status details')
        ->RequestType('request type')
        ->RequesterContactEmail('requester contact email')
        ->RequesterContactName('requester contact name')
        ->RequesterContactPhoneNumber('requester contact phone number')
        ->RequesterCustomerNumber('requester customer number')
        ->TimeStamp('time stamp')
    ;

    ok($manage_accounts_request);

    is($manage_accounts_request->AdvertiserAccountNumbers, 'advertiser account numbers', 'can get advertiser account numbers');
    is($manage_accounts_request->AgencyCustomerNumber, 'agency customer number', 'can get agency customer number');
    is($manage_accounts_request->EffectiveDate, 'effective date', 'can get effective date');
    is($manage_accounts_request->Id, 'id', 'can get id');
    is($manage_accounts_request->LastModifiedByUserId, 'last modified by user id', 'can get last modified by user id');
    is($manage_accounts_request->LastModifiedDateTime, '2010-05-31T12:23:34', 'can get 2010-05-31T12:23:34');
    is($manage_accounts_request->Notes, 'notes', 'can get notes');
    is($manage_accounts_request->PaymentMethodId, 'payment method id', 'can get payment method id');
    is($manage_accounts_request->RequestDate, '2010-06-01T12:23:34', 'can get 2010-06-01T12:23:34');
    is($manage_accounts_request->RequestStatus, 'request status', 'can get request status');
    is($manage_accounts_request->RequestStatusDetails, 'request status details', 'can get request status details');
    is($manage_accounts_request->RequestType, 'request type', 'can get request type');
    is($manage_accounts_request->RequesterContactEmail, 'requester contact email', 'can get requester contact email');
    is($manage_accounts_request->RequesterContactName, 'requester contact name', 'can get requester contact name');
    is($manage_accounts_request->RequesterContactPhoneNumber, 'requester contact phone number', 'can get requester contact phone number');
    is($manage_accounts_request->RequesterCustomerNumber, 'requester customer number', 'can get requester customer number');
    is($manage_accounts_request->TimeStamp, 'time stamp', 'can get time stamp');
};

1;
