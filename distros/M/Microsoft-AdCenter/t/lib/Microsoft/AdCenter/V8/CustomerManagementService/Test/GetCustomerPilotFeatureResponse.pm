package Microsoft::AdCenter::V8::CustomerManagementService::Test::GetCustomerPilotFeatureResponse;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::CustomerManagementService;
use Microsoft::AdCenter::V8::CustomerManagementService::GetCustomerPilotFeatureResponse;

sub test_can_create_get_customer_pilot_feature_response_and_set_all_fields : Test(2) {
    my $get_customer_pilot_feature_response = Microsoft::AdCenter::V8::CustomerManagementService::GetCustomerPilotFeatureResponse->new
        ->FeaturePilotFlags('feature pilot flags')
    ;

    ok($get_customer_pilot_feature_response);

    is($get_customer_pilot_feature_response->FeaturePilotFlags, 'feature pilot flags', 'can get feature pilot flags');
};

1;
