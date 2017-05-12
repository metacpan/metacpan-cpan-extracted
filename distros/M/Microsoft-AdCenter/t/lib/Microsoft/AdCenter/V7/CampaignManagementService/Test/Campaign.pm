package Microsoft::AdCenter::V7::CampaignManagementService::Test::Campaign;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V7::CampaignManagementService;
use Microsoft::AdCenter::V7::CampaignManagementService::Campaign;

sub test_can_create_campaign_and_set_all_fields : Test(15) {
    my $campaign = Microsoft::AdCenter::V7::CampaignManagementService::Campaign->new
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
        ->NegativeKeywords('negative keywords')
        ->NegativeSiteUrls('negative site urls')
        ->Status('status')
        ->TimeZone('time zone')
    ;

    ok($campaign);

    is($campaign->BudgetType, 'budget type', 'can get budget type');
    is($campaign->CashBackInfo, 'cash back info', 'can get cash back info');
    is($campaign->ConversionTrackingEnabled, 'conversion tracking enabled', 'can get conversion tracking enabled');
    is($campaign->ConversionTrackingScript, 'conversion tracking script', 'can get conversion tracking script');
    is($campaign->DailyBudget, 'daily budget', 'can get daily budget');
    is($campaign->DaylightSaving, 'daylight saving', 'can get daylight saving');
    is($campaign->Description, 'description', 'can get description');
    is($campaign->Id, 'id', 'can get id');
    is($campaign->MonthlyBudget, 'monthly budget', 'can get monthly budget');
    is($campaign->Name, 'name', 'can get name');
    is($campaign->NegativeKeywords, 'negative keywords', 'can get negative keywords');
    is($campaign->NegativeSiteUrls, 'negative site urls', 'can get negative site urls');
    is($campaign->Status, 'status', 'can get status');
    is($campaign->TimeZone, 'time zone', 'can get time zone');
};

1;
