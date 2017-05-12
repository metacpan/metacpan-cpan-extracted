package Microsoft::AdCenter::V6::CampaignManagementService::Test::MetroAreaTarget;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V6::CampaignManagementService;
use Microsoft::AdCenter::V6::CampaignManagementService::MetroAreaTarget;

sub test_can_create_metro_area_target_and_set_all_fields : Test(2) {
    my $metro_area_target = Microsoft::AdCenter::V6::CampaignManagementService::MetroAreaTarget->new
        ->Bids('bids')
    ;

    ok($metro_area_target);

    is($metro_area_target->Bids, 'bids', 'can get bids');
};

1;
