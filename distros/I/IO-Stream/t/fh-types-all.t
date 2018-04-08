# All possible one- and two-way fh types:
# - pipe
# - fifo
# - socket pair
# - tcp socket
# - unix socket
use warnings;
use strict;
use lib 't';
use share;

@CheckPoint = (
    [ 'client',     SENT            ], 'client: SENT',
    [ 'server',     EOF             ], 'server: EOF',
    [ 'server',     'sockpair'      ], '  got "sockpair"',
    [ 'server',     SENT            ], 'server: SENT',
    [ 'client',     EOF             ], 'client: EOF',
    [ 'client',     'echo: sockpair'], '  got "echo: sockpair"',

    [ 'client',     SENT            ], 'client: SENT',
    [ 'server',     EOF             ], 'server: EOF',
    [ 'server',     'socket'        ], '  got "socket"',
    [ 'server',     SENT            ], 'server: SENT',
    [ 'client',     EOF             ], 'client: EOF',
    [ 'client',     'echo: socket'  ], '  got "echo: socket"',
);
plan tests => @CheckPoint/2;


socketpair my $server, my $client, AF_UNIX, SOCK_STREAM, PF_UNSPEC or die "socketpair: $!";
nonblocking($server);
nonblocking($client);
stream2('sockpair', $server, $client);

my $lst_sock = tcp_server('127.0.0.1', 0);
my $cln_sock = tcp_client('127.0.0.1', sockport($lst_sock));
my $srv_sock;
use Errno qw( EBADF );
until (accept $srv_sock, $lst_sock) {
    $! == EAGAIN or (WIN32 && $! == EBADF) or die "accept: $!";
    sleep 1;
}
close $lst_sock or die "close: $!";
stream2('socket', $srv_sock, $cln_sock);


sub stream2 {
    my ($name, $srv_fh, $cln_fh) = @_;
    IO::Stream->new({
        fh          => $srv_fh,
        cb          => \&server,
        wait_for    => EOF,
        in_buf_limit=> 1024,
    });
    IO::Stream->new({
        fh          => $cln_fh,
        cb          => \&client,
        wait_for    => SENT,
        out_buf     => $name,
        in_buf_limit=> 1024,
    });
    EV::loop;
}

sub server {
    my ($io, $e, $err) = @_;
    die $err if $err;
    checkpoint($e);
    if ($e & EOF) {
        checkpoint($io->{in_buf});
        $io->{wait_for} = SENT;
        $io->write("echo: $io->{in_buf}");
    }
    if ($e & SENT) {
        $io->close();
    }
}

sub client {
    my ($io, $e, $err) = @_;
    die $err if $err;
    checkpoint($e);
    if ($e & SENT) {
        $io->{wait_for} = EOF;
        shutdown $io->{fh}, 1;
    }
    if ($e & EOF) {
        checkpoint($io->{in_buf});
        $io->close();
        EV::unloop;
    }
}

