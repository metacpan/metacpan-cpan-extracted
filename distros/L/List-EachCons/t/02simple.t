
use Test::More tests => 1;

use List::EachCons;
my @list = qw/a b c d/;
my @r = each_cons 3, @list, sub {
  \@_
};

is_deeply(\@r, [[qw/a b c/], [qw/b c d/]]);
