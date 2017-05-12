#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use MVC::Neaf::Util qw(http_date);
use POSIX qw(strftime locale_h);

my $skip = 27 * 24 * 3600; # 27 days
my $times = 14; # 27 * 14 > 365 - guaranteed to hit all days & months

my $t0 = 1_000_000_000;


setlocale( LC_TIME, "C" );

for (1..$times) {
    my $t = $t0 + $skip * $_;
    my $real_date = strftime( "%a, %d %b %Y %H:%M:%S GMT", gmtime($t));
    is (http_date($t), $real_date, "Date ok ($real_date)");
};

done_testing;
