#!/usr/bin/perl
# Do not normalise this test file. It has deliberately unnormalised characters in it.
use v5.10;
use strict;
use warnings;
use utf8;
use if $^V ge v5.12.0, feature => 'unicode_strings';

use Test::More tests => 58;
use Test::Exception;

use ok 'Locale::CLDR';

my $locale = Locale::CLDR->new('ca');
my $months = $locale->month_format_wide();
is_deeply ($months, ['de gener', 'de febrer', 'de març', 'd’abril', 'de maig', 'de juny', 'de juliol', 'd’agost', 'de setembre', 'd’octubre', 'de novembre', 'de desembre' ], 'Month format wide');
$months = $locale->month_format_abbreviated();
is_deeply ($months, [ 'de gen.', 'de febr.', 'de març', 'd’abr.', 'de maig', 'de juny', 'de jul.', 'd’ag.', 'de set.', 'd’oct.', 'de nov.', 'de des.' ], 'Month format abbreviated');
$months = $locale->month_format_narrow();
is_deeply ($months, [qw( GN FB MÇ AB MG JN JL AG ST OC NV DS )], 'Month format narrow');
$months = $locale->month_stand_alone_wide();
is_deeply ($months, [qw( gener febrer març abril maig juny juliol agost setembre octubre novembre desembre )], 'Month stand alone wide');
$months = $locale->month_stand_alone_abbreviated();
is_deeply ($months, [qw( gen. febr. març abr. maig juny jul. ag. set. oct. nov. des. )], 'Month stand alone abbreviated');
$months = $locale->month_stand_alone_narrow();
is_deeply ($months, [qw( GN FB MÇ AB MG JN JL AG ST OC NV DS )], 'Month stand alone narrow');

my $days = $locale->day_format_wide();
is_deeply ($days, [qw( dilluns dimarts dimecres dijous divendres dissabte diumenge )], 'Day format wide');
$days = $locale->day_format_abbreviated();
is_deeply ($days, [qw( dl. dt. dc. dj. dv. ds. dg. )], 'Day format abbreviated');
$days = $locale->day_format_narrow();
is_deeply ($days, [qw( dl dt dc dj dv ds dg )], 'Day format narrow');
$days = $locale->day_stand_alone_wide();
is_deeply ($days, [qw( dilluns dimarts dimecres dijous divendres dissabte diumenge )], 'Day stand alone wide');
$days = $locale->day_stand_alone_abbreviated();
is_deeply ($days, [qw( dl. dt. dc. dj. dv. ds. dg. )], 'Day stand alone abbreviated');
$days = $locale->day_stand_alone_narrow();
is_deeply ($days, [qw( dl dt dc dj dv ds dg )], 'Day stand alone narrow');

my $quarters = $locale->quarter_format_wide();
is_deeply ($quarters, ['1r trimestre', '2n trimestre', '3r trimestre', '4t trimestre'], 'Quarter format wide');
$quarters = $locale->quarter_format_abbreviated();
is_deeply ($quarters, [qw( 1T 2T 3T 4T )], 'Quarter format abbreviated');
$quarters = $locale->quarter_format_narrow();
is_deeply ($quarters, [qw( 1 2 3 4 )], 'Quarter format narrow');
$quarters = $locale->quarter_stand_alone_wide();
is_deeply ($quarters, [ '1r trimestre', '2n trimestre', '3r trimestre', '4t trimestre' ], 'Quarter stand alone wide');
$quarters = $locale->quarter_stand_alone_abbreviated();
is_deeply ($quarters, [qw( 1T 2T 3T 4T )], 'Quarter stand alone abbreviated');
$quarters = $locale->quarter_stand_alone_narrow();
is_deeply ($quarters, [qw( 1 2 3 4 )], 'Quarter stand alone narrow');

my $am_pm = $locale->am_pm_wide();
is_deeply ($am_pm, [ 'a. m.', 'p. m.' ], 'AM PM wide');
$am_pm = $locale->am_pm_abbreviated();
is_deeply ($am_pm, [ 'a. m.', 'p. m.' ], 'AM PM abbreviated');
$am_pm = $locale->am_pm_narrow();
is_deeply ($am_pm, [ 'a. m.', 'p. m.' ], 'AM PM narrow');
$am_pm = $locale->am_pm_format_wide();
is_deeply ($am_pm, { am => 'a. m.', pm => 'p. m.', morning1 => 'matinada', morning2 => 'matí', afternoon1 => 'migdia', afternoon2 => 'tarda', evening1 => 'vespre', night1 => 'nit', midnight => 'mitjanit' }, 'AM PM format wide');
$am_pm = $locale->am_pm_format_abbreviated();
is_deeply ($am_pm, { am => 'a. m.', pm => 'p. m.', morning1 => 'matinada', morning2 => 'matí', afternoon1 => 'migdia', afternoon2 => 'tarda', evening1 => 'vespre', night1 => 'nit', midnight => 'mitjanit' }, 'AM PM format abbreviated');
$am_pm = $locale->am_pm_format_narrow();
is_deeply ($am_pm, { am => 'a. m.', pm => 'p. m.', morning1 => 'mat.', morning2 => 'matí', afternoon1 => 'md', afternoon2 => 'tarda', evening1 => 'vespre', night1 => 'nit', midnight => 'mitjanit' }, 'AM PM format narrow');
$am_pm = $locale->am_pm_stand_alone_wide();
is_deeply ($am_pm, { am => 'a. m.', pm => 'p. m.', morning1 => 'matinada', morning2 => 'matí', afternoon1 => 'migdia', afternoon2 => 'tarda', evening1 => 'vespre', night1 => 'nit', midnight => 'mitjanit' }, 'AM PM stand alone wide');
$am_pm = $locale->am_pm_stand_alone_abbreviated();
is_deeply ($am_pm, { am => 'a. m.', pm => 'p. m.', morning1 => 'matinada', morning2 => 'matí', afternoon1 => 'migdia', afternoon2 => 'tarda', evening1 => 'vespre', night1 => 'nit', midnight => 'mitjanit' }, 'AM PM stand alone abbreviated');
$am_pm = $locale->am_pm_stand_alone_narrow();
is_deeply ($am_pm, { am => 'a. m.', pm => 'p. m.', morning1 => 'matinada', morning2 => 'matí', afternoon1 => 'migdia', afternoon2 => 'tarda', evening1 => 'vespre', night1 => 'nit', midnight => 'mitjanit' }, 'AM PM stand alone narrow');

my $era = $locale->era_wide();
is_deeply ($era, ['abans de Crist', 'després de Crist'], 'Era wide');
$era = $locale->era_abbreviated();
is_deeply ($era, [qw( aC dC )], 'Era abbreviated');
$era = $locale->era_narrow();
is_deeply ($era, [qw( aC dC )], 'Era narrow');
$era = $locale->era_format_wide();
is_deeply ($era, ['abans de Crist', 'després de Crist' ], 'Era format wide');
$era = $locale->era_format_abbreviated();
is_deeply ($era, ['aC', 'dC' ], 'Era format abbreviated');
$era = $locale->era_format_narrow();
is_deeply ($era, ['aC', 'dC' ], 'Era format narrow');
$era = $locale->era_stand_alone_wide();
is_deeply ($era, ['abans de Crist', 'després de Crist'], 'Era stand alone wide');
$era = $locale->era_stand_alone_abbreviated();
is_deeply ($era, ['aC', 'dC'], 'Era stand alone abbreviated');
$era = $locale->era_stand_alone_narrow();
is_deeply ($era, [ 'aC', 'dC' ], 'Era stand alone narrow');

=for comment
my $day_period_data = $locale->get_day_period('0000');
is($day_period_data, 'a. m.', 'Day period data AM');
$day_period_data = $locale->get_day_period('1200');
is($day_period_data, 'p. m.', 'Day period data Noon');
$day_period_data = $locale->get_day_period('1800');
is($day_period_data, 'p. m.', 'Day period data PM');
=cut

my $date_format = $locale->date_format_full;
is($date_format, "EEEE, d MMMM 'de' y", 'Date Format Full');
$date_format = $locale->date_format_long;
is($date_format, "d MMMM 'de' y", 'Date Format Long');
$date_format = $locale->date_format_medium;
is($date_format, 'd MMM y', 'Date Format Medium');
$date_format = $locale->date_format_short;
is($date_format, 'd/M/yy', 'Date Format Short');

my $time_format = $locale->time_format_full;
is($time_format, 'H:mm:ss zzzz', 'Time Format Full');
$time_format = $locale->time_format_long;
is($time_format, 'H:mm:ss z', 'Time Format Long');
$time_format = $locale->time_format_medium;
is($time_format, 'H:mm:ss', 'Time Format Medium');
$time_format = $locale->time_format_short;
is($time_format, 'H:mm', 'Time Format Short');

my $date_time_format = $locale->datetime_format_full;
is($date_time_format, "EEEE, d MMMM 'de' y 'a' 'les' H:mm:ss zzzz", 'Date Time Format Full');
$date_time_format = $locale->datetime_format_long;
is($date_time_format, "d MMMM 'de' y 'a' 'les' H:mm:ss z", 'Date Time Format Long');
$date_time_format = $locale->datetime_format_medium;
is($date_time_format, 'd MMM y, H:mm:ss', 'Date Time Format Medium');
$date_time_format = $locale->datetime_format_short;
is($date_time_format, 'd/M/yy H:mm', 'Date Time Format Short');

is ($locale->prefers_24_hour_time(), 1, 'Prefers 24 hour time');
is ($locale->first_day_of_week(), 1, 'First day of week recoded for DateTime');

is($locale->era_boundry( gregorian => -12 ), 0, 'Gregorian era');
is($locale->era_boundry( japanese => 9610217 ), 38, 'Japanese era');

is($locale->week_data_min_days(), 4, 'Number of days a week must have in Catalan before it counts as the first week of a year');
is($locale->week_data_first_day(), 'mon', 'First day of the week in Catalan when displaying calendars');
is($locale->week_data_weekend_start(), 'sat', 'First day of the week end in Catalan');
is($locale->week_data_weekend_end(), 'sun', 'Last day of the week end in Catalan');

# Overrides for week data
$locale=Locale::CLDR->new('ca_ES_u_fw_thu');
is($locale->week_data_first_day(), 'thu', 'Override first day of the week in spain when displaying calendars');