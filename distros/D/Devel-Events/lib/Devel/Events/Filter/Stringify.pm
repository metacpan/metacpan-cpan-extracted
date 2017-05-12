#!/usr/bin/perl

package Devel::Events::Filter::Stringify;
use Moose;

use Scalar::Util qw/reftype/;
use overload ();

with qw/Devel::Events::Filter/;

has respect_overloading => (
	isa => "Bool",
	is  => "rw",
	default => 0,
);

sub filter_event {
	my ( $self, @event ) = @_;
	map { ref($_) ? $self->stringify($_) : $_ } @event;
}

sub stringify {
	my ( $self, $ref ) = @_;

	$self->stringify_value($ref);
}

sub stringify_value {
	my ( $self, $ref ) = @_;

	if ( $self->respect_overloading ) {
		return "$ref";
	} else {
		return overload::StrVal($ref);
	}
}

__PACKAGE__;

__END__

=pod

=head1 NAME

Devel::Events::Filter::Stringify - A simple event filter to prevent leaks

=head1 SYNOPSIS

	use Devel::Events::Filter::Stringify;

	my $handler = Devel::Events::Filter::Stringify->new(
		handler => $wrapped_handler,
	);

=head1 DESCRIPTION

This event filter will remove all reference data from events.

Events may contain references to the data they are reporting on. If the event
data is not thrown away immediately this might affect the flow of the program,
causing leaks.

This filter prevents leaks from happenning when an event logger is used by
simply stringifying all data.

Note that objects that overload stringification will *not* have their
stringification callbacks activated unless C<respect_overloading> is set to a
true value.

=head1 SUBCLASSING

In order ot perform custom dumps of objects that are more descriptive or even
useful for log replay, override the C<stringify> method.

=head1 ATTRIBUTES

=over 4

=item respect_overloading

See C<respect_overloading>

=back

=head1 METHODS

=over 4

=item filter_event @event

See L<Devel::Events::Filter>.

Will map the values in C<@event> calling C<stringify> on reference elements.

=item stringify $ref

Simply delegates to C<stringify_value> at this point.

In the future minimal formatting may be added.

=item stringify_value $ref

This method will do either C<"$_"> or C<overload::StrVal($_)> depending on the
value of C<respect_overloading>.

=back

=cut


