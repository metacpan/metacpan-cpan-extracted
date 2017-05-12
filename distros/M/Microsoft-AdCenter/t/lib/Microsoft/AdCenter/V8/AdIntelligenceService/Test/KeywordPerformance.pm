package Microsoft::AdCenter::V8::AdIntelligenceService::Test::KeywordPerformance;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::AdIntelligenceService;
use Microsoft::AdCenter::V8::AdIntelligenceService::KeywordPerformance;

sub test_can_create_keyword_performance_and_set_all_fields : Test(5) {
    my $keyword_performance = Microsoft::AdCenter::V8::AdIntelligenceService::KeywordPerformance->new
        ->AverageCpc('average cpc')
        ->BidDensity('bid density')
        ->Impressions('impressions')
        ->Keyword('keyword')
    ;

    ok($keyword_performance);

    is($keyword_performance->AverageCpc, 'average cpc', 'can get average cpc');
    is($keyword_performance->BidDensity, 'bid density', 'can get bid density');
    is($keyword_performance->Impressions, 'impressions', 'can get impressions');
    is($keyword_performance->Keyword, 'keyword', 'can get keyword');
};

1;
