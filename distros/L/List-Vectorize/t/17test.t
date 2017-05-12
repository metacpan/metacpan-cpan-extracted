use strict;
use warnings;
use Test::More tests => 2;

BEGIN { use_ok('List::Vectorize') }

my $x = [-5..5];
my $t = test($x, sub{$_[0] > 0});

is_deeply($t, [0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1]);
