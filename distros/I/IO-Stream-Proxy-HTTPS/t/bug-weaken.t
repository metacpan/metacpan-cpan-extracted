# bug in 1.0.1: IO object doesn't destroyed on close()
use warnings;
use strict;
use lib 't';
use share;

plan skip_all => '$TEST_HTTPS_PROXY_{HOST,PORT,USER,PASS} are not configured'
    if !$ENV{TEST_HTTPS_PROXY_HOST};


my $runs_left = 3;

@CheckPoint = (
  (
    [ 'client',     EOF             ], 'client: got eof',
  ) x $runs_left
);
plan tests => $runs_left + @CheckPoint/2;

start_google();

EV::loop;

sub start_google {
    EV::unloop if !$runs_left--;
    IO::Stream->new({
        host        => 'www.google.com',
        port        => 80,
        cb          => \&client,
        wait_for    => EOF,
        out_buf     => "GET / HTTP/1.0\nHost: www.google.com\n\n",
        in_buf_limit=> 102400,
        plugin      => [
            proxy       => IO::Stream::Proxy::HTTPS->new({
                host        => $ENV{TEST_HTTPS_PROXY_HOST},
                port        => $ENV{TEST_HTTPS_PROXY_PORT},
            ( $ENV{TEST_HTTPS_PROXY_USER} ? (
                user        => $ENV{TEST_HTTPS_PROXY_USER},
                pass        => $ENV{TEST_HTTPS_PROXY_PASS},
            ) : () ),
            }),
        ],
    });
}

sub client {
    my ($io, $e, $err) = @_;
    checkpoint($e);
    like($io->{in_buf}, qr{\AHTTP/\d+\.\d+ }, 'got reply from web server');
    die "server error\n" if $e != EOF || $err;
    $io->close();
    start_google();
}

