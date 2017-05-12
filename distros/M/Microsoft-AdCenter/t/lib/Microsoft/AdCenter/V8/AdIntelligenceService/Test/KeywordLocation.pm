package Microsoft::AdCenter::V8::AdIntelligenceService::Test::KeywordLocation;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::AdIntelligenceService;
use Microsoft::AdCenter::V8::AdIntelligenceService::KeywordLocation;

sub test_can_create_keyword_location_and_set_all_fields : Test(3) {
    my $keyword_location = Microsoft::AdCenter::V8::AdIntelligenceService::KeywordLocation->new
        ->Location('location')
        ->Percentage('percentage')
    ;

    ok($keyword_location);

    is($keyword_location->Location, 'location', 'can get location');
    is($keyword_location->Percentage, 'percentage', 'can get percentage');
};

1;
