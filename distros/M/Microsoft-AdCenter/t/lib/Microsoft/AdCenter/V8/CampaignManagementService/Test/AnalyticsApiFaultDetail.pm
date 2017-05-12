package Microsoft::AdCenter::V8::CampaignManagementService::Test::AnalyticsApiFaultDetail;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::CampaignManagementService;
use Microsoft::AdCenter::V8::CampaignManagementService::AnalyticsApiFaultDetail;

sub test_can_create_analytics_api_fault_detail_and_set_all_fields : Test(3) {
    my $analytics_api_fault_detail = Microsoft::AdCenter::V8::CampaignManagementService::AnalyticsApiFaultDetail->new
        ->GoalErrors('goal errors')
        ->OperationErrors('operation errors')
    ;

    ok($analytics_api_fault_detail);

    is($analytics_api_fault_detail->GoalErrors, 'goal errors', 'can get goal errors');
    is($analytics_api_fault_detail->OperationErrors, 'operation errors', 'can get operation errors');
};

1;
