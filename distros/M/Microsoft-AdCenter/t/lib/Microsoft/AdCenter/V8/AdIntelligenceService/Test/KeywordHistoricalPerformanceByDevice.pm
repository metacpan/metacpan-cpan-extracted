package Microsoft::AdCenter::V8::AdIntelligenceService::Test::KeywordHistoricalPerformanceByDevice;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::AdIntelligenceService;
use Microsoft::AdCenter::V8::AdIntelligenceService::KeywordHistoricalPerformanceByDevice;

sub test_can_create_keyword_historical_performance_by_device_and_set_all_fields : Test(4) {
    my $keyword_historical_performance_by_device = Microsoft::AdCenter::V8::AdIntelligenceService::KeywordHistoricalPerformanceByDevice->new
        ->Device('device')
        ->Keyword('keyword')
        ->KeywordKPIs('keyword kpis')
    ;

    ok($keyword_historical_performance_by_device);

    is($keyword_historical_performance_by_device->Device, 'device', 'can get device');
    is($keyword_historical_performance_by_device->Keyword, 'keyword', 'can get keyword');
    is($keyword_historical_performance_by_device->KeywordKPIs, 'keyword kpis', 'can get keyword kpis');
};

1;
