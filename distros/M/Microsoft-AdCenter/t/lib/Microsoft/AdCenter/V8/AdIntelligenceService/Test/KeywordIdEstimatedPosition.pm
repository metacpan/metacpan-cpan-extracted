package Microsoft::AdCenter::V8::AdIntelligenceService::Test::KeywordIdEstimatedPosition;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::AdIntelligenceService;
use Microsoft::AdCenter::V8::AdIntelligenceService::KeywordIdEstimatedPosition;

sub test_can_create_keyword_id_estimated_position_and_set_all_fields : Test(3) {
    my $keyword_id_estimated_position = Microsoft::AdCenter::V8::AdIntelligenceService::KeywordIdEstimatedPosition->new
        ->KeywordEstimatedPosition('keyword estimated position')
        ->KeywordId('keyword id')
    ;

    ok($keyword_id_estimated_position);

    is($keyword_id_estimated_position->KeywordEstimatedPosition, 'keyword estimated position', 'can get keyword estimated position');
    is($keyword_id_estimated_position->KeywordId, 'keyword id', 'can get keyword id');
};

1;
