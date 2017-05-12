package Microsoft::AdCenter::V8::AdIntelligenceService::Test::KeywordCategory;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::AdIntelligenceService;
use Microsoft::AdCenter::V8::AdIntelligenceService::KeywordCategory;

sub test_can_create_keyword_category_and_set_all_fields : Test(3) {
    my $keyword_category = Microsoft::AdCenter::V8::AdIntelligenceService::KeywordCategory->new
        ->Category('category')
        ->ConfidenceScore('confidence score')
    ;

    ok($keyword_category);

    is($keyword_category->Category, 'category', 'can get category');
    is($keyword_category->ConfidenceScore, 'confidence score', 'can get confidence score');
};

1;
