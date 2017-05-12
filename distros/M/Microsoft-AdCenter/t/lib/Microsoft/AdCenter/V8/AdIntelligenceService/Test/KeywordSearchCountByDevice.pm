package Microsoft::AdCenter::V8::AdIntelligenceService::Test::KeywordSearchCountByDevice;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::AdIntelligenceService;
use Microsoft::AdCenter::V8::AdIntelligenceService::KeywordSearchCountByDevice;

sub test_can_create_keyword_search_count_by_device_and_set_all_fields : Test(4) {
    my $keyword_search_count_by_device = Microsoft::AdCenter::V8::AdIntelligenceService::KeywordSearchCountByDevice->new
        ->Device('device')
        ->HistoricalSearchCounts('historical search counts')
        ->Keyword('keyword')
    ;

    ok($keyword_search_count_by_device);

    is($keyword_search_count_by_device->Device, 'device', 'can get device');
    is($keyword_search_count_by_device->HistoricalSearchCounts, 'historical search counts', 'can get historical search counts');
    is($keyword_search_count_by_device->Keyword, 'keyword', 'can get keyword');
};

1;
