#!perl

use Test::More tests => 1;

use Math::Spline;
my @x = (1,2,3);
my @y = (1,2,3);
my $x = 1.5;
my $spline = Math::Spline->new(\@x,\@y);
my $y_interp=$spline->evaluate($x);
ok(defined($y_interp));