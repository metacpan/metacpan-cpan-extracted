use strict;
use Test::Lib;
use Test::Most;
use Example::Contracts::BoundedQueue;

my $q = Example::Contracts::BoundedQueue::->new({max_size => 3});

is $q->size => 0, 'is empty';
throws_ok { $q->pop } qr/Precondition 'not_empty' on 'pop', is not satisfied/;

throws_ok { my $q2 = Example::Contracts::BoundedQueue::->new({max_size => 'b'}) } 
  qr/Precondition 'positive_int_size' on 'new', is not satisfied/;

done_testing();
