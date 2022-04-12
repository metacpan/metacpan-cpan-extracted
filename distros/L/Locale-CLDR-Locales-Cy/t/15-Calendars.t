#!/usr/bin/perl
# Do not normalise this test file. It has deliberately unnormalised characters in it.
use v5.10;
use strict;
use warnings;
use utf8;
use if $^V ge v5.12.0, feature => 'unicode_strings';

use Test::More tests => 61;
use Test::Exception;

use ok 'Locale::CLDR';

my $locale = Locale::CLDR->new('cy_GB');
my $months = $locale->month_format_wide();
is_deeply ($months, [qw( Ionawr Chwefror Mawrth Ebrill Mai Mehefin Gorffennaf Awst Medi Hydref Tachwedd Rhagfyr )], 'Month format wide');
$months = $locale->month_format_abbreviated();
is_deeply ($months, [qw( Ion Chwef Maw Ebrill Mai Meh Gorff Awst Medi Hyd Tach Rhag )], 'Month format abbreviated');
$months = $locale->month_format_narrow();
is_deeply ($months, [qw( I Ch M E M M G A M H T Rh )], 'Month format narrow');
$months = $locale->month_stand_alone_wide();
is_deeply ($months, [qw( Ionawr Chwefror Mawrth Ebrill Mai Mehefin Gorffennaf Awst Medi Hydref Tachwedd Rhagfyr )], 'Month stand alone wide');
$months = $locale->month_stand_alone_abbreviated();
is_deeply ($months, [qw( Ion Chw Maw Ebr Mai Meh Gor Awst Medi Hyd Tach Rhag )], 'Month stand alone abbreviated');
$months = $locale->month_stand_alone_narrow();
is_deeply ($months, [qw( I Ch M E M M G A M H T Rh )], 'Month stand alone narrow');

my $days = $locale->day_format_wide();
is_deeply ($days, ['Dydd Llun', 'Dydd Mawrth', 'Dydd Mercher', 'Dydd Iau', 'Dydd Gwener', 'Dydd Sadwrn', 'Dydd Sul'], 'Day format wide');
$days = $locale->day_format_abbreviated();
is_deeply ($days, [qw( Llun Maw Mer Iau Gwen Sad Sul )], 'Day format abbreviated');
$days = $locale->day_format_narrow();
is_deeply ($days, [qw( Ll M M I G S S )], 'Day format narrow');
$days = $locale->day_stand_alone_wide();
is_deeply ($days, ['Dydd Llun', 'Dydd Mawrth', 'Dydd Mercher', 'Dydd Iau', 'Dydd Gwener', 'Dydd Sadwrn', 'Dydd Sul'], 'Day stand alone wide');
$days = $locale->day_stand_alone_abbreviated();
is_deeply ($days, [qw( Llun Maw Mer Iau Gwe Sad Sul )], 'Day stand alone abbreviated');
$days = $locale->day_stand_alone_narrow();
is_deeply ($days, [qw( Ll M M I G S S )], 'Day stand alone narrow');

my $quarters = $locale->quarter_format_wide();
is_deeply ($quarters, ['chwarter 1af', '2il chwarter', '3ydd chwarter', '4ydd chwarter'], 'Quarter format wide');
$quarters = $locale->quarter_format_abbreviated();
is_deeply ($quarters, [qw( Ch1 Ch2 Ch3 Ch4 )], 'Quarter format abbreviated');
$quarters = $locale->quarter_format_narrow();
is_deeply ($quarters, [qw( 1 2 3 4 )], 'Quarter format narrow');
$quarters = $locale->quarter_stand_alone_wide();
is_deeply ($quarters, [ 'chwarter 1af', '2il chwarter', '3ydd chwarter', '4ydd chwarter' ], 'Quarter stand alone wide');
$quarters = $locale->quarter_stand_alone_abbreviated();
is_deeply ($quarters, [qw( Ch1 Ch2 Ch3 Ch4 )], 'Quarter stand alone abbreviated');
$quarters = $locale->quarter_stand_alone_narrow();
is_deeply ($quarters, [qw( 1 2 3 4 )], 'Quarter stand alone narrow');

my $am_pm = $locale->am_pm_wide();
is_deeply ($am_pm, [qw( yb yh )], 'AM PM wide');
$am_pm = $locale->am_pm_abbreviated();
is_deeply ($am_pm, [qw( yb yh )], 'AM PM abbreviated');
$am_pm = $locale->am_pm_narrow();
is_deeply ($am_pm, [qw( b h )], 'AM PM narrow');
$am_pm = $locale->am_pm_format_wide();
is_deeply ($am_pm, { pm => q{yh}, am => q{yb}, morning1 => 'y bore', noon => 'canol dydd', afternoon1 => 'y prynhawn', evening1 => 'yr hwyr', midnight => 'canol nos' }, 'AM PM format wide');
$am_pm = $locale->am_pm_format_abbreviated();
is_deeply ($am_pm, { pm => q{yh}, am => q{yb}, morning1 => 'y bore', noon => 'canol dydd', afternoon1 => 'y prynhawn', evening1 => 'yr hwyr', midnight => 'canol nos' }, 'AM PM format abbreviated');
$am_pm = $locale->am_pm_format_narrow();
is_deeply ($am_pm, { pm => q{h}, am => q{b}, morning1 => 'yn y bore', noon => 'canol dydd', afternoon1 => 'yn y prynhawn', evening1 => 'min nos', midnight => 'canol nos' }, 'AM PM format narrow');
$am_pm = $locale->am_pm_stand_alone_wide();
is_deeply ($am_pm, { pm => q{yh}, am => q{yb}, morning1 => 'y bore', noon => 'canol dydd', afternoon1 => 'y prynhawn', evening1 => 'yr hwyr', midnight => 'canol nos' }, 'AM PM stand alone wide');
$am_pm = $locale->am_pm_stand_alone_abbreviated();
is_deeply ($am_pm, { pm => q{yh}, am => q{yb}, morning1 => 'bore', noon => 'canol dydd', afternoon1 => 'prynhawn', evening1 => 'yr hwyr', midnight => 'canol nos' }, 'AM PM stand alone abbreviated');
$am_pm = $locale->am_pm_stand_alone_narrow();
is_deeply ($am_pm, { pm => q{yh}, am => q{yb}, morning1 => 'bore', noon => 'canol dydd', afternoon1 => 'prynhawn', evening1 => 'min nos', midnight => 'canol nos' }, 'AM PM stand alone narrow');

my $era = $locale->era_wide();
is_deeply ($era, ['Cyn Crist', 'Oed Crist'], 'Era wide');
$era = $locale->era_abbreviated();
is_deeply ($era, [ 'CC', 'OC' ], 'Era abbreviated');
$era = $locale->era_narrow();
is_deeply ($era, [ 'C', 'O' ], 'Era narrow');
$era = $locale->era_format_wide();
is_deeply ($era, ['Cyn Crist', 'Oed Crist' ], 'Era format wide');
$era = $locale->era_format_abbreviated();
is_deeply ($era, [ 'CC', 'OC' ], 'Era format abbreviated');
$era = $locale->era_format_narrow();
is_deeply ($era, [ 'C', 'O' ], 'Era format narrow');
$era = $locale->era_stand_alone_wide();
is_deeply ($era, ['Cyn Crist', 'Oed Crist'], 'Era stand alone wide');
$era = $locale->era_stand_alone_abbreviated();
is_deeply ($era, ['CC', 'OC'], 'Era stand alone abbreviated');
$era = $locale->era_stand_alone_narrow();
is_deeply ($era, [ 'C', 'O' ], 'Era stand alone narrow');

TODO: {
	local $TODO = 'Need to look up how fall back should work';
my $day_period_data = $locale->get_day_period('0000');
is($day_period_data, 'AM', 'Day period data AM');
$day_period_data = $locale->get_day_period('1200');
is($day_period_data, 'PM', 'Day period data Noon');
$day_period_data = $locale->get_day_period('1210');
is($day_period_data, 'PM', 'Day period data PM');
}
my $date_format = $locale->date_format_full;
is($date_format, 'EEEE, d MMMM y', 'Date Format Full');
$date_format = $locale->date_format_long;
is($date_format, 'd MMMM y', 'Date Format Long');
$date_format = $locale->date_format_medium;
is($date_format, 'd MMM y', 'Date Format Medium');
$date_format = $locale->date_format_short;
is($date_format, 'dd/MM/yy', 'Date Format Short');

my $time_format = $locale->time_format_full;
is($time_format, 'HH:mm:ss zzzz', 'Time Format Full');
$time_format = $locale->time_format_long;
is($time_format, 'HH:mm:ss z', 'Time Format Long');
$time_format = $locale->time_format_medium;
is($time_format, 'HH:mm:ss', 'Time Format Medium');
$time_format = $locale->time_format_short;
is($time_format, 'HH:mm', 'Time Format Short');

my $date_time_format = $locale->datetime_format_full;
is($date_time_format, "EEEE, d MMMM y 'am' HH:mm:ss zzzz", 'Date Time Format Full');
$date_time_format = $locale->datetime_format_long;
is($date_time_format, "d MMMM y 'am' HH:mm:ss z", 'Date Time Format Long');
$date_time_format = $locale->datetime_format_medium;
is($date_time_format, 'd MMM y HH:mm:ss', 'Date Time Format Medium');
$date_time_format = $locale->datetime_format_short;
is($date_time_format, 'dd/MM/yy HH:mm', 'Date Time Format Short');

is ($locale->prefers_24_hour_time(), 1, 'Prefers 24 hour time');
is ($locale->first_day_of_week(), 7, 'First day of week recoded for DateTime');

is($locale->era_boundry( gregorian => -12 ), 0, 'Gregorian era');
is($locale->era_boundry( japanese => 9610217 ), 38, 'Japanese era');

is($locale->week_data_min_days(), 4, 'Number of days a week must have in wales before it counts as the first week of a year');
is($locale->week_data_first_day(), 'sun', 'First day of the week in wales when displaying calendars');
is($locale->week_data_weekend_start(), 'sat', 'First day of the week end in wales');
is($locale->week_data_weekend_end(), 'sun', 'Last day of the week end in wales');

# Overrides for week data
$locale=Locale::CLDR->new('cy_GB_u_fw_thu');
is($locale->week_data_first_day(), 'thu', 'Override first day of the week in wales when displaying calendars');