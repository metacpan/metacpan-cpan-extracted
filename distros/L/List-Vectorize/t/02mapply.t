use strict;
use Test::More tests => 6;

BEGIN { use_ok('List::Vectorize') }

my $x = [1..5];
my $y = [6..10];
my $z = [11..15];

my $c = mapply($x, $y, sub{$_[0] + $_[1]});
my $d = mapply($x, $y, sub{scalar(@_)});
my $e = mapply($x, 1, sub {$_[0]+$_[1]});
my $f = mapply($x, 1, 2, sub {sum(\@_)});
my $g = mapply($x, $y, $z, 1, sub {sum(\@_)});

is_deeply($c, [7, 9, 11, 13, 15], 'on two arrays');
is_deeply($d, [2, 2, 2, 2, 2], 'on two arrays');
is_deeply($e, [2, 3, 4, 5, 6], 'on array and scalar');
is_deeply($f, [4, 5, 6, 7, 8], 'on array and scalars');
is_deeply($g, [19, 22, 25, 28, 31], 'on arrays and scalar');
