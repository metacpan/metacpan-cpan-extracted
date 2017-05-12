package Microsoft::AdCenter::V8::AdIntelligenceService::Test::KeywordKPI;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::AdIntelligenceService;
use Microsoft::AdCenter::V8::AdIntelligenceService::KeywordKPI;

sub test_can_create_keyword_kpi_and_set_all_fields : Test(9) {
    my $keyword_kpi = Microsoft::AdCenter::V8::AdIntelligenceService::KeywordKPI->new
        ->AdPosition('ad position')
        ->AverageBid('average bid')
        ->AverageCPC('average cpc')
        ->CTR('ctr')
        ->Clicks('clicks')
        ->Impressions('impressions')
        ->MatchType('match type')
        ->TotalCost('total cost')
    ;

    ok($keyword_kpi);

    is($keyword_kpi->AdPosition, 'ad position', 'can get ad position');
    is($keyword_kpi->AverageBid, 'average bid', 'can get average bid');
    is($keyword_kpi->AverageCPC, 'average cpc', 'can get average cpc');
    is($keyword_kpi->CTR, 'ctr', 'can get ctr');
    is($keyword_kpi->Clicks, 'clicks', 'can get clicks');
    is($keyword_kpi->Impressions, 'impressions', 'can get impressions');
    is($keyword_kpi->MatchType, 'match type', 'can get match type');
    is($keyword_kpi->TotalCost, 'total cost', 'can get total cost');
};

1;
