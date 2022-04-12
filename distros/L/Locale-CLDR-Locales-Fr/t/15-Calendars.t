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

my $locale = Locale::CLDR->new('fr_FR');
my $months = $locale->month_format_wide();
is_deeply ($months, [qw( janvier février mars avril mai juin juillet août septembre octobre novembre décembre )], 'Month format wide');
$months = $locale->month_format_abbreviated();
is_deeply ($months, [qw( janv. févr. mars avr. mai juin juil. août sept. oct. nov. déc. )], 'Month format abbreviated');
$months = $locale->month_format_narrow();
is_deeply ($months, [qw( J F M A M J J A S O N D )], 'Month format narrow');
$months = $locale->month_stand_alone_wide();
is_deeply ($months, [qw( janvier février mars avril mai juin juillet août septembre octobre novembre décembre )], 'Month stand alone wide');
$months = $locale->month_stand_alone_abbreviated();
is_deeply ($months, [qw( janv. févr. mars avr. mai juin juil. août sept. oct. nov. déc. )], 'Month stand alone abbreviated');
$months = $locale->month_stand_alone_narrow();
is_deeply ($months, [qw( J F M A M J J A S O N D )], 'Month stand alone narrow');

my $days = $locale->day_format_wide();
is_deeply ($days, [qw( lundi mardi mercredi jeudi vendredi samedi dimanche )], 'Day format wide');
$days = $locale->day_format_abbreviated();
is_deeply ($days, [qw( lun. mar. mer. jeu. ven. sam. dim. )], 'Day format abbreviated');
$days = $locale->day_format_narrow();
is_deeply ($days, [qw( L M M J V S D )], 'Day format narrow');
$days = $locale->day_stand_alone_wide();
is_deeply ($days, [qw( lundi mardi mercredi jeudi vendredi samedi dimanche )], 'Day stand alone wide');
$days = $locale->day_stand_alone_abbreviated();
is_deeply ($days, [qw( lun. mar. mer. jeu. ven. sam. dim. )], 'Day stand alone abbreviated');
$days = $locale->day_stand_alone_narrow();
is_deeply ($days, [qw( L M M J V S D )], 'Day stand alone narrow');

my $quarters = $locale->quarter_format_wide();
is_deeply ($quarters, ['1er trimestre', '2e trimestre', '3e trimestre', '4e trimestre'], 'Quarter format wide');
$quarters = $locale->quarter_format_abbreviated();
is_deeply ($quarters, [qw( T1 T2 T3 T4 )], 'Quarter format abbreviated');
$quarters = $locale->quarter_format_narrow();
is_deeply ($quarters, [qw( 1 2 3 4 )], 'Quarter format narrow');
$quarters = $locale->quarter_stand_alone_wide();
is_deeply ($quarters, [ '1er trimestre', '2e trimestre', '3e trimestre', '4e trimestre' ], 'Quarter stand alone wide');
$quarters = $locale->quarter_stand_alone_abbreviated();
is_deeply ($quarters, [qw( T1 T2 T3 T4 )], 'Quarter stand alone abbreviated');
$quarters = $locale->quarter_stand_alone_narrow();
is_deeply ($quarters, [qw( 1 2 3 4 )], 'Quarter stand alone narrow');

my $am_pm = $locale->am_pm_wide();
is_deeply ($am_pm, [qw( AM PM )], 'AM PM wide');
$am_pm = $locale->am_pm_abbreviated();
is_deeply ($am_pm, [qw( AM PM )], 'AM PM abbreviated');
$am_pm = $locale->am_pm_narrow();
is_deeply ($am_pm, [qw( AM PM )], 'AM PM narrow');
$am_pm = $locale->am_pm_format_wide();
is_deeply ($am_pm, { am => q{AM}, noon => q{midi}, pm => q{PM}, morning1 => q{du matin}, afternoon1 => q{de l’après-midi}, evening1 => q{du soir}, night1 => q{du matin}, midnight => q{minuit} }, 'AM PM format wide');
$am_pm = $locale->am_pm_format_abbreviated();
is_deeply ($am_pm, { am => q{AM}, noon => q{midi},  pm => q{PM}, morning1 => q{mat.}, afternoon1 => q{ap.m.}, evening1 => q{soir}, night1 => q{nuit}, midnight => q{minuit} }, 'AM PM format abbreviated');
$am_pm = $locale->am_pm_format_narrow();
is_deeply ($am_pm, { am => q{AM}, noon => q{midi}, pm => q{PM}, morning1 => q{mat.}, afternoon1 => q{ap.m.}, evening1 => q{soir}, night1 => q{nuit}, midnight => q{minuit} }, 'AM PM format narrow');
$am_pm = $locale->am_pm_stand_alone_wide();
is_deeply ($am_pm, { am => q{AM}, noon => q{midi}, pm => q{PM}, morning1 => q{matin}, afternoon1 => q{après-midi}, evening1 => q{soir}, night1 => q{nuit}, midnight => q{minuit} }, 'AM PM stand alone wide');
$am_pm = $locale->am_pm_stand_alone_abbreviated();
is_deeply ($am_pm, { am => q{AM}, noon => q{midi}, pm => q{PM}, morning1 => q{mat.}, afternoon1 => q{ap.m.}, evening1 => q{soir}, night1 => q{nuit}, midnight => q{minuit} }, 'AM PM stand alone abbreviated');
$am_pm = $locale->am_pm_stand_alone_narrow();
is_deeply ($am_pm, { am => q{AM}, noon => q{midi}, pm => q{PM}, morning1 => q{mat.}, afternoon1 => q{ap.m.}, evening1 => q{soir}, night1 => q{nuit}, midnight => q{minuit} }, 'AM PM stand alone narrow');

my $era = $locale->era_wide();
is_deeply ($era, ['avant Jésus-Christ', 'après Jésus-Christ'], 'Era wide');
$era = $locale->era_abbreviated();
is_deeply ($era, [ 'av. J.-C.', 'ap. J.-C.' ], 'Era abbreviated');
$era = $locale->era_narrow();
is_deeply ($era, [ 'av. J.-C.', 'ap. J.-C.' ], 'Era narrow');
$era = $locale->era_format_wide();
is_deeply ($era, ['avant Jésus-Christ', 'après Jésus-Christ' ], 'Era format wide');
$era = $locale->era_format_abbreviated();
is_deeply ($era, [ 'av. J.-C.', 'ap. J.-C.' ], 'Era format abbreviated');
$era = $locale->era_format_narrow();
is_deeply ($era, [ 'av. J.-C.', 'ap. J.-C.' ], 'Era format narrow');
$era = $locale->era_stand_alone_wide();
is_deeply ($era, ['avant Jésus-Christ', 'après Jésus-Christ'], 'Era stand alone wide');
$era = $locale->era_stand_alone_abbreviated();
is_deeply ($era, ['av. J.-C.', 'ap. J.-C.'], 'Era stand alone abbreviated');
$era = $locale->era_stand_alone_narrow();
is_deeply ($era, [ 'av. J.-C.', 'ap. J.-C.' ], 'Era stand alone narrow');

my $day_period_data = $locale->get_day_period('0000');
is($day_period_data, 'minuit', 'Day period data AM');
$day_period_data = $locale->get_day_period('1200');
is($day_period_data, 'midi', 'Day period data Noon');
$day_period_data = $locale->get_day_period('1210');
is($day_period_data, 'ap.m.', 'Day period data PM');

my $date_format = $locale->date_format_full;
is($date_format, 'EEEE d MMMM y', 'Date Format Full');
$date_format = $locale->date_format_long;
is($date_format, 'd MMMM y', 'Date Format Long');
$date_format = $locale->date_format_medium;
is($date_format, 'd MMM y', 'Date Format Medium');
$date_format = $locale->date_format_short;
is($date_format, 'dd/MM/y', 'Date Format Short');

my $time_format = $locale->time_format_full;
is($time_format, 'HH:mm:ss zzzz', 'Time Format Full');
$time_format = $locale->time_format_long;
is($time_format, 'HH:mm:ss z', 'Time Format Long');
$time_format = $locale->time_format_medium;
is($time_format, 'HH:mm:ss', 'Time Format Medium');
$time_format = $locale->time_format_short;
is($time_format, 'HH:mm', 'Time Format Short');

my $date_time_format = $locale->datetime_format_full;
is($date_time_format, "EEEE d MMMM y 'à' HH:mm:ss zzzz", 'Date Time Format Full');
$date_time_format = $locale->datetime_format_long;
is($date_time_format, "d MMMM y 'à' HH:mm:ss z", 'Date Time Format Long');
$date_time_format = $locale->datetime_format_medium;
is($date_time_format, "d MMM y 'à' HH:mm:ss", 'Date Time Format Medium');
$date_time_format = $locale->datetime_format_short;
is($date_time_format, 'dd/MM/y HH:mm', 'Date Time Format Short');

is ($locale->prefers_24_hour_time(), 1, 'Prefers 24 hour time');
is ($locale->first_day_of_week(), 1, 'First day of week recoded for DateTime');

is($locale->era_boundry( gregorian => -12 ), 0, 'Gregorian era');
is($locale->era_boundry( japanese => 9610217 ), 38, 'Japanese era');

is($locale->week_data_min_days(), 4, 'Number of days a week must have in FR before it counts as the first week of a year');
is($locale->week_data_first_day(), 'mon', 'First day of the week in FR when displaying calendars');
is($locale->week_data_weekend_start(), 'sat', 'First day of the week end in FR');
is($locale->week_data_weekend_end(), 'sun', 'Last day of the week end in FR');


# Overrides for week data
$locale=Locale::CLDR->new('fr_FR_u_fw_thu');
is($locale->week_data_first_day(), 'thu', 'Override first day of the week in france when displaying calendars');