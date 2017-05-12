package Microsoft::AdCenter::V8::AdIntelligenceService::Test::KeywordSearchCount;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::AdIntelligenceService;
use Microsoft::AdCenter::V8::AdIntelligenceService::KeywordSearchCount;

sub test_can_create_keyword_search_count_and_set_all_fields : Test(3) {
    my $keyword_search_count = Microsoft::AdCenter::V8::AdIntelligenceService::KeywordSearchCount->new
        ->HistoricalSearchCounts('historical search counts')
        ->Keyword('keyword')
    ;

    ok($keyword_search_count);

    is($keyword_search_count->HistoricalSearchCounts, 'historical search counts', 'can get historical search counts');
    is($keyword_search_count->Keyword, 'keyword', 'can get keyword');
};

1;
