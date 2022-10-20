use 5.006;
use strict;
use warnings;

package LINQ::FieldSet::Single;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.003';

use Class::Tiny;
use parent qw( LINQ::FieldSet );

use overload (
	'fallback' => !!1,
	q[bool]    => sub { !! 1 },
	q[""]      => 'to_string',
	q[&{}]     => 'coderef',
);

sub new {
	my $class = shift;
	my $field = shift;
	my $self  = $class->SUPER::new( $field );
	
	if ( wantarray ) {
		return ( $self, @_ );
	}
	
	if ( @_ ) {
		LINQ::Util::Internal::throw(
			'CallerError',
			'message' => 'Unexpected extra parameters; single field name expected',
		);
	}
	
	return $self;
}

sub coderef {
	my ( $self ) = ( shift );
	$self->{coderef} ||= $self->_build_coderef;
}

sub _build_coderef {
	my ( $self )  = ( shift );
	my ( $field ) = @{ $self->fields };
	return $field->getter;
}

sub to_string {
	my ( $self ) = ( shift );
	sprintf 'field(%s)', join q[, ], map $_->name, @{ $self->fields };
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

LINQ::FieldSet::Single - similar to LINQ::FieldSet::Selection, but only selects one field

=head1 DESCRIPTION

LINQ::FieldSet::Single is a subclass of L<LINQ::FieldSet>.

This is used internally by LINQ and you probably don't need to know about it
unless you're writing very specific extensions for LINQ. The end user
interface is the C<field> function in L<LINQ::Util>.

=head1 CONSTRUCTOR

=over

=item C<< new( NAME, EXTRAARGS ) >>

Constructs a fieldset like:

  'LINQ::FieldSet::Single'->new( 'name', @stuff );

If called in scalar context, and C<< @stuff >> isn't the empty list, then
will throw an exception.

If called in list context, will return the newly constructed object followed
by unadulterated C<< @stuff >>.

=back

=head1 METHODS

=over

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
