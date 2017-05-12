package Microsoft::AdCenter::V6::CampaignManagementService::Test::CityTarget;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V6::CampaignManagementService;
use Microsoft::AdCenter::V6::CampaignManagementService::CityTarget;

sub test_can_create_city_target_and_set_all_fields : Test(2) {
    my $city_target = Microsoft::AdCenter::V6::CampaignManagementService::CityTarget->new
        ->Bids('bids')
    ;

    ok($city_target);

    is($city_target->Bids, 'bids', 'can get bids');
};

1;
