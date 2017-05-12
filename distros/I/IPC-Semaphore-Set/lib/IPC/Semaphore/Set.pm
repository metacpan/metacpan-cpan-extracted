package IPC::Semaphore::Set;
use strict;
use warnings;

use 5.008;
use Digest::CRC qw(crc8);
use IPC::SysV qw(IPC_PRIVATE IPC_CREAT IPC_NOWAIT S_IRUSR S_IWUSR);
use IPC::Semaphore;
use IPC::Semaphore::Set::Resource;

our $VERSION = 1.20;

############
## Public ##
############

sub new
{
	my $class = shift;
	my $args  = ref($_[0]) ? $_[0] : {@_};
	# set some sane defaults: we want at least one resource (semaphore in the set),
	# and for each semaphore we want it to have a value of at least one, and
	# when working on the semaphore by default we want to use IPC_CREAT to create
	# the semaphore if it didn't already exist, and S_IRUSR & S_IWUSR to give the
	# semaphore read and write permissions for the current perl user which you could
	# see by getting and viewing the results of the perl function getlogin()
	$args->{_resources} = delete($args->{resources}) || 1;
	$args->{_value}     = delete($args->{value})     || 1;
	$args->{_flags}     = delete($args->{flags})     || S_IRUSR | S_IWUSR | IPC_CREAT;
	# determine if we're using a key_name, key, or private semaphore set
	my $self = bless($args, $class);
	if (my $key = $self->{key}) {
		if ($key =~ m/[^0-9]/) {
			die "key [$key] was not numeric";
		}
		$self->{_pre_exist} = semget($key, 0, IPC_NOWAIT);
		$self->{_key}       = $key;
		$self->{_semaphore} = IPC::Semaphore->new($key, $self->{_resources}, $self->{_flags});
	} elsif (my $key_name = $self->{key_name}) {
		$self->{_key_name}  = $key_name;
		$self->{_key}       = crc8($key_name);
		$self->{_pre_exist} = semget($self->{_key}, 0, IPC_NOWAIT);
		$self->{_semaphore} = IPC::Semaphore->new($self->key, $self->{_resources}, $self->{_flags});
	} else {
		$self->{_semaphore} = IPC::Semaphore->new(IPC_PRIVATE, $self->{_resources}, $self->{_flags});
	}
	# bail out if we didn't get an IPC::Semaphore
	if (ref($self->semaphore) ne 'IPC::Semaphore') {
		die 'could not get a semaphore with ' . $self->key . ": $!";
	}
	# if we created this semaphore, allow use of 'available' but if we didn't, don't clobber what
	# the semaphore resources were already set to
	if (!$self->{_pre_exist}) {
		$self->semaphore->setall(($self->{_value}) x $self->{_resources});
	}
	return $self;
}

sub resource
{
	my $self = shift;
	my $args = ref($_[0]) ? $_[0] : {@_};
	# default to 0, the first resource in the set
	$args->{number} = $args->{number} ? $args->{number} : 0;
	if (!$self->{resources}{$args->{number}}) {
		$args->{key}       = $self->key ? $self->key : IPC_PRIVATE;
		$args->{semaphore} = $self->semaphore;
		$self->{resources}{$args->{number}} = IPC::Semaphore::Set::Resource->new($args);
	}
	return $self->{resources}{$args->{number}};
}

sub resources
{
	my $self  = shift;
	my $total = () = $self->semaphore->getall;
	my @resources;
	for (0..($total - 1)) {
		push(@resources, $self->resource(number => $_));
	}
	return wantarray ? @resources : \@resources;
}

############
## Helper ##
############

sub id        {return shift->sem->id}
sub key       {return shift->{_key}}
sub keyName   {return shift->{_key_name}}
sub remove    {return shift->semaphore->remove ? 1 : 0}
sub semaphore {return shift->{_semaphore}}

1;

__END__

=head1 NAME

IPC::Semaphore::Set

=head1 DESCRIPTION

An abstract interface to semaphore sets and their resources.

A semaphore is an abstract data type that is provided by the system
to give access control to common resources by multiple processes in
parallel programming or in a multi-user environment.

A semaphore 'set' is the set of resources the system provides by an
identification number, and the values (availability) of those resources.

Resources are the semaphores themselves in the set.

You could, for instance, use a semaphore to lock on a single file between
multiple processes by saying that the set has one resource (one file) and
that the resource has one availability (one process can use it at one time).
You could also represent a series of network printers. Perhaps you have
five printers that all have the ability to do ten jobs. You could create
the semaphore set with five resources, each resource with ten availability.

This module tries to "Do The Right Thing". It assumes a lot about what
you're looking for when you call '->new', and basically will set you up with
a semaphore set that has at least one resource with at least one availability.
If this assumption is wrong for your purposes, pay close attention to the
options for '->new'.

=head1 SYNOPSIS

Get/Create a semaphore set:

	my $semset = IPC::Semaphore::Set->new(
		key_name     => 'my_lock',
		resources    => 2,
		availability => 3,
	);

The above semaphore set has two resource, each of those resources has
an availability of three.

Now you can get the first resource (resource 0):

	my $resource = $semset->resource;

Or you can select the resource explicitly:

	my $resource = $semset->resource(1);

But note that with two resources total, one is our last resource because we
start at "0".

You can make conditionals checking whether or not a lock is available on
the resource:

	if ($semset->resource->lock) {
		# ... can use resource!
	} else {
		# ... can't use resource!
	}

You can simply wait for resource availability:

	$semset->resource->lockWait;
	# ... resource is now available

You can die if the resource isn't currently available:

	$semset->resource->lockOrDie;
	# ... if we're here we have a lock

=head1 METHODS

=over

=item new

Get a new IPC::Semaphore::Set object. If 'key' is provided, get
or create a semaphore with that key. if 'key_name' is provided,
generate a key based off of the ascii character codes of that name.
If neither is provided, a new 'private' semaphore set will be created
(note that 'private' is how SysV refers to it, but this is something
of a misnomer).

=over

=item ARGUMENTS

=over

=item key

A numeric key to get/create the semaphore.

=item key_name

A string key to get/create the semaphore.

=item value

How much value (availability) the resources in the set should have.
Is ignored if the semaphore existed previously, and is optional. Defaults to 1.

=item resources

How many resources (semaphores) will be in the set. Is ignored if the
semaphore existed previously, and is optional. Defaults to 1.

=item flags

IPC::SysV flags that will be used to create the semaphore set.

Defaults to the following:

	S_IRUSR | S_IWUSR | IPC_CREAT | SEM_UNDO

Which means it creates it if it doesn't exist, keeps track of ownership,
and will clean up it's changes after exit.

=back

=back

=item resource

Returns a IPC::Semaphore::Set::Resource object.

A "resource" is an abstraction around a semaphore in a set. For every
semaphore present in your semaphore set you will have a "resource" to
reference that.

=over

=item ARGUMENTS

=over

=item number

The number of the resource in the semaphore set

=item semaphore

The IPC::Semaphore object that the resource is a part of.

=item key

The number that represents the set.

=item cleanup_object

Boolean. If enabled the object DESTROY will revert changes to the resource.

Defaults to 1.

=over

=back

=back

=item RESOURCE METHODS

=over

=item lock

Attempts to get a lock on the resource and returns boolean.

=item lockWait

Waits until a lock becomes available on the resource then returns 1.

=item lockWaitTimeout

Takes first argument as seconds to wait for a lock, or defaults to 3 seconds.

Returns boolean.

=item lockWaitTimeoutDie

Takes first arguments as seconds to wait for a lock, or defaults to 3 seconds.

Dies if a lock can not be established, or returns 1.

=item lockOrDie

Attempts to get a lock on the resource and dies if it can not. Returns 1 otherwise.

=item addValue

Adds a single point of value to the resource

=item number

Returns the number of the resource in its semaphore set

=item semaphore

Returns the IPC::Semaphore the resource is a part of.

=item value

Returns the value of the current semaphore resource.

=back

=back

=item resources

Returns a list or arrayref of all the IPC::Semaphore::Set::Resource objects
available for this semaphore set.

=item id

Returns the numeric system ID of the semaphore set.

=item key

Returns the numeric key if available.

=item keyName

Returns the 'word' key if used.

=item remove

Remove the semaphore set entirely from the system.

=item sem

Returns the internal 'IPC::Semaphore' object.

=back

=cut

# ABSTRACT: An abstract Perl5 interface to semaphore sets and their resources

