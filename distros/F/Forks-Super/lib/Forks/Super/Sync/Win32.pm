package Forks::Super::Sync::Win32;
use strict;
use warnings;
use Carp;
use Time::HiRes;
use POSIX ':sys_wait_h';
use Win32::Semaphore;

our @ISA = qw(Forks::Super::Sync);
our $VERSION = '0.94';
our $NOWAIT_YIELD_DURATION = 250;
my @RELEASE_ON_EXIT = ();

# Something we have to watch out for is a process dying without
# releasing the resources that it possessed. We have three
# defences against this issue below.
#
# 1. call CORE::kill 0, ... to see if other proc is still alive
# 2. check $!{EINVAL} (Win) and $!{ESRCH} (Cyg) to see if wait call failed
# 3. release resources in a DESTROY block (and  remove  func, though that
#    probably doesn't help that much)

$Forks::Super::Config::CONFIG{'Win32::Semaphore'} = 1;

my $sem_id = 0;

sub new {
    my ($pkg, $count, @initial) = @_;
    my $self = bless {}, $pkg;
    $self->{count} = $count;
    $self->{initial} = [ @initial ];
    $self->{id} = $sem_id++;

    # initial value of 1 means that resource is available
    $self->{sem} = [ map { Win32::Semaphore->new(1,1) } 1..$count ];

    $self->{ppid} = $$;
    $self->{acquired} = [];
    $self->{invalid} = [];

    return $self;
}

sub _releaseAfterFork {
    my ($self, $childPid) = @_;

    $self->{childPid} = $childPid;
    my $label = $$ == $self->{ppid} ? 'P' : 'C';

    for my $i (0 .. $self->{count} - 1) {
	if ($self->{initial}[$i] ne $label) {
	    $self->release($i);
	} else {
	    $self->acquire($i,0);
	}
    }
    return;
}

# more robust version of Win32::Semaphore->wait.
# detects when partner process has died without releasing the semaphore
# return true if successfully waited on lock
sub _wait_on {
    my ($self, $n, $expire) = @_;
    return 1 if !$self->{sem};
    my $partner = $$ == $self->{ppid} ? $self->{childPid} : $self->{ppid};
    while (1) {
	local $! = 0;
	my $nk = CORE::kill 0, $partner;
	if (!$nk) {
	    carp "sync::_wait_on thinks $partner is gone";
	    $self->{skip_wait_on} = 1;
	    delete $self->{sem};
	    return $Forks::Super::Sync::SYNC_PARTNER_GONE;
	}

	my $z = $self->{sem} && $self->{sem}[$n]->wait($NOWAIT_YIELD_DURATION);
	if ($z) {
	    return 1;
	}
	# $!{ERROR_BAD_COMMAND} is a Windows thing
	if ($!{EINVAL} || $!{ESRCH} || $!{ERROR_BAD_COMMAND}) {
	    carp "sync::_wait_on: \$!=$!";
	    return 2;
	} 
	elsif ($!) {
	    carp "\$! is ",0+$!," $! ",0+$^E," $^E ",
	        join(",", grep { $!{$_} } sort keys %!), "\n";
	}

	if ($expire > 0 && Time::HiRes::time() >= $expire) {
	    return 0;
	}
	waitpid -1, &WNOHANG;
    }
}

sub acquire {
    my ($self, $n, $timeout) = @_;
    if ($n < 0 || $n >= $self->{count}) {
	return;
    }
    if ($self->{acquired}[$n]) {
	return -1;
    }

    # XXX - need to handle the case where the partner process has died
    #       without releasing a lock

    my $expire = -1;
    if (defined $timeout) {
	$expire = Time::HiRes::time() + $timeout;
    }
    my $z = $self->_wait_on($n, $expire);
    if ($z > 0) {
	$self->{acquired}[$n] = 1;
	return 1;
    } else {
	$self->{acquired}[$n] = 0;
	return 0;
    }
}

sub release {
    my ($self, $n) = @_;
    if ($n < 0 || $n >= $self->{count}) {
	return;
    }
    if (!$self->{acquired}[$n]) {
	return 0;
    }
    $self->{acquired}[$n] = 0;
    if ($self->{sem} && $self->{sem}[$n]) {

	local ($!,$^E) = (0,0);

	my $z = eval { $self->{sem}[$n]->release() };
	if ($z) { return $z; }

	# does carp clear $! or $^E?  that's inconvenient
	my ($e,$E) = (0+$!,0+$^E);

	if (0 && $self->{DESTROYING} && $e == 0 && $E == 0) {
	  # is the other process gone?

	  use Data::Dumper;
	  print STDERR Dumper($self, $$);

	  
	}


	carp "Forks::Super::Sync::Win32::release[$n] failed: $!/$^E/$@ // ",
		"$e/$E";

	if ($E == 6 || $E == 126) { # The handle is invalid
				      # The specified module could not be found
	    # XXX - why does this happen?
	    $self->{invalid}[$n] = 1;
	    return -1;
	}

	return;

    } elsif ($self->{DESTROYING}) {
	return -1;
    } elsif ($self->{invalid}[$n]) {
	return -1;
    } else {
	carp "Forks::Super::Sync::Win32: ",
		"release [$n] called on undefined semaphore";
	$self->{invalid}[$n] = 1;
	return -1;
    }
}

sub remove {
    my $self = shift;
    $self->release($_) for 0 .. $self->{count} - 1;
    $self->{sem} = [];
    return;
}

sub DESTROY {
    my $self = shift;
    $self->{DESTROYING} = 1;
    $self->release($_) for 0 .. $self->{count}-1;
    $self->{sem} = [];
}

1;

=head1 NAME

Forks::Super::Sync::Win32
- Forks::Super sync object using Win32::Semaphore

=head1 SYNOPSIS

    $lock = Forks::Super::Sync->new(implementation => 'Win32', ...);

    $pid=fork();
    $lock->releaseAfterFork();

    if ($pid == 0) { # child code
       $lock->acquire(...);
       $lock->release(...);
    } else {
       $lock->acquire(...);
       $lock->release(...);
    }

=head1 DESCRIPTION

IPC synchronization object implemented with
L<Win32::Semaphore|Win32::Semaphore>.

Advantages: fast, doesn't create files or use filehandles

Disadvantages: Windows only. And I have unverified concerns about
what it will do if a lock-holder exits ungracefully.

=head1 SEE ALSO

L<Forks::Super::Sync|Forks::Super::Sync>

=cut

