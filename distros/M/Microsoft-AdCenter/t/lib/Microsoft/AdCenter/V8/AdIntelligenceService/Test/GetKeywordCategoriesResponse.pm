package Microsoft::AdCenter::V8::AdIntelligenceService::Test::GetKeywordCategoriesResponse;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::AdIntelligenceService;
use Microsoft::AdCenter::V8::AdIntelligenceService::GetKeywordCategoriesResponse;

sub test_can_create_get_keyword_categories_response_and_set_all_fields : Test(2) {
    my $get_keyword_categories_response = Microsoft::AdCenter::V8::AdIntelligenceService::GetKeywordCategoriesResponse->new
        ->Result('result')
    ;

    ok($get_keyword_categories_response);

    is($get_keyword_categories_response->Result, 'result', 'can get result');
};

1;
