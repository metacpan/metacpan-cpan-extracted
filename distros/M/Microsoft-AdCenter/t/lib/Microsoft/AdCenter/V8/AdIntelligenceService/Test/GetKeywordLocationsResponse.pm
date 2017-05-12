package Microsoft::AdCenter::V8::AdIntelligenceService::Test::GetKeywordLocationsResponse;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::AdIntelligenceService;
use Microsoft::AdCenter::V8::AdIntelligenceService::GetKeywordLocationsResponse;

sub test_can_create_get_keyword_locations_response_and_set_all_fields : Test(2) {
    my $get_keyword_locations_response = Microsoft::AdCenter::V8::AdIntelligenceService::GetKeywordLocationsResponse->new
        ->KeywordLocationResult('keyword location result')
    ;

    ok($get_keyword_locations_response);

    is($get_keyword_locations_response->KeywordLocationResult, 'keyword location result', 'can get keyword location result');
};

1;
