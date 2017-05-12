# Use case: HTTP GET until EOF
use warnings;
use strict;
use t::share;

IO::Stream->new({
#    fh          => tcp_client('www.google.com', 443),
    host        => 'www.google.com',
    port        => 443,
    cb          => \&client,
    wait_for    => EOF,
    out_buf     => "GET / HTTP/1.0\nHost: www.google.com\n\n",
    in_buf_limit=> 1024000,
    plugin      => [
        ssl         => IO::Stream::MatrixSSL::Client->new({
            cb          => \&validate,
        }),
    ],
});

@CheckPoint = (
    {
        www => [
            [ 'validate',   'www.google.com'], 'validate: got certificate for www.google.com',
        ],
        nowww => [
            [ 'validate',   'google.com'    ], 'validate: got certificate for www.google.com',
        ],
    },
    [ 'client',     EOF,    undef           ], 'client: got eof',
);
plan tests => 1 + checkpoint_count();

EV::loop;

sub validate {
    my ($ssl, $certs) = @_;
    checkpoint($certs->[0]{subject}{commonName});
    return 0;
}

sub client {
    my ($io, $e, $err) = @_;
    checkpoint($e, $err);
    like($io->{in_buf}, qr{\AHTTP/\d+\.\d+ }, 'got reply from web server');
    die "server error\n" if $e != EOF || $err;
    EV::unloop;
}
