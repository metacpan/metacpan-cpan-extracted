use strict;
use IPC::Run    qw(start finish);
use Time::HiRes qw/usleep/;
use IO::Socket::INET;

our $pubsubPort  = 62987;
our $pubsubToken = 'aazz';

my $pubsub;

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
    $pubsub->kill_kill( grace => 5 );
}

1;
