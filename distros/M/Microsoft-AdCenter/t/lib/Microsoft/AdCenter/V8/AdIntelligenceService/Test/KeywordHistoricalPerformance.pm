package Microsoft::AdCenter::V8::AdIntelligenceService::Test::KeywordHistoricalPerformance;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::AdIntelligenceService;
use Microsoft::AdCenter::V8::AdIntelligenceService::KeywordHistoricalPerformance;

sub test_can_create_keyword_historical_performance_and_set_all_fields : Test(3) {
    my $keyword_historical_performance = Microsoft::AdCenter::V8::AdIntelligenceService::KeywordHistoricalPerformance->new
        ->Keyword('keyword')
        ->KeywordKPIs('keyword kpis')
    ;

    ok($keyword_historical_performance);

    is($keyword_historical_performance->Keyword, 'keyword', 'can get keyword');
    is($keyword_historical_performance->KeywordKPIs, 'keyword kpis', 'can get keyword kpis');
};

1;
