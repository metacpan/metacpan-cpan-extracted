package Microsoft::AdCenter::V8::AdIntelligenceService::Test::MonthAndYear;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::AdIntelligenceService;
use Microsoft::AdCenter::V8::AdIntelligenceService::MonthAndYear;

sub test_can_create_month_and_year_and_set_all_fields : Test(3) {
    my $month_and_year = Microsoft::AdCenter::V8::AdIntelligenceService::MonthAndYear->new
        ->Month('month')
        ->Year('year')
    ;

    ok($month_and_year);

    is($month_and_year->Month, 'month', 'can get month');
    is($month_and_year->Year, 'year', 'can get year');
};

1;
