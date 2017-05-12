package Microsoft::AdCenter::V6::CampaignManagementService::Test::HourTarget;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V6::CampaignManagementService;
use Microsoft::AdCenter::V6::CampaignManagementService::HourTarget;

sub test_can_create_hour_target_and_set_all_fields : Test(3) {
    my $hour_target = Microsoft::AdCenter::V6::CampaignManagementService::HourTarget->new
        ->Bids('bids')
        ->TargetAllHours('target all hours')
    ;

    ok($hour_target);

    is($hour_target->Bids, 'bids', 'can get bids');
    is($hour_target->TargetAllHours, 'target all hours', 'can get target all hours');
};

1;
