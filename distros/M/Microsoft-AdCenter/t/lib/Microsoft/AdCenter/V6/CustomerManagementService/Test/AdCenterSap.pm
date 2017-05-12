package Microsoft::AdCenter::V6::CustomerManagementService::Test::AdCenterSap;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V6::CustomerManagementService;
use Microsoft::AdCenter::V6::CustomerManagementService::AdCenterSap;

sub test_can_create_ad_center_sap_and_set_all_fields : Test(2) {
    my $ad_center_sap = Microsoft::AdCenter::V6::CustomerManagementService::AdCenterSap->new
        ->SapId('sap id')
    ;

    ok($ad_center_sap);

    is($ad_center_sap->SapId, 'sap id', 'can get sap id');
};

1;
