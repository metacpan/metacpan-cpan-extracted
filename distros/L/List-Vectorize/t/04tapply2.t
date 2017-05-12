use strict;
use Test::More;

eval 'use Test::Exception';

plan (skip_all => 'Test::Exception not installed') if ($@);

use List::Vectorize;

my $x = [1..10];
my $t1 = ["a", "a", "a", "a", "a", "b", "b", "b", "b", "b"];
my $t2 = [1,   0,   1,   0,   1,   0,   1,   0,   1,   0];
my $t3 = [1, 0];


eval qq` dies_ok {List::Vectorize::tapply(\$x, \$t1, \$t3, sub{sum(\\\@_)})} 'cannot be cycled' `;

done_testing();
