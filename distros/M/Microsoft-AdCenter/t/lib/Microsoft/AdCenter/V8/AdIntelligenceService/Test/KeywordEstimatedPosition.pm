package Microsoft::AdCenter::V8::AdIntelligenceService::Test::KeywordEstimatedPosition;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::AdIntelligenceService;
use Microsoft::AdCenter::V8::AdIntelligenceService::KeywordEstimatedPosition;

sub test_can_create_keyword_estimated_position_and_set_all_fields : Test(3) {
    my $keyword_estimated_position = Microsoft::AdCenter::V8::AdIntelligenceService::KeywordEstimatedPosition->new
        ->EstimatedPositions('estimated positions')
        ->Keyword('keyword')
    ;

    ok($keyword_estimated_position);

    is($keyword_estimated_position->EstimatedPositions, 'estimated positions', 'can get estimated positions');
    is($keyword_estimated_position->Keyword, 'keyword', 'can get keyword');
};

1;
