# DNS error.
use warnings;
use strict;
use lib 't';
use share;


# cover code which process stale DNS replies on closed streams
IO::Stream->new({
    host        => 'no.such.host.q1w2e3',
    port        => 80,
    cb          => \&client,
    wait_for    => IN,
})->close();

ok(1);


done_testing();
