package Microsoft::AdCenter::V7::CampaignManagementService::Test::GetBusinessesByIdsResponse;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V7::CampaignManagementService;
use Microsoft::AdCenter::V7::CampaignManagementService::GetBusinessesByIdsResponse;

sub test_can_create_get_businesses_by_ids_response_and_set_all_fields : Test(2) {
    my $get_businesses_by_ids_response = Microsoft::AdCenter::V7::CampaignManagementService::GetBusinessesByIdsResponse->new
        ->Businesses('businesses')
    ;

    ok($get_businesses_by_ids_response);

    is($get_businesses_by_ids_response->Businesses, 'businesses', 'can get businesses');
};

1;
