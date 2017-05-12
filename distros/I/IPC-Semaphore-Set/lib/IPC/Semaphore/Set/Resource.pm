package IPC::Semaphore::Set::Resource;
use strict;
use warnings;

use 5.008;
use IPC::SysV qw(SEM_UNDO IPC_NOWAIT);

our $VERSION = 1.20;

############
## Public ##
############

sub new
{
	my $class = shift;
	my $args  = ref($_[0]) ? $_[0] : {@_};
	# check for required arguments.
	die "'key' is required"       unless defined($args->{key});
	die "'number' is required"    unless defined($args->{number});
	die "'semaphore' is required" unless (ref($args->{semaphore}) eq 'IPC::Semaphore');
	# 'cleanup_object' determines whether or not we'll be cleaning up in DESTROY
	if (!defined($args->{cleanup_object})) {
		$args->{cleanup_object} = 1;
	}
	my $self = bless($args, $class);
	# blow up if the system doesn't have this resource in the set
	if (!defined($self->value)) {
		my $total = () = $self->semaphore->getall;
		die $self->{number} . ' is not a valid resource for semaphore [' . $self->{key}
			. "] which only has [$total] total resources. The resources start at 0.";
	}
	return bless($args, $class);
}

sub lockOrDie {
	my $self  = shift;
	if ($self->_lock(IPC_NOWAIT)) {
		return 1;
	} else {
		die "could not lock on semaphore [$self->{key}] resource number [$self->{number}]";
	}
}

sub lockWaitTimeout
{
	my $self    = shift;
	my $timeout = shift || 3;
	my $lock;
	eval {
		local $SIG{ALRM} = sub { die "alarm\n" };
		alarm $timeout;
		$lock = $self->_lock;
		alarm 0;
	};
	if (!$lock) {
		return 0;
	}
	return 1;
}

sub lockWaitTimeoutDie
{
	my $self    = shift;
	my $timeout = shift || 3;
	my $lock;
	eval {
		local $SIG{ALRM} = sub { die "alarm\n" };
		alarm $timeout;
		$lock = $self->_lock;
		alarm 0;
	};
	if (!$lock) {
		die "could not establish lock after $timeout seconds";
	}
	return 1;
}

sub lock     {return shift->_lock(IPC_NOWAIT)      ? 1 : 0}
sub lockWait {return shift->_lock                  ? 1 : 0}
sub addValue {return shift->_add_value(IPC_NOWAIT) ? 1 : 0}

############
## Helper ##
############

sub number    {return shift->{number}}
sub semaphore {return shift->{semaphore}}

sub value {
	my $self = shift;
	return $self->semaphore->getval($self->number);
}

#############
## Private ##
#############

sub _lock
{
	my ($self, $flags) = @_;
	if ($self->semaphore->op($self->number, -1, $flags)) {
		$self->{_locks}++;
		return 1;
	}
	return 0;
}

sub _add_value
{
	my ($self, $flags) = @_;
	if ($self->semaphore->op($self->number, 1, $flags)) {
		$self->{_locks}--;
		return 1;
	}
	return 0;
}

sub DESTROY
{
	my $self = shift;
	return unless $self->{cleanup_object};
	if (defined($self->{_locks})) {
		if ($self->{_locks} > 0) {
			while ($self->{_locks} > 0) {
				$self->semaphore->op($self->number, 1, IPC_NOWAIT);
				$self->{_locks}--;
			}
		}
		if ($self->{_locks} < 0) {
			while ($self->{_locks} < 0) {
				$self->semaphore->op($self->number, -1, IPC_NOWAIT);
				$self->{_locks}++;
			}
		}
	}
}

1;

__END__

=head1 NAME

IPC::Semaphore::Set::Resource;

=head1 DESCRIPTION

A simple interface to a resource value in a semaphore set.

=cut

