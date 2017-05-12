package Microsoft::AdCenter::V8::AdIntelligenceService::Test::GetEstimatedPositionByKeywordIdsResponse;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::AdIntelligenceService;
use Microsoft::AdCenter::V8::AdIntelligenceService::GetEstimatedPositionByKeywordIdsResponse;

sub test_can_create_get_estimated_position_by_keyword_ids_response_and_set_all_fields : Test(2) {
    my $get_estimated_position_by_keyword_ids_response = Microsoft::AdCenter::V8::AdIntelligenceService::GetEstimatedPositionByKeywordIdsResponse->new
        ->KeywordEstimatedPositions('keyword estimated positions')
    ;

    ok($get_estimated_position_by_keyword_ids_response);

    is($get_estimated_position_by_keyword_ids_response->KeywordEstimatedPositions, 'keyword estimated positions', 'can get keyword estimated positions');
};

1;
