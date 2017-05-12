package Microsoft::AdCenter::V8::AdIntelligenceService::Test::GetKeywordDemographicsResponse;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::AdIntelligenceService;
use Microsoft::AdCenter::V8::AdIntelligenceService::GetKeywordDemographicsResponse;

sub test_can_create_get_keyword_demographics_response_and_set_all_fields : Test(2) {
    my $get_keyword_demographics_response = Microsoft::AdCenter::V8::AdIntelligenceService::GetKeywordDemographicsResponse->new
        ->KeywordDemographicResult('keyword demographic result')
    ;

    ok($get_keyword_demographics_response);

    is($get_keyword_demographics_response->KeywordDemographicResult, 'keyword demographic result', 'can get keyword demographic result');
};

1;
