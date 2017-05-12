use warnings;
use strict;
use t::share;

my $cipher  = "This Is A Secret Key!";
my $banner  = "Server ready";
my $msg     = "Test message!\0\n" x 10_000;
my $repeat  = 2;

use constant ACCEPTED => 123;
@CheckPoint = (
    [ '__ANON__',   ACCEPTED        ], 'accept incoming connection',
    [ 'client',     IN              ], 'client: got server banner',
    [ 'client',     $banner         ], 'client: banner is correct',
((
    [ 'server',     IN              ], 'server: got in',
    [ 'server',     $msg            ], 'server: requst is correct',
    [ 'client',     IN              ], 'client: got in',
    [ 'client',     "echo: $msg"    ], 'client: reply is correct',
) x ($repeat-1)),

    [ 'client',     SENT            ], 'client: request sent',
    [ 'server',     IN              ], 'server: got last in',
    [ 'server',     $msg            ], 'server: requst is correct',
    [ 'server',     EOF             ], 'server: got eof',
    [ 'server',     SENT            ], 'server: reply sent',
    [ 'client',     EOF             ], 'client: got eof',
    [ 'client',     "echo: $msg"    ], 'client: reply is correct',
);
plan tests => @CheckPoint/2;

my $srv_sock = tcp_server('127.0.0.1', 0);
my ($srv_port) = sockaddr_in(getsockname $srv_sock);
my $srv_w = EV::io($srv_sock, EV::READ, sub {
    if (accept my $sock, $srv_sock) {
        checkpoint(ACCEPTED);
        IO::Stream->new({
            fh          => $sock,
            cb          => \&server,
            wait_for    => IN|EOF,
            in_buf_limit=> 1024000,
            out_buf     => $banner,
            plugin      => [
                rc4         => IO::Stream::Crypt::RC4->new($cipher),
            ],
            Repeat      => $repeat,
        });
    }
    elsif ($! != EAGAIN) {
        die "accept: $!\n";
    }
});

IO::Stream->new({
    host        => '127.0.0.1',
    port        => $srv_port,
    cb          => \&client,
    wait_for    => IN,
    in_buf_limit=> 1024000,
    plugin      => [
        rc4         => IO::Stream::Crypt::RC4->new($cipher),
    ],
    Repeat      => $repeat,
});

EV::loop;


sub server {
    my ($io, $e, $err) = @_;
#  &diag_event;
    return if $e == IN && length $io->{in_buf} < length $msg;
    checkpoint($e);
    if ($err) {
        $io->close();
        die $err;
    }
    if ($e & IN) {
        checkpoint($io->{in_buf});
        $io->{wait_for} = EOF|SENT if ! --$io->{Repeat};
        $io->write("echo: $io->{in_buf}");
        $io->{in_buf} = q{};
    }
    if ($e & SENT) {
        shutdown $io->{fh}, 1;
    }
}

sub client {
    my ($io, $e, $err) = @_;
#  &diag_event;
    return
        if $e == IN
        && length $io->{in_buf} != length $banner
        && length $io->{in_buf} < length $msg
        ;
    checkpoint($e);
    if ($e & IN) {
        checkpoint($io->{in_buf});
        $io->{in_buf} = q{};
        $io->{wait_for} = SENT|EOF if ! --$io->{Repeat};
        $io->write($msg);
    }
    if ($e & SENT) {
        shutdown $io->{fh}, 1;
    }
    if ($e & EOF) {
        checkpoint($io->{in_buf});
        exit;
    }
}

