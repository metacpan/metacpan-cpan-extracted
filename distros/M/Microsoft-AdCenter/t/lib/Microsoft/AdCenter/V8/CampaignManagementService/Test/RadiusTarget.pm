package Microsoft::AdCenter::V8::CampaignManagementService::Test::RadiusTarget;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::CampaignManagementService;
use Microsoft::AdCenter::V8::CampaignManagementService::RadiusTarget;

sub test_can_create_radius_target_and_set_all_fields : Test(2) {
    my $radius_target = Microsoft::AdCenter::V8::CampaignManagementService::RadiusTarget->new
        ->Bids('bids')
    ;

    ok($radius_target);

    is($radius_target->Bids, 'bids', 'can get bids');
};

1;
