package Microsoft::AdCenter::V8::AdIntelligenceService::Test::GetEstimatedBidByKeywordsResponse;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::AdIntelligenceService;
use Microsoft::AdCenter::V8::AdIntelligenceService::GetEstimatedBidByKeywordsResponse;

sub test_can_create_get_estimated_bid_by_keywords_response_and_set_all_fields : Test(2) {
    my $get_estimated_bid_by_keywords_response = Microsoft::AdCenter::V8::AdIntelligenceService::GetEstimatedBidByKeywordsResponse->new
        ->KeywordEstimatedBids('keyword estimated bids')
    ;

    ok($get_estimated_bid_by_keywords_response);

    is($get_estimated_bid_by_keywords_response->KeywordEstimatedBids, 'keyword estimated bids', 'can get keyword estimated bids');
};

1;
