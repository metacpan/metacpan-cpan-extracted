package Microsoft::AdCenter::V7::CustomerManagementService::Test::AdvertiserAccount;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V7::CustomerManagementService;
use Microsoft::AdCenter::V7::CustomerManagementService::AdvertiserAccount;

sub test_can_create_advertiser_account_and_set_all_fields : Test(4) {
    my $advertiser_account = Microsoft::AdCenter::V7::CustomerManagementService::AdvertiserAccount->new
        ->AgencyContactName('agency contact name')
        ->AgencyCustomerId('agency customer id')
        ->SalesHouseCustomerId('sales house customer id')
    ;

    ok($advertiser_account);

    is($advertiser_account->AgencyContactName, 'agency contact name', 'can get agency contact name');
    is($advertiser_account->AgencyCustomerId, 'agency customer id', 'can get agency customer id');
    is($advertiser_account->SalesHouseCustomerId, 'sales house customer id', 'can get sales house customer id');
};

1;
