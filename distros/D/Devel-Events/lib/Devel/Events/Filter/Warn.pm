#!/usr/bin/perl

package Devel::Events::Filter::Warn;
use Moose;

use overload ();
use Scalar::Util qw(blessed reftype looks_like_number);

with qw/Devel::Events::Filter::HandlerOptional/;

has pretty => (
	isa => "Bool",
	is  => "rw",
	default => 1,
);

has kvp => (
	isa => "Bool",
	is  => "rw",
	default => 1,
);

has stringify => (
	isa => "Bool",
	is  => "rw",
	default => 0,
);

sub filter_event {
	my ( $self, @event ) = @_;

	if ( $self->pretty ) {
		my ( $name, @data ) = @event;

		if ( $self->kvp ) {
			my $output = "$name:";

			my $even = 1;
			foreach my $field ( @data ) {
				if ( $even ) {
					$output .= " $field =>";
				} else {
					$output .= " " . $self->_make_printable($field) . ",";
				}

				$even = !$even;
			}

			$output =~ s/,$| =>$//;

			warn "$output\n";
		} else {
			warn "$name: " . join(" ", map { $self->_make_printable($_) } @data );
		}
	} else {
		no warnings 'uninitialized';
		warn "@event\n";
	}

	return @event;
}

sub _make_printable {
	my ( $self, $field, $no_rec ) = @_;

	defined($field)
		? ( ref($field)
			? blessed($field)
				? $self->stringify ? "$field" : overload::StrVal($field)
				: ( reftype($field) eq 'ARRAY' && !$no_rec
					?  "[ " . join(", ", map { $self->_make_printable( $_, 1 ) } @$field ) . " ]"
					: "$field" )
			: ( looks_like_number($field)
				? $field
				: do {
					my $str = $field;
					# FIXME require String::Escape
					$str =~ s/\n/\\n/g;
					$str =~ s/\r/\\r/g;
					qq{"$str"}
				} ) )
		: "undef"
}

__PACKAGE__;

__END__

=pod

=head1 NAME

Devel::Events::Filter::Warn - log every event to STDERR

=head1 SYNOPSIS

	# can be used as a handler
	my $h = Devel::Events::Filter::Warn->new();

	# or as a filter in a handler chain

	my $f = Devel::Events::Filter::Warn->new(
		handler => $sub_handler,
	);

=head1 DESCRIPTION

This is a very simple debugging aid to see that your filter/handler chains are
set up correctly.

A useful helper function you can define is something along the lines of:

	sub _warn_events ($) {
		my $handler = shift;
		Devel::Events::Filter::Warn->new( handler => $handler );
	}

and then prefix handlers which seem to not be getting their events with
C<_warn_events> in the source code.

=head1 METHODS

=over 4

=item filter_event @event

calls C<warn "@event">. and returns the event unfiltered.

=back

=cut
