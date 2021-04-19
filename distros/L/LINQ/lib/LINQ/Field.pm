use 5.006;
use strict;
use warnings;

package LINQ::Field;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.002';

use Class::Tiny qw( index name value params );

sub BUILD {
	my ( $self ) = ( shift );
	
	if ( not $self->{params} ) {
		$self->{params} = {};
	}
	
	if ( not defined $self->{name} ) {
		if ( defined $self->{params}{as} ) {
			$self->{name} = $self->{params}{as};
		}
		elsif ( !ref $self->{value} and $self->{value} =~ /\A[^\W0-9]\w*\z/ ) {
			$self->{name} = $self->{value};
		}
		else {
			$self->{name} = sprintf( '_%d', $self->{index} );
		}
	} #/ if ( not defined $self...)
	
} #/ sub BUILD

sub getter {
	my ( $self ) = @_;
	$self->{getter} ||= $self->_build_getter;
}

sub _build_getter {
	my ( $self ) = @_;
	
	my $attr = $self->value;
	
	if ( ref( $attr ) eq 'CODE' ) {
		return $attr;
	}
	
	require Scalar::Util;
	
	return sub {
		my $blessed = Scalar::Util::blessed( $_ );
		if ( ( $blessed || '' ) =~ /\AObject::Adhoc::__ANON__::/ ) {
			$blessed = undef;
		}
		scalar( $blessed ? $_->$attr : $_->{$attr} );
	};
} #/ sub _build_getter

1;

__END__

=pod

=encoding utf-8

=head1 NAME

LINQ::Field - represents a single field in a LINQ::FieldSet

=head1 DESCRIPTION

See L<LINQ::FieldSet> for details.

This is used internally by LINQ and you probably don't need to know about it
unless you're writing very specific extensions for LINQ.

=head1 CONSTRUCTOR

=over

=item C<< new( ARGSHASH ) >>

=back

=begin trustme

=item BUILD

=end trustme 

=head1 METHODS

=over

=item C<index>

The order of a field within a fieldset. Starts at zero.

=item C<name>

The name of a field.

=item C<value>

The hashref key or method name used to find the value for the field from
a hashref or object; or a coderef which will get the value from C<< $_ >>.

=item C<params>

Additional metadata for the field.

=item C<getter>

A coderef which will get the value of a field from C<< $_ >>.

=back

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=LINQ>.

=head1 SEE ALSO

L<LINQ::FieldSet>.

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
