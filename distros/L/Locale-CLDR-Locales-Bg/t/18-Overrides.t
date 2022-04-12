#!/usr/bin/perl
# Do not normalise this test file. It has deliberately unnormalised characters in it.
use v5.10;
use strict;
use warnings;
use utf8;
use if $^V ge v5.12.0, feature => 'unicode_strings';

use Test::More tests => 19;

use ok 'Locale::CLDR';

my $locale = Locale::CLDR->new('bg_u_ca_islamic');

my $day_period_data = $locale->get_day_period('0000');
is($day_period_data, 'полунощ', 'Islamic Day period data AM');
$day_period_data = $locale->get_day_period('1200');
is($day_period_data, 'на обяд', 'Islamic Day period data Noon');
$day_period_data = $locale->get_day_period('1210');
is($day_period_data, 'на обяд', 'Islamic Day period data PM');

my $date_format = $locale->date_format_full;
is($date_format, q(EEEE, d MMMM y 'г'.), 'Islamic Date Format Full');
$date_format = $locale->date_format_long;
is($date_format, q(d MMMM y 'г'.), 'Islamic Date Format Long');
$date_format = $locale->date_format_medium;
is($date_format, q(d.MM.y 'г'.), 'Islamic Date Format Medium');
$date_format = $locale->date_format_short;
is($date_format, q(d.MM.yy 'г'.), 'Islamic Date Format Short');

my $time_format = $locale->time_format_full;
is($time_format, 'H:mm:ss \'ч\'. zzzz', 'Islamic Time Format Full');
$time_format = $locale->time_format_long;
is($time_format, 'H:mm:ss \'ч\'. z', 'Islamic Time Format Long');
$time_format = $locale->time_format_medium;
is($time_format, 'H:mm:ss \'ч\'.', 'Islamic Time Format Medium');
$time_format = $locale->time_format_short;
is($time_format, 'H:mm \'ч\'.', 'Islamic Time Format Short');

my $date_time_format = $locale->datetime_format_full;
is($date_time_format, q(EEEE, d MMMM y 'г'., H:mm:ss 'ч'. zzzz), 'Islamic Date Time Format Full');
$date_time_format = $locale->datetime_format_long;
is($date_time_format, q(d MMMM y 'г'., H:mm:ss 'ч'. z), 'Islamic Date Time Format Long');
$date_time_format = $locale->datetime_format_medium;
is($date_time_format, q(d.MM.y 'г'., H:mm:ss 'ч'.), 'Islamic Date Time Format Medium');
$date_time_format = $locale->datetime_format_short;
is($date_time_format, q(d.MM.yy 'г'., H:mm 'ч'.), 'Islamic Date Time Format Short');

is ($locale->prefers_24_hour_time(), 1, 'Islamic Prefers 24 hour time');
is ($locale->first_day_of_week(), 1, 'Islamic First day of week');

# Number Overrides
$locale = Locale::CLDR->new('bg_u_numbers_roman');
is($locale->format_number(12345, '#,####,00'), "ↂMMCCCXLV", 'Format Roman override');