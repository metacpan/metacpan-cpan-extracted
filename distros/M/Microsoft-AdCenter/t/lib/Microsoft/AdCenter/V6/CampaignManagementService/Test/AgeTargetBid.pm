package Microsoft::AdCenter::V6::CampaignManagementService::Test::AgeTargetBid;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V6::CampaignManagementService;
use Microsoft::AdCenter::V6::CampaignManagementService::AgeTargetBid;

sub test_can_create_age_target_bid_and_set_all_fields : Test(3) {
    my $age_target_bid = Microsoft::AdCenter::V6::CampaignManagementService::AgeTargetBid->new
        ->Age('age')
        ->IncrementalBid('incremental bid')
    ;

    ok($age_target_bid);

    is($age_target_bid->Age, 'age', 'can get age');
    is($age_target_bid->IncrementalBid, 'incremental bid', 'can get incremental bid');
};

1;
