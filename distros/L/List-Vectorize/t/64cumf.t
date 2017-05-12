use strict;
use warnings;
use Test::More tests => 4;

BEGIN { use_ok('List::Vectorize') }

my $x = [1..10];

my $c = cumf($x);

is_deeply($c, [1..10]);

$c = cumf($x, \&sum);
is_deeply($c, [1, 3, 6, 10, 15, 21, 28, 36, 45, 55]);

$c = cumf($x, sub{max($_[0])*sum($_[0])});
is_deeply($c, [1, 6, 18, 40, 75, 126, 196, 288, 405, 550]);
