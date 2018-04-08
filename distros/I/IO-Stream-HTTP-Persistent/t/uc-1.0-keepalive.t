use warnings;
use strict;
use lib 't';
use share;

# Use case: HTTP/1.0 Keep-Alive: GET without EOF
my $request = "GET / HTTP/1.0\nHost: localhost\nConnection: Keep-Alive\n\n";
my $response = "HTTP/1.1 200 OK\nContent-Length: 3\nConnection: keep-alive\n\nok\n";

@CheckPoint = (
    [ 'client', HTTP_SENT,  undef   ], 'client: got HTTP_SENT',
    [ 'client', HTTP_RECV,  undef   ], 'client: got HTTP_RECV',
    [ 'timeout',                    ], 'timeout: no EOF',
);
plan tests => 1 + @CheckPoint/2;


my ($srv_w, $port) = start_server($request, $response);

IO::Stream->new({
    host        => '127.0.0.1',
    port        => $port,
    cb          => \&client,
    wait_for    => EOF|HTTP_SENT|HTTP_RECV,
    out_buf     => $request,
    in_buf_limit=> 102400,
    plugin      => [
        http        => IO::Stream::HTTP::Persistent->new(),
    ],
});

my $t_timeout;

EV::loop;


sub client {
    my ($io, $e, $err) = @_;
    checkpoint($e, $err);
    if ($e & HTTP_RECV) {
        like($io->{in_buf}, qr{\AHTTP/\d+\.\d+ }, 'got reply from web server');
        $t_timeout = EV::timer 1, 0, \&timeout;
    }
    EV::unloop if $e & EOF || $err;
}

sub timeout {
    checkpoint();
    EV::unloop;
}
