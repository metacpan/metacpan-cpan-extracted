package HPCI::TimeoutQueue;

### INCLUDES ##################################################################

# safe Perl
use warnings;
use strict;

=head1 NAME

	HPCI::TimeoutQueue;

=head1 SYNOPSIS

Manage a collection of requests for timeout notifications.

=head1 DESCRIPTION

This is used internally to HPCI - no user-serviceable parts to be
found here.

A TimeoutQueue keeps a list of outstanding timeout entries.
Each entry consists of a time when it will trigger (passed in as
seconds until trigger, stored internally as epoch time of the trigger
moment), an object to be informed, along with the name of the method
to call to inform the object, and any additional arguments required.

They are kept in a list, sorted in trigger order.

When entries are deleted before being triggered, they are deleted
only if they are at an end of the list.  They are not removed if
they are in the middle of the list; instead the object field is
set to undef.

When a new object is being inserted, it will replace a "deleted"
entry (undef object) if there is one in an acceptable spot.

=head1 METHODS

=head2 new

No arguments, initials a new TimeoutQueue object.

=cut

sub new {
	my $class = shift;
	$class = ref($class) || $class;
	bless [], $class;
}

=head2 delete_timeouts( $object [, method_name [, arg ...] ] )

Deletes all timeouts which match the specified object (and method
and arg values if provided).

It may sometimes make sense to provide arg values that the method
will ignore, if there is a need to be able to selectively disable
specific timeouts while leaving others intact.

=cut

sub delete_timeouts {
	my $self = shift;
	for my $entry (@$self) {
		$entry->[1] = undef if cmp_args( $entry, \@_ );
	}
	$self->_clean_front;
	$self->_clean_back;
}

sub cmp_args {
	my( $entry, $args ) = @_;
	my $ind = 1;
	for (@$args) {
		return 0 unless $entry->[$ind++] eq $_;
	}
}

=head2 expire_timeouts

Trigger all timeouts that have expired. Returns a list of them in
array context, a count of the number triggered in scalar context,
or nothing.

=cut

sub expire_timeouts {
	my $self     = shift;
	my $now      = time;
	if (wantarray) {
		my @list;
		$self->_expire_timeouts(
			sub {
				my $elem = shift;
				$elem = [ @$elem ];
				shift @$elem;
				push @list, $elem;
			},
			@_
		);
		return \@list;
	}
	elsif (defined wantarray) {
		my $count = 0;
		$self->_expire_timeouts( sub { ++$count }, @_ );
		return $count;
	}
	else {
		$self->_expire_timeouts( undef, @_ );
		return;
	}
}

sub _expire_timeouts {
	my $self     = shift;
	my $callback = shift;
	my $now      = time;
	while (@$self && $self->[0][0] < $now) {
		my $entry = shift @$self;
		my ( undef, $obj, $meth, @args ) = @$entry;
		if (defined $obj && $obj->can($meth)) {
			$obj->$meth(@args);
			$callback->( $entry ) if $callback;
		}
	}
	$self->_clean_front;
	return;
}

=head2 time_to_next_timeout

Return the time until the next timeout will trigger.  A zero or
negative means that there is one or more not yet triggered timeout
that is already (over)due.

Returns undef if the queue is empty.

=cut

sub time_to_next_timeout {
	my $self = shift;
	return undef unless @$self;
	return $self->[0][0] - time;
}

=head2 add_timeout( seconds_until_trigger, object, method[, args ...] )

Add a timeout trigger entry to the queue.

The time until the trigger is given in seconds, but is converted
to seconds from epoch by adding the current time to it.

If the trigger time is reached without the entry being deleted,
the specified object will be notified using the specified method
(and any additional specified arguments).

This method is complicated somewhat because it tries to find a
previously deleted entry that can be replaced.

=cut

sub add_timeout {
	my $self = shift;
	my $time = shift;
	my $obj  = shift;
	my $meth = shift;

	$time += time;
	my $entry = [ $time, $obj, $meth, @_ ];

	# push on the end if we can
	# note: it is not worth the bother of checking for a deleted entry
	# that has the same trigger time, so we might push instead of
	# replacing on some rare occassions.  Here, it is better to do a
	# reasonable job quickly than a perfect job slowly.
	if (0 == scalar(@$self) || $time >= $self->[-1][0])
	{
		push @$self, $entry;
		return;
	}

	# list is not empty, last element <= trigger time

	# unshift onto the beginning if we can
	if ($time <= $self->[0][0]) {
		unshift @$self, $entry;
		return;
	}

	# list has 2+ entries (otheriwse we would have pushed or unshifted above)
	# also, replace or splice must occur BETWEEN first and last element
	my $ind = $#$self;
	--$ind while $self->[$ind][0] > $time; # will stop at 0 or higher
	# ind is highest index without a later time, cant be last
	if (not defined $self->[$ind+1][1]) {
		$self->[$ind+1] = $entry;
		return;
	}

	--$ind while $self->[$ind][0] == $time && defined $self->[$ind][1];
	# ind is highest index with a earlier time, or is replaceable with equal time
	if (not defined $self->[$ind][1]) {
		$self->[$ind] = $entry;
		return;
	}

	# cant replace anything without copying chunk of the array
	splice @$self, $ind, 0, $entry;
	return;
}

=head2 _clean_front

=head2 _clean_back

The state of the TimeoutQueue, execpt in the middle of internal
operations, guarantees that the first and last entries in the list
(if there are any entries) are not deleted elements.

_clean_front and _clean_back are internal methods used to
re-establish this assertion whenever any action is taken that might
have disrupted it.

=cut

sub _clean_front {
	my $self = shift;
	shift @$self while scalar(@$self) && not defined $self->[0][1];
}

sub _clean_back {
	my $self = shift;
	pop @$self while scalar(@$self) && not defined $self->[-1][1];
}

=head1 AUTHOR

John Macdonald - Boutros Lab

=head1 ACKNOWLEDGEMENTS

Paul Boutros, Phd, PI - Boutros Lab

The Ontario Institute for Cancer Research

=cut

1;
