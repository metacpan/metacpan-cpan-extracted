# All possible one- and two-way fh types:
# - pipe
# - fifo
# - socket pair
# - tcp socket
# - unix socket
use warnings;
use strict;
use t::share;

if (WIN32) {
    plan skip_all => 'OS unsupported';
}

@CheckPoint = (
    [ 'writer',     SENT            ], 'writer: SENT',
    [ 'reader',     EOF             ], 'reader: EOF',
    [ 'reader',     'pipe'          ], '  got "pipe"',

    [ 'writer',     SENT            ], 'writer: SENT',
    [ 'reader',     IN              ], 'reader: IN',
    [ 'reader',     'fifo'          ], '  got "fifo"',

    [ 'client',     SENT            ], 'client: SENT',
    [ 'server',     EOF             ], 'server: EOF',
    [ 'server',     'unix'          ], '  got "unix"',
    [ 'server',     SENT            ], 'server: SENT',
    [ 'client',     EOF             ], 'client: EOF',
    [ 'client',     'echo: unix'    ], '  got "echo: unix"',
);
plan tests => @CheckPoint/2;


pipe my $rd_pipe, my $wr_pipe or die "pipe: $!";
nonblocking($rd_pipe);
nonblocking($wr_pipe);
stream1('pipe', $rd_pipe, $wr_pipe);

my $fifo = "/tmp/fifo.$$";
END { unlink $fifo }
system("mkfifo \Q$fifo\E") and die "system: $!";
open my $tmp_fifo, '+>', $fifo or die "open: $!";
open my $rd_fifo, '<', $fifo or die "open: $!";
open my $wr_fifo, '>', $fifo or die "open: $!";
close $tmp_fifo or die "close: $!";
nonblocking($rd_fifo);
nonblocking($wr_fifo);
stream1('fifo', $rd_fifo, $wr_fifo, 1);

my $lst_unix = unix_server("/tmp/sock.$$");
my $cln_unix = unix_client("/tmp/sock.$$");
accept my $srv_unix, $lst_unix or die "accept: $!";
close $lst_unix or die "close: $!";
stream2('unix', $srv_unix, $cln_unix);


sub stream1 {
    my ($name, $read_fh, $write_fh, $is_fifo) = @_;
    IO::Stream->new({
        fh          => $read_fh,
        cb          => \&reader,
        wait_for    => $is_fifo ? IN : EOF,
        in_buf_limit=> 1024,
    });
    IO::Stream->new({
        fh          => $write_fh,
        cb          => \&writer,
        wait_for    => SENT,
        out_buf     => $name,
        in_buf_limit=> 1024,
    });
    EV::loop;
}

sub reader {
    my ($io, $e, $err) = @_;
    die $err if $err;
    checkpoint($e);
    checkpoint($io->{in_buf});
    $io->close();
    EV::unloop;
}

sub writer {
    my ($io, $e, $err) = @_;
    die $err if $err;
    checkpoint($e);
    $io->close();
}


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

