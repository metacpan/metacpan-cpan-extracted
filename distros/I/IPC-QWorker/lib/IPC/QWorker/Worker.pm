package IPC::QWorker::Worker;

use strict;
use warnings;
use utf8;

our $VERSION = '0.07'; # VERSION

use Carp;
use IO::Socket;
use Storable qw(fd_retrieve store_fd);
use Data::Dumper;

sub new {
    my $this  = shift;
    my $class = ref($this) || $this;
    my $self  = {
        'pid'   => 0,
        'pipe'  => undef,
        'calls' => {@_},
        'ctx'   => {},
				'ready' => 0,
    };
    bless( $self, $class );
    $self->_fork_worker();
    return ($self);
}

sub _fork_worker {
    my $self = shift;
    my $pid;
    my $parent_pipe;
    my $child_pipe;

    socketpair( $parent_pipe, $child_pipe, AF_UNIX, SOCK_STREAM, PF_UNIX )
      or croak("cant create socketpair: $!");

    $parent_pipe->autoflush(1);
    $child_pipe->autoflush(1);

    if ( $pid = fork ) {
        close($parent_pipe);
        $self->{'pid'}  = $pid;
        $self->{'pipe'} = $child_pipe;
    }
    else {
        if ( !defined($pid) ) {
            croak("cannot fork child process");
        }
        close($child_pipe);
        $self->{'pipe'} = $parent_pipe;
        if ( defined( $self->{'calls'}->{'_init'} ) ) {
            $self->{'calls'}->{'_init'}->( $self->{'ctx'} );
        }
        $SIG{'HUP'} = sub { $self->_shutdown() };
        $self->_child_loop();
        close($parent_pipe);
        exit;
    }
}

sub _child_loop {
    my $self = shift;
    my $qentry;

    $self->send_ready();

    while ( $qentry = ${ fd_retrieve( $self->{'pipe'} ) } ) {
        if ($IPC::QWorker::DEBUG) { print STDERR Dumper($qentry); }

        if ( defined $self->{'calls'}->{ $qentry->{'cmd'} } ) {
            $self->{'calls'}->{ $qentry->{'cmd'} }
              ->( $self->{'ctx'}, $qentry->{'params'} );
        }
        else {
            croak( $$ . ": no such call defined in this worker" );
        }

        $self->send_ready();
    }
}

sub send_ready {
	my $self = shift();

	print ${ $self->{'pipe'} }($$." READY\n");
}

sub send_entry {
		my $self = shift;
		my $qentry = shift;

		$self->{'ready'} = 0;

		if ($IPC::QWorker::DEBUG) {
			print STDERR $$ . ": sending entry...\n";
		}
		store_fd( \$qentry, $self->{'pipe'} );
}

sub exit_child {
    my $self = shift();

    if ( $self->{'pid'} == 0 ) {    # do nothing when called from within child
        return ();
    }

    kill( 'HUP', $self->{'pid'} );
    waitpid( $self->{'pid'}, 0 );
}

sub _shutdown {
    my $self = shift();

    if ( defined( $self->{'calls'}->{'_destroy'} ) ) {
        $self->{'calls'}->{'_destroy'}->( $self->{'ctx'} );
    }
    if ($IPC::QWorker::DEBUG) { print STDERR $$ . ": exiting...\n"; }
    exit(0);
}

1;

# vim:ts=2:syntax=perl:
# vim600:foldmethod=marker:
