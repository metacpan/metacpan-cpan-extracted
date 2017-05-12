package Microsoft::AdCenter::V8::CampaignManagementService::Test::SitePlacement;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::CampaignManagementService;
use Microsoft::AdCenter::V8::CampaignManagementService::SitePlacement;

sub test_can_create_site_placement_and_set_all_fields : Test(6) {
    my $site_placement = Microsoft::AdCenter::V8::CampaignManagementService::SitePlacement->new
        ->Bid('bid')
        ->Id('id')
        ->PlacementId('placement id')
        ->Status('status')
        ->Url('url')
    ;

    ok($site_placement);

    is($site_placement->Bid, 'bid', 'can get bid');
    is($site_placement->Id, 'id', 'can get id');
    is($site_placement->PlacementId, 'placement id', 'can get placement id');
    is($site_placement->Status, 'status', 'can get status');
    is($site_placement->Url, 'url', 'can get url');
};

1;
