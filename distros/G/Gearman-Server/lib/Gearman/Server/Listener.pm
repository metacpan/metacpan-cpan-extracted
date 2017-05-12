package Gearman::Server::Listener;
use version;
$Gearman::Server::Listener::VERSION = qv("v1.130.1");

use strict;
use warnings;

use base 'Danga::Socket';
use fields qw/
    server
    accept_per_loop
    /;

use Errno qw(EAGAIN);
use Socket qw/
    IPPROTO_TCP
    TCP_NODELAY
    SOL_SOCKET
    SO_ERROR
    /;

sub new {
    my Gearman::Server::Listener $self = shift;
    my $sock                           = shift;
    my $server                         = shift;

    my %opts = @_;

    my $accept_per_loop = delete $opts{accept_per_loop};

    warn "Extra options passed into new: " . join(', ', keys %opts) . "\n"
        if keys %opts;

    $accept_per_loop = 10
        unless defined $accept_per_loop and $accept_per_loop >= 1;

    $self = fields::new($self) unless ref $self;

    # make sure provided listening socket is non-blocking
    IO::Handle::blocking($sock, 0);

    $self->SUPER::new($sock);

    $self->{server}          = $server;
    $self->{accept_per_loop} = int($accept_per_loop);

    $self->watch_read(1);

    return $self;
} ## end sub new

sub event_read {
    my Gearman::Server::Listener $self = shift;

    my $listen_sock = $self->sock;

    local $!;
    local $SIG{PIPE} = "IGNORE";

    my $remaining = $self->{accept_per_loop};

    while (my $csock = $listen_sock->accept) {
        IO::Handle::blocking($csock, 0);
        setsockopt($csock, IPPROTO_TCP, TCP_NODELAY, pack("l", 1)) or die;

        my $server = $self->{server};

        $server->debug(
            sprintf("Listen child making a Client for %d.", fileno($csock)));
        $server->new_client($csock);
        return unless $remaining-- > 0;
    } ## end while (my $csock = $listen_sock...)

    return if $! == EAGAIN;

    warn "Error accepting incoming connection: $!\n";

    $self->watch_read(0);

    Danga::Socket->AddTimer(
        .1,
        sub {
            $self->watch_read(1);
        }
    );
} ## end sub event_read

1;
