#!/usr/bin/perl
# Do not normalise this test file. It has deliberately unnormalised characters in it.
use v5.10;
use strict;
use warnings;
use utf8;
use if $^V ge v5.12.0, feature => 'unicode_strings';
 
use Test::More tests => 4;
use Test::Exception;
 
use ok 'Locale::CLDR';
 
use DateTime;
 
my $locale = Locale::CLDR->new('ru_RU');
 
my $dt_ru_summer_morning = DateTime->new(
        year => 2015,
        month => 07,
        day        => 14,
    hour       => 7,
    minute     => 15,
    second     => 47,
    locale         => $locale,
        time_zone  => 'Europe/Moscow',
);
my $dt_ru_summer_evening = DateTime->new(
        year => 2015,
        month => 07,
        day        => 14,
    hour       => 17,
    minute     => 15,
    second     => 47,
    locale         => $locale,
        time_zone  => 'Europe/Moscow',
);
my $dt_ru_winter_evening = DateTime->new(
        year => 2015,
        month => 12,
        day        => 15,
    hour       => 17,
    minute     => 15,
    second     => 47,
    locale         => $locale,
        time_zone  => 'Europe/Moscow',
);
is ($dt_ru_summer_morning->format_cldr($locale->datetime_format_full), 'вторник, 14 июля 2015 г., 07:15:47 Europe/Moscow', 'Date Time Format Russian: summer, morning');
is ($dt_ru_summer_evening->format_cldr($locale->datetime_format_full), 'вторник, 14 июля 2015 г., 17:15:47 Europe/Moscow', 'Date Time Format Russian: summer, evening');
is ($dt_ru_winter_evening->format_cldr($locale->datetime_format_full), 'вторник, 15 декабря 2015 г., 17:15:47 Europe/Moscow', 'Date Time Format Russian: winter, evening');
