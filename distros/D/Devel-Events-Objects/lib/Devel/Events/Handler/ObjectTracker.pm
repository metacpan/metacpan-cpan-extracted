#!/usr/bin/perl

package Devel::Events::Handler::ObjectTracker;
use Moose;

with qw/Devel::Events::Handler/;

use Scalar::Util qw/refaddr weaken/;
use Tie::RefHash::Weak;

has live_objects => (
	isa => "HashRef",
	is  => "ro",
	default => sub {
		tie my %hash, 'Tie::RefHash::Weak';
		\%hash;	
	},
);

has object_to_class => (
	isa => "HashRef",
	is  => "ro",
	default => sub { +{} },
);

has class_counters => (
	isa => "HashRef",
	is  => "ro",
	default => sub { +{} },
);

sub new_event {
	my ( $self, $type, @data ) = @_;

	if ( $self->can( my $method = "handle_$type" ) ) { # FIXME pattern match? i want erlang =)
		$self->$method( @data );
	}
}

sub handle_object_bless {
	my ( $self, %args ) = @_;

	return unless $args{tracked}; # don't keep track of objects that can't be garbage collected (shared code refs for instance)

	my $object = $args{object};
	my $class  = $args{class};

	my $class_counters = $self->class_counters;

	$class_counters->{$class}++;

	if ( defined(my $old_class = $args{old_class}) ) {
		# rebless
		$class_counters->{$old_class}--;
	} else {
		# new object
		my $entry = $self->event_to_entry( %args );
		( tied %{ $self->live_objects } )->STORE( $object, $entry ); # FIXME hash access triggers overload +0
	}

	# we need this because in object_destroy it's not blessed anymore
	#( tied %{ $self->object_to_class } )->STORE( $object, $class );
	$self->object_to_class->{refaddr($object)} = $class;
}

sub event_to_entry {
	my ( $self, %entry ) = @_;

	weaken($entry{object});

	return \%entry;
}

sub handle_object_destroy {
	my ( $self, %args ) = @_;
	
	my $object = $args{object};

	if ( defined( my $class = delete($self->object_to_class->{refaddr($object)}) ) ) {
		$self->class_counters->{$class}--;
	}
}

__PACKAGE__;

__END__

=pod

=head1 NAME

Devel::Events::Handler::ObjectTracker - A L<Devel::Events> that tracks leaks

=head1 SYNOPSIS

	use Devel::Events::Handler::ObjectTracker;
	use Devel::Events::Generator::Objects;

	my $tracker = Devel::Events::Handler::ObjectTracker->new();

	my $gen = Devel::Events::Generator::Objects->new(
		handler => $tracker,
	);

	$gen->enable(); # start generating events

	$code->();

	$gen->disable();

	use Data::Dumper;
	warn Dumper($tracker->live_objects);

=head1 DESCRIPTION

This object will keep track of every object created and every object destroyed
based on the C<object_bless> and C<object_destroy> events. Reblessing is
accounted for.

This handler doesn't perform any magical stuff,
L<Devel::Events::Generator::Objects> is responsible for raising the proper
events.

=head1 ATTRIBUTES

=over 4

=item live_objects

A L<Tie::RefHash::Weak> hash that keeps an index of every live object and the
C<object_bless> event that created it.

=item class_counters

Keeps a count of the live instances per class, much like
L<Devel::Leak::Object>.

=item object_to_class

USed to maintain the C<class_counters> hash.

=back

=head1 METHODS

=over 4

=item new_event @event

Delegates to C<handle_object_bless> or C<handle_object_destroy>

=item handle_object_bless @event

Adds an entry in the C<live_objects> table.

=item event_to_entry @event

Munges event data into an entry for the C<live_objects> table.

=item handle_object_destroy

Decrements the C<class_counters> counter.

=back

=cut


