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

my $locale = Locale::CLDR->new('cs');
my $months = $locale->month_format_wide();
is_deeply ($months, [qw( ledna února března dubna května června července srpna září října listopadu prosince )], 'Month format wide');
$months = $locale->month_format_abbreviated();
is_deeply ($months, [qw( led úno bře dub kvě čvn čvc srp zář říj lis pro )], 'Month format abbreviated');
$months = $locale->month_format_narrow();
is_deeply ($months, [qw( 1 2 3 4 5 6 7 8 9 10 11 12 )], 'Month format narrow');
$months = $locale->month_stand_alone_wide();
is_deeply ($months, [qw( leden únor březen duben květen červen červenec srpen září říjen listopad prosinec )], 'Month stand alone wide');
$months = $locale->month_stand_alone_abbreviated();
is_deeply ($months, [qw( led úno bře dub kvě čvn čvc srp zář říj lis pro )], 'Month stand alone abbreviated');
$months = $locale->month_stand_alone_narrow();
is_deeply ($months, [qw( 1 2 3 4 5 6 7 8 9 10 11 12 )], 'Month stand alone narrow');

my $days = $locale->day_format_wide();
is_deeply ($days, [qw( pondělí úterý středa čtvrtek pátek sobota neděle )], 'Day format wide');
$days = $locale->day_format_abbreviated();
is_deeply ($days, [qw( po út st čt pá so ne )], 'Day format abbreviated');
$days = $locale->day_format_narrow();
is_deeply ($days, [qw( P Ú S Č P S N )], 'Day format narrow');
$days = $locale->day_stand_alone_wide();
is_deeply ($days, [qw( pondělí úterý středa čtvrtek pátek sobota neděle )], 'Day stand alone wide');
$days = $locale->day_stand_alone_abbreviated();
is_deeply ($days, [qw( po út st čt pá so ne )], 'Day stand alone abbreviated');
$days = $locale->day_stand_alone_narrow();
is_deeply ($days, [qw( P Ú S Č P S N )], 'Day stand alone narrow');

my $quarters = $locale->quarter_format_wide();
is_deeply ($quarters, ['1. čtvrtletí', '2. čtvrtletí', '3. čtvrtletí', '4. čtvrtletí'], 'Quarter format wide');
$quarters = $locale->quarter_format_abbreviated();
is_deeply ($quarters, [qw( Q1 Q2 Q3 Q4 )], 'Quarter format abbreviated');
$quarters = $locale->quarter_format_narrow();
is_deeply ($quarters, [qw( 1 2 3 4 )], 'Quarter format narrow');
$quarters = $locale->quarter_stand_alone_wide();
is_deeply ($quarters, [ '1. čtvrtletí', '2. čtvrtletí', '3. čtvrtletí', '4. čtvrtletí' ], 'Quarter stand alone wide');
$quarters = $locale->quarter_stand_alone_abbreviated();
is_deeply ($quarters, [qw( Q1 Q2 Q3 Q4 )], 'Quarter stand alone abbreviated');
$quarters = $locale->quarter_stand_alone_narrow();
is_deeply ($quarters, [qw( 1 2 3 4 )], 'Quarter stand alone narrow');

my $am_pm = $locale->am_pm_wide();
is_deeply ($am_pm, [ qw( dop. odp. ) ], 'AM PM wide');
$am_pm = $locale->am_pm_abbreviated();
is_deeply ($am_pm, [ qw( dop. odp. ) ], 'AM PM abbreviated');
$am_pm = $locale->am_pm_narrow();
is_deeply ($am_pm, [qw( dop. odp. )], 'AM PM narrow');
$am_pm = $locale->am_pm_format_wide();
is_deeply ($am_pm, { am => 'dop.', noon => 'poledne', pm => 'odp.', midnight => 'půlnoc', morning1 => 'ráno', morning2 => 'dopoledne', afternoon1 => 'odpoledne', evening1 => 'večer', night1 => 'v noci' }, 'AM PM format wide');
$am_pm = $locale->am_pm_format_abbreviated();
is_deeply ($am_pm, { am => 'dop.', noon => 'pol.', pm => 'odp.', midnight => 'půln.', morning1 => 'r.', morning2 => 'dop.', afternoon1 => 'odp.', evening1 => 'več.', night1 => 'v n.' }, 'AM PM format abbreviated');
$am_pm = $locale->am_pm_format_narrow();
is_deeply ($am_pm, { am => 'dop.', noon => 'pol.', pm => 'odp.', midnight => 'půl.', morning1 => 'r.', morning2 => 'd.', afternoon1 => 'o.', evening1 => 'v.', night1 => 'n.' }, 'AM PM format narrow');
$am_pm = $locale->am_pm_stand_alone_wide();
is_deeply ($am_pm, { am => 'dop.', noon => 'poledne', pm => 'odp.', midnight => 'půlnoc', morning1 => 'ráno', morning2 => 'dopoledne', afternoon1 => 'odpoledne', evening1 => 'večer', night1 => 'noc' }, 'AM PM stand alone wide');
$am_pm = $locale->am_pm_stand_alone_abbreviated();
is_deeply ($am_pm, { am => 'dop.', noon => 'poledne', pm => 'odp.', midnight => 'půlnoc', morning1 => 'ráno', morning2 => 'dopoledne', afternoon1 => 'odpoledne', evening1 => 'večer', night1 => 'noc' }, 'AM PM stand alone abbreviated');
$am_pm = $locale->am_pm_stand_alone_narrow();
is_deeply ($am_pm, { am => 'dop.', noon => 'pol.', pm => 'odp.', midnight => 'půl.', morning1 => 'ráno', morning2 => 'dop.', afternoon1 => 'odp.', evening1 => 'več.', night1 => 'noc' }, 'AM PM stand alone narrow');

my $era = $locale->era_wide();
is_deeply ($era, ['před naším letopočtem', 'našeho letopočtu'], 'Era wide');
$era = $locale->era_abbreviated();
is_deeply ($era, [ 'př. n. l.', 'n. l.' ], 'Era abbreviated');
$era = $locale->era_narrow();
is_deeply ($era, [qw( př.n.l. n.l. )], 'Era narrow');
$era = $locale->era_format_wide();
is_deeply ($era, ['před naším letopočtem', 'našeho letopočtu' ], 'Era format wide');
$era = $locale->era_format_abbreviated();
is_deeply ($era, ['př. n. l.', 'n. l.' ], 'Era format abbreviated');
$era = $locale->era_format_narrow();
is_deeply ($era, ['př.n.l.', 'n.l.' ], 'Era format narrow');
$era = $locale->era_stand_alone_wide();
is_deeply ($era, ['před naším letopočtem', 'našeho letopočtu'], 'Era stand alone wide');
$era = $locale->era_stand_alone_abbreviated();
is_deeply ($era, ['př. n. l.', 'n. l.'], 'Era stand alone abbreviated');
$era = $locale->era_stand_alone_narrow();
is_deeply ($era, [ 'př.n.l.', 'n.l.' ], 'Era stand alone narrow');

my $day_period_data = $locale->get_day_period('0000');
is($day_period_data, 'půln.', 'Day period data AM');
$day_period_data = $locale->get_day_period('1200');
is($day_period_data, 'pol.', 'Day period data Noon');
$day_period_data = $locale->get_day_period('1800');
is($day_period_data, 'več.', 'Day period data PM');

my $date_format = $locale->date_format_full;
is($date_format, "EEEE d. MMMM y", 'Date Format Full');
$date_format = $locale->date_format_long;
is($date_format, "d. MMMM y", 'Date Format Long');
$date_format = $locale->date_format_medium;
is($date_format, 'd. M. y', 'Date Format Medium');
$date_format = $locale->date_format_short;
is($date_format, 'dd.MM.yy', 'Date Format Short');

my $time_format = $locale->time_format_full;
is($time_format, 'H:mm:ss zzzz', 'Time Format Full');
$time_format = $locale->time_format_long;
is($time_format, 'H:mm:ss z', 'Time Format Long');
$time_format = $locale->time_format_medium;
is($time_format, 'H:mm:ss', 'Time Format Medium');
$time_format = $locale->time_format_short;
is($time_format, 'H:mm', 'Time Format Short');

my $date_time_format = $locale->datetime_format_full;
is($date_time_format, "EEEE d. MMMM y H:mm:ss zzzz", 'Date Time Format Full');
$date_time_format = $locale->datetime_format_long;
is($date_time_format, "d. MMMM y H:mm:ss z", 'Date Time Format Long');
$date_time_format = $locale->datetime_format_medium;
is($date_time_format, 'd. M. y H:mm:ss', 'Date Time Format Medium');
$date_time_format = $locale->datetime_format_short;
is($date_time_format, 'dd.MM.yy H:mm', 'Date Time Format Short');

is ($locale->prefers_24_hour_time(), 1, 'Prefers 24 hour time');
is ($locale->first_day_of_week(), 1, 'First day of week recoded for DateTime');

is($locale->era_boundry( gregorian => -12 ), 0, 'Gregorian era');
is($locale->era_boundry( japanese => 9610217 ), 38, 'Japanese era');

is($locale->week_data_min_days(), 4, 'Number of days a week must have in Catalan before it counts as the first week of a year');
is($locale->week_data_first_day(), 'mon', 'First day of the week in Catalan when displaying calendars');
is($locale->week_data_weekend_start(), 'sat', 'First day of the week end in Catalan');
is($locale->week_data_weekend_end(), 'sun', 'Last day of the week end in Catalan');

# Overrides for week data
$locale=Locale::CLDR->new('cs_CZ_u_fw_thu');
is($locale->week_data_first_day(), 'thu', 'Override first day of the week in czech when displaying calendars');