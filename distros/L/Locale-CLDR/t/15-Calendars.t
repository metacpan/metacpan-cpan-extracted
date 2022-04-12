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

my $locale = Locale::CLDR->new('en');
my $months = $locale->month_format_wide();
is_deeply ($months, [qw( January February March April May June July August September October November December )], 'Month format wide');
$months = $locale->month_format_abbreviated();
is_deeply ($months, [qw( Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec )], 'Month format abbreviated');
$months = $locale->month_format_narrow();
is_deeply ($months, [qw( J F M A M J J A S O N D )], 'Month format narrow');
$months = $locale->month_stand_alone_wide();
is_deeply ($months, [qw( January February March April May June July August September October November December )], 'Month stand alone wide');
$months = $locale->month_stand_alone_abbreviated();
is_deeply ($months, [qw( Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec )], 'Month stand alone abbreviated');
$months = $locale->month_stand_alone_narrow();
is_deeply ($months, [qw( J F M A M J J A S O N D )], 'Month stand alone narrow');

my $days = $locale->day_format_wide();
is_deeply ($days, [qw( Monday Tuesday Wednesday Thursday Friday Saturday Sunday )], 'Day format wide');
$days = $locale->day_format_abbreviated();
is_deeply ($days, [qw( Mon Tue Wed Thu Fri Sat Sun )], 'Day format abbreviated');
$days = $locale->day_format_narrow();
is_deeply ($days, [qw( M T W T F S S )], 'Day format narrow');
$days = $locale->day_stand_alone_wide();
is_deeply ($days, [qw( Monday Tuesday Wednesday Thursday Friday Saturday Sunday )], 'Day stand alone wide');
$days = $locale->day_stand_alone_abbreviated();
is_deeply ($days, [qw( Mon Tue Wed Thu Fri Sat Sun )], 'Day stand alone abbreviated');
$days = $locale->day_stand_alone_narrow();
is_deeply ($days, [qw( M T W T F S S )], 'Day stand alone narrow');

my $quarters = $locale->quarter_format_wide();
is_deeply ($quarters, ['1st quarter', '2nd quarter', '3rd quarter', '4th quarter'], 'Quarter format wide');
$quarters = $locale->quarter_format_abbreviated();
is_deeply ($quarters, [qw( Q1 Q2 Q3 Q4 )], 'Quarter format abbreviated');
$quarters = $locale->quarter_format_narrow();
is_deeply ($quarters, [qw( 1 2 3 4 )], 'Quarter format narrow');
$quarters = $locale->quarter_stand_alone_wide();
is_deeply ($quarters, [ '1st quarter', '2nd quarter', '3rd quarter', '4th quarter' ], 'Quarter stand alone wide');
$quarters = $locale->quarter_stand_alone_abbreviated();
is_deeply ($quarters, [qw( Q1 Q2 Q3 Q4 )], 'Quarter stand alone abbreviated');
$quarters = $locale->quarter_stand_alone_narrow();
is_deeply ($quarters, [qw( 1 2 3 4 )], 'Quarter stand alone narrow');

my $am_pm = $locale->am_pm_wide();
is_deeply ($am_pm, [qw( am pm )], 'AM PM wide');
$am_pm = $locale->am_pm_abbreviated();
is_deeply ($am_pm, [qw( am pm )], 'AM PM abbreviated');
$am_pm = $locale->am_pm_narrow();
is_deeply ($am_pm, [qw( a p )], 'AM PM narrow');
$am_pm = $locale->am_pm_format_wide();
is_deeply ($am_pm, { afternoon1 => 'in the afternoon', night1 => 'at night', noon => 'noon', midnight => 'midnight', evening1 => 'in the evening', morning1 => 'in the morning', am => 'am', pm => 'pm' }, 'AM PM format wide');
$am_pm = $locale->am_pm_format_abbreviated();
is_deeply ($am_pm, { afternoon1 => 'in the afternoon', night1 => 'at night', noon => 'noon', midnight => 'midnight', evening1 => 'in the evening', morning1 => 'in the morning', am => 'am', pm => 'pm' }, 'AM PM format abbreviated');
$am_pm = $locale->am_pm_format_narrow();
is_deeply ($am_pm, { afternoon1 => 'in the afternoon', night1 => 'at night', noon => 'n', midnight => 'mi', evening1 => 'in the evening', morning1 => 'in the morning', am => 'a', pm => 'p' }, 'AM PM format narrow');
$am_pm = $locale->am_pm_stand_alone_wide();
is_deeply ($am_pm, { afternoon1 => 'afternoon', night1 => 'night', midnight => 'midnight', evening1 => 'evening', morning1 => 'morning', am => 'AM', noon => 'noon', pm => 'PM' }, 'AM PM stand alone wide');
$am_pm = $locale->am_pm_stand_alone_abbreviated();
is_deeply ($am_pm, { afternoon1 => 'afternoon', night1 => 'night', midnight => 'midnight', evening1 => 'evening', morning1 => 'morning', am => 'AM', noon => 'noon', pm => 'PM' }, 'AM PM stand alone abbreviated');
$am_pm = $locale->am_pm_stand_alone_narrow();
is_deeply ($am_pm, { afternoon1 => 'afternoon', night1 => 'night', midnight => 'midnight', evening1 => 'evening', morning1 => 'morning', am => 'AM', noon => 'noon', pm => 'PM' }, 'AM PM stand alone narrow');

my $era = $locale->era_wide();
is_deeply ($era, ['Before Christ', 'Anno Domini'], 'Era wide');
$era = $locale->era_abbreviated();
is_deeply ($era, [qw( BC AD )], 'Era abbreviated');
$era = $locale->era_narrow();
is_deeply ($era, [qw( B A )], 'Era narrow');
$era = $locale->era_format_wide();
is_deeply ($era, ['Before Christ', 'Anno Domini' ], 'Era format wide');
$era = $locale->era_format_abbreviated();
is_deeply ($era, ['BC', 'AD' ], 'Era format abbreviated');
$era = $locale->era_format_narrow();
is_deeply ($era, ['B', 'A' ], 'Era format narrow');
$era = $locale->era_stand_alone_wide();
is_deeply ($era, ['Before Christ', 'Anno Domini'], 'Era stand alone wide');
$era = $locale->era_stand_alone_abbreviated();
is_deeply ($era, ['BC', 'AD'], 'Era stand alone abbreviated');
$era = $locale->era_stand_alone_narrow();
is_deeply ($era, [ 'B', 'A' ], 'Era stand alone narrow');

# Day periods are broken
my $day_period_data = $locale->get_day_period('0000');
#is($day_period_data, 'am', 'Day period data AM');
$day_period_data = $locale->get_day_period('1200');
is($day_period_data, 'noon', 'Day period data Noon');
$day_period_data = $locale->get_day_period('1210');
#is($day_period_data, 'pm', 'Day period data PM');

my $date_format = $locale->date_format_full;
is($date_format, 'EEEE, MMMM d, y', 'Date Format Full');
$date_format = $locale->date_format_long;
is($date_format, 'MMMM d, y', 'Date Format Long');
$date_format = $locale->date_format_medium;
is($date_format, 'MMM d, y', 'Date Format Medium');
$date_format = $locale->date_format_short;
is($date_format, 'M/d/yy', 'Date Format Short');

my $time_format = $locale->time_format_full;
is($time_format, 'h:mm:ss a zzzz', 'Time Format Full');
$time_format = $locale->time_format_long;
is($time_format, 'h:mm:ss a z', 'Time Format Long');
$time_format = $locale->time_format_medium;
is($time_format, 'h:mm:ss a', 'Time Format Medium');
$time_format = $locale->time_format_short;
is($time_format, 'h:mm a', 'Time Format Short');

my $date_time_format = $locale->datetime_format_full;
is($date_time_format, "EEEE, MMMM d, y 'at' h:mm:ss a zzzz", 'Date Time Format Full');
$date_time_format = $locale->datetime_format_long;
is($date_time_format, "MMMM d, y 'at' h:mm:ss a z", 'Date Time Format Long');
$date_time_format = $locale->datetime_format_medium;
is($date_time_format, 'MMM d, y, h:mm:ss a', 'Date Time Format Medium');
$date_time_format = $locale->datetime_format_short;
is($date_time_format, 'M/d/yy, h:mm a', 'Date Time Format Short');

is ($locale->prefers_24_hour_time(), 0, 'Prefers 24 hour time');
is ($locale->first_day_of_week(), 7, 'First day of week recoded for DateTime');

is($locale->era_boundry( gregorian => -12 ), 0, 'Gregorian era');
is($locale->era_boundry( japanese => 9610217 ), 38, 'Japanese era');

is($locale->week_data_min_days(), 1, 'Number of days a week must have in en before it counts as the first week of a year');
is($locale->week_data_first_day(), 'sun', 'First day of the week in en when displaying calendars');
is($locale->week_data_weekend_start(), 'sat', 'First day of the week end in en');
is($locale->week_data_weekend_end(), 'sun', 'Last day of the week end in en');

# Overrides for week data
$locale=Locale::CLDR->new('en_US_u_fw_thu');
is($locale->week_data_first_day(), 'thu', 'Override first day of the week in US when displaying calendars');

$locale = Locale::CLDR->new('en_US_u_ca_chinese');
is_deeply($locale->month_patterns('stand-alone', 'abbreviated', 'leap'), [
	qw( Mo1bis Mo2bis Mo3bis Mo4bis Mo5bis Mo6bis Mo7bis Mo8bis Mo9bis Mo10bis Mo11bis Mo12bis )
	], 'Month Pattens for Chinese Calendar in en' );
	
# Cyclic names
is_deeply($locale->cyclic_name_sets( qw( format wide dayParts )), [	qw( zi chou yin mao chen si wu wei shen you xu hai) ], 'Cyclic day parts');

