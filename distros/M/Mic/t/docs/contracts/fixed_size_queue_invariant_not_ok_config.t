use strict;
use File::Temp qw/ tempfile /;
use Test::Lib;
use Test::Most;

BEGIN { 
    my ($fh, $filename) = tempfile();
    print $fh <<CONFIG;
[Example::Contracts::BoundedQueue]
invariant = on
pre = off
CONFIG
    $ENV{MIC_CONTRACTS} = $filename;
}

use Mic::Bind 'Example::Contracts::BoundedQueue' => 'Example::Contracts::Acme::BoundedQueue_v5';
use Example::Contracts::BoundedQueue;

my $q = Example::Contracts::BoundedQueue::->new({max_size => 3});

$q->push($_) for 1 .. 3;
is $q->size => 3;

throws_ok { $q->push($_) for 4 .. 6 } qr/Invariant 'max_size_not_exceeded' violated/;
done_testing();
