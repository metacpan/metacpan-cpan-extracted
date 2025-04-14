package Math::NoCarry;
use strict;

use warnings;
no warnings;

use Exporter qw(import);

our @EXPORT_OK = qw(add subtract multiply);
our %EXPORT_TAGS =  ( all => [ @EXPORT_OK ] );

our $VERSION = '1.117';

=encoding utf8

=head1 NAME

Math::NoCarry - Perl extension for no-carry arithmetic

=head1 SYNOPSIS

	use Math::NoCarry qw(:all);

	my $sum        = add( 123, 456 );

	my $difference = subtract( 123, 456 );

	my $product    = multiply( 123, 456 );

=head1 DESCRIPTION

No-carry arithmetic doesn't allow you to carry digits to the
next column. For example, if you add 8 and 4, you normally
expect the answer to be 12, but that 1 digit is a carry.
In no-carry arithmetic you can't do that, so the sum of
8 and 4 is just 2. In effect, this is addition modulo 10
in each column. I discard all of the carry digits in
this example:

	  1234
	+ 5678
	------
	  6802

For multiplication, the result of pair-wise multiplication
of digits is the modulo 10 value of their normal, everyday
multiplication.

        123
      x 456
      -----
          8   6 x 3
         2    6 x 2
        6     6 x 1

         5    5 x 3
        0     5 x 2
       5      5 x 1

        2     4 x 3
       8      4 x 2
    + 4       4 x 1
    -------
      43878

Since multiplication and subtraction are actually types of
additions, you can multiply and subtract like this as well.

No carry arithmetic is both associative and commutative.

=head2 Functions

As of version 1.11, all of these functions are exportable on
demand, or with the tag C<:all> to get them all at once.

=over 4

=item multiply( A, B )

Returns the no carry product of A and B.

Return A if it is the only argument ( A x 1 );

=cut

sub multiply {
	return $_[0] if $#_ < 1;

	@_ = map { $_ += 0 } @_;

	my $sign = ($_[0] > 0 and $_[1] < 0 ) ||
		($_[1] > 0 and $_[0] < 0 );

	my @p0 = reverse split //, abs $_[0];
	my @p1 = reverse split //, abs $_[1];

	my @m;

	foreach my $i ( 0 .. $#p0 ) {
		foreach my $j ( 0 .. $#p1 ) {
			push @m, ( ( $p1[$j] * $p0[$i] ) % 10 ) * ( 10**($i+$j) );
			}
		}

	while( @m > 1 ) {
		unshift @m, Math::NoCarry::add( shift @m, shift @m );
		}

	$m[0] *= -1 if $sign;

	return $m[0];
	}

=item add( A, B )

Returns the no carry sum of the positive numbers A and B.

Returns A if it is the only argument ( A + 0 )

Returns false if either number is negative.

=cut

sub add {
	return $_[0] if $#_ < 1;

	@_ = map { local $^W; $_ += 0 } @_;

	return unless( $_[0] >= 0 and $_[1] >= 0 );

	my @addends = map scalar reverse, @_;

	my $string = '';

	my $max = length $addends[0];
	$max = length $addends[1] if length $addends[1] > $max;

	for( my $i = 0; $i < $max ; $i++ ) {
		my @digits = map { local $^W = 0; substr( $_, $i, 1) or 0 } @addends;

		my $sum = ( $digits[0] + $digits[1] ) % 10;

		$string .= $sum;
		}

	$string =~ s/0*$//;

	$string = scalar reverse $string;

	return $string;
	}

=item subtract( A, B )

Returns the no carry difference of the positive numbers A and B.

Returns A if it is the only argument ( A - 0 )

Returns false if either number is negative.

=cut

sub subtract {
	return $_[0] if $#_ < 1;

	return unless( $_[0] >= 0 and $_[1] >= 0);

	my @addends = map scalar reverse, @_;

	my $string = '';

	my $max = length $addends[0];
	$max = length $addends[1] if length $addends[1] > $max;

	for( my $i = 0; $i < $max ; $i++ ) {
		my @digits = map { substr $_, $i, 1 } @addends;

		$digits[0] += 10 if $digits[0] < $digits[1];

		my $sum = ( $digits[0] - $digits[1] ) % 10;

		$string .= $sum;
		}

	return scalar reverse $string;
	}

1;

__END__

=back

=head1 BUGS

=over 4

=item * none reported yet :)

=back

=head1 TO DO

=over 4

=item * this could be a full object package with overloaded +, *, and - operators

=item * it would be nice if I could give the functions more than two arguments.

=item * addition and subtraction don't do negative numbers.

=back

=head1 SOURCE AVAILABILITY

This source is in GitHub:

	https://github.com/briandfoy/math-nocarry

=head1 AUTHOR

brian d foy, C<< <briandfoy@pobox.com> >>

=head1 COPYRIGHT AND LICENSE

Copyright © 2002-2025, brian d foy <briandfoy@pobox.com>. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the Artistic License 2.0.

=cut
