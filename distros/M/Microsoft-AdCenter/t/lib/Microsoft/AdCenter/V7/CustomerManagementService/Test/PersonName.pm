package Microsoft::AdCenter::V7::CustomerManagementService::Test::PersonName;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V7::CustomerManagementService;
use Microsoft::AdCenter::V7::CustomerManagementService::PersonName;

sub test_can_create_person_name_and_set_all_fields : Test(4) {
    my $person_name = Microsoft::AdCenter::V7::CustomerManagementService::PersonName->new
        ->FirstName('first name')
        ->LastName('last name')
        ->MiddleInitial('middle initial')
    ;

    ok($person_name);

    is($person_name->FirstName, 'first name', 'can get first name');
    is($person_name->LastName, 'last name', 'can get last name');
    is($person_name->MiddleInitial, 'middle initial', 'can get middle initial');
};

1;
