package Microsoft::AdCenter::V8::AdIntelligenceService::Test::KeywordDemographicResult;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::AdIntelligenceService;
use Microsoft::AdCenter::V8::AdIntelligenceService::KeywordDemographicResult;

sub test_can_create_keyword_demographic_result_and_set_all_fields : Test(4) {
    my $keyword_demographic_result = Microsoft::AdCenter::V8::AdIntelligenceService::KeywordDemographicResult->new
        ->Device('device')
        ->Keyword('keyword')
        ->KeywordDemographics('keyword demographics')
    ;

    ok($keyword_demographic_result);

    is($keyword_demographic_result->Device, 'device', 'can get device');
    is($keyword_demographic_result->Keyword, 'keyword', 'can get keyword');
    is($keyword_demographic_result->KeywordDemographics, 'keyword demographics', 'can get keyword demographics');
};

1;
