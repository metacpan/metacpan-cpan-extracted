package Microsoft::AdCenter::V7::CampaignManagementService::Test::AdGroup;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V7::CampaignManagementService;
use Microsoft::AdCenter::V7::CampaignManagementService::AdGroup;

sub test_can_create_ad_group_and_set_all_fields : Test(17) {
    my $ad_group = Microsoft::AdCenter::V7::CampaignManagementService::AdGroup->new
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
        ->NegativeKeywords('negative keywords')
        ->NegativeSiteUrls('negative site urls')
        ->PhraseMatchBid('phrase match bid')
        ->PricingModel('pricing model')
        ->StartDate('start date')
        ->Status('status')
    ;

    ok($ad_group);

    is($ad_group->AdDistribution, 'ad distribution', 'can get ad distribution');
    is($ad_group->BiddingModel, 'bidding model', 'can get bidding model');
    is($ad_group->BroadMatchBid, 'broad match bid', 'can get broad match bid');
    is($ad_group->CashBackInfo, 'cash back info', 'can get cash back info');
    is($ad_group->ContentMatchBid, 'content match bid', 'can get content match bid');
    is($ad_group->EndDate, 'end date', 'can get end date');
    is($ad_group->ExactMatchBid, 'exact match bid', 'can get exact match bid');
    is($ad_group->Id, 'id', 'can get id');
    is($ad_group->LanguageAndRegion, 'language and region', 'can get language and region');
    is($ad_group->Name, 'name', 'can get name');
    is($ad_group->NegativeKeywords, 'negative keywords', 'can get negative keywords');
    is($ad_group->NegativeSiteUrls, 'negative site urls', 'can get negative site urls');
    is($ad_group->PhraseMatchBid, 'phrase match bid', 'can get phrase match bid');
    is($ad_group->PricingModel, 'pricing model', 'can get pricing model');
    is($ad_group->StartDate, 'start date', 'can get start date');
    is($ad_group->Status, 'status', 'can get status');
};

1;
