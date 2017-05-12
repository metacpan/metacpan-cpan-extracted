package Microsoft::AdCenter::V7::CampaignManagementService::Test::KeywordBid;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V7::CampaignManagementService;
use Microsoft::AdCenter::V7::CampaignManagementService::KeywordBid;

sub test_can_create_keyword_bid_and_set_all_fields : Test(5) {
    my $keyword_bid = Microsoft::AdCenter::V7::CampaignManagementService::KeywordBid->new
        ->BroadMatchBid('broad match bid')
        ->ExactMatchBid('exact match bid')
        ->Keyword('keyword')
        ->PhraseMatchBid('phrase match bid')
    ;

    ok($keyword_bid);

    is($keyword_bid->BroadMatchBid, 'broad match bid', 'can get broad match bid');
    is($keyword_bid->ExactMatchBid, 'exact match bid', 'can get exact match bid');
    is($keyword_bid->Keyword, 'keyword', 'can get keyword');
    is($keyword_bid->PhraseMatchBid, 'phrase match bid', 'can get phrase match bid');
};

1;
