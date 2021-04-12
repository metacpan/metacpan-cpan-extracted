use 5.006;
use strict;
use warnings;

package LINQ::Util::Internal;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.001';

sub create_linq {
	require LINQ;
	goto \&LINQ::LINQ;
}

sub throw {
	require LINQ::Exception;
	my $e = shift;
	"LINQ::Exception::$e"->throw( @_ );
}

sub assert_code {
	my $code = shift;
	
	if ( ref( $code ) eq 'ARRAY' ) {
		@_    = @$code;
		$code = shift;
	}
	
	if ( ref( $code ) eq 'Regexp' ) {
		throw(
			"CallerError",
			message => "Regexp cannot accept curried arguments"
		) if @_;
		
		my $re = $code;
		return sub { m/$re/ };
	}
	
	if ( ref( $code ) ne 'CODE' ) {
		require Scalar::Util;
		require overload;
		
		throw(
			"CallerError",
			message => "Expected coderef; got '$code'"
		) unless Scalar::Util::blessed( $code ) && overload::Method( $code, '&{}' );
	}
	
	if ( @_ ) {
		my @curry = @_;
		return sub { $code->( @curry, @_ ) };
	}
	
	return $code;
} #/ sub assert_code

1;

__END__

=pod

=encoding utf-8

=head1 NAME

LINQ::Util::Internal - common functions used internally by LINQ

=head1 FUNCTIONS

=over

=item C<< create_linq( SOURCE ) >>

=item C<< throw( EXCEPTION_TYPE, ARGS ) >>

=item C<< assert_code( CALLABLE ) >>

=back

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=LINQ>.

=head1 SEE ALSO

L<LINQ>.

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
