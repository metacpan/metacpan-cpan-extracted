package Microsoft::AdCenter::V8::AdIntelligenceService::Test::HistoricalSearchCountPeriodic;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::AdIntelligenceService;
use Microsoft::AdCenter::V8::AdIntelligenceService::HistoricalSearchCountPeriodic;

sub test_can_create_historical_search_count_periodic_and_set_all_fields : Test(3) {
    my $historical_search_count_periodic = Microsoft::AdCenter::V8::AdIntelligenceService::HistoricalSearchCountPeriodic->new
        ->DayMonthAndYear('day month and year')
        ->SearchCount('search count')
    ;

    ok($historical_search_count_periodic);

    is($historical_search_count_periodic->DayMonthAndYear, 'day month and year', 'can get day month and year');
    is($historical_search_count_periodic->SearchCount, 'search count', 'can get search count');
};

1;
