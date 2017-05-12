package Microsoft::AdCenter::V6::CampaignManagementService::Test::AdGroupInfo;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V6::CampaignManagementService;
use Microsoft::AdCenter::V6::CampaignManagementService::AdGroupInfo;

sub test_can_create_ad_group_info_and_set_all_fields : Test(15) {
    my $ad_group_info = Microsoft::AdCenter::V6::CampaignManagementService::AdGroupInfo->new
        ->AdDistribution('ad distribution')
        ->BiddingModel('bidding model')
        ->BroadMatchBid('broad match bid')
        ->CashBackInfo('cash back info')
        ->ContentMatchBid('content match bid')
        ->EndDate('end date')
        ->ExactMatchBid('exact match bid')
        ->Id('id')
        ->LanguageAndRegion('language and region')
        ->Name('name')
        ->PhraseMatchBid('phrase match bid')
        ->PricingModel('pricing model')
        ->StartDate('start date')
        ->Status('status')
    ;

    ok($ad_group_info);

    is($ad_group_info->AdDistribution, 'ad distribution', 'can get ad distribution');
    is($ad_group_info->BiddingModel, 'bidding model', 'can get bidding model');
    is($ad_group_info->BroadMatchBid, 'broad match bid', 'can get broad match bid');
    is($ad_group_info->CashBackInfo, 'cash back info', 'can get cash back info');
    is($ad_group_info->ContentMatchBid, 'content match bid', 'can get content match bid');
    is($ad_group_info->EndDate, 'end date', 'can get end date');
    is($ad_group_info->ExactMatchBid, 'exact match bid', 'can get exact match bid');
    is($ad_group_info->Id, 'id', 'can get id');
    is($ad_group_info->LanguageAndRegion, 'language and region', 'can get language and region');
    is($ad_group_info->Name, 'name', 'can get name');
    is($ad_group_info->PhraseMatchBid, 'phrase match bid', 'can get phrase match bid');
    is($ad_group_info->PricingModel, 'pricing model', 'can get pricing model');
    is($ad_group_info->StartDate, 'start date', 'can get start date');
    is($ad_group_info->Status, 'status', 'can get status');
};

1;
