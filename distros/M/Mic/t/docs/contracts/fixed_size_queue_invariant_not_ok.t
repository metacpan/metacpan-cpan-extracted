use strict;
use Test::Lib;
use Test::Most;

use Mic::Contracts 'Example::Contracts::BoundedQueue' => { invariant => 1 };
use Mic::Bind      'Example::Contracts::BoundedQueue' => 'Example::Contracts::Acme::BoundedQueue_v5';
use Example::Contracts::BoundedQueue;

my $q = Example::Contracts::BoundedQueue::->new({max_size => 3});

$q->push($_) for 1 .. 3;
is $q->size => 3;

throws_ok { $q->push($_) for 4 .. 6 } qr/Invariant 'max_size_not_exceeded' violated/;
done_testing();
