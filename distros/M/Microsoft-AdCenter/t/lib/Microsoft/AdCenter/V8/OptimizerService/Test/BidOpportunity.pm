package Microsoft::AdCenter::V8::OptimizerService::Test::BidOpportunity;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::OptimizerService;
use Microsoft::AdCenter::V8::OptimizerService::BidOpportunity;

sub test_can_create_bid_opportunity_and_set_all_fields : Test(9) {
    my $bid_opportunity = Microsoft::AdCenter::V8::OptimizerService::BidOpportunity->new
        ->AdGroupId('ad group id')
        ->CurrentBid('current bid')
        ->EstimatedIncreaseInClicks('estimated increase in clicks')
        ->EstimatedIncreaseInCost('estimated increase in cost')
        ->EstimatedIncreaseInImpressions('estimated increase in impressions')
        ->KeywordId('keyword id')
        ->MatchType('match type')
        ->SuggestedBid('suggested bid')
    ;

    ok($bid_opportunity);

    is($bid_opportunity->AdGroupId, 'ad group id', 'can get ad group id');
    is($bid_opportunity->CurrentBid, 'current bid', 'can get current bid');
    is($bid_opportunity->EstimatedIncreaseInClicks, 'estimated increase in clicks', 'can get estimated increase in clicks');
    is($bid_opportunity->EstimatedIncreaseInCost, 'estimated increase in cost', 'can get estimated increase in cost');
    is($bid_opportunity->EstimatedIncreaseInImpressions, 'estimated increase in impressions', 'can get estimated increase in impressions');
    is($bid_opportunity->KeywordId, 'keyword id', 'can get keyword id');
    is($bid_opportunity->MatchType, 'match type', 'can get match type');
    is($bid_opportunity->SuggestedBid, 'suggested bid', 'can get suggested bid');
};

1;
