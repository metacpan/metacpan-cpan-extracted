package Microsoft::AdCenter::V6::CustomerManagementService::Test::AdCenterAddress;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V6::CustomerManagementService;
use Microsoft::AdCenter::V6::CustomerManagementService::AdCenterAddress;

sub test_can_create_ad_center_address_and_set_all_fields : Test(10) {
    my $ad_center_address = Microsoft::AdCenter::V6::CustomerManagementService::AdCenterAddress->new
        ->AddressId('address id')
        ->AddressLine1('address line1')
        ->AddressLine2('address line2')
        ->AddressLine3('address line3')
        ->AddressLine4('address line4')
        ->City('city')
        ->Country('country')
        ->StateOrProvince('state or province')
        ->ZipOrPostalCode('zip or postal code')
    ;

    ok($ad_center_address);

    is($ad_center_address->AddressId, 'address id', 'can get address id');
    is($ad_center_address->AddressLine1, 'address line1', 'can get address line1');
    is($ad_center_address->AddressLine2, 'address line2', 'can get address line2');
    is($ad_center_address->AddressLine3, 'address line3', 'can get address line3');
    is($ad_center_address->AddressLine4, 'address line4', 'can get address line4');
    is($ad_center_address->City, 'city', 'can get city');
    is($ad_center_address->Country, 'country', 'can get country');
    is($ad_center_address->StateOrProvince, 'state or province', 'can get state or province');
    is($ad_center_address->ZipOrPostalCode, 'zip or postal code', 'can get zip or postal code');
};

1;
