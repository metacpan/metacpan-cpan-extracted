use strict;
use warnings;
use Test::More;
use Test::Exception;
use t::QServer;

test_qserver {
    my $port = shift;

    use_ok 'K';

    my $k = K->new(port => $port);

    is $k->cmd('4 + 4'), 8, 'make an int';

    is_deeply $k->cmd(q/"abc"/), [qw/a b c/], 'make string';

    my $timestamp = $k->cmd(q/2012.03.24D12:13:14.15161728/);
    is "$timestamp", '385906394151617280', 'timestamp';

    throws_ok { $k->cmd } qr/No command provided/,
        'cmd method needs an arg';

    throws_ok { $k->async_cmd } qr/No command provided/,
        'async_cmd method needs an arg';
};

test_qserver {

    my $port = shift;

    throws_ok { K->new( port => $port, timeout => 10 )->cmd('2+2') }
              qr/Failed to connect/, 'exception on timeout';

    pass 'timed out';

} { hang => 1 };

END { done_testing; }
