# Write timeout.
use warnings;
use strict;
use lib 't';
use IO::Stream::MatrixSSL::const;
BEGIN {
    no warnings 'redefine';
    *IO::Stream::MatrixSSL::const::TOHANDSHAKE = sub () { 0.1 };
}
use share;


@CheckPoint = (
    [ 'server', RESOLVED, undef             ], 'server: RESOLVED',
    [ 'server', CONNECTED, undef            ], 'server: CONNECTED',
    [ 'server', 0, 'ssl handshake timeout'  ], 'server: ssl handshake timeout',
);
plan tests => @CheckPoint/2;



my $srv_sock = tcp_server('127.0.0.1', 0);
my ($srv_port) = sockaddr_in(getsockname $srv_sock);
IO::Stream->new({
    host        => '127.0.0.1',
    port        => $srv_port,
    cb          => \&server,
    wait_for    => RESOLVED|CONNECTED|SENT,
    out_buf     => 'test',
    plugin      => [
        ssl         => IO::Stream::MatrixSSL::Server->new({
            crt         => 't/cert/testsrv.crt',
            key         => 't/cert/testsrv.key',
        }),
    ],
});

EV::loop;


sub server {
    my ($io, $e, $err) = @_;
    checkpoint($e, $err);
    EV::unloop if $err;
}

