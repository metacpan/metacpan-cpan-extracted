package Microsoft::AdCenter::V7::CampaignManagementService::Test::GenderTarget;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V7::CampaignManagementService;
use Microsoft::AdCenter::V7::CampaignManagementService::GenderTarget;

sub test_can_create_gender_target_and_set_all_fields : Test(2) {
    my $gender_target = Microsoft::AdCenter::V7::CampaignManagementService::GenderTarget->new
        ->Bids('bids')
    ;

    ok($gender_target);

    is($gender_target->Bids, 'bids', 'can get bids');
};

1;
