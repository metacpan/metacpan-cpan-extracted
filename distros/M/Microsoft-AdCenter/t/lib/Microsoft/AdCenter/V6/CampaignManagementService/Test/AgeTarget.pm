package Microsoft::AdCenter::V6::CampaignManagementService::Test::AgeTarget;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V6::CampaignManagementService;
use Microsoft::AdCenter::V6::CampaignManagementService::AgeTarget;

sub test_can_create_age_target_and_set_all_fields : Test(2) {
    my $age_target = Microsoft::AdCenter::V6::CampaignManagementService::AgeTarget->new
        ->Bids('bids')
    ;

    ok($age_target);

    is($age_target->Bids, 'bids', 'can get bids');
};

1;
