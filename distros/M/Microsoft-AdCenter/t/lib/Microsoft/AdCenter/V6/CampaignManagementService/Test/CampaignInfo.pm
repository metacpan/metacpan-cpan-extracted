package Microsoft::AdCenter::V6::CampaignManagementService::Test::CampaignInfo;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V6::CampaignManagementService;
use Microsoft::AdCenter::V6::CampaignManagementService::CampaignInfo;

sub test_can_create_campaign_info_and_set_all_fields : Test(13) {
    my $campaign_info = Microsoft::AdCenter::V6::CampaignManagementService::CampaignInfo->new
        ->BudgetType('budget type')
        ->CashBackInfo('cash back info')
        ->ConversionTrackingEnabled('conversion tracking enabled')
        ->ConversionTrackingScript('conversion tracking script')
        ->DailyBudget('daily budget')
        ->DaylightSaving('daylight saving')
        ->Description('description')
        ->Id('id')
        ->MonthlyBudget('monthly budget')
        ->Name('name')
        ->Status('status')
        ->TimeZone('time zone')
    ;

    ok($campaign_info);

    is($campaign_info->BudgetType, 'budget type', 'can get budget type');
    is($campaign_info->CashBackInfo, 'cash back info', 'can get cash back info');
    is($campaign_info->ConversionTrackingEnabled, 'conversion tracking enabled', 'can get conversion tracking enabled');
    is($campaign_info->ConversionTrackingScript, 'conversion tracking script', 'can get conversion tracking script');
    is($campaign_info->DailyBudget, 'daily budget', 'can get daily budget');
    is($campaign_info->DaylightSaving, 'daylight saving', 'can get daylight saving');
    is($campaign_info->Description, 'description', 'can get description');
    is($campaign_info->Id, 'id', 'can get id');
    is($campaign_info->MonthlyBudget, 'monthly budget', 'can get monthly budget');
    is($campaign_info->Name, 'name', 'can get name');
    is($campaign_info->Status, 'status', 'can get status');
    is($campaign_info->TimeZone, 'time zone', 'can get time zone');
};

1;
