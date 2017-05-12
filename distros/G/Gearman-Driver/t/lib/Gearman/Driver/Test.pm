package    # hide from PAUSE
  Gearman::Driver::Test;

use strict;
use warnings;
use FindBin qw( $Bin );
use Gearman::Driver;
use Net::Telnet;
use Gearman::Client;
use Gearman::Server;
use Danga::Socket;
use IO::Socket::INET;

BEGIN {
    $ENV{GEARMAN_DRIVER_ADAPTOR} = 'Gearman::Driver::Adaptor::PP'
        unless $ENV{GEARMAN_DRIVER_ADAPTOR};
}

my ( $host, $port ) = ( '127.0.0.1', 4731 );

$|++;

sub new {
    return bless {}, shift;
}

sub run_gearman_server {
    my $server = Gearman::Server->new( port => $port );
    Danga::Socket->EventLoop();
}

sub run_gearmand {
    my ($self) = @_;

    unless ( $self->{gearmand_pid} = fork ) {
        die "cannot fork: $!" unless defined $self->{gearmand_pid};

        my @cmd = ( $^X, "$Bin/gearmand.pl" );

        exec @cmd or die "Could not exec $Bin/gearmand.pl";

        exit(0);
    }

    my $cnt = 0;
    while ( !check_connection($port) ) {
        sleep(1);
        $cnt++;
        die "Could not connect to $port after $cnt seconds" if $cnt == 30;
    }
}

sub stop_gearmand {
    my ($self) = @_;
    if ( my $pid = $self->{gearmand_pid} ) {
        kill 15, $pid;
        waitpid $pid, 0;
    }
}

sub run_gearman_driver {
    my ( $self, @args ) = @_;
    
    unless ( $self->{gearman_driver_pid} = fork ) {
        die "cannot fork: $!" unless defined $self->{gearman_driver_pid};
        @args = map { $_ =~/^--/ ? split /\s+/ ,$_,2: ('--namespaces',$_) } @args;
        my @cmd = ($^X, "$Bin/gearman_driver.pl", @args);
        exec (@cmd ) or die "Could not exec $Bin/gearman_driver.pl";
        exit(0);
    }

    my $cnt = 0;
    while ( !check_connection(47300) ) {
        sleep(1);
        $cnt++;
        die "Could not connect to 47300 after $cnt seconds" if $cnt == 60;
    }
}

sub stop_gearman_driver {
    my ($self) = @_;
    if ( my $pid = $self->{gearman_driver_pid} ) {
        kill 15, $pid;
        waitpid $pid, 0;
    }
}

sub check_connection {
    my ($port) = @_;
    return do {
        my $sock = IO::Socket::INET->new(
            PeerAddr => '127.0.0.1',
            PeerPort => $port,
            Proto    => 'tcp',
        ) or return 0;
        undef $sock;
        return 1;
    };
}

sub gearman_client {
    my ( $self, $h, $p ) = @_;

    $h ||= $host;
    $p ||= $port;

    my $client = Gearman::Client->new( exceptions => 1 );
    $client->job_servers("${h}:${p}");

    return $client;
}

sub gearman_driver {
    return Gearman::Driver->new_with_options(
        max_idle_time => 5,
        interval      => 1,
        loglevel      => 'DEBUG',
        server        => join( ':', $host, $port ),
    );
}

sub prepare {
    my ( $self, @args ) = @_;
    $self->run_gearmand;
    $self->run_gearman_driver(@args);
}

sub telnet_client {
    my ($self) = @_;
    unless ( defined $self->{telnet} ) {
        $self->{telnet} = Net::Telnet->new(
            Timeout => 30,
            Host    => '127.0.0.1',
            Port    => 47300,
        );
        $self->{telnet}->open;
    }
    return $self->{telnet};
}

sub shutdown {
    my ($self) = @_;
    $self->telnet_client->print('shutdown');
    sleep 3;
}

sub DESTROY {
    my ($self) = @_;
    $self->stop_gearmand();
    $self->stop_gearman_driver();
}

1;
