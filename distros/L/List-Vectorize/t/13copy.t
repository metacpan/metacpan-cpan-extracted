use strict;
use warnings;
use Test::More tests => 7;

BEGIN { use_ok('List::Vectorize') }

my $x = [1..10];
my $y = copy($x);
is_deeply($y, $x);
$y->[0] = 100;
is_deeply($x, [1..10]);
is_deeply($y, [100, 2, 3, 4, 5, 6, 7, 8, 9, 10]);

$x = {a => 1, b => 2};
$y = copy($x);
is_deeply($y, $x);
$y->{a} = 100;
is_deeply($x, {a => 1, b => 2});
is_deeply($y, {a => 100, b => 2});