package Microsoft::AdCenter::V8::CampaignManagementService::Test::ExcludedRadiusTarget;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::CampaignManagementService;
use Microsoft::AdCenter::V8::CampaignManagementService::ExcludedRadiusTarget;

sub test_can_create_excluded_radius_target_and_set_all_fields : Test(2) {
    my $excluded_radius_target = Microsoft::AdCenter::V8::CampaignManagementService::ExcludedRadiusTarget->new
        ->ExcludedRadiusLocations('excluded radius locations')
    ;

    ok($excluded_radius_target);

    is($excluded_radius_target->ExcludedRadiusLocations, 'excluded radius locations', 'can get excluded radius locations');
};

1;
