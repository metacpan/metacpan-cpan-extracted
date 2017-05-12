package Microsoft::AdCenter::V8::CustomerManagementService::Test::Address;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::CustomerManagementService;
use Microsoft::AdCenter::V8::CustomerManagementService::Address;

sub test_can_create_address_and_set_all_fields : Test(11) {
    my $address = Microsoft::AdCenter::V8::CustomerManagementService::Address->new
        ->City('city')
        ->CountryCode('country code')
        ->Id('id')
        ->Line1('line1')
        ->Line2('line2')
        ->Line3('line3')
        ->Line4('line4')
        ->PostalCode('postal code')
        ->StateOrProvince('state or province')
        ->TimeStamp('time stamp')
    ;

    ok($address);

    is($address->City, 'city', 'can get city');
    is($address->CountryCode, 'country code', 'can get country code');
    is($address->Id, 'id', 'can get id');
    is($address->Line1, 'line1', 'can get line1');
    is($address->Line2, 'line2', 'can get line2');
    is($address->Line3, 'line3', 'can get line3');
    is($address->Line4, 'line4', 'can get line4');
    is($address->PostalCode, 'postal code', 'can get postal code');
    is($address->StateOrProvince, 'state or province', 'can get state or province');
    is($address->TimeStamp, 'time stamp', 'can get time stamp');
};

1;
