use strict;
use Test::Lib;
use Test::Most;
use Mic::Contracts 'Example::Contracts::BoundedQueue' => { post => 1 };
use Mic::Bind      'Example::Contracts::BoundedQueue' => 'Example::Contracts::Acme::BoundedQueue_v2';
use Example::Contracts::BoundedQueue;

my $q = Example::Contracts::BoundedQueue::->new({max_size => 3});

$q->push(1);
is $q->size => 1, 'non empty';
throws_ok { $q->pop } qr/Method 'pop' failed postcondition 'returns_old_head'/;
done_testing();
