# EAGAIN in sysread/syswrite
use warnings;
use strict;
use t::share;

@CheckPoint = (
    [ 'timeout_write'   ], 'force EAGAIN in syswrite',
    {
        win32 => [
            [ 'writer', 0 ], '',
            [ 'timeout_read'    ], 'force EAGAIN in sysread',
            [ 'reader', 0 ], '',
        ],
        other => [
            [ 'timeout_read'    ], 'force EAGAIN in sysread',
        ],
    },
);
plan tests => WIN32 ? 4 : 2;

socketpair my $server, my $client, AF_UNIX, SOCK_STREAM, PF_UNSPEC or die "socketpair: $!";
nonblocking($server);
nonblocking($client);

my $timeout = $INC{'Devel/Cover.pm'} ? 2 : 0.5;
my ($r, $w, $t);
$w = IO::Stream->new({
    fh          => $client,
    cb          => \&writer,
    wait_for    => OUT,
});
$w->write('x' x 204800);

EV::loop;


sub writer {
    my ($io, $e, $err) = @_;
    if ($e == OUT) {
        $t = EV::timer($timeout, 0, \&timeout_write);
    } else {
        checkpoint($e);
    }
}

sub reader {
    my ($io, $e, $err) = @_;
    if ($e == IN) {
        $t = EV::timer($timeout, 0, \&timeout_read);
    } else {
        checkpoint($e);
    }
}

sub timeout_write {
    checkpoint();
    EV::feed_fd_event(fileno($w->{fh}), EV::WRITE); # force EAGAIN in syswrite
    $r = IO::Stream->new({
        fh          => $server,
        cb          => \&reader,
        wait_for    => IN,
    });
}

sub timeout_read {
    checkpoint();
    EV::feed_fd_event(fileno($r->{fh}), EV::READ);  # force EAGAIN in sysread
    $t = EV::timer($timeout, 0, sub { EV::unloop });
}

