use 5.006;
use strict;
use warnings;

package LINQ::FieldSet::Selection;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.002';

use Class::Tiny;
use parent qw( LINQ::FieldSet );

use overload (
	'fallback' => !!1,
	q[bool]    => sub { !! 1 },
	q[""]      => 'to_string',
	q[&{}]     => 'coderef',
);

sub _known_parameter_names {
	my ( $self ) = ( shift );
	
	return (
		$self->SUPER::_known_parameter_names,
		'as' => 1,
	);
}

sub target_class {
	my ( $self ) = ( shift );
	$self->{target_class} ||= $self->_build_target_class;
}

sub _build_target_class {
	my ( $self ) = ( shift );
	require Object::Adhoc;
	return Object::Adhoc::make_class( [ keys %{ $self->fields_hash } ] );
}

sub coderef {
	my ( $self ) = ( shift );
	$self->{coderef} ||= $self->_build_coderef;
}

sub _build_coderef {
	my ( $self ) = ( shift );
	my @fields   = @{ $self->fields };
	my $bless    = $self->target_class;
	my $asterisk = $self->seen_asterisk;
	return sub {
		my %output = ();
		if ( $asterisk ) {
			%output = %$_;
		}
		for my $field ( @fields ) {
			$output{ $field->name } = $field->getter->( $_ );
		}
		$asterisk ? Object::Adhoc::object( \%output ) : bless( \%output, $bless );
	};
} #/ sub _build_coderef

sub to_string {
	my ( $self ) = ( shift );
	sprintf 'fields(%s)', join q[, ], map $_->name, @{ $self->fields };
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

LINQ::FieldSet::Selection - represents an SQL-SELECT-like transformation

=head1 DESCRIPTION

LINQ::FieldSet::Selection is a subclass of L<LINQ::FieldSet>.

This is used internally by LINQ and you probably don't need to know about it
unless you're writing very specific extensions for LINQ. The end user
interface is the C<fields> function in L<LINQ::Util>.

=head1 CONSTRUCTOR

=over

=item C<< new( ARGSLIST ) >>

Constructs a fieldset from a list of fields like:

  'LINQ::FieldSet::Selection'->new(
    'field1', -param1 => 'value1', -param2,
    'field2', -param1 => 'value2',
  );

Allowed parameters are:
C<< -as >> (followed by a value).

=back

=head1 METHODS

=over

=item C<target_class>

The class data selected by this selection will be blessed into. 

=item C<coderef>

Gets a coderef for this assertion; the coderef operates on C<< $_ >>.

=item C<to_string>

Basic string representation of the fieldset.

=back

=head1 OVERLOADING

This class overloads
C<< "" >> to call the C<< to_string >> method and
C<< &{} >> to call the C<< coderef >> method.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=LINQ>.

=head1 SEE ALSO

L<LINQ::FieldSet>, L<LINQ::Util>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2021 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
