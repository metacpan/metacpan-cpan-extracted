package Mail::POP3::Daemon;

use strict;
use IO::Socket;
use IO::File;
use POSIX;

# horrible globals!
my $CONFIG_FILE = './mpopd.conf';

sub new {
    my ($class, $config, $connection_class) = @_;
    my $self = {};
    bless $self, $class;
    $self->{CONFIG} = $config;
    $self;
}

# server daemon that will fork
sub start {
    my ($self) = @_;
    $self->_setup_sighandlers;
    # Counter used to track number of children
    $self->{KID_COUNT} = 0;
    # Build the server socket and bind to $self->{CONFIG}->{port}
    $self->_build_server;
    # Listen for a client and fork off a child server process
    while (1) {
        # Trap errors caused by peer-resets etc.
        my $client;
        unless ( eval { $client = $self->{SERVER_SOCKET}->accept } ) {
            eval { $client->close; };
            next;
        }
        # Close the connection if this one would exceed the maximum
        # concurrent servers allowed, $self->{CONFIG}->{max_servers}.
        unless ($self->{KID_COUNT} < $self->{CONFIG}->{max_servers}) {
            eval { $client->close; };
            sleep 2;
            next;
        }
        # Try and fork
        my $kidpid;
        if ($kidpid = fork) {
            ++$self->{KID_COUNT};
            $self->{KID_PIDS}->{$kidpid} = 1;
            next;
        }
        # If fork fails log the event to a file
        unless (defined $kidpid) {
            $self->_to_file(
                $self->{CONFIG}->{fork_alert},
                "Fork failed at: " . localtime(time) . ": $!\n",
            );
            eval { $client->close; };
            next;
        }
        # Everything below here (almost) belongs to the child server.
        $self->{SERVER_SOCKET}->close; # Close clone of SERVER handle.
        my $server = Mail::POP3::Server->new(
            $self->{CONFIG},
        );
        $server->start(
            $client,
            $client,
            $client->peerhost,
        );
    }
}

# Create parent socket and bind to POP3 port (or custom port)
sub _build_server {
    my $self = shift;
    my $server_socket = IO::Socket::INET->new(
        LocalPort => $self->{CONFIG}->{port},
        Proto => 'tcp',
        Reuse => 1,
        Listen => IO::Socket::SOMAXCONN,
    ) || die "Couldn't bind to port $self->{CONFIG}->{port} : $!";
    $self->{SERVER_SOCKET} = $server_socket;
    # Write a pid file with the port used on line 2
    $self->_to_file(
        $self->{CONFIG}->{mpopd_pid_file},
        "$$\n$self->{CONFIG}->{port}\n",
    );
}

sub MPOPDQUIT {
    my $self = shift;
    my $key;
    foreach $key (keys %{ $self->{KID_PIDS} }) {
        kill "USR1", $key;
        $self->REAPER;
    }
    $self->{SERVER_SOCKET}->close;
    unlink $self->{CONFIG}->{mpopd_pid_file};
    exit;
}

sub READCONFIG {
    my $self = shift;
    $self->{CONFIG} = (ref $self)->read_config($CONFIG_FILE);
    $SIG{USR1} = $self->_make_closure(\&READCONFIG);
}

sub MPOPDRESTART {
    my $self = shift;
    kill "USR1", keys %{ $self->{KID_PIDS} };
    $self->REAPER;
    $self->{SERVER_SOCKET}->close;
    $self->READCONFIG;
    $self->_build_server;
    $SIG{HUP} = $self->_make_closure(\&MPOPDRESTART);
    $SIG{PIPE} = $self->_make_closure(\&MPOPDRESTART);
    $SIG{INT} = $self->_make_closure(\&MPOPDRESTART);
}

sub REAPER {
    my $self = shift;
    while ((my $kidpid = waitpid(-1, POSIX::WNOHANG)) > 0) {
        --$self->{KID_COUNT};
        delete $self->{KID_PIDS}->{$kidpid};
    }
    $SIG{CHLD} = $self->_make_closure(\&REAPER);
}

sub _setup_sighandlers {
    my $self = shift;
    # do this with lexical closures
    # Try and rescue a broken pipe by rebuilding
    # the server-socket etc.
    $SIG{PIPE} = $self->_make_closure(\&MPOPDRESTART);
    # Ignore alarm signals from kernel
    $SIG{ALRM} = "IGNORE";
    # If we get a plain kill then try and close down all child
    # servers, remove pid file and exit.
    $SIG{TERM} = $self->_make_closure(\&MPOPDQUIT);
    $SIG{INT} = $self->_make_closure(\&MPOPDQUIT);
    # Just re-read the config file on a SIGUSR1, don't restart.
    $SIG{USR1} = $self->_make_closure(\&READCONFIG);
    # If we receive a SIGHUP kill off the forked servers gracefully(?)
    # with a SIGUSR1, close and re-open the server socket, reset as much
    # as possible and then re-read the config file.
    $SIG{HUP} = $self->_make_closure(\&MPOPDRESTART);
    # Catch SIGCHLD
    $SIG{CHLD} = $self->_make_closure(\&REAPER);
}

sub _make_closure {
    my ($self, $subref) = @_;
    sub { $subref->($self) };
}

sub _to_file {
    my ($self, $file, $data) = @_;
    local *FH;
    open FH, ">$file";
    print FH $data;
    close FH;
}

1;
