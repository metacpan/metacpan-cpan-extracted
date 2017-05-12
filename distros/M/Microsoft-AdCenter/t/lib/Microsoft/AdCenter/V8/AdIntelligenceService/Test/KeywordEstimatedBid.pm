package Microsoft::AdCenter::V8::AdIntelligenceService::Test::KeywordEstimatedBid;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::AdIntelligenceService;
use Microsoft::AdCenter::V8::AdIntelligenceService::KeywordEstimatedBid;

sub test_can_create_keyword_estimated_bid_and_set_all_fields : Test(3) {
    my $keyword_estimated_bid = Microsoft::AdCenter::V8::AdIntelligenceService::KeywordEstimatedBid->new
        ->EstimatedBids('estimated bids')
        ->Keyword('keyword')
    ;

    ok($keyword_estimated_bid);

    is($keyword_estimated_bid->EstimatedBids, 'estimated bids', 'can get estimated bids');
    is($keyword_estimated_bid->Keyword, 'keyword', 'can get keyword');
};

1;
