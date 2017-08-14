use strict;
use Test::Lib;
use Test::More;
use Mic::Contracts 'Example::Contracts::BoundedQueue' => { pre => 1 };
use Example::Contracts::BoundedQueue;

my $q = Example::Contracts::BoundedQueue::->new({max_size => 3});

$q->push($_) for 1 .. 3;
is $q->size => 3;

$q->push($_) for 4 .. 6;
is $q->size => 3;
is $q->pop => 4;
done_testing();
