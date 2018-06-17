package Forks::Super::Sync::IPCSemaphore;
use strict;
use warnings;
use Carp;
use Time::HiRes;
use POSIX ':sys_wait_h';
use IPC::SysV qw(IPC_PRIVATE S_IRUSR S_IWUSR IPC_CREAT IPC_NOWAIT);
use IPC::Semaphore;
use Forks::Super::Util qw(DEVNULL DEVTTY Ctime);
our @ISA = qw(Forks::Super::Sync);
our $VERSION = '0.94';

our $NOWAIT_YIELD_DURATION = 0.05;

my @RELEASE_ON_EXIT = ();

sub new {
    my ($pkg, $count, @initial) = @_;

    if ($^O eq 'MSWin32' || $^O eq 'cygwin') {
	return;
    }

    my $self = bless{ count => $count, initial => [ @initial ] }, $pkg;

    $self->{sems} = eval {
	IPC::Semaphore->new(
	    &IPC_PRIVATE, $count, &S_IRUSR|&S_IWUSR|&IPC_CREAT);
    };
    unless ($self->{sems}) {
	carp "IPC::Semaphore constructor failed: $@";
	return;
    }

    # set initial semaphore values before fork
    my @set = map { $_ eq 'P' || $_ eq 'C' ? 1 : 0 } @initial;
    push @set, (0) x $count;
    @set = splice @set, 0, $count;
    $self->{sems}->setall(@set);

    return $self;
}

sub _releaseAfterFork {
    my ($self, $childPid) = @_;

    $self->{childPid} = $childPid;
    my $label = $self->{label} = $$ == $self->{ppid} ? "P" : "C";
    for my $i (0 .. $self->{count}-1) {
	if ($self->{initial}[$i] eq $label) {
            # semaphore was already acquired before the fork
            # but we need to set $self->{acquired};
            $self->{acquired}[$i] = 1;
	}
    }
    return;
}

sub release {
    my ($self, $n) = @_;
    if ($n < 0 || $n >= $self->{count}) {
        return;
    }
    if ($self->{acquired}[$n]) {
	$self->{sems} && $self->{sems}->op($n, -1, 0);
	$self->{acquired}[$n] = 0;
	return 1;
    }
    return;
}

# robuster version of  $self->{sems}->op($n,0,FLAGS, $n,1,FLAGS)
# detects when partner process has died without removing the semaphore
# return true if successfully waited on lock and incremented the semaphore
sub _wait_on {
    my ($self, $n, $expire) = @_;
    if (!$self->{sems}) {
        return 1;
    }

    my $partner = $$ == $self->{ppid} ? $self->{childPid} : $self->{ppid};

    while (1) {
	local $! = 0;

	my $nk = $partner && CORE::kill 0, $partner;
	if (!$nk) {
	    carp "sync::_wait_on $$ thinks that $partner is gone ...return 3.1";
	    $self->{skip_wait_on} = 1;
	    delete $self->{sems};
	    return $Forks::Super::Sync::SYNC_PARTNER_GONE + 0.1;
	}
        if (!$self->{sems}) {
            carp "sync::_wait_on: semaphore resource not available";
            return 4;
        }

	my $z = $self->{sems}->op($n, 0, &IPC_NOWAIT,
                                  $n, 1, 0);
	if ($z) {
	    return 1;
	} elsif ($!{EINVAL}) {  # semaphore was removed

	    carp "sync::_wait_on: \$!=Invalid resource ... return 2";
	    return 2;
	}

	if ($expire > 0 && Time::HiRes::time() >= $expire) {
	    return 0;
	}

	# sem value not zero. Is the process that partner process still alive?
	if (!CORE::kill(0, $partner)) {
	    carp "sync::_wait_on thinks that $partner is gone ...return 3";
	    $self->{skip_wait_on} = 1;
	    delete $self->{sems};
	    return $Forks::Super::Sync::SYNC_PARTNER_GONE;
	}
	Time::HiRes::sleep( $NOWAIT_YIELD_DURATION );
	my $z5 = waitpid -1, &WNOHANG;
    }
    return; # unreachable
}

sub acquire {
    my ($self, $n, $timeout) = @_;
    if ($n < 0 || $n >= $self->{count}) {
	return;
    }
    if ($n >= 0 && $self->{acquired}[$n]) {
	return -1; # already acquired
    }


    my $expire = -1;
    if (defined $timeout) {
	$expire = Time::HiRes::time() + $timeout;
    }
    my $z = $self->_wait_on($n, $expire);
    if ($z > 0) {
        $self->{acquired}[$n] = 1;
    }

    if ($z > 1) {
	return "0 but true";
    }
    return $z;
}

END {
    foreach my $sync (@RELEASE_ON_EXIT) {
	$sync->release($_) for 0 .. $sync->{count} - 1;
	$sync->{sems} && $sync->{sems}->remove;
    }
}

1;

=head1 NAME

Forks::Super::Sync::IPCSemaphore
- Forks::Super sync object using SysV semaphores

=head1 SYNOPSIS

    $lock = Forks::Super::Sync->new(implementation => 'IPCSemaphore', ...);

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

IPC synchronization object implemented with SysV semaphores.

Advantages: fast, doesn't create files or use filehandles

Disadvantages: Unix only. Gets complicated when a child process dies
without releasing its locks.

=head1 SEE ALSO

L<Forks::Super::Sync|Forks::Super::Sync>

=cut
