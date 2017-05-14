use strict;
use warnings;

use Test::More;
use t::QServer;

test_qserver {
    my $port = shift;

    use_ok 'K';

    my $k = K->new(port => $port);

    # have Q send us a message in 50 ms
    $k->cmd(q/.z.ts: { h:first key .z.W; (neg h)[(1;2;3)] }/);
    $k->cmd(q/system"t 50"/);

    is_deeply $k->recv, [1, 2, 3], 'receive';

    $k->cmd(q/system"t 0"/);
};

END { done_testing; }
