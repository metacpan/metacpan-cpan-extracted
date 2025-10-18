use strict;
use IPC::Run qw(start finish);

our $pubsubPort  = 62987;
our $pubsubToken = 'aazz';

my $pubsub;

my $level = ( $ENV{LLNGLOGLEVEL} ||= 'error' );

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
    sleep 1;
}

sub stopPubsub {
    $pubsub->kill_kill( grace => 5 );
}

1;
