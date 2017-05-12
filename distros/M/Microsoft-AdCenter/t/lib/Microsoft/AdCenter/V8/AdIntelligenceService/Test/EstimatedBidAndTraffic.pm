package Microsoft::AdCenter::V8::AdIntelligenceService::Test::EstimatedBidAndTraffic;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::AdIntelligenceService;
use Microsoft::AdCenter::V8::AdIntelligenceService::EstimatedBidAndTraffic;

sub test_can_create_estimated_bid_and_traffic_and_set_all_fields : Test(12) {
    my $estimated_bid_and_traffic = Microsoft::AdCenter::V8::AdIntelligenceService::EstimatedBidAndTraffic->new
        ->AverageCPC('average cpc')
        ->CTR('ctr')
        ->Currency('currency')
        ->EstimatedMinBid('estimated min bid')
        ->MatchType('match type')
        ->MaxClicksPerWeek('max clicks per week')
        ->MaxImpressionsPerWeek('max impressions per week')
        ->MaxTotalCostPerWeek('max total cost per week')
        ->MinClicksPerWeek('min clicks per week')
        ->MinImpressionsPerWeek('min impressions per week')
        ->MinTotalCostPerWeek('min total cost per week')
    ;

    ok($estimated_bid_and_traffic);

    is($estimated_bid_and_traffic->AverageCPC, 'average cpc', 'can get average cpc');
    is($estimated_bid_and_traffic->CTR, 'ctr', 'can get ctr');
    is($estimated_bid_and_traffic->Currency, 'currency', 'can get currency');
    is($estimated_bid_and_traffic->EstimatedMinBid, 'estimated min bid', 'can get estimated min bid');
    is($estimated_bid_and_traffic->MatchType, 'match type', 'can get match type');
    is($estimated_bid_and_traffic->MaxClicksPerWeek, 'max clicks per week', 'can get max clicks per week');
    is($estimated_bid_and_traffic->MaxImpressionsPerWeek, 'max impressions per week', 'can get max impressions per week');
    is($estimated_bid_and_traffic->MaxTotalCostPerWeek, 'max total cost per week', 'can get max total cost per week');
    is($estimated_bid_and_traffic->MinClicksPerWeek, 'min clicks per week', 'can get min clicks per week');
    is($estimated_bid_and_traffic->MinImpressionsPerWeek, 'min impressions per week', 'can get min impressions per week');
    is($estimated_bid_and_traffic->MinTotalCostPerWeek, 'min total cost per week', 'can get min total cost per week');
};

1;
