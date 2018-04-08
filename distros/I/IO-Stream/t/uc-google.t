# Use case: HTTP GET until EOF
use warnings;
use strict;
use lib 't';
use share;

IO::Stream->new({
#    fh          => tcp_client('www.google.com', 80),
    host        => 'www.google.com',
    port        => 80,
    cb          => \&client,
    wait_for    => EOF,
    out_buf     => "GET / HTTP/1.0\nHost: www.google.com\n\n",
    in_buf_limit=> 1024000,
});

@CheckPoint = (
    [ 'client',     EOF, undef      ], 'client: got eof',
);
plan tests => 1 + @CheckPoint/2;

EV::loop;

sub client {
    my ($io, $e, $err) = @_;
    checkpoint($e, $err);
    like($io->{in_buf}, qr{\AHTTP/\d+\.\d+ }, 'got reply from web server');
    die "server error\n" if $e != EOF || $err;
    EV::unloop;
}
