package Microsoft::AdCenter::V7::CampaignManagementService::Test::SetAnalyticsTypeResponse;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V7::CampaignManagementService;
use Microsoft::AdCenter::V7::CampaignManagementService::SetAnalyticsTypeResponse;

sub test_can_create_set_analytics_type_response_and_set_all_fields : Test(1) {
    my $set_analytics_type_response = Microsoft::AdCenter::V7::CampaignManagementService::SetAnalyticsTypeResponse->new
    ;

    ok($set_analytics_type_response);

};

1;
