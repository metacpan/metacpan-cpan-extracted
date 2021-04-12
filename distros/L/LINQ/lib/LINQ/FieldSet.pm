use 5.006;
use strict;
use warnings;

package LINQ::FieldSet;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.001';

use Class::Tiny qw( fields seen_asterisk );
use LINQ::Util::Internal ();

sub _known_parameter_names {
	my ( $self ) = ( shift );
	return ();
}

sub BUILDARGS {
	my ( $class, @args ) = ( shift, @_ );
	
	if ( @args == 1 and ref( $args[0] ) eq 'HASH' ) {
		return $args[0];
	}
	
	require LINQ::Field;
	
	my %known = $class->_known_parameter_names;
	
	my @fields;
	my $idx = 0;
	my $seen_asterisk;
	
	ARG: while ( @args ) {
		my $value = shift @args;
		if ( $value eq '*' ) {
			$seen_asterisk = 1;
			next ARG;
		}
		my %params = ();
		while ( @args and !ref $args[0] and $args[0] =~ /\A-/ ) {
			my $p_name = substr( shift( @args ), 1 );
			if ( $known{$p_name} ) {
				$params{$p_name} = shift( @args );
			}
			elsif ( exists $known{$p_name} ) {
				$params{$p_name} = 1;
			}
			else {
				LINQ::Util::Internal::throw(
					'CallerError',
					message => "Unknown field parameter '$p_name'",
				);
			}
		} #/ while ( @args and !ref $args...)
		
		my $field = 'LINQ::Field'->new(
			value  => $value,
			index  => ++$idx,
			params => \%params,
		);
		push @fields, $field;
	} #/ ARG: while ( @args )
	
	return {
		fields        => \@fields,
		seen_asterisk => $seen_asterisk,
	};
} #/ sub BUILDARGS

sub fields_hash {
	my ( $self ) = ( shift );
	$self->{fields_hash} ||= $self->_build_fields_hash;
}

sub _build_fields_hash {
	my ( $self ) = ( shift );
	my %fields;
	foreach my $field ( @{ $self->fields } ) {
		$fields{ $field->name } = $field;
	}
	return \%fields;
}

1;


__END__

=pod

=encoding utf-8

=head1 NAME

LINQ::FieldSet - base class for LINQ::FieldSet::{Selection,Assertion}

=head1 DESCRIPTION

This is used internally by LINQ and you probably don't need to know about it
unless you're writing very specific extensions for LINQ.

=head1 CONSTRUCTOR

=over

=item C<< new( ARGSLIST ) >>

Constructs a fieldset from a list of fields like:

  'LINQ::FieldSet'->new(
    'field1', -param1 => 'value1', -param2,
    'field2', -param1 => 'value2',
  );

The list of allowed parameters and whether each one takes a value is returned
by the C<_known_parameter_names> method. This is empty in LINQ::FieldSet itself
so doing anything interesting with this class probably requires subclassing.

=back

=begin trustme

=item BUILDARGS

=end trustme 

=head1 METHODS

=over

=item C<fields>

An arrayref of fields in this fieldset.

=item C<fields_hash>

The same, but as a hashref keyed on field name.

=item C<seen_asterisk>

Whether "*" was seen by the constructor.

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
