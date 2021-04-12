use 5.006;
use strict;
use warnings;

package LINQ;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.001';

use Exporter::Shiny qw( LINQ Range Repeat END );

our $FORCE_ITERATOR;
our $IN_LOOP;

my $end = do {

	package LINQ::END;
	our $AUTHORITY = 'cpan:TOBYINK';
	our $VERSION   = '0.001';
	my $x = 42;
	bless( \$x );
	&Internals::SvREADONLY( \$x, !!1 );
	\$x;
};

my $last = do {

	package LINQ::LAST;
	our $AUTHORITY = 'cpan:TOBYINK';
	our $VERSION   = '0.001';
	my $x = 666;
	bless( \$x );
	&Internals::SvREADONLY( \$x, !!1 );
	\$x;
};

BEGIN {
	*LINQ::END = sub () { $end };
	
	*LINQ::LAST = sub () {
		if ( $IN_LOOP ) {
			die( $last );
		}
		require LINQ::Exception;
		'LINQ::Exception::CallerError'->throw(
			message => "Cannot call LINQ::LAST outside foreach",
		);
	};
} #/ BEGIN

sub LINQ ($) {
	my $data = shift;
	my $ref  = ref( $data );
	
	if ( $ref eq 'ARRAY' ) {
		if ( $FORCE_ITERATOR ) {
			my @data = @$data;
			require LINQ::Iterator;
			return LINQ::Iterator::->new( sub { @data ? shift( @data ) : LINQ::END } );
		}
		
		require LINQ::Array;
		return LINQ::Array::->new( $data );
	} #/ if ( $ref eq 'ARRAY' )
	
	if ( $ref eq 'CODE' ) {
		require LINQ::Iterator;
		return LINQ::Iterator::->new( $data );
	}
	
	require Scalar::Util;
	if ( Scalar::Util::blessed( $data ) and $data->DOES( 'LINQ::Collection' ) ) {
		return $data;
	}
	
	require LINQ::Exception;
	'LINQ::Exception::CallerError'->throw(
		message => "Cannot create LINQ object from '$data'",
	);
} #/ sub LINQ ($)

sub Range {
	my ( $min, $max ) = @_;
	
	my $value = defined( $min ) ? $min : 0;
	
	if ( not defined $max ) {
		return LINQ sub { $value++ };
	}
	
	return LINQ sub { return LINQ::END if $value > $max; $value++ };
} #/ sub Range

sub Repeat {
	my ( $value, $count ) = @_;
	
	if ( not defined $count ) {
		return LINQ sub { $value };
	}
	
	return LINQ sub { return LINQ::END if $count-- <= 0; $value };
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

LINQ - an interpretation of Microsoft's Language Integrated Query

=head1 SYNOPSIS

  use feature qw( say );
  use LINQ qw( LINQ )';
  
  my $double_even_numbers =
    LINQ( [ 1 .. 100 ] )
      ->where( sub { $_ % 2 == 0 } )
      ->select( sub { $_ * 2 } );
  
  for my $n ( $double_even_numbers->to_list ) {
    say $n;
  }

=head1 DESCRIPTION

LINQ is basically an application of SQL concepts to arrays and iterators.
Hopefully this implementation will eventually cover other data types like
SQL tables, XML and JSON data, etc.

Not much is documented yet, but the test suite includes numerous examples
of LINQ's usage.

=head1 FUNCTIONS

The C<LINQ>, C<Range>, and C<Repeat> functions return LINQ collections,
objects implementing the L<LINQ::Collection> interface.

The C<< LINQ::END() >> and C<< LINQ::LAST() >> functions are used as
signals to control LINQ's iterators and loops.

Additional utility functions can be found in L<LINQ::Util>.

=over

=item C<< LINQ( SOURCE ) >>

Creates a LINQ collection from a source. The source may be an existing LINQ
collection, which will be returned as-is, an arrayref of items, or a coderef
which will be called in scalar context and expected to return a single item
each time it is called. It should return the special value C<< LINQ::END() >>
to indicate that the end of the collection has been reached.

C<LINQ> may be exported, but is not exported by default. 

=item C<< Range( MIN, MAX ) >>

Returns a LINQ collection containing the range of numbers from MIN to MAX.
If MIN is undef, it is treated as 0. If MAX is undef, it is treated as positive
infinity.

If you want a range from 0 to negative infinity, use:

  my $below_zero = Range( 0, undef )->select( sub { -$_ } );

C<Range> may be exported, but is not exported by default. 

=item C<< Repeat( VALUE, COUNT ) >>

Returns a LINQ collection containing the same value multiple times. If COUNT
is undef, then it is treated as infinity.

C<Repeat> may be exported, but is not exported by default. 

=item C<< END() >>

Returns the special value C<< LINQ::END() >>.

C<END> may be exported, but is not exported by default, and I recommend
calling it by its fully qualified name for clarity. 

=item C<< LAST() >>

Used by the C<foreach> method of L<LINQ::Collection>. If called otherwise,
will die.

=back

=head1 HISTORY

I wrote this back in 2014, but never released it. After a discussion
about how nice it would be to have a programming language which used SQL
concepts natively, eliminating the need to "map" between how your
application handled data and how your database handled data, I remembered
this. So I thought I'd push what I had so far onto CPAN and maybe think
about reviving it.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=LINQ>.

=head1 SEE ALSO

L<LINQ::Collection>, L<LINQ::Util>, L<LINQ::Exception>.

L<https://en.wikipedia.org/wiki/Language_Integrated_Query>

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014, 2021 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
