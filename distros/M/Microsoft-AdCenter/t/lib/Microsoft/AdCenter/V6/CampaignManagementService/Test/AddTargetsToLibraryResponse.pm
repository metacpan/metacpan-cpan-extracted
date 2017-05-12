package Microsoft::AdCenter::V6::CampaignManagementService::Test::AddTargetsToLibraryResponse;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V6::CampaignManagementService;
use Microsoft::AdCenter::V6::CampaignManagementService::AddTargetsToLibraryResponse;

sub test_can_create_add_targets_to_library_response_and_set_all_fields : Test(2) {
    my $add_targets_to_library_response = Microsoft::AdCenter::V6::CampaignManagementService::AddTargetsToLibraryResponse->new
        ->TargetIds('target ids')
    ;

    ok($add_targets_to_library_response);

    is($add_targets_to_library_response->TargetIds, 'target ids', 'can get target ids');
};

1;
