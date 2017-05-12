#!/usr/bin/perl

package Devel::Events::Filter::Stamp;
use Moose;

with qw/Devel::Events::Filter/;

use Time::HiRes qw/time/;

sub filter_event {
	my ( $self, $type, @data ) = @_;

	return (
		$type,
		$self->stamp_data,
		@data,
	);
}

my $i;

sub stamp_data {
	return (
		id   => ++$i,
		time => time(), # DateTime eats HiRes time =D
		pid  => $$,
		( defined &Thread::tid # Only if threads are loaded
			? ( thread_id => Thread->self->tid )
			: () ),
	)
}

__PACKAGE__;

__END__

=pod

=head1 NAME

Devel::Events::Filter::Stamp - Add time/context stamping to events

=head1 SYNOPSIS

	use Devel::Events::Filter::Stamp;

	my $filter = Devel::Events::Filter::Stamp->new(
		handler => $handler,
	);

	Generator::Blah->new( handler => $filter );

=head1 DESCRIPTION

This event filter will add timing and context information to the event.

The parameters are prepended so that upon hash assignment the event generator
will get precedence.

=head1 METHODS

=over 4

=item filter_event @event

Prepends the output of C<stamp_data> to C<@event>

=item stamp_data

Returns the new fields, as detailed in L</STAMP DATA>

=back

=head1 STAMP DATA

=over 4

=item time

A fractional timestamp, from L<Time::HiRes>.

Suitable for passing to L<DateTime> unaltered. Other modules may require application of C<int>.

=item pid

The value of C<$$>

=item thread_id

Only included if threads are in use.

The current thread ID.

=back

=cut


