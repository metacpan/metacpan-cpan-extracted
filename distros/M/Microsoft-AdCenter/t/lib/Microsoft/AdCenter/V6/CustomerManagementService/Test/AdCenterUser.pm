package Microsoft::AdCenter::V6::CustomerManagementService::Test::AdCenterUser;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V6::CustomerManagementService;
use Microsoft::AdCenter::V6::CustomerManagementService::AdCenterUser;

sub test_can_create_ad_center_user_and_set_all_fields : Test(18) {
    my $ad_center_user = Microsoft::AdCenter::V6::CustomerManagementService::AdCenterUser->new
        ->ContactInfo('contact info')
        ->CustomerId('customer id')
        ->Email('email')
        ->FirstName('first name')
        ->JobTitle('job title')
        ->LanguageLCID('language lcid')
        ->LastName('last name')
        ->MiddleInitial('middle initial')
        ->Password('password')
        ->SecretAnswer('secret answer')
        ->SecretQuestion('secret question')
        ->UserAddress('user address')
        ->UserContactEmailFormat('user contact email format')
        ->UserContactPhone('user contact phone')
        ->UserContactPost('user contact post')
        ->UserId('user id')
        ->UserName('user name')
    ;

    ok($ad_center_user);

    is($ad_center_user->ContactInfo, 'contact info', 'can get contact info');
    is($ad_center_user->CustomerId, 'customer id', 'can get customer id');
    is($ad_center_user->Email, 'email', 'can get email');
    is($ad_center_user->FirstName, 'first name', 'can get first name');
    is($ad_center_user->JobTitle, 'job title', 'can get job title');
    is($ad_center_user->LanguageLCID, 'language lcid', 'can get language lcid');
    is($ad_center_user->LastName, 'last name', 'can get last name');
    is($ad_center_user->MiddleInitial, 'middle initial', 'can get middle initial');
    is($ad_center_user->Password, 'password', 'can get password');
    is($ad_center_user->SecretAnswer, 'secret answer', 'can get secret answer');
    is($ad_center_user->SecretQuestion, 'secret question', 'can get secret question');
    is($ad_center_user->UserAddress, 'user address', 'can get user address');
    is($ad_center_user->UserContactEmailFormat, 'user contact email format', 'can get user contact email format');
    is($ad_center_user->UserContactPhone, 'user contact phone', 'can get user contact phone');
    is($ad_center_user->UserContactPost, 'user contact post', 'can get user contact post');
    is($ad_center_user->UserId, 'user id', 'can get user id');
    is($ad_center_user->UserName, 'user name', 'can get user name');
};

1;
