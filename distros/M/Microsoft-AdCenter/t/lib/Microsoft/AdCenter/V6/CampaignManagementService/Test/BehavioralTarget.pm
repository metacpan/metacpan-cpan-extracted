package Microsoft::AdCenter::V6::CampaignManagementService::Test::BehavioralTarget;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V6::CampaignManagementService;
use Microsoft::AdCenter::V6::CampaignManagementService::BehavioralTarget;

sub test_can_create_behavioral_target_and_set_all_fields : Test(2) {
    my $behavioral_target = Microsoft::AdCenter::V6::CampaignManagementService::BehavioralTarget->new
        ->Bids('bids')
    ;

    ok($behavioral_target);

    is($behavioral_target->Bids, 'bids', 'can get bids');
};

1;
