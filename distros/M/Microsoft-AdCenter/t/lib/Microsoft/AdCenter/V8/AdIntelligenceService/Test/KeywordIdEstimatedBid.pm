package Microsoft::AdCenter::V8::AdIntelligenceService::Test::KeywordIdEstimatedBid;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::AdIntelligenceService;
use Microsoft::AdCenter::V8::AdIntelligenceService::KeywordIdEstimatedBid;

sub test_can_create_keyword_id_estimated_bid_and_set_all_fields : Test(3) {
    my $keyword_id_estimated_bid = Microsoft::AdCenter::V8::AdIntelligenceService::KeywordIdEstimatedBid->new
        ->KeywordEstimatedBid('keyword estimated bid')
        ->KeywordId('keyword id')
    ;

    ok($keyword_id_estimated_bid);

    is($keyword_id_estimated_bid->KeywordEstimatedBid, 'keyword estimated bid', 'can get keyword estimated bid');
    is($keyword_id_estimated_bid->KeywordId, 'keyword id', 'can get keyword id');
};

1;
