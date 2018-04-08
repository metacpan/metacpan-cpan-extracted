# Use case: HTTP GET until EOF
use warnings;
use strict;
use lib 't';
use share;

plan skip_all => '$TEST_SOCKS4_PROXY_{HOST,PORT} are not configured'
    if !$ENV{TEST_SOCKS4_PROXY_HOST};


IO::Stream->new({
    host        => 'www.google.com',
    port        => 80,
    cb          => \&client,
    wait_for    => EOF,
    out_buf     => "GET / HTTP/1.0\nHost: www.google.com\n\n",
    in_buf_limit=> 102400,
    plugin      => [
        proxy       => IO::Stream::Proxy::SOCKSv4->new({
            host        => $ENV{TEST_SOCKS4_PROXY_HOST},
            port        => $ENV{TEST_SOCKS4_PROXY_PORT},
        }),
    ],
});

@CheckPoint = (
    [ 'client',     EOF             ], 'client: got eof',
);
plan tests => 1 + @CheckPoint/2;

EV::loop;

sub client {
    my ($io, $e, $err) = @_;
    checkpoint($e);
    like($io->{in_buf}, qr{\AHTTP/\d+\.\d+ }, 'got reply from web server');
    die "server error\n" if $e != EOF || $err;
    EV::unloop;
}

