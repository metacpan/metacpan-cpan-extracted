#!perl -T

use 5.010;
use strict;
use warnings;
use Test::More 0.98;

use DateTime;
use DateTimeX::strftimeq;
#use POSIX 'strftime';

my @localtime = (30, 9, 11, 19, 10, 119, 2, 322, 0); #"Tue Nov 19 11:09:30 2019"
my $dt = DateTime->new(
    year   => $localtime[5]+1900,
    month  => $localtime[4]+1,
    day    => $localtime[3],
    hour   => $localtime[2],
    minute => $localtime[1],
    second => $localtime[0],
);

my @tests = (
    ['<%%>', "<%>"],
    ['%Y-%m-%d', "2019-11-19"],
    #['%5Y-%3m-%-3d', "02019-011- 19"], # commented-out because unsupported in some platforms e.g. freebsd?
    ['%Y-%m-%d<%( 1+1 )q>', "2019-11-19<2>"],
    ['%Y-%m-%d<%( $_->day_of_week == 7 ? "sun":"" )q>', "2019-11-19<>"],
    ['%Y-%m-%d<%( $_->day_of_week == 2 ? "tue":"" )q>', "2019-11-19<tue>"],
);

for my $test (@tests) {
    my ($fmt, $res) = @$test;
    is(strftimeq($fmt, @localtime), $res, "$fmt = $res (ints args)");
    is(strftimeq($fmt, $dt), $res, "$fmt = $res (dt arg)");
}

DONE_TESTING:
done_testing;
