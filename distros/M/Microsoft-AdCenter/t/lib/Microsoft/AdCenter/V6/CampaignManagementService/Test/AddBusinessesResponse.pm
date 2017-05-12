package Microsoft::AdCenter::V6::CampaignManagementService::Test::AddBusinessesResponse;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V6::CampaignManagementService;
use Microsoft::AdCenter::V6::CampaignManagementService::AddBusinessesResponse;

sub test_can_create_add_businesses_response_and_set_all_fields : Test(2) {
    my $add_businesses_response = Microsoft::AdCenter::V6::CampaignManagementService::AddBusinessesResponse->new
        ->BusinessIds('business ids')
    ;

    ok($add_businesses_response);

    is($add_businesses_response->BusinessIds, 'business ids', 'can get business ids');
};

1;
