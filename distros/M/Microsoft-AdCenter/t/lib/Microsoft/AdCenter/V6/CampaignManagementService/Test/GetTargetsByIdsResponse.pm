package Microsoft::AdCenter::V6::CampaignManagementService::Test::GetTargetsByIdsResponse;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V6::CampaignManagementService;
use Microsoft::AdCenter::V6::CampaignManagementService::GetTargetsByIdsResponse;

sub test_can_create_get_targets_by_ids_response_and_set_all_fields : Test(2) {
    my $get_targets_by_ids_response = Microsoft::AdCenter::V6::CampaignManagementService::GetTargetsByIdsResponse->new
        ->Targets('targets')
    ;

    ok($get_targets_by_ids_response);

    is($get_targets_by_ids_response->Targets, 'targets', 'can get targets');
};

1;
