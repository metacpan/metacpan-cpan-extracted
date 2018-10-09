#
# tied filehandle class for interprocess communication file and socket
# handles. This class is mainly for facilitating testing and debugging.
# We ought to be able to drop in and drop out this class without
# changing the behavior of any application using Forks::Super.
#

# usage:
#    $fh = gensym();
#    create real socket handle (socketpair, accept, etc.)
#    tie *$fh, 'Forks::Super::Tie::IPCSocketHandle',
#          *$the_real_socket_handle, $fh;


# as of Forks::Super v0.35 this package is still being
# improved and evaluated, and is not being referenced by
# any other part of this module

package Forks::Super::Tie::IPCSocketHandle;
use Forks::Super::Tie::IPCFileHandle;
use Forks::Super::Debug;

use Exporter;
use strict;
use warnings;
use Carp;
use IO::Socket;
use IO::Handle;

our @ISA = qw(IO::Socket IO::Handle);
our $VERSION = '0.97';

# XXX Windows hack. To get smoothly running sockets on Windows it
#     seems we have to do a slight pause after each write op.
# v0.55: try to remove ...
#sub trivial_pause { return $^O eq 'MSWin32'
#			&& 0
#			&& Forks::Super::Util::pause(0.001) };

sub TIEHANDLE {
    my ($class, $real_socket, $glob) = @_;
    $$glob->{DELEGATE} = $real_socket;
    eval {
	bless $glob, 'Forks::Super::Tie::IPCSocketHandle::Delegator';
    } or carp 'Forks::Super::Tie::IPCSocketHandle: ',
            "failed to bless tied obj as Delegator\n";

    # any attributes that the real socket had should be passed
    # on to the glob.
    foreach (keys %$$real_socket) {
	$$glob->{$_} = $$real_socket->{$_};
    }

    # apply PerlIO layers to the socket here ...
    my $job = $$glob->{job} || Forks::Super::Job->this;
    if (defined($job) && $job->{debug}) {
	Forks::Super::Debug::debug("io layers are " 
				   . "@{$job->{fh_config}{layers} || []}");
    }
    if (defined($job) && $job->{fh_config}{layers}) {
	my @io_layers = @{$job->{fh_config}{layers}};
	if ($$real_socket->{is_read}) {
	    @io_layers = reverse @io_layers;
	}
	foreach my $layer (@io_layers) {
	    for my $redo (1..2) {
		local $! = 0;
		if (binmode $real_socket, $layer) {
		    if ($job->{debug}) {
			Forks::Super::Debug::debug("applied PerlIO layer $layer",
						 " to socket $real_socket");
		    }
		    last;
		} elsif ($redo==1) {
		    carp 'Forks::Super::Tie::IPCSocketHandle: ',
		        "failed to apply PerlIO layer $layer to $real_socket: $!";
		}
		Forks::Super::pause(0.01);
	    }
	}
    }

    my $self = { SOCKET => $real_socket, GLOB => $glob };
    $self->{_FILENO} = CORE::fileno($real_socket);
    $self->{_SHUTDOWN} = $$real_socket->{_SHUTDOWN} || 0;

    bless $self, $class;
    return $self;
}

#############################################################################

sub OPEN {
    Carp::confess "Can't call 'open' on a socket handle\n";
}

sub BINMODE {
    my ($self, $layer) = @_;
    $self->{BINMODE}++;
    return binmode $self->{SOCKET}, $layer || ':raw';
}

sub GETC {
    my $self = shift;
    $self->{GETC}++;

    # XXX - handle undef/$! ?
    return getc($self->{SOCKET});
}

sub FILENO {
    my $self = shift;
    $self->{FILENO}++;
    return $self->{_FILENO};
}

sub PRINT {
    my ($self, @list) = @_;
    $self->{PRINT}++;

    my $bytes = join(defined $, ? $, : '', @list)
                  . (defined $\ ? $\ : '');

    my $z = print {$self->{SOCKET}} @list;
#    if ($^O eq 'MSWin32') {
#	trivial_pause();
#    }
    return $z;
}

sub PRINTF {
    my ($self, $template, @list) = @_;
    $self->{PRINTF}++;
    return $self->PRINT(sprintf $template, @list);
}

sub WRITE {
    my ($self, $string, $length, $offset) = @_;
    $self->{WRITE}++;
    $length ||= length $string;
    $offset ||= 0;

    my $n = syswrite $self->{SOCKET}, $string, $length, $offset;
    # $self->{SOCKET}->flush();
#   trivial_pause();
    return $n;
}

sub READLINE {
    # TODO - call F::S::J::Ipc::_read_socket for appropriate job, sockhandle
    my $self = shift;
    $self->{READLINE}++;

    my $glob = $self->{GLOB};

    # rt#127016
    if (Forks::Super::Util::IS_WIN32()) {
	${$self->{SOCKET}}->{emulate_blocking} ||= $$glob->{emulate_blocking};
    }
    
    if ($$glob->{job} || ref($$glob->{job})) {
	return Forks::Super::Job::Ipc::_read_socket(
	    $self->{SOCKET}, $$glob->{job}, wantarray);
    }

    return readline($self->{SOCKET});
}

sub TELL {
    my $self = shift;
    $self->{TELL}++;
    return tell $self->{SOCKET};
}

sub EOF {
    my $self = shift;
    return eof $self->{SOCKET};
}

sub READ {
    my ($self, undef, $length, $offset) = @_;
    $self->{READ}++;
    return read $self->{SOCKET}, $_[1], $length, $offset || 0;
}

sub SEEK {
    my ($self, $position, $whence) = @_;
    $self->{SEEK}++;
    return seek $self->{SOCKET}, $position, $whence;
}

sub is_pipe {
    return 0;
}

sub opened {
    my $self = shift;
    return $self->{SOCKET}->opened;
}

sub Forks::Super::Tie::IPCSocketHandle::shutdown {
    my ($self, $how) = @_;
    my $glob = $self->{GLOB};
    while (defined $$glob->{std_delegate}) {
	$self = tied *{$glob->{std_delegate}};
	$glob = $self->{GLOB};
    }
    $self->{_SHUTDOWN} ||= 0;

    if (($self->{_SHUTDOWN} & (1 + $how)) == 1 + $how) {
	return 1;    # already shutdown
    }
    if (!defined $self->{SOCKET}) {
	return 1;
    }
    my $result = shutdown($self->{SOCKET}, $how);
    if ($result) {
	$self->{_SHUTDOWN} |= 1 + $how;
	if ($self->{_SHUTDOWN} == 3) {
	  # should close
	}
    }
    return $result;
}

sub CLOSE {
    my $self = shift;
    if (&Forks::Super::Job::_INSIDE_END_QUEUE) {
	untie *{$self->{GLOB}};
	if ($self->{SOCKET}) {
	    CORE::shutdown $self->{SOCKET}, 2;
	    close $self->{SOCKET};
	}
	close *{$self->{GLOB}};
    }

    $self->{CLOSE}++;
    $self->{_SHUTDOWN} ||= 0;
    my $glob = $self->{GLOB};

    my $how = $$glob->{is_read} || 0;
    $how += 2*($$glob->{is_write} || 0);
    $how = ($how+2) % 3;

    delete $self->{SOCKET};
    ${$self->{GLOB}}->{closed}++;
    return $self->shutdown($how);
}

sub UNTIE {
}

sub DESTROY {
    my $self = shift;
    $self = {};
    return;
}

#
# when you call a method on a glob that is tied to a 
# Forks::Super::Tie::IPCSocketHandle , the method should be invoked
# on the tied object's real underlying socket handle
#
sub Forks::Super::Tie::IPCSocketHandle::Delegator::AUTOLOAD {
    return if &Forks::Super::Job::_INSIDE_END_QUEUE;
    my $method = $Forks::Super::Tie::IPCSocketHandle::Delegator::AUTOLOAD;
    $method =~ s/.*:://;
    my $delegator = shift;
    return if !$delegator;

    my $delegate = $$delegator->{DELEGATE};
    return if !$delegate;

    ## no critic (StringyEval)
    if (wantarray) {
	my @r = eval "\$delegate->$method(\@_)" or do {};
	if ($@) {
	    Carp::cluck "IPCSocketHandle delegate fail: $method @_; error=$@\n";
	}
	return @r;
    } else {
	my $r = eval "\$delegate->$method(\@_)";
	if ($@) {
	    Carp::cluck "IPCSocketHandle delegate fail: $method @_; error=$@\n";
	}
	return $r;
    }
}

sub Forks::Super::Tie::IPCSockethandle::Delegator::DESTROY {
}

1;
