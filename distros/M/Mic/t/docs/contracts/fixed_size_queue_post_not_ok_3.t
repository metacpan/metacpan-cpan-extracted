use strict;
use Test::Lib;
use Test::Most;
use Mic::Contracts 'Example::Contracts::BoundedQueue' => { post => 1 };
use Mic::Bind      'Example::Contracts::BoundedQueue' => 'Example::Contracts::Acme::BoundedQueue_v4';
use Example::Contracts::BoundedQueue;

my $q = Example::Contracts::BoundedQueue::->new({max_size => 3});

throws_ok { $q->push(1) } qr/Method 'push' failed postcondition 'tail_updated'/;
done_testing();
