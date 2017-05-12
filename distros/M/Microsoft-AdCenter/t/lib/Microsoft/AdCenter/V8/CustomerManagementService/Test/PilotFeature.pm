package Microsoft::AdCenter::V8::CustomerManagementService::Test::PilotFeature;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::CustomerManagementService;
use Microsoft::AdCenter::V8::CustomerManagementService::PilotFeature;

sub test_can_create_pilot_feature_and_set_all_fields : Test(3) {
    my $pilot_feature = Microsoft::AdCenter::V8::CustomerManagementService::PilotFeature->new
        ->Countries('countries')
        ->Id('id')
    ;

    ok($pilot_feature);

    is($pilot_feature->Countries, 'countries', 'can get countries');
    is($pilot_feature->Id, 'id', 'can get id');
};

1;
