use strict;
use warnings;
use Test::More tests => 3;

BEGIN { use_ok('List::Vectorize') }

my $x = [1..10];
my $y = [2..11];
my $z = 10;

my $r1 = minus($x, $y);
my $r2 = minus($x, $y, $z);

is($r1->[1], -1);
is($r2->[1], -11);
