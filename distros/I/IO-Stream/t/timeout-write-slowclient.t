# Write timeout.
use warnings;
use strict;
use lib 't';
use IO::Stream::const ();
BEGIN {
    local $SIG{__WARN__} = sub {};  # no 'constant redefined' warning
    *IO::Stream::const::TOWRITE     = sub () { 1 };
}
use share;


@CheckPoint = (
    [ 'client',     RESOLVED, undef         ], 'client: RESOLVED',
    [ 'client',     CONNECTED|OUT, undef    ], 'client: CONNECTED',
    [ 'server',     16,                     ], 'server: read 16 bytes',
    [ 'server',     16,                     ], 'server: read 16 bytes',
    [ 'server',     16,                     ], 'server: read 16 bytes',
    [ 'client',     0, 'write timeout'      ], 'client: write timeout',
);
plan tests => checkpoint_count();



my $srv_sock = tcp_server('127.0.0.1', 0);
my %srv_t;
my $srv_w = EV::io($srv_sock, EV::READ, sub {
    accept my $sock, $srv_sock or die "accept: $!";
    nonblocking($sock);
    my $i = 3;
    $srv_t{$sock} = EV::timer 0, 0.1, sub { server($sock, \$i) };
});

IO::Stream->new({
    host        => '127.0.0.1',
    port        => sockport($srv_sock),
    cb          => \&client,
    wait_for    => RESOLVED|CONNECTED|OUT|SENT,
    out_buf     => ('x' x 2048000),
});

EV::loop;


sub server {
    my ($sock, $i) = @_;
    my $n = sysread $sock, my $buf, 16;
    checkpoint($n) if $$i > 0;
    EV::unloop if --$$i < -30; # client doesn't get 'write timeout' in 3 seconds
    return;
}


sub client {
    my ($io, $e, $err) = @_;
  # &diag_event;
    if ($e == OUT) {
        $io->{out_buf} .= 'x' x (2048000 - length $io->{out_buf});
    } else {
        checkpoint($e, $err);
    }
    EV::unloop if $err;
}

