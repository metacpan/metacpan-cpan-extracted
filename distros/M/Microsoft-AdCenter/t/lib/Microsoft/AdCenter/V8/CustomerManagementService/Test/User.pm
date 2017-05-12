package Microsoft::AdCenter::V8::CustomerManagementService::Test::User;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::CustomerManagementService;
use Microsoft::AdCenter::V8::CustomerManagementService::User;

sub test_can_create_user_and_set_all_fields : Test(16) {
    my $user = Microsoft::AdCenter::V8::CustomerManagementService::User->new
        ->ContactInfo('contact info')
        ->CustomerAppScope('customer app scope')
        ->CustomerId('customer id')
        ->Id('id')
        ->JobTitle('job title')
        ->LastModifiedByUserId('last modified by user id')
        ->LastModifiedTime('2010-05-31T12:23:34')
        ->Lcid('lcid')
        ->Name('name')
        ->Password('password')
        ->SecretAnswer('secret answer')
        ->SecretQuestion('secret question')
        ->TimeStamp('time stamp')
        ->UserLifeCycleStatus('user life cycle status')
        ->UserName('user name')
    ;

    ok($user);

    is($user->ContactInfo, 'contact info', 'can get contact info');
    is($user->CustomerAppScope, 'customer app scope', 'can get customer app scope');
    is($user->CustomerId, 'customer id', 'can get customer id');
    is($user->Id, 'id', 'can get id');
    is($user->JobTitle, 'job title', 'can get job title');
    is($user->LastModifiedByUserId, 'last modified by user id', 'can get last modified by user id');
    is($user->LastModifiedTime, '2010-05-31T12:23:34', 'can get 2010-05-31T12:23:34');
    is($user->Lcid, 'lcid', 'can get lcid');
    is($user->Name, 'name', 'can get name');
    is($user->Password, 'password', 'can get password');
    is($user->SecretAnswer, 'secret answer', 'can get secret answer');
    is($user->SecretQuestion, 'secret question', 'can get secret question');
    is($user->TimeStamp, 'time stamp', 'can get time stamp');
    is($user->UserLifeCycleStatus, 'user life cycle status', 'can get user life cycle status');
    is($user->UserName, 'user name', 'can get user name');
};

1;
