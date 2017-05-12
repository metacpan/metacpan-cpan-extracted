package Microsoft::AdCenter::V8::AdIntelligenceService::Test::DayMonthAndYear;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Test::Class/;
use Test::More;

use Microsoft::AdCenter::V8::AdIntelligenceService;
use Microsoft::AdCenter::V8::AdIntelligenceService::DayMonthAndYear;

sub test_can_create_day_month_and_year_and_set_all_fields : Test(4) {
    my $day_month_and_year = Microsoft::AdCenter::V8::AdIntelligenceService::DayMonthAndYear->new
        ->Day('day')
        ->Month('month')
        ->Year('year')
    ;

    ok($day_month_and_year);

    is($day_month_and_year->Day, 'day', 'can get day');
    is($day_month_and_year->Month, 'month', 'can get month');
    is($day_month_and_year->Year, 'year', 'can get year');
};

1;
