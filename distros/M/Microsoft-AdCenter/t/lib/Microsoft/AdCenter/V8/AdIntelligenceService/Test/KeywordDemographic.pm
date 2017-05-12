package Microsoft::AdCenter::V8::AdIntelligenceService::Test::KeywordDemographic;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::AdIntelligenceService;
use Microsoft::AdCenter::V8::AdIntelligenceService::KeywordDemographic;

sub test_can_create_keyword_demographic_and_set_all_fields : Test(10) {
    my $keyword_demographic = Microsoft::AdCenter::V8::AdIntelligenceService::KeywordDemographic->new
        ->Age18_24('age18_24')
        ->Age25_34('age25_34')
        ->Age35_49('age35_49')
        ->Age50_64('age50_64')
        ->Age65Plus('age65 plus')
        ->AgeUnknown('age unknown')
        ->Female('female')
        ->GenderUnknown('gender unknown')
        ->Male('male')
    ;

    ok($keyword_demographic);

    is($keyword_demographic->Age18_24, 'age18_24', 'can get age18_24');
    is($keyword_demographic->Age25_34, 'age25_34', 'can get age25_34');
    is($keyword_demographic->Age35_49, 'age35_49', 'can get age35_49');
    is($keyword_demographic->Age50_64, 'age50_64', 'can get age50_64');
    is($keyword_demographic->Age65Plus, 'age65 plus', 'can get age65 plus');
    is($keyword_demographic->AgeUnknown, 'age unknown', 'can get age unknown');
    is($keyword_demographic->Female, 'female', 'can get female');
    is($keyword_demographic->GenderUnknown, 'gender unknown', 'can get gender unknown');
    is($keyword_demographic->Male, 'male', 'can get male');
};

1;
