package Microsoft::AdCenter::V8::CampaignManagementService::Test::DayTarget;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::CampaignManagementService;
use Microsoft::AdCenter::V8::CampaignManagementService::DayTarget;

sub test_can_create_day_target_and_set_all_fields : Test(3) {
    my $day_target = Microsoft::AdCenter::V8::CampaignManagementService::DayTarget->new
        ->Bids('bids')
        ->TargetAllDays('target all days')
    ;

    ok($day_target);

    is($day_target->Bids, 'bids', 'can get bids');
    is($day_target->TargetAllDays, 'target all days', 'can get target all days');
};

1;
