use strict;
use IPC::Run    qw(start finish);
use Time::HiRes qw/usleep/;
use IO::Socket::INET;

# A free port is chosen at each run: a server left by an interrupted run would
# otherwise bind the same port without any error (llng-pubsub-server uses
# SO_REUSEPORT) and the kernel would share the connections between them
our $pubsubPort  = &freePort;
our $pubsubToken = 'aazz';

my $pubsub;

sub freePort {
    my $s = IO::Socket::INET->new(
        LocalAddr => 'localhost',
        Proto     => 'tcp',
        Listen    => 1,
    ) or die "Unable to find a free port: $!";
    my $port = $s->sockport;
    $s->close;
    return $port;
}

my $level = ( $ENV{LLNGLOGLEVEL} ||= 'error' );

sub waitForPubSub {
    my $waitloop = 0;
    note "Waiting for Pubsub server to be available";

    while (
        $waitloop < 100
        and !IO::Socket::INET->new(
            PeerAddr => "localhost",
            PeerPort => $pubsubPort,
            Proto    => 'tcp',
        )
      )
    {
        $waitloop++;
        usleep 100000;
    }
    die "Timed out waiting for PubSub server to start" if $waitloop == 100;
}

sub startPubsub {
    $pubsub = start [
        '../lemonldap-ng-common/eg/llng-pubsub-server',
        '--token' => $pubsubToken,
        '--port'  => $pubsubPort,
        (
              $ENV{LLNGLOGLEVEL} eq 'debug' ? '--debug'
            : $ENV{LLNGLOGLEVEL} eq 'info'  ? ()
            :                                 ('--quiet')
        ),
    ];
    print STDERR "# Pubsub server started\n";
    waitForPubSub;
}

sub stopPubsub {
    return unless ($pubsub);
    $pubsub->kill_kill( grace => 5 );
    $pubsub = undef;
}

# Don't leave a server behind if the test dies before its last stopPubsub
END {
    eval { &stopPubsub };
}

1;
