use strict;
use Test::Lib;
use Test::More;
use Example::Delegates::BoundedQueue_v2;

my $q = Example::Delegates::BoundedQueue_v2::->new({max_size => 3});

$q->push($_) for 1 .. 3;
is $q->q_size => 3;

$q->push($_) for 4 .. 6;
is $q->q_size => 3;
is $q->q_pop => 4;
done_testing();
