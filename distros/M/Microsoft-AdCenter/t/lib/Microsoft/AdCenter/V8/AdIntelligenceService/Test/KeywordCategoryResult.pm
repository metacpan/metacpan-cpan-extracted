package Microsoft::AdCenter::V8::AdIntelligenceService::Test::KeywordCategoryResult;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::AdIntelligenceService;
use Microsoft::AdCenter::V8::AdIntelligenceService::KeywordCategoryResult;

sub test_can_create_keyword_category_result_and_set_all_fields : Test(3) {
    my $keyword_category_result = Microsoft::AdCenter::V8::AdIntelligenceService::KeywordCategoryResult->new
        ->Keyword('keyword')
        ->KeywordCategories('keyword categories')
    ;

    ok($keyword_category_result);

    is($keyword_category_result->Keyword, 'keyword', 'can get keyword');
    is($keyword_category_result->KeywordCategories, 'keyword categories', 'can get keyword categories');
};

1;
