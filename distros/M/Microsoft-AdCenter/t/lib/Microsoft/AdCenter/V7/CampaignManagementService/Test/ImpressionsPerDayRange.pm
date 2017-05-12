package Microsoft::AdCenter::V7::CampaignManagementService::Test::ImpressionsPerDayRange;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V7::CampaignManagementService;
use Microsoft::AdCenter::V7::CampaignManagementService::ImpressionsPerDayRange;

sub test_can_create_impressions_per_day_range_and_set_all_fields : Test(3) {
    my $impressions_per_day_range = Microsoft::AdCenter::V7::CampaignManagementService::ImpressionsPerDayRange->new
        ->Maximum('maximum')
        ->Minimum('minimum')
    ;

    ok($impressions_per_day_range);

    is($impressions_per_day_range->Maximum, 'maximum', 'can get maximum');
    is($impressions_per_day_range->Minimum, 'minimum', 'can get minimum');
};

1;
