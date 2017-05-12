#!/usr/bin/perl

package Devel::Events::Filter::Drop;
use Moose;

with qw/Devel::Events::Filter/;

use Devel::Events::Match;

has non_matching => (
	isa => "Bool",
	is  => "rw",
	default => 0,
);

has matcher => (
	isa => "Devel::Events::Match",
	is  => "ro",
	default => sub { Devel::Events::Match->new },
);

has match => (
	isa => "Any",
	is  => "ro",
	required => 1,
);

has _compiled_match => (
	isa => "CodeRef",
	is  => "ro",
	lazy    => 1,
	default => sub { 
		my $self = shift;
		$self->_compile_match;
	},
);

sub _compile_match {
	my $self = shift;
	$self->matcher->compile_cond( $self->match );
}

sub filter_event {
	my ( $self, @event ) = @_;

	my $event_matches = $self->_compiled_match->(@event);

	if ( $event_matches xor !$self->non_matching ) {
		return @event;
	} else {
		return;
	}
}


__PACKAGE__;

__END__

=pod

=head1 NAME

Devel::Events::Filter::Drop - Remove events that match or don't match a
condition.

=head1 SYNOPSIS

	use Devel::Events::Filter::Drop;

	my $f = Devel::Events::Filter::Drop->new(
		match        => $cond, # see Devel::Events::Match
		non_matching => 1,     # invert so that nonmatching events get dropped
		handler      => $h,
	);

=head1 DESCRIPTION

This filter allows dropping of events that match (or that don't match) a
condition. The actual matching is done by L<Devel::Events::Match>.

=head1 ATTRIBUTES

=over 4

=item match

The condition to be passed to L<Devel::Events::Match/compile_cond>.

=item matcher

An instance of L<Devel::Events::Match> used to compile C<match>.

=item non_matching

Drop events that don't match the condition, instead of ones that do.

=back

=head1 METHODS

=over 4

=item filter_event @event

Delegates to the compiled condition and then returns the event unaltered or
returns nothing based on the values of C<non_matching> and the result of the
match.

=back

=cut

