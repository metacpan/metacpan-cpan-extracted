# No-op plugins in action.
use warnings;
use strict;
use lib 't';
use share;
use IO::Stream::Noop;


@CheckPoint = (
    [ 'EVENT', RESOLVED, undef          ], 'EventLog::EVENT(RESOLVED)',
    [ 'WRITE'                           ], 'EventLog::WRITE',
    [ 'EVENT', CONNECTED|OUT|SENT, undef], 'EventLog::EVENT(CONNECTED|OUT|SENT)',
    [ 'client', SENT                    ], 'client: SENT',
    [ 'server', EOF                     ], 'server: EOF',
    [ 'server', 'test'                  ], '  got "test"',
    [ 'server', SENT                    ], 'server: SENT',
    [ 'EVENT', IN, undef                ], 'EventLog::EVENT(IN)',
    [ 'EVENT', EOF, undef               ], 'EventLog::EVENT(EOF)',
    [ 'client', EOF                     ], 'client: EOF',
    [ 'client', 'echo: test'            ], '  got "echo: test"',
);
plan tests => 2 + @CheckPoint/2;


my $srv_sock = tcp_server('127.0.0.1', 0);
my $srv_w = EV::io($srv_sock, EV::READ, sub {
    if (accept my $sock, $srv_sock) {
        IO::Stream->new({
            fh          => $sock,
            cb          => \&server,
            wait_for    => EOF,
            in_buf_limit=> 1024,
        });
    }
    elsif ($! != EAGAIN) {
        die "accept: $!\n";
    }
});

my $io = IO::Stream->new({
    host        => '127.0.0.1',
    port        => sockport($srv_sock),
    cb          => \&client,
    wait_for    => SENT,
    in_buf_limit=> 1024,
    out_buf     => 'test',
    plugin      => [
        noop        => IO::Stream::Noop->new(),
        eventlog    => IO::Stream::EventLog->new(),
    ],
});

is(ref $io->{plugin}{noop}, 'IO::Stream::Noop',
    '{plugin}{noop} available');
is(ref $io->{plugin}{eventlog}, 'IO::Stream::EventLog',
    '{plugin}{eventlog} available');

EV::loop;


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
        EV::unloop();
    }
}


package IO::Stream::EventLog;
use base 'IO::Stream::Noop';
sub WRITE {
    main::checkpoint();
    shift->SUPER::WRITE(@_);
}
sub EVENT {
    main::checkpoint($_[1], $_[2]);
    shift->SUPER::EVENT(@_);
}

