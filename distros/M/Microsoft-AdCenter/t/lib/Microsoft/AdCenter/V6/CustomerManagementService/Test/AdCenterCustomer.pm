package Microsoft::AdCenter::V6::CustomerManagementService::Test::AdCenterCustomer;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V6::CustomerManagementService;
use Microsoft::AdCenter::V6::CustomerManagementService::AdCenterCustomer;

sub test_can_create_ad_center_customer_and_set_all_fields : Test(6) {
    my $ad_center_customer = Microsoft::AdCenter::V6::CustomerManagementService::AdCenterCustomer->new
        ->CustomerAddress('customer address')
        ->CustomerId('customer id')
        ->CustomerName('customer name')
        ->IndustryId('industry id')
        ->MarketId('market id')
    ;

    ok($ad_center_customer);

    is($ad_center_customer->CustomerAddress, 'customer address', 'can get customer address');
    is($ad_center_customer->CustomerId, 'customer id', 'can get customer id');
    is($ad_center_customer->CustomerName, 'customer name', 'can get customer name');
    is($ad_center_customer->IndustryId, 'industry id', 'can get industry id');
    is($ad_center_customer->MarketId, 'market id', 'can get market id');
};

1;
