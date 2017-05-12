package Microsoft::AdCenter::V8::NotificationService::Test::CampaignInfo;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::NotificationService;
use Microsoft::AdCenter::V8::NotificationService::CampaignInfo;

sub test_can_create_campaign_info_and_set_all_fields : Test(4) {
    my $campaign_info = Microsoft::AdCenter::V8::NotificationService::CampaignInfo->new
        ->BudgetAmount('budget amount')
        ->CampaignId('campaign id')
        ->CampaignName('campaign name')
    ;

    ok($campaign_info);

    is($campaign_info->BudgetAmount, 'budget amount', 'can get budget amount');
    is($campaign_info->CampaignId, 'campaign id', 'can get campaign id');
    is($campaign_info->CampaignName, 'campaign name', 'can get campaign name');
};

1;
