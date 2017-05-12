package Microsoft::AdCenter::V7::CampaignManagementService::Test::GetAnalyticsTypeResponse;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V7::CampaignManagementService;
use Microsoft::AdCenter::V7::CampaignManagementService::GetAnalyticsTypeResponse;

sub test_can_create_get_analytics_type_response_and_set_all_fields : Test(2) {
    my $get_analytics_type_response = Microsoft::AdCenter::V7::CampaignManagementService::GetAnalyticsTypeResponse->new
        ->Types('types')
    ;

    ok($get_analytics_type_response);

    is($get_analytics_type_response->Types, 'types', 'can get types');
};

1;
