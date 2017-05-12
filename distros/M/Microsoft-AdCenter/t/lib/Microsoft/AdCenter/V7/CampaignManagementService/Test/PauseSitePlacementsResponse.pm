package Microsoft::AdCenter::V7::CampaignManagementService::Test::PauseSitePlacementsResponse;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V7::CampaignManagementService;
use Microsoft::AdCenter::V7::CampaignManagementService::PauseSitePlacementsResponse;

sub test_can_create_pause_site_placements_response_and_set_all_fields : Test(1) {
    my $pause_site_placements_response = Microsoft::AdCenter::V7::CampaignManagementService::PauseSitePlacementsResponse->new
    ;

    ok($pause_site_placements_response);

};

1;
