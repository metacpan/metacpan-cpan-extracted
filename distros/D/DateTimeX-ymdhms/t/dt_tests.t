#!/usr/bin/perl

use strict;
use warnings;
use Test::Most;

use DateTime;
use DateTimeX::ymdhms;

my $dt = DateTime->now;

my $d_check = sprintf "%s %s", $dt->ymd, $dt->hms;

is( $dt->ymdhms, $d_check, "ymdhms" );

my $d_check2 = sprintf "%s %02d:%02d", $dt->ymd, $dt->hour, $dt->minute;

is( $dt->ymdhm, $d_check2, "ymdhm" );

done_testing;
