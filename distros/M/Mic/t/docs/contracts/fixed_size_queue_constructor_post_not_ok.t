use strict;
use Test::Lib;
use Test::Most;

use Mic::Contracts 'Example::Contracts::BoundedQueue' => { post => 1 };
use Mic::Bind      'Example::Contracts::BoundedQueue' => 'Example::Contracts::Acme::BoundedQueue_v6';
use Example::Contracts::BoundedQueue;

throws_ok { 
    my $q = Example::Contracts::BoundedQueue::->new({max_size => 3});
} 
qr/Method 'new' failed postcondition 'zero_sized'/;
done_testing();
