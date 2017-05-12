package Microsoft::AdCenter::V7::CustomerManagementService::Test::ContactInfo;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V7::CustomerManagementService;
use Microsoft::AdCenter::V7::CustomerManagementService::ContactInfo;

sub test_can_create_contact_info_and_set_all_fields : Test(12) {
    my $contact_info = Microsoft::AdCenter::V7::CustomerManagementService::ContactInfo->new
        ->Address('address')
        ->ContactByPhone('contact by phone')
        ->ContactByPostalMail('contact by postal mail')
        ->Email('email')
        ->EmailFormat('email format')
        ->Fax('fax')
        ->HomePhone('home phone')
        ->Id('id')
        ->Mobile('mobile')
        ->Phone1('phone1')
        ->Phone2('phone2')
    ;

    ok($contact_info);

    is($contact_info->Address, 'address', 'can get address');
    is($contact_info->ContactByPhone, 'contact by phone', 'can get contact by phone');
    is($contact_info->ContactByPostalMail, 'contact by postal mail', 'can get contact by postal mail');
    is($contact_info->Email, 'email', 'can get email');
    is($contact_info->EmailFormat, 'email format', 'can get email format');
    is($contact_info->Fax, 'fax', 'can get fax');
    is($contact_info->HomePhone, 'home phone', 'can get home phone');
    is($contact_info->Id, 'id', 'can get id');
    is($contact_info->Mobile, 'mobile', 'can get mobile');
    is($contact_info->Phone1, 'phone1', 'can get phone1');
    is($contact_info->Phone2, 'phone2', 'can get phone2');
};

1;
