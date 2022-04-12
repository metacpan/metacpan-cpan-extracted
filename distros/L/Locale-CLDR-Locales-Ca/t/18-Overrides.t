#!/usr/bin/perl
# Do not normalise this test file. It has deliberately unnormalised characters in it.
use v5.10;
use strict;
use warnings;
use utf8;
use if $^V ge v5.12.0, feature => 'unicode_strings';

use Test::More tests => 56;

use ok 'Locale::CLDR';

my $locale = Locale::CLDR->new('ca_FR_u_ca_islamic');

my $months = $locale->month_format_wide();
is_deeply ($months, [ 'Muharram', 'Safar', "Rabiʻ I", 'Rabiʻ II', 'Jumada I', 'Jumada II', 'Rajab', "Shaʻban", 'Ramadan', 'Shawwal', "Dhuʻl-Qiʻdah", "Dhuʻl-Hijjah" ], 'Islamic Month format wide');
$months = $locale->month_format_abbreviated();
is_deeply ($months, [ 'Muh.', 'Saf.', "Rab. I", 'Rab. II', 'Jum. I', 'Jum. II', 'Raj.', "Sha.", 'Ram.', 'Shaw.', "Dhuʻl-Q.", "Dhuʻl-H." ], 'Islamic Month format abbreviated');
$months = $locale->month_format_narrow();
is_deeply ($months, [qw( 1 2 3 4 5 6 7 8 9 10 11 12 )], 'Islamic Month format narrow');
$months = $locale->month_stand_alone_wide();
is_deeply ($months, ['Muharram', 'Safar', "Rabiʻ I", 'Rabiʻ II', 'Jumada I', 'Jumada II', 'Rajab', "Shaʻban", 'Ramadan', 'Shawwal', "Dhuʻl-Qiʻdah", "Dhuʻl-Hijjah"], 'Islamic Month stand alone wide');
$months = $locale->month_stand_alone_abbreviated();
is_deeply ($months, [ 'Muh.', 'Saf.', "Rab. I", 'Rab. II', 'Jum. I', 'Jum. II', 'Raj.', "Sha.", 'Ram.', 'Shaw.', "Dhuʻl-Q.", "Dhuʻl-H."], 'Islamic Month stand alone abbreviated');
$months = $locale->month_stand_alone_narrow();
is_deeply ($months, [qw( 1 2 3 4 5 6 7 8 9 10 11 12 )], 'Islamic Month stand alone narrow');

my $days = $locale->day_format_wide();
is_deeply ($days, [qw( dilluns dimarts dimecres dijous divendres dissabte diumenge )], 'Islamic Day format wide');
$days = $locale->day_format_abbreviated();
is_deeply ($days, [qw( dl. dt. dc. dj. dv. ds. dg. )], 'Islamic Day format abbreviated');
$days = $locale->day_format_narrow();
is_deeply ($days, [qw( dl dt dc dj dv ds dg )], 'Islamic Day format narrow');
$days = $locale->day_stand_alone_wide();
is_deeply ($days, [qw( dilluns dimarts dimecres dijous divendres dissabte diumenge )], 'Islamic Day stand alone wide');
$days = $locale->day_stand_alone_abbreviated();
is_deeply ($days, [qw( dl. dt. dc. dj. dv. ds. dg. )], 'Islamic Day stand alone abbreviated');
$days = $locale->day_stand_alone_narrow();
is_deeply ($days, [qw( dl dt dc dj dv ds dg )], 'Islamic Day stand alone narrow');

my $quarters = $locale->quarter_format_wide();
is_deeply ($quarters, [ '1r trimestre', '2n trimestre', '3r trimestre', '4t trimestre' ], 'Islamic Quarter format wide');
$quarters = $locale->quarter_format_abbreviated();
is_deeply ($quarters, [ qw( 1T 2T 3T 4T ) ], 'Islamic Quarter format abbreviated');
$quarters = $locale->quarter_format_narrow();
is_deeply ($quarters, [qw( 1 2 3 4 )], 'Islamic Quarter format narrow');
$quarters = $locale->quarter_stand_alone_wide();
is_deeply ($quarters, [ '1r trimestre', '2n trimestre', '3r trimestre', '4t trimestre' ], 'Islamic Quarter stand alone wide');
$quarters = $locale->quarter_stand_alone_abbreviated();
is_deeply ($quarters, [ qw( 1T 2T 3T 4T ) ], 'Islamic Quarter stand alone abbreviated');
$quarters = $locale->quarter_stand_alone_narrow();
is_deeply ($quarters, [qw( 1 2 3 4 )], 'Islamic Quarter stand alone narrow');

my $am_pm = $locale->am_pm_wide();
is_deeply ($am_pm, [ 'a. m.', 'p. m.' ], 'Islamic AM PM wide');
$am_pm = $locale->am_pm_abbreviated();
is_deeply ($am_pm, [ 'a. m.', 'p. m.' ], 'Islamic AM PM abbreviated');
$am_pm = $locale->am_pm_narrow();
is_deeply ($am_pm, [ 'a. m.', 'p. m.' ], 'Islamic AM PM narrow');
$am_pm = $locale->am_pm_format_wide();
is_deeply ($am_pm, { am => 'a. m.', pm => 'p. m.', morning1 => 'matinada', morning2 => 'matí', afternoon1 => 'migdia', afternoon2 => 'tarda', evening1 => 'vespre', night1 => 'nit', midnight => 'mitjanit' }, 'Islamic AM PM format wide');
$am_pm = $locale->am_pm_format_abbreviated();
is_deeply ($am_pm, { am => 'a. m.', pm => 'p. m.', morning1 => 'matinada', morning2 => 'matí', afternoon1 => 'migdia', afternoon2 => 'tarda', evening1 => 'vespre', night1 => 'nit', midnight => 'mitjanit' }, 'Islamic AM PM format abbreviated');
$am_pm = $locale->am_pm_format_narrow();
is_deeply ($am_pm, { am => 'a. m.', pm => 'p. m.', morning1 => 'mat.', morning2 => 'matí', afternoon1 => 'md', afternoon2 => 'tarda', evening1 => 'vespre', night1 => 'nit', midnight => 'mitjanit' }, 'Islamic AM PM format narrow');
$am_pm = $locale->am_pm_stand_alone_wide();
is_deeply ($am_pm, { am => 'a. m.', pm => 'p. m.', morning1 => 'matinada', morning2 => 'matí', afternoon1 => 'migdia', afternoon2 => 'tarda', evening1 => 'vespre', night1 => 'nit', midnight => 'mitjanit' }, 'Islamic AM PM stand alone wide');
$am_pm = $locale->am_pm_stand_alone_abbreviated();
is_deeply ($am_pm, { am => 'a. m.', pm => 'p. m.', morning1 => 'matinada', morning2 => 'matí', afternoon1 => 'migdia', afternoon2 => 'tarda', evening1 => 'vespre', night1 => 'nit', midnight => 'mitjanit' }, 'Islamic AM PM stand alone abbreviated');
$am_pm = $locale->am_pm_stand_alone_narrow();
is_deeply ($am_pm, { am => 'a. m.', pm => 'p. m.', morning1 => 'matinada', morning2 => 'matí', afternoon1 => 'migdia', afternoon2 => 'tarda', evening1 => 'vespre', night1 => 'nit', midnight => 'mitjanit' }, 'Islamic AM PM stand alone narrow');

my $era = $locale->era_wide();
is_deeply ($era, [ 'AH', undef() ], 'Islamic Era wide');
$era = $locale->era_abbreviated();
is_deeply ($era, [ 'AH', undef() ], 'Islamic Era abbreviated');
$era = $locale->era_narrow();
is_deeply ($era, [ 'AH', undef() ], 'Islamic Era narrow');
$era = $locale->era_format_wide();
is_deeply ($era, [ 'AH'], 'Islamic Era format wide');
$era = $locale->era_format_abbreviated();
is_deeply ($era, [ 'AH' ], 'Islamic Era format abbreviated');
$era = $locale->era_format_narrow();
is_deeply ($era, [ 'AH' ], 'Islamic Era format narrow');
$era = $locale->era_stand_alone_wide();
is_deeply ($era, [ 'AH' ], 'Islamic Era stand alone wide');
$era = $locale->era_stand_alone_abbreviated();
is_deeply ($era, [ 'AH' ], 'Islamic Era stand alone abbreviated');
$era = $locale->era_stand_alone_narrow();
is_deeply ($era, [ 'AH' ], 'Islamic Era stand alone narrow');

my $day_period_data = $locale->get_day_period('0000');
is($day_period_data, 'mitjanit', 'Islamic Day period data AM');
$day_period_data = $locale->get_day_period('1200');
is($day_period_data, 'migdia', 'Islamic Day period data Noon');
$day_period_data = $locale->get_day_period('1800');
is($day_period_data, 'tarda', 'Islamic Day period data PM');

my $date_format = $locale->date_format_full;
is($date_format, "EEEE, d MMMM 'de' y", 'Islamic Date Format Full');
$date_format = $locale->date_format_long;
is($date_format, "d MMMM 'de' y", 'Islamic Date Format Long');
$date_format = $locale->date_format_medium;
is($date_format, 'd MMM y', 'Islamic Date Format Medium');
$date_format = $locale->date_format_short;
is($date_format, 'd/M/yy', 'Islamic Date Format Short');

my $time_format = $locale->time_format_full;
is($time_format, 'H:mm:ss zzzz', 'Islamic Time Format Full');
$time_format = $locale->time_format_long;
is($time_format, 'H:mm:ss z', 'Islamic Time Format Long');
$time_format = $locale->time_format_medium;
is($time_format, 'H:mm:ss', 'Islamic Time Format Medium');
$time_format = $locale->time_format_short;
is($time_format, 'H:mm', 'Islamic Time Format Short');

my $date_time_format = $locale->datetime_format_full;
is($date_time_format, "EEEE, d MMMM 'de' y 'a' 'les' H:mm:ss zzzz", 'Islamic Date Time Format Full');
$date_time_format = $locale->datetime_format_long;
is($date_time_format, "d MMMM 'de' y 'a' 'les' H:mm:ss z", 'Islamic Date Time Format Long');
$date_time_format = $locale->datetime_format_medium;
is($date_time_format, 'd MMM y, H:mm:ss', 'Islamic Date Time Format Medium');
$date_time_format = $locale->datetime_format_short;
is($date_time_format, 'd/M/yy, H:mm', 'Islamic Date Time Format Short');

is ($locale->prefers_24_hour_time(), 1, 'Islamic Prefers 24 hour time');
is ($locale->first_day_of_week(), 1, 'Islamic First day of week');

# Number Overrides
$locale = Locale::CLDR->new('ca_FR_u_numbers_roman');
is_deeply([$locale->get_digits], [qw( 0 1 2 3 4 5 6 7 8 9 )], 'Get digits Roman');
is($locale->format_number(12345, '#,####,00'), "ↂMMCCCXLV", 'Format Roman override');
