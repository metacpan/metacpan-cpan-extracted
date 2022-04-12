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

my $locale = Locale::CLDR->new('da_DK');
my $months = $locale->month_format_wide();
is_deeply ($months, [qw( januar februar marts april maj juni juli august september oktober november december )], 'Month format wide');
$months = $locale->month_format_abbreviated();
is_deeply ($months, [qw( jan. feb. mar. apr. maj jun. jul. aug. sep. okt. nov. dec. )], 'Month format abbreviated');
$months = $locale->month_format_narrow();
is_deeply ($months, [qw( J F M A M J J A S O N D )], 'Month format narrow');
$months = $locale->month_stand_alone_wide();
is_deeply ($months, [qw( januar februar marts april maj juni juli august september oktober november december )], 'Month stand alone wide');
$months = $locale->month_stand_alone_abbreviated();
is_deeply ($months, [qw( jan. feb. mar. apr. maj jun. jul. aug. sep. okt. nov. dec. )], 'Month stand alone abbreviated');
$months = $locale->month_stand_alone_narrow();
is_deeply ($months, [qw( J F M A M J J A S O N D )], 'Month stand alone narrow');

my $days = $locale->day_format_wide();
is_deeply ($days, [qw( mandag tirsdag onsdag torsdag fredag lørdag søndag )], 'Day format wide');
$days = $locale->day_format_abbreviated();
is_deeply ($days, [qw( man. tir. ons. tor. fre. lør. søn. )], 'Day format abbreviated');
$days = $locale->day_format_narrow();
is_deeply ($days, [qw( M T O T F L S )], 'Day format narrow');
$days = $locale->day_stand_alone_wide();
is_deeply ($days, [qw( mandag tirsdag onsdag torsdag fredag lørdag søndag )], 'Day stand alone wide');
$days = $locale->day_stand_alone_abbreviated();
is_deeply ($days, [qw( man tir ons tor fre lør søn )], 'Day stand alone abbreviated');
$days = $locale->day_stand_alone_narrow();
is_deeply ($days, [qw( M T O T F L S )], 'Day stand alone narrow');

my $quarters = $locale->quarter_format_wide();
is_deeply ($quarters, [ '1. kvartal', '2. kvartal', '3. kvartal', '4. kvartal' ], 'Quarter format wide');
$quarters = $locale->quarter_format_abbreviated();
is_deeply ($quarters, [ '1. kvt.', '2. kvt.', '3. kvt.', '4. kvt.' ], 'Quarter format abbreviated');
$quarters = $locale->quarter_format_narrow();
is_deeply ($quarters, [qw( 1 2 3 4 )], 'Quarter format narrow');
$quarters = $locale->quarter_stand_alone_wide();
is_deeply ($quarters, [ '1. kvartal', '2. kvartal', '3. kvartal', '4. kvartal' ], 'Quarter stand alone wide');
$quarters = $locale->quarter_stand_alone_abbreviated();
is_deeply ($quarters, [ '1. kvt.', '2. kvt.', '3. kvt.', '4. kvt.' ], 'Quarter stand alone abbreviated');
$quarters = $locale->quarter_stand_alone_narrow();
is_deeply ($quarters, [qw( 1 2 3 4 )], 'Quarter stand alone narrow');

my $am_pm = $locale->am_pm_wide();
is_deeply ($am_pm, [qw( AM PM )], 'AM PM wide');
$am_pm = $locale->am_pm_abbreviated();
is_deeply ($am_pm, [qw( AM PM )], 'AM PM abbreviated');
$am_pm = $locale->am_pm_narrow();
is_deeply ($am_pm, [qw( a p )], 'AM PM narrow');
$am_pm = $locale->am_pm_format_wide();
is_deeply ($am_pm, { midnight => 'midnat', morning1 => 'om morgenen', morning2 => 'om formiddagen', afternoon1 => 'om eftermiddagen', evening1 => 'om aftenen', night1 => 'om natten', am => 'AM', pm => 'PM' }, 'AM PM format wide');
$am_pm = $locale->am_pm_format_abbreviated();
is_deeply ($am_pm, { midnight => 'midnat', morning1 => 'om morgenen', morning2 => 'om formiddagen', afternoon1 => 'om eftermiddagen', evening1 => 'om aftenen', night1 => 'om natten', am => 'AM', pm => 'PM' }, 'AM PM format abbreviated');
$am_pm = $locale->am_pm_format_narrow();
is_deeply ($am_pm, { midnight => 'midnat', morning1 => 'om morgenen', morning2 => 'om formiddagen', afternoon1 => 'om eftermiddagen', evening1 => 'om aftenen', night1 => 'om natten', am => 'a', pm => 'p' }, 'AM PM format narrow');
$am_pm = $locale->am_pm_stand_alone_wide();
is_deeply ($am_pm, { midnight => 'midnat', morning1 => 'morgen', morning2 => 'formiddag', afternoon1 => 'eftermiddag', evening1 => 'aften', night1 => 'nat', am => 'AM', pm => 'PM' }, 'AM PM stand alone wide');
$am_pm = $locale->am_pm_stand_alone_abbreviated();
is_deeply ($am_pm, { midnight => 'midnat', morning1 => 'morgen', morning2 => 'formiddag', afternoon1 => 'eftermiddag', evening1 => 'aften', night1 => 'nat', am => 'AM', pm => 'PM' }, 'AM PM stand alone abbreviated');
$am_pm = $locale->am_pm_stand_alone_narrow();
is_deeply ($am_pm, { midnight => 'midnat', morning1 => 'morgen', morning2 => 'formiddag', afternoon1 => 'eftermiddag', evening1 => 'aften', night1 => 'nat', am => 'AM', pm => 'PM' }, 'AM PM stand alone narrow');

my $era = $locale->era_wide();
is_deeply ($era, ['f.Kr.', 'e.Kr.'], 'Era wide');
$era = $locale->era_abbreviated();
is_deeply ($era, [qw( f.Kr. e.Kr. )], 'Era abbreviated');
$era = $locale->era_narrow();
is_deeply ($era, [qw( fKr eKr )], 'Era narrow');
$era = $locale->era_format_wide();
is_deeply ($era, ['f.Kr.', 'e.Kr.' ], 'Era format wide');
$era = $locale->era_format_abbreviated();
is_deeply ($era, ['f.Kr.', 'e.Kr.' ], 'Era format abbreviated');
$era = $locale->era_format_narrow();
is_deeply ($era, ['fKr', 'eKr' ], 'Era format narrow');
$era = $locale->era_stand_alone_wide();
is_deeply ($era, ['f.Kr.', 'e.Kr.'], 'Era stand alone wide');
$era = $locale->era_stand_alone_abbreviated();
is_deeply ($era, ['f.Kr.', 'e.Kr.'], 'Era stand alone abbreviated');
$era = $locale->era_stand_alone_narrow();
is_deeply ($era, [ 'fKr', 'eKr' ], 'Era stand alone narrow');

my $day_period_data = $locale->get_day_period('0000');
is($day_period_data, 'midnat', 'Day period data AM');
$day_period_data = $locale->get_day_period('1200');
is($day_period_data, 'om eftermiddagen', 'Day period data Noon');
$day_period_data = $locale->get_day_period('1210');
is($day_period_data, 'om eftermiddagen', 'Day period data PM');

my $date_format = $locale->date_format_full;
is($date_format, "EEEE 'den' d. MMMM y", 'Date Format Full');
$date_format = $locale->date_format_long;
is($date_format, 'd. MMMM y', 'Date Format Long');
$date_format = $locale->date_format_medium;
is($date_format, 'd. MMM y', 'Date Format Medium');
$date_format = $locale->date_format_short;
is($date_format, 'dd.MM.y', 'Date Format Short');

my $time_format = $locale->time_format_full;
is($time_format, 'HH.mm.ss zzzz', 'Time Format Full');
$time_format = $locale->time_format_long;
is($time_format, 'HH.mm.ss z', 'Time Format Long');
$time_format = $locale->time_format_medium;
is($time_format, 'HH.mm.ss', 'Time Format Medium');
$time_format = $locale->time_format_short;
is($time_format, 'HH.mm', 'Time Format Short');

my $date_time_format = $locale->datetime_format_full;
is($date_time_format, "EEEE 'den' d. MMMM y 'kl'. HH.mm.ss zzzz", 'Date Time Format Full');
$date_time_format = $locale->datetime_format_long;
is($date_time_format, "d. MMMM y 'kl'. HH.mm.ss z", 'Date Time Format Long');
$date_time_format = $locale->datetime_format_medium;
is($date_time_format, 'd. MMM y HH.mm.ss', 'Date Time Format Medium');
$date_time_format = $locale->datetime_format_short;
is($date_time_format, 'dd.MM.y HH.mm', 'Date Time Format Short');

is ($locale->prefers_24_hour_time(), 1, 'Prefers 24 hour time');
is ($locale->first_day_of_week(), 1, 'First day of week recoded for DateTime');

is($locale->era_boundry( gregorian => -12 ), 0, 'Gregorian era');
is($locale->era_boundry( japanese => 9610217 ), 38, 'Japanese era');

is($locale->week_data_min_days(), 4, 'Number of days a week must have in DK before it counts as the first week of a year');
is($locale->week_data_first_day(), 'mon', 'First day of the week in DK when displaying calendars');
is($locale->week_data_weekend_start(), 'sat', 'First day of the week end in DK');
is($locale->week_data_weekend_end(), 'sun', 'Last day of the week end in DK');

# Overrides for week data
$locale=Locale::CLDR->new('da_DK_u_fw_thu');
is($locale->week_data_first_day(), 'thu', 'Override first day of the week in denmark when displaying calendars');