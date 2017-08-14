use strict;
use Test::Lib;
use Test::Most;
use Mic::Contracts 'Example::Contracts::BoundedQueue' => { pre => 1 };
use Example::Contracts::BoundedQueue;

my $q = Example::Contracts::BoundedQueue::->new({max_size => 3});

is $q->size => 0, 'is empty';
throws_ok { $q->pop } qr/Method 'pop' failed precondition 'not_empty'/;

throws_ok { my $q2 = Example::Contracts::BoundedQueue::->new({max_size => 'b'}) } 
  qr/Method 'new' failed precondition 'positive_int_size'/;

done_testing();
