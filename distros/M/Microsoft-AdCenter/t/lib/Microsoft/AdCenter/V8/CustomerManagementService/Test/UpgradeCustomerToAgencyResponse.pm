package Microsoft::AdCenter::V8::CustomerManagementService::Test::UpgradeCustomerToAgencyResponse;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::CustomerManagementService;
use Microsoft::AdCenter::V8::CustomerManagementService::UpgradeCustomerToAgencyResponse;

sub test_can_create_upgrade_customer_to_agency_response_and_set_all_fields : Test(1) {
    my $upgrade_customer_to_agency_response = Microsoft::AdCenter::V8::CustomerManagementService::UpgradeCustomerToAgencyResponse->new
    ;

    ok($upgrade_customer_to_agency_response);

};

1;
