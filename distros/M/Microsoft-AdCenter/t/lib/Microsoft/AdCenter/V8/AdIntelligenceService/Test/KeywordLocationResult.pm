package Microsoft::AdCenter::V8::AdIntelligenceService::Test::KeywordLocationResult;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::AdIntelligenceService;
use Microsoft::AdCenter::V8::AdIntelligenceService::KeywordLocationResult;

sub test_can_create_keyword_location_result_and_set_all_fields : Test(4) {
    my $keyword_location_result = Microsoft::AdCenter::V8::AdIntelligenceService::KeywordLocationResult->new
        ->Device('device')
        ->Keyword('keyword')
        ->KeywordLocations('keyword locations')
    ;

    ok($keyword_location_result);

    is($keyword_location_result->Device, 'device', 'can get device');
    is($keyword_location_result->Keyword, 'keyword', 'can get keyword');
    is($keyword_location_result->KeywordLocations, 'keyword locations', 'can get keyword locations');
};

1;
