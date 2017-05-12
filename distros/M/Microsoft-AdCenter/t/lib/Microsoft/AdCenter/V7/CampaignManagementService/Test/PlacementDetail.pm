package Microsoft::AdCenter::V7::CampaignManagementService::Test::PlacementDetail;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V7::CampaignManagementService;
use Microsoft::AdCenter::V7::CampaignManagementService::PlacementDetail;

sub test_can_create_placement_detail_and_set_all_fields : Test(5) {
    my $placement_detail = Microsoft::AdCenter::V7::CampaignManagementService::PlacementDetail->new
        ->ImpressionsRangePerDay('impressions range per day')
        ->PathName('path name')
        ->PlacementId('placement id')
        ->SupportedMediaTypes('supported media types')
    ;

    ok($placement_detail);

    is($placement_detail->ImpressionsRangePerDay, 'impressions range per day', 'can get impressions range per day');
    is($placement_detail->PathName, 'path name', 'can get path name');
    is($placement_detail->PlacementId, 'placement id', 'can get placement id');
    is($placement_detail->SupportedMediaTypes, 'supported media types', 'can get supported media types');
};

1;
