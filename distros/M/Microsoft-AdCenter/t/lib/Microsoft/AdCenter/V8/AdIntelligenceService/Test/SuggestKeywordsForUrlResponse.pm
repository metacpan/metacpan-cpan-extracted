package Microsoft::AdCenter::V8::AdIntelligenceService::Test::SuggestKeywordsForUrlResponse;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::AdIntelligenceService;
use Microsoft::AdCenter::V8::AdIntelligenceService::SuggestKeywordsForUrlResponse;

sub test_can_create_suggest_keywords_for_url_response_and_set_all_fields : Test(2) {
    my $suggest_keywords_for_url_response = Microsoft::AdCenter::V8::AdIntelligenceService::SuggestKeywordsForUrlResponse->new
        ->Keywords('keywords')
    ;

    ok($suggest_keywords_for_url_response);

    is($suggest_keywords_for_url_response->Keywords, 'keywords', 'can get keywords');
};

1;
