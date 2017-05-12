package Microsoft::AdCenter::V7::CampaignManagementService::Test::Business;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V7::CampaignManagementService;
use Microsoft::AdCenter::V7::CampaignManagementService::Business;

sub test_can_create_business_and_set_all_fields : Test(22) {
    my $business = Microsoft::AdCenter::V7::CampaignManagementService::Business->new
        ->AddressLine1('address line1')
        ->AddressLine2('address line2')
        ->BusinessImageIcon('business image icon')
        ->City('city')
        ->CountryOrRegion('country or region')
        ->Description('description')
        ->Email('email')
        ->GeoCodeStatus('geo code status')
        ->HrsOfOperation('hrs of operation')
        ->Id('id')
        ->IsOpen24Hours('is open24 hours')
        ->LatitudeDegrees('latitude degrees')
        ->LongitudeDegrees('longitude degrees')
        ->Name('name')
        ->OtherPaymentTypeDesc('other payment type desc')
        ->Payment('payment')
        ->Phone('phone')
        ->StateOrProvince('state or province')
        ->Status('status')
        ->URL('url')
        ->ZipOrPostalCode('zip or postal code')
    ;

    ok($business);

    is($business->AddressLine1, 'address line1', 'can get address line1');
    is($business->AddressLine2, 'address line2', 'can get address line2');
    is($business->BusinessImageIcon, 'business image icon', 'can get business image icon');
    is($business->City, 'city', 'can get city');
    is($business->CountryOrRegion, 'country or region', 'can get country or region');
    is($business->Description, 'description', 'can get description');
    is($business->Email, 'email', 'can get email');
    is($business->GeoCodeStatus, 'geo code status', 'can get geo code status');
    is($business->HrsOfOperation, 'hrs of operation', 'can get hrs of operation');
    is($business->Id, 'id', 'can get id');
    is($business->IsOpen24Hours, 'is open24 hours', 'can get is open24 hours');
    is($business->LatitudeDegrees, 'latitude degrees', 'can get latitude degrees');
    is($business->LongitudeDegrees, 'longitude degrees', 'can get longitude degrees');
    is($business->Name, 'name', 'can get name');
    is($business->OtherPaymentTypeDesc, 'other payment type desc', 'can get other payment type desc');
    is($business->Payment, 'payment', 'can get payment');
    is($business->Phone, 'phone', 'can get phone');
    is($business->StateOrProvince, 'state or province', 'can get state or province');
    is($business->Status, 'status', 'can get status');
    is($business->URL, 'url', 'can get url');
    is($business->ZipOrPostalCode, 'zip or postal code', 'can get zip or postal code');
};

1;
