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

my $locale = Locale::CLDR->new('de_DE');
my $months = $locale->month_format_wide();
is_deeply ($months, [qw( Januar Februar März April Mai Juni Juli August September Oktober November Dezember )], 'Month format wide');
$months = $locale->month_format_abbreviated();
is_deeply ($months, [qw( Jan. Feb. März Apr. Mai Juni Juli Aug. Sept. Okt. Nov. Dez. )], 'Month format abbreviated');
$months = $locale->month_format_narrow();
is_deeply ($months, [qw( J F M A M J J A S O N D )], 'Month format narrow');
$months = $locale->month_stand_alone_wide();
is_deeply ($months, [qw( Januar Februar März April Mai Juni Juli August September Oktober November Dezember )], 'Month stand alone wide');
$months = $locale->month_stand_alone_abbreviated();
is_deeply ($months, [qw( Jan Feb Mär Apr Mai Jun Jul Aug Sep Okt Nov Dez )], 'Month stand alone abbreviated');
$months = $locale->month_stand_alone_narrow();
is_deeply ($months, [qw( J F M A M J J A S O N D )], 'Month stand alone narrow');

my $days = $locale->day_format_wide();
is_deeply ($days, [qw( Montag Dienstag Mittwoch Donnerstag Freitag Samstag Sonntag )], 'Day format wide');
$days = $locale->day_format_abbreviated();
is_deeply ($days, [qw( Mo. Di. Mi. Do. Fr. Sa. So. )], 'Day format abbreviated');
$days = $locale->day_format_narrow();
is_deeply ($days, [qw( M D M D F S S )], 'Day format narrow');
$days = $locale->day_stand_alone_wide();
is_deeply ($days, [qw( Montag Dienstag Mittwoch Donnerstag Freitag Samstag Sonntag )], 'Day stand alone wide');
$days = $locale->day_stand_alone_abbreviated();
is_deeply ($days, [qw( Mo Di Mi Do Fr Sa So )], 'Day stand alone abbreviated');
$days = $locale->day_stand_alone_narrow();
is_deeply ($days, [qw( M D M D F S S )], 'Day stand alone narrow');

my $quarters = $locale->quarter_format_wide();
is_deeply ($quarters, ['1. Quartal', '2. Quartal', '3. Quartal', '4. Quartal'], 'Quarter format wide');
$quarters = $locale->quarter_format_abbreviated();
is_deeply ($quarters, [qw( Q1 Q2 Q3 Q4 )], 'Quarter format abbreviated');
$quarters = $locale->quarter_format_narrow();
is_deeply ($quarters, [qw( 1 2 3 4 )], 'Quarter format narrow');
$quarters = $locale->quarter_stand_alone_wide();
is_deeply ($quarters, [ '1. Quartal', '2. Quartal', '3. Quartal', '4. Quartal' ], 'Quarter stand alone wide');
$quarters = $locale->quarter_stand_alone_abbreviated();
is_deeply ($quarters, [qw( Q1 Q2 Q3 Q4 )], 'Quarter stand alone abbreviated');
$quarters = $locale->quarter_stand_alone_narrow();
is_deeply ($quarters, [qw( 1 2 3 4 )], 'Quarter stand alone narrow');

my $am_pm = $locale->am_pm_wide();
is_deeply ($am_pm, [qw( AM PM )], 'AM PM wide');
$am_pm = $locale->am_pm_abbreviated();
is_deeply ($am_pm, [qw( AM PM )], 'AM PM abbreviated');
$am_pm = $locale->am_pm_narrow();
is_deeply ($am_pm, [qw( a p )], 'AM PM narrow');
$am_pm = $locale->am_pm_format_wide();
is_deeply ($am_pm, { morning1 => q{morgens}, pm => q{PM}, night1 => q{nachts}, morning2 => q{vormittags}, evening1 => q{abends}, afternoon2 => q{nachmittags}, am => q{AM}, afternoon1 => q{mittags}, midnight => q{Mitternacht} }, 'AM PM format wide');
$am_pm = $locale->am_pm_format_abbreviated();
is_deeply ($am_pm, { morning1 => q{morgens}, pm => q{PM}, night1 => q{nachts}, morning2 => q{vormittags}, evening1 => q{abends}, afternoon2 => q{nachmittags}, am => q{AM}, afternoon1 => q{mittags}, midnight => q{Mitternacht} }, 'AM PM format abbreviated');
$am_pm = $locale->am_pm_format_narrow();
is_deeply ($am_pm, { morning1 => q{morgens}, pm => q{p}, night1 => q{nachts}, morning2 => q{vormittags}, evening1 => q{abends}, afternoon2 => q{nachmittags}, am => q{a}, afternoon1 => q{mittags}, midnight => q{Mitternacht} }, 'AM PM format narrow');
$am_pm = $locale->am_pm_stand_alone_wide();
is_deeply ($am_pm, { afternoon1 => q{Mittag}, midnight => q{Mitternacht}, afternoon2 => q{Nachmittag}, am => q{AM}, evening1 => q{Abend}, night1 => q{Nacht}, pm => q{PM}, morning2 => q{Vormittag}, morning1 => q{Morgen} }, 'AM PM stand alone wide');
$am_pm = $locale->am_pm_stand_alone_abbreviated();
is_deeply ($am_pm, { afternoon1 => q{Mittag}, midnight => q{Mitternacht}, afternoon2 => q{Nachmittag}, am => q{AM}, evening1 => q{Abend}, night1 => q{Nacht}, pm => q{PM}, morning2 => q{Vormittag}, morning1 => q{Morgen} }, 'AM PM stand alone abbreviated');
$am_pm = $locale->am_pm_stand_alone_narrow();
is_deeply ($am_pm, { afternoon1 => q{Mittag}, midnight => q{Mitternacht}, afternoon2 => q{Nachmittag}, am => q{a}, evening1 => q{Abend}, night1 => q{Nacht}, pm => q{p}, morning2 => q{Vormittag}, morning1 => q{Morgen} }, 'AM PM stand alone narrow');

my $era = $locale->era_wide();
is_deeply ($era, ['v. Chr.', 'n. Chr.'], 'Era wide');
$era = $locale->era_abbreviated();
is_deeply ($era, [ 'v. Chr.', 'n. Chr.' ], 'Era abbreviated');
$era = $locale->era_narrow();
is_deeply ($era, [ 'v. Chr.', 'n. Chr.' ], 'Era narrow');
$era = $locale->era_format_wide();
is_deeply ($era, [ 'v. Chr.', 'n. Chr.' ], 'Era format wide');
$era = $locale->era_format_abbreviated();
is_deeply ($era, [ 'v. Chr.', 'n. Chr.' ], 'Era format abbreviated');
$era = $locale->era_format_narrow();
is_deeply ($era, [ 'v. Chr.', 'n. Chr.' ], 'Era format narrow');
$era = $locale->era_stand_alone_wide();
is_deeply ($era, ['v. Chr.', 'n. Chr.'], 'Era stand alone wide');
$era = $locale->era_stand_alone_abbreviated();
is_deeply ($era, ['v. Chr.', 'n. Chr.'], 'Era stand alone abbreviated');
$era = $locale->era_stand_alone_narrow();
is_deeply ($era, [ 'v. Chr.', 'n. Chr.' ], 'Era stand alone narrow');

my $day_period_data = $locale->get_day_period('0000');
is($day_period_data, 'Mitternacht', 'Day period data AM');
$day_period_data = $locale->get_day_period('1200');
is($day_period_data, 'mittags', 'Day period data Noon');
$day_period_data = $locale->get_day_period('1210');
is($day_period_data, 'mittags', 'Day period data PM');

my $date_format = $locale->date_format_full;
is($date_format, 'EEEE, d. MMMM y', 'Date Format Full');
$date_format = $locale->date_format_long;
is($date_format, 'd. MMMM y', 'Date Format Long');
$date_format = $locale->date_format_medium;
is($date_format, 'dd.MM.y', 'Date Format Medium');
$date_format = $locale->date_format_short;
is($date_format, 'dd.MM.yy', 'Date Format Short');

my $time_format = $locale->time_format_full;
is($time_format, 'HH:mm:ss zzzz', 'Time Format Full');
$time_format = $locale->time_format_long;
is($time_format, 'HH:mm:ss z', 'Time Format Long');
$time_format = $locale->time_format_medium;
is($time_format, 'HH:mm:ss', 'Time Format Medium');
$time_format = $locale->time_format_short;
is($time_format, 'HH:mm', 'Time Format Short');

my $date_time_format = $locale->datetime_format_full;
is($date_time_format, "EEEE, d. MMMM y 'um' HH:mm:ss zzzz", 'Date Time Format Full');
$date_time_format = $locale->datetime_format_long;
is($date_time_format, "d. MMMM y 'um' HH:mm:ss z", 'Date Time Format Long');
$date_time_format = $locale->datetime_format_medium;
is($date_time_format, 'dd.MM.y, HH:mm:ss', 'Date Time Format Medium');
$date_time_format = $locale->datetime_format_short;
is($date_time_format, 'dd.MM.yy, HH:mm', 'Date Time Format Short');

is ($locale->prefers_24_hour_time(), 1, 'Prefers 24 hour time');
is ($locale->first_day_of_week(), 1, 'First day of week recoded for DateTime');

is($locale->era_boundry( gregorian => -12 ), 0, 'Gregorian era');
is($locale->era_boundry( japanese => 9610217 ), 38, 'Japanese era');

is($locale->week_data_min_days(), 4, 'Number of days a week must have in GB before it counts as the first week of a year');
is($locale->week_data_first_day(), 'mon', 'First day of the week in GB when displaying calendars');
is($locale->week_data_weekend_start(), 'sat', 'First day of the week end in GB');
is($locale->week_data_weekend_end(), 'sun', 'Last day of the week end in GB');

# Overrides for week data
$locale=Locale::CLDR->new('de_DE_u_fw_thu');
is($locale->week_data_first_day(), 'thu', 'Override first day of the week in germany when displaying calendars');