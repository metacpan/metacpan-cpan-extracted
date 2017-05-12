package LSF;

use strict;
use warnings;

use Exporter;
use File::Temp 'tempdir';
use IO::Socket::INET;
use IO::Select ();
use Log::Syslog::Fast::Constants ':all';
use Test::More ();

our @ISA = qw(Exporter);
our @EXPORT = qw(listen_port wait_for_readable make_server test_dir $CLASS);
our $CLASS = $main::CLASS;

# old IO::Socket::INET fails with "Bad service '0'" when attempting to use
# the special wildcard port 0
my $port = 24767;
sub listen_port {
    return 0 if $IO::Socket::INET::VERSION >= 1.31;
    Test::More::diag("Using port $port for IO::Socket::INET v$IO::Socket::INET::VERSION");
    return $port++;
}

# use select so test won't block on failure
sub wait_for_readable {
    my $sock = shift;
    return IO::Select->new($sock)->can_read(1);
}

my $test_dir;
sub test_dir {
    return $test_dir ||= tempdir(CLEANUP => 1);
}

my %server_makers = (
    tcp => sub {
        my $listener = IO::Socket::INET->new(
            Proto       => 'tcp',
            Type        => SOCK_STREAM,
            LocalHost   => 'localhost',
            LocalPort   => listen_port(),
            Listen      => 5,
            Reuse       => 1,
        ) or die $!;
        return StreamServer->new(
            listener    => $listener,
            proto       => LOG_TCP,
            address     => [$listener->sockhost, $listener->sockport],
        );
    },
    udp => sub {
        my $listener = IO::Socket::INET->new(
            Proto       => 'udp',
            Type        => SOCK_DGRAM,
            LocalHost   => 'localhost',
            LocalPort   => listen_port(),
            Reuse       => 1,
        ) or die $!;
        return DgramServer->new(
            listener    => $listener,
            proto       => LOG_UDP,
            address     => [$listener->sockhost, $listener->sockport],
        );
    },
    unix_stream => sub {
        my $listener = IO::Socket::UNIX->new(
            Local   => test_dir . "/stream",
            Type    => SOCK_STREAM,
            Listen  => 1,
        ) or die $!;
        return StreamServer->new(
            listener    => $listener,
            proto       => LOG_UNIX,
            address     => [$listener->hostpath, 0],
        );
    },
    unix_dgram => sub {
        my $listener = IO::Socket::UNIX->new(
            Local   => test_dir . "/dgram",
            Type    => SOCK_DGRAM,
            Listen  => 1,
        ) or die $!;
        return DgramServer->new(
            listener    => $listener,
            proto       => LOG_UNIX,
            address     => [$listener->hostpath, 0],
        );
    },
);

sub make_server { $server_makers{shift()}->() }

package ServerCreator;

sub new {
    my $class = shift;
    return bless {label => $_[0], listen => $_[1]}, $class;
}


sub listen {
    my $self = shift;
    $self->{listen}->();
}

package Server;

sub new {
    my $class = shift;
    return bless {@_}, $class;
}
sub proto {
    my $self = shift;
    return $self->{proto};
}

sub address {
    my $self = shift;
    return @{ $self->{address} };
}

sub connect {
    my $self = shift;
    my $class = shift;
    return $class->new($self->proto, $self->address, @_);
}

sub close {
    my $self = shift;
    $self->{listener} = undef;
}

# remove unix socket file on server close
sub DESTROY {
    my $self = shift;
    if ($self->{address}[1] == 0) {
        unlink $self->{address}[0];
    }
}

package StreamServer;

use base 'Server';

sub accept {
    my $self = shift;
    my $receiver = $self->{listener}->accept;
    $receiver->blocking(0);
    return $receiver;
}

package DgramServer;

use base 'Server';

sub accept {
    my $self = shift;
    return $self->{listener};
}

1;
