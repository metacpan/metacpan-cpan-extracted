#!/usr/bin/perl

package Devel::Events::Filter::Size;
use Moose;

with qw/Devel::Events::Filter/;

our $VERSION = "0.03";

use Devel::Size ();
#use Devel::Size::Report (); # it breaks
use Scalar::Util qw/refaddr reftype/;

has fields => (
	isa => "Any",
	is  => "ro",
);

has one_field => (
	isa => "Bool",
	is  => "ro",
	lazy    => 1,
	default => sub {
		my $self = shift;
		defined $self->fields and not ref $self->fields;
	},
);

has no_total => (
	isa => "Bool",
	is  => "rw",
);

has no_report => (
	isa => "Bool",
	is  => "rw",
	default => 1,
);

sub filter_event {
	my ( $self, @event ) = @_;
	my ( $type, @data ) = @event;

	if ( $self->is_one_field(@event) ) {
		my $field = $self->get_field(@event);

		my $ref = { @data }->{ $field };

		return ( $type, $self->calculate_sizes($ref), @data );
	} else {
		my @fields = $self->get_fields(@event);

		my %sizes;
		my %fields = map { $_ => [] } @fields;

		my @data_copy = @data;

		while ( @data_copy ) {
			my ( $key, $value ) = splice( @data_copy, 0, 2 );
			push @{ $fields{$key} }, $value if exists $fields{$key};
		}

		foreach my $field ( @fields ) {
			foreach my $ref ( grep { ref } @{ $fields{$field} ||=[] } ) {
				push @{ $sizes{$field} }, {
					refaddr => refaddr($ref),
					$self->calculate_sizes($ref)
				};
			}
		}

		return (
			$type,
			sizes => \%sizes,
			@data,
		);
	}
}

sub is_one_field {
	my ( $self, @event ) = @_;
	$self->one_field;
}

sub get_fields {
	my ( $self, @args ) = @_;

	my $fields = $self->fields;

	if ( not ref $fields ) {
		if ( defined $fields ) {
			return $fields;
		} else {
			my ( $type, @data ) = @args;
			my ( $i, %seen );
			return ( grep { !$seen{$_}++ } grep { ++$i % 2 == 1 } @data ); # even fields
		}
	} else {
		if ( reftype $fields eq 'ARRAY' ) {
			return @$fields;
		} elsif ( reftype $fields eq 'CODE' ) {
			$self->$fields(@args);
		} else {
			die "Uknown type for field spec: $fields";
		}
	}
}

sub get_field {
	my ( $self, @args ) = @_;
	( $self->get_fields(@args) )[0];
}

sub calculate_sizes {
	my ( $self, $ref ) = @_;

	return (
		$self->calculate_size($ref),
 		$self->calculate_total_size($ref),
		$self->calculate_size_report($ref),
	);
}

sub calculate_size {
	my ( $self, $ref ) = @_;
	return ( size => Devel::Size::size($ref) );
}

sub calculate_total_size {
	my ( $self, $ref ) = @_;
	return if $self->no_total;
	return ( total_size => Devel::Size::total_size($ref) );
}

sub calculate_size_report {
	my ( $self, $ref ) = @_;
	return if $self->no_report;
	require Devel::Size::Report; # only use it if necessary, since it breaks for some people.
	return ( size_report => Devel::Size::Report::report_size($ref) );
}

__PACKAGE__;

__END__

=pod

=head1 NAME

Devel::Events::Filter::Size - Add L<Devel::Size> info to event data.

=head1 SYNOPSIS

	my $f = Devel::Events::Filter::Size->new(
		handler => $h,
		fields => [qw/foo bar gorch/], # calculate the size of these fields
	);

	# OR

	my $f = Devel::Events::Filter::Size->new(
		handler => $h,
		fields => "object", # just one field
	);

=head1 DESCRIPTION

This class uses L<Devel::Size> and optionally L<Devel::Size::Report> to provide
size information for data found inside events.

Typical usage would be to apply it to the C<object> field in conjunction with
L<Devel::Events::Objects>.

=head1 ATTRIBUTES

=over 4

=item fields

The fields whose size to check.

Can be a single string, or an array reference.

When undefined all fields will be computed.

=item one_field

This parameter controls the placement of the results (top level, or under the
C<sizes> field).

It defaults to true when C<fields> is a scalar, and false in any other
situation.

=item no_total

When true, L<Devel::Size/total_size> will not be used.

Defaults to false.

=item no_report

When true, L<Devel::Size::Report> will not be used.

Defaults to true.

=back

=head1 METHODS

=over 4

=item filter_event

When C<is_one_field> returns a true value, this method will add a C<size>, and
optionally a C<total_size> and C<size_report> field to the event. Otherwise it
will add several of these to the C<sizes> field, keyed by the C<refaddr> of the
value.

Only reference types will have their sizes computed.

=item is_one_field

Internal method. Used by C<filter_event>

=item get_field

Returns the fields whose sizes need computing. This is either all fields if
C<fields> is undef, or the specified fields.

=item get_fields

Returns only one field. Used when C<is_one_field> is true.

=item calculate_sizes

Return an entry with the C<size>, C<total_size> and C<size_report> results.

=item calculate_size

See L<Devel::Size/size>

=item calculate_total_size

Optionally uses L<Devel::Size/total_size>, depending on the value of
C<no_total>.

=item calculate_size_report

Optionally loads L<Devel::Size::Report> and uses uses
L<Devel::Size::Report/report_size>, depending on the value of C<no_report>.

=back

=head1 SEE ALSO

L<Devel::Events>, L<Devel::Size>, L<Devel::Events::Filter>

=head1 AUTHOR

Yuval Kogman <nothingmuch@woobling.org>

=head1 COPYRIGHT & LICENSE

	Copyright (c) 2007 Yuval Kogman. All rights reserved
	This program is free software; you can redistribute it and/or modify it
	under the terms of the MIT license or the same terms as Perl itself.

=cut


