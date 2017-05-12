use strict;
use Test;
BEGIN { plan tests => 1 }

use Dunce::time;

my $t1 = time;
my $t2 = time + 100_000_000;

eval {
    my @str_compared = sort $t1, $t2;
};
ok($@);
