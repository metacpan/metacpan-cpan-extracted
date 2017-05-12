#!/usr/bin/perl

# Formula from:
#   http://www.wolframalpha.com/input/?i=a(0)+%3D+0,a(1)%3D0,+a(2)%3D1,+a(n)+%3D+a(n-1)+%2B+a(n-2)+%2B+a(n-3)

use 5.014;
use warnings;

use lib qw(../lib);
use Math::AnyNum qw(:overload);

sub tribonacci {
    my ($n) = @_;

    my $m = 1 / 3;
    my $p = 2 / 3;
    my $a = (99 + 19 * sqrt(33));
    my $b = (19 + 3 * sqrt(33))**$m;
    my $c = (19 - 3 * sqrt(33))**$m;
    my $d = (4 * 33**$p);
    my $e = (33 * $a)**$m;
    my $f = $a**$m;
    my $g = (1 / 6) * $c;
    my $h = (1 / 6) * $b;
    my $j = i * sqrt(3);
    my $k = (1 - $j);
    my $l = (1 + $j);

#<<<
      (($k / $e - $l * $f / $d) * ($m - $g * $k - $h * $l)**$n)
    + (($l / $e - $k * $f / $d) * ($m - $g * $l - $h * $k)**$n)
    + (($f / (2 * 33**$p) - 2 / (33 * $a)**$m) * (3 / (1 + $b + $c))**(-$n));
#>>>
}

foreach my $n (2 .. 20) {
    say tribonacci($n);
}

say "Tribonacci constant: ", tribonacci(1e3 + 1) / tribonacci(1e3);
