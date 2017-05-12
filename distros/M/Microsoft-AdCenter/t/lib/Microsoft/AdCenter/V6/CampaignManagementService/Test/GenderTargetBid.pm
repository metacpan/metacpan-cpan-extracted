package Microsoft::AdCenter::V6::CampaignManagementService::Test::GenderTargetBid;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V6::CampaignManagementService;
use Microsoft::AdCenter::V6::CampaignManagementService::GenderTargetBid;

sub test_can_create_gender_target_bid_and_set_all_fields : Test(3) {
    my $gender_target_bid = Microsoft::AdCenter::V6::CampaignManagementService::GenderTargetBid->new
        ->Gender('gender')
        ->IncrementalBid('incremental bid')
    ;

    ok($gender_target_bid);

    is($gender_target_bid->Gender, 'gender', 'can get gender');
    is($gender_target_bid->IncrementalBid, 'incremental bid', 'can get incremental bid');
};

1;
