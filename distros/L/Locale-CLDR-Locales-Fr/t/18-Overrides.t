#!/usr/bin/perl
# Do not normalise this test file. It has deliberately unnormalised characters in it.
use v5.10;
use strict;
use warnings;
use utf8;
use if $^V ge v5.12.0, feature => 'unicode_strings';

use Test::More tests => 56;

use ok 'Locale::CLDR';

my $locale = Locale::CLDR->new('fr_FR_u_ca_islamic');

my $months = $locale->month_format_wide();
is_deeply ($months, [ 'mouharram', 'safar', "rabia al awal", 'rabia ath-thani', 'joumada al oula', 'joumada ath-thania', 'rajab', 'chaabane', 'ramadan', 'chawwal', 'dhou al qi`da', 'dhou al-hijja' ], 'Islamic Month format wide');
$months = $locale->month_format_abbreviated();
is_deeply ($months, [ 'mouh.', 'saf.', 'rab. aw.', 'rab. th.', 'joum. oul.', 'joum. tha.', 'raj.', 'chaa.', 'ram.', 'chaw.', 'dhou. q.', 'dhou. h.' ], 'Islamic Month format abbreviated');
$months = $locale->month_format_narrow();
is_deeply ($months, [qw( 1 2 3 4 5 6 7 8 9 10 11 12 )], 'Islamic Month format narrow');
$months = $locale->month_stand_alone_wide();
is_deeply ($months, ['mouharram', 'safar', "rabia al awal", 'rabia ath-thani', 'joumada al oula', 'joumada ath-thania', 'rajab', 'chaabane', 'ramadan', 'chawwal', 'dhou al qi`da', 'dhou al-hijja'], 'Islamic Month stand alone wide');
$months = $locale->month_stand_alone_abbreviated();
is_deeply ($months, [ 'mouh.', 'saf.', 'rab. aw.', 'rab. th.', 'joum. ou.', 'joum. th.', 'raj.', 'chaa.', 'ram.', 'chaw.', 'dhou. qi.', 'dhou. hi.' ], 'Islamic Month stand alone abbreviated');
$months = $locale->month_stand_alone_narrow();
is_deeply ($months, [qw( 1 2 3 4 5 6 7 8 9 10 11 12 )], 'Islamic Month stand alone narrow');

my $days = $locale->day_format_wide();
is_deeply ($days, [qw( lundi mardi mercredi jeudi vendredi samedi dimanche )], 'Islamic Day format wide');
$days = $locale->day_format_abbreviated();
is_deeply ($days, [qw( lun. mar. mer. jeu. ven. sam. dim. )], 'Islamic Day format abbreviated');
$days = $locale->day_format_narrow();
is_deeply ($days, [qw( L M M J V S D )], 'Islamic Day format narrow');
$days = $locale->day_stand_alone_wide();
is_deeply ($days, [qw( lundi mardi mercredi jeudi vendredi samedi dimanche )], 'Islamic Day stand alone wide');
$days = $locale->day_stand_alone_abbreviated();
is_deeply ($days, [qw( lun. mar. mer. jeu. ven. sam. dim. )], 'Islamic Day stand alone abbreviated');
$days = $locale->day_stand_alone_narrow();
is_deeply ($days, [qw( L M M J V S D )], 'Islamic Day stand alone narrow');

my $quarters = $locale->quarter_format_wide();
is_deeply ($quarters, [ '1er trimestre', '2e trimestre', '3e trimestre', '4e trimestre' ], 'Islamic Quarter format wide');
$quarters = $locale->quarter_format_abbreviated();
is_deeply ($quarters, [ qw( T1 T2 T3 T4) ], 'Islamic Quarter format abbreviated');
$quarters = $locale->quarter_format_narrow();
is_deeply ($quarters, [qw( 1 2 3 4 )], 'Islamic Quarter format narrow');
$quarters = $locale->quarter_stand_alone_wide();
is_deeply ($quarters, [ '1er trimestre', '2e trimestre', '3e trimestre', '4e trimestre' ], 'Islamic Quarter stand alone wide');
$quarters = $locale->quarter_stand_alone_abbreviated();
is_deeply ($quarters, [ qw( T1 T2 T3 T4 ) ], 'Islamic Quarter stand alone abbreviated');
$quarters = $locale->quarter_stand_alone_narrow();
is_deeply ($quarters, [qw( 1 2 3 4 )], 'Islamic Quarter stand alone narrow');

my $am_pm = $locale->am_pm_wide();
is_deeply ($am_pm, [qw( AM PM )], 'Islamic AM PM wide');
$am_pm = $locale->am_pm_abbreviated();
is_deeply ($am_pm, [qw( AM PM )], 'Islamic AM PM abbreviated');
$am_pm = $locale->am_pm_narrow();
is_deeply ($am_pm, [qw( AM PM )], 'Islamic AM PM narrow');
$am_pm = $locale->am_pm_format_wide();
is_deeply ($am_pm, { am => q{AM}, noon => q{midi}, pm => q{PM}, morning1 => q{du matin}, afternoon1 => q{de l’après-midi}, evening1 => q{du soir}, night1 => q{du matin}, midnight => q{minuit} }, 'Islamic AM PM format wide');
$am_pm = $locale->am_pm_format_abbreviated();
is_deeply ($am_pm, { am => q{AM}, noon => q{midi},  pm => q{PM}, morning1 => q{mat.}, afternoon1 => q{ap.m.}, evening1 => q{soir}, night1 => q{nuit}, midnight => q{minuit} }, 'Islamic AM PM format abbreviated');
$am_pm = $locale->am_pm_format_narrow();
is_deeply ($am_pm, { am => q{AM}, noon => q{midi}, pm => q{PM}, morning1 => q{mat.}, afternoon1 => q{ap.m.}, evening1 => q{soir}, night1 => q{nuit}, midnight => q{minuit} }, 'Islamic AM PM format narrow');
$am_pm = $locale->am_pm_stand_alone_wide();
is_deeply ($am_pm, { am => q{AM}, noon => q{midi}, pm => q{PM}, morning1 => q{matin}, afternoon1 => q{après-midi}, evening1 => q{soir}, night1 => q{nuit}, midnight => q{minuit} }, 'Islamic AM PM stand alone wide');
$am_pm = $locale->am_pm_stand_alone_abbreviated();
is_deeply ($am_pm, { am => q{AM}, noon => q{midi}, pm => q{PM}, morning1 => q{mat.}, afternoon1 => q{ap.m.}, evening1 => q{soir}, night1 => q{nuit}, midnight => q{minuit} }, 'Islamic AM PM stand alone abbreviated');
$am_pm = $locale->am_pm_stand_alone_narrow();
is_deeply ($am_pm, { am => q{AM}, noon => q{midi}, pm => q{PM}, morning1 => q{mat.}, afternoon1 => q{ap.m.}, evening1 => q{soir}, night1 => q{nuit}, midnight => q{minuit} }, 'Islamic AM PM stand alone narrow');

my $era = $locale->era_wide();
is_deeply ($era, [ 'ère de l’Hégire', undef() ], 'Islamic Era wide');
$era = $locale->era_abbreviated();
is_deeply ($era, [ 'AH', undef() ], 'Islamic Era abbreviated');
$era = $locale->era_narrow();
is_deeply ($era, [ 'H', undef() ], 'Islamic Era narrow');
$era = $locale->era_format_wide();
is_deeply ($era, [ 'ère de l’Hégire'], 'Islamic Era format wide');
$era = $locale->era_format_abbreviated();
is_deeply ($era, [ 'AH' ], 'Islamic Era format abbreviated');
$era = $locale->era_format_narrow();
is_deeply ($era, [ 'H' ], 'Islamic Era format narrow');
$era = $locale->era_stand_alone_wide();
is_deeply ($era, [ 'ère de l’Hégire' ], 'Islamic Era stand alone wide');
$era = $locale->era_stand_alone_abbreviated();
is_deeply ($era, [ 'AH' ], 'Islamic Era stand alone abbreviated');
$era = $locale->era_stand_alone_narrow();
is_deeply ($era, [ 'H' ], 'Islamic Era stand alone narrow');

my $day_period_data = $locale->get_day_period('0000');
is($day_period_data, 'minuit', 'Islamic Day period data AM');
$day_period_data = $locale->get_day_period('1200');
is($day_period_data, 'midi', 'Islamic Day period data Noon');
$day_period_data = $locale->get_day_period('1210');
is($day_period_data, 'ap.m.', 'Islamic Day period data PM');

my $date_format = $locale->date_format_full;
is($date_format, 'EEEE d MMMM y G', 'Islamic Date Format Full');
$date_format = $locale->date_format_long;
is($date_format, 'd MMMM y G', 'Islamic Date Format Long');
$date_format = $locale->date_format_medium;
is($date_format, 'd MMM y G', 'Islamic Date Format Medium');
$date_format = $locale->date_format_short;
is($date_format, 'dd/MM/y GGGGG', 'Islamic Date Format Short');

my $time_format = $locale->time_format_full;
is($time_format, 'HH:mm:ss zzzz', 'Islamic Time Format Full');
$time_format = $locale->time_format_long;
is($time_format, 'HH:mm:ss z', 'Islamic Time Format Long');
$time_format = $locale->time_format_medium;
is($time_format, 'HH:mm:ss', 'Islamic Time Format Medium');
$time_format = $locale->time_format_short;
is($time_format, 'HH:mm', 'Islamic Time Format Short');

my $date_time_format = $locale->datetime_format_full;
is($date_time_format, "EEEE d MMMM y G 'à' HH:mm:ss zzzz", 'Islamic Date Time Format Full');
$date_time_format = $locale->datetime_format_long;
is($date_time_format, "d MMMM y G 'à' HH:mm:ss z", 'Islamic Date Time Format Long');
$date_time_format = $locale->datetime_format_medium;
is($date_time_format, 'd MMM y G HH:mm:ss', 'Islamic Date Time Format Medium');
$date_time_format = $locale->datetime_format_short;
is($date_time_format, 'dd/MM/y GGGGG HH:mm', 'Islamic Date Time Format Short');

is ($locale->prefers_24_hour_time(), 1, 'Islamic Prefers 24 hour time');
is ($locale->first_day_of_week(), 1, 'Islamic First day of week');

# Number Overrides
$locale = Locale::CLDR->new('fr_FR_u_numbers_roman');
is_deeply([$locale->get_digits], [qw( 0 1 2 3 4 5 6 7 8 9 )], 'Get digits Roman');
is($locale->format_number(12345, '#,####,00'), "ↂMMCCCXLV", 'Format Roman override');
