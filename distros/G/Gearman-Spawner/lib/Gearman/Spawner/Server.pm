package Gearman::Spawner::Server;

use strict;
use warnings;

use Gearman::Spawner::Process;
use IO::Socket::INET;

use base 'Gearman::Spawner::Process';

my ($ADDRESS, $INSTANCE);
sub address {
    my $class = shift;

    return $ADDRESS if $ADDRESS;
    return $ADDRESS = $ENV{GEARMAN_SERVER} if $ENV{GEARMAN_SERVER};

    $INSTANCE = $class->create;
    return $ADDRESS = $INSTANCE->address;
}

sub create {
    my $class = shift;

    unless (eval "require Gearman::Server; 1") {
        die "need server to run against; either set GEARMAN_SERVER or install Gearman::Server\n";
    }

    return Gearman::Spawner::Server::Instance->new($class->fork_gearmand());
}

# start up a gearmand that exits when its parent process does. returns the
# address of the listening server and its pid
sub fork_gearmand {
    my $class = shift;

    # NB: this relies on Gearman::Spawner::Process allowing use of fork,
    # run_periodically, exit_with_parent, and loop as class methods instead of
    # object methods

    # get an unused port from the OS
    my $sock = IO::Socket::INET->new(
        Type      => SOCK_STREAM,
        Proto     => 'tcp',
        Reuse     => 1,
        LocalHost => 'localhost',
        Listen    => 1,
    );

    $sock or die "failed to request a listening socket: $!";

    my $port = $sock->sockport;
    my $host = $sock->sockhost;
    my $address = "$host:$port";
    $sock->close;

    my $parent_pid = $$;

    $Gearman::Spawner::Process::CHECK_PERIOD = 0.5;
    my $pid = $class->fork("[Gearman::Server $address] $0", 1);

    if ($pid) {
        # wait until server is contactable
        for (1 .. 50) {
            my $sock = IO::Socket::INET->new($address);
            return ($address, $pid) if $sock;
            select undef, undef, undef, 0.1;
        }
        die "couldn't contact server at $host:$port: $!";
    }

    require Gearman::Util; # Gearman::Server doesn't itself
    my $server = Gearman::Server->new;
    $server->create_listening_sock($port);

    $class->loop;
}

package Gearman::Spawner::Server::Instance;

use strict;
use warnings;

sub new {
    my $class = shift;
    my ($address, $pid) = @_;
    return bless {
        address => $address,
        pid => $pid,
        me => $$,
    }, $class;
}

sub address {
    my $self = shift;
    return $self->{address};
}

sub DESTROY {
    my $self = shift;
    kill 'INT', $self->{pid} if $$ == $self->{me};
}

1;
