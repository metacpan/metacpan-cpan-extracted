#
# tied filehandle class for interprocess communication file and socket
# handles. This class is mainly for facilitating testing and debugging.
# We ought to be able to drop in and drop out this class without
# changing the behavior of any application using Forks::Super.
#

# usage:
#    $fh = gensym();
#    create real pipe handle (pipe, IO::Pipe->new, etc.)
#    tie *$fh, 'Forks::Super::Tie::IPCPipeHandle',
#            *$the_real_pipe_handle, $fh;


package Forks::Super::Tie::IPCPipeHandle;
use Forks::Super::Tie::IPCFileHandle;
use Forks::Super::Debug ':all';

use Exporter;
use strict;
use warnings;
use Carp;
use IO::Pipe;
use IO::Handle;

our @ISA = qw(IO::Pipe IO::Handle);
our $VERSION = '0.89';

sub TIEHANDLE {
    my ($class, $real_pipe, $glob) = @_;
    $$glob->{DELEGATE} = $real_pipe;
    eval {
	bless $glob, 'Forks::Super::Tie::IPCPipeHandle::Delegator';
    } or carp 'Forks::Super::Tie::IPCPipeHandle: ',
	    "failed to bless tied obj as a Delegator\n";

    # any attributes that the real pipe had should be passed
    # on to the glob.
    foreach my $attr (keys %$$real_pipe) {
	$$glob->{$attr} = $$real_pipe->{$attr};
    }

    # apply PerlIO layers to the real pipe here
    my $job = $$glob->{job} || Forks::Super::Job->this;
    if (defined($job) && $job->{fh_config}{layers}) {
	my @io_layers = @{$job->{fh_config}{layers}};
	if ($$real_pipe->{is_read}) {
	    @io_layers = reverse @io_layers;
	}
	foreach my $layer (@io_layers) {
	    local $! = 0;
	    if (binmode $real_pipe, $layer) {
		if ($job->{debug}) {
		    debug("applied PerlIO layer $layer to pipe $real_pipe");
		}
	    } else {
		carp 'Forks::Super::Tie::IPCPipeHandle: ',
			"failed to apply PerlIO layer $layer to $real_pipe: $!";
	    }
	}
    }

    my $self = { PIPE => $real_pipe, GLOB => $glob };
    $self->{_FILENO} = CORE::fileno($real_pipe);

    bless $self, $class;
    return $self;
}

#############################################################################

sub OPEN {
    Carp::confess "Can't call 'open' on a pipe handle\n";
}

sub BINMODE {
    my ($self, $layer) = @_;
    $self->{BINMODE}++;
    return binmode $self->{PIPE}, $layer || ':raw';
}

sub GETC {
    my $self = shift;
    $self->{GETC}++;

    my $buffer = '';

    # sysread returns undef on solaris in t/44j. 
    # Is the SIGCHLD causing an interruption?
    {
	local $! = 0;
	my $n = sysread $self->{PIPE}, $buffer, 1;
	if (!defined $n) {
	    if ($!{EINTR}) {
		redo;
	    }
	    carp "IPCPipeHandle::GETC: $!";
	    return;
	}
	if ($n == 0) {
	    return;
	}
    }
    return $buffer;
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

    my $z = print {$self->{PIPE}} @list;
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

    my $n = syswrite $self->{PIPE}, $string, $length, $offset;
    return $n;
}

sub READLINE {
    my $self = shift;
    $self->{READLINE}++;
    my $glob = $self->{GLOB};
    if ($$glob->{job} || ref($$glob->{job})) {
	return Forks::Super::Job::Ipc::_read_pipe(

	    # XXX - block should be determined by the $job settings
	    # read pipe is blocking by default
	    $self->{PIPE}, $$glob->{job}, wantarray, block => 1);
    }

    return readline($self->{PIPE});
}

sub TELL {
    my $self = shift;
    $self->{TELL}++;
    return tell $self->{PIPE};
}

sub EOF {
    my $self = shift;
    return eof $self->{PIPE};
}


# we will almost always use select4 before reading, so
# we prefer to use sysread and sysseek
sub READ {
    my ($self, undef, $length, $offset) = @_;
    $self->{READ}++;

    # XXX - blocking ? timeout ?

    # we could get a "sysread() is deprecated on :utf8 handles"?
    return sysread $self->{PIPE}, $_[1], $length, $offset || 0;
}

sub SEEK {
    my ($self, $position, $whence) = @_;
    $self->{SEEK}++;
    return sysseek $self->{PIPE}, $position, $whence;
}



sub is_pipe {
    return 0;
}

sub opened {
    my $self = shift;
    return $self->{PIPE}->opened;
}

sub CLOSE {
    my $self = shift;
    if (&Forks::Super::Job::_INSIDE_END_QUEUE) {
	untie *{$self->{GLOB}};
	if ($self->{PIPE}) {
	    close $self->{PIPE};
	}
	close *{$self->{GLOB}};
    }

    if (!$self->{CLOSE}++) {
	${$self->{GLOB}}->{closed}++;
	return close delete $self->{PIPE};
    }
    return;
}

sub UNTIE {
    my $self = shift;
    if ($self->{PIPE}) {
        close $self->{PIPE};
    }
    return;
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
sub Forks::Super::Tie::IPCPipeHandle::Delegator::AUTOLOAD {
    return if &Forks::Super::Job::_INSIDE_END_QUEUE;
    my $method = $Forks::Super::Tie::IPCPipeHandle::Delegator::AUTOLOAD;
    $method =~ s/.*:://;
    my $delegator = shift;
    return if !$delegator;

    my $delegate = $$delegator->{DELEGATE};
    return if !$delegate;

    ## no critic (StringyEval)
    if (wantarray) {
	my @r = eval "\$delegate->$method(\@_)";
	if ($@) {
	    Carp::cluck "IPCPipeHandle delegate fail: $method @_; error=$@\n";
	}
	return @r;
    } else {
	my $r = eval "\$delegate->$method(\@_)";
	if ($@) {
	    Carp::cluck "IPCPipeHandle delegate fail: $method @_; error=$@\n";
	}
	return $r;
    }
}

sub Forks::Super::Tie::IPCPipeHandle::Delegator::DESTROY {
}

1;
