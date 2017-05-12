package Math::BaseArith;

use 5.006;
use strict;
use warnings;
use integer;
use Carp;

require Exporter;

our @ISA = qw(Exporter);

our($debug) = 0;

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Math::BaseArith ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	encode
	decode
	$Math::BaseArith::debug
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	encode
	decode	
);
our $VERSION = '1.00';

#######################################################################

sub encode {
	croak "Function called in void context" unless defined wantarray;
	
	my $value = shift; # value to be encoded
	my $b_listRef = shift; # list of base values

	my @b_list = @$b_listRef; # copy the base value list
	my @r_list;
	my @radix_list = (1);
	
	print STDERR "encode($value ,[@$b_listRef])" 
		if $Math::BaseArith::debug >= 1;

	my $r = 0;	
	my $b = 1;

	# Compute the radix divisors from the base list, and put in reverse order
	# [1760,3,12] miles/yards/feet/inches becomes [63360,5280,1760]
	# [2,2,2,2] becomes [16,8,4,2]
	do {
		$b *= pop @b_list;
		unshift @radix_list, $b;
	} while @b_list;

	my $i = 0;
	foreach $b (@radix_list) {
		$i++;
		if ($b > $value) {
			printf STDERR "%10d%10d%10d%10d\n", $b,$value,$r,$value%$b 
				if $Math::BaseArith::debug >= 2;
			push @r_list, 0 if $i > 1;
			next;
		}
		my $r = $b ? int($value/$b) : 0;
		printf STDERR "%10d%10d%10d%10d\n", $b,$value,$r,$b?$value%$b:0 if $Math::BaseArith::debug >= 2;
		push @r_list, $r;
		$value %= $b if $b;
	}
	
	shift @r_list while (scalar(@r_list) > scalar(@$b_listRef));
	
	return wantarray ? @r_list : \@r_list;	
}	

#######################################################################

sub decode {
	my $r_listRef = shift; # list of representation values
	my $b_listRef = shift; # list of base values

	print STDERR "decode([@$r_listRef],[@$b_listRef])" 
		if $Math::BaseArith::debug >= 1;

	if ( scalar(@$r_listRef) > scalar(@$b_listRef) && 
		 scalar(@$b_listRef) != 1 )
	{
		carp "length error";
		return; 
	}
	
	my $value = 0;
	my $b = 1;
	my $base = 1;
	my $r;

	do {
		$r = pop @$r_listRef;
		$value += $r * $base;
		printf STDERR "%10d%10d%10d%10d\n", $r,$b,$base,$value 
			if $Math::BaseArith::debug >= 2;
		$b = pop @$b_listRef || $b;
		$base *= $b;
	} while @$r_listRef;
	$value;
}

1;
__END__

=head1 NAME

Math::BaseArith - Perl extension for mixed-base number representation (like APL encode/decode)

=head1 SYNOPSIS

  use Math::BaseArith;
  encode( value, base_list );
  decode( representation_list, base_list );

=head1 DESCRIPTION

The inspiration for this module is a pair of functions in the APL
programming language called encode (a.k.a. "representation") and decode
(a.k.a. base-value). Their principal use is to convert numbers from one
number base to another. Mixed number bases are permitted. 

In this perl implementation, the representation of a number in a
particular number base consists of a list whose elements are the digit
values in that base. For example, the decimal number 31 would be
expressed in binary as a list of five ones with any number of leading
zeros: [0, 0, 0, 1, 1, 1, 1, 1]. The same number expressed as three
hexadecimal (base 16) digits would be [0, 1, 15], while in base 10 it
would be [0, 3, 1]. Fifty-one inches would be expressed in yards, feet,
inches as [1, 1, 3], an example of a mixed number base. 

In the following description of encode and decode, Q will mean an
abstract value or quantity, R will be its representation and B will
define the number base. Q will be a perl scalar; R and B are perl lists.
The values in R correspond to the radix values in B. 

In the examples below, assume the output of B<print> has been altered by
setting $, = ' ' and that C<=E<gt>> is your shell prompt. 

=head1 &encode

Encode is used to represent a number in one or more number bases. The
first argument is the number to be converted, and the second argument
defines the base (or bases) to be used for the representation. Consider
first the representation of a scalar in a single uniform number base: 

    print encode( 2, [2, 2, 2, 2] )
    => 0 0 1 0

    print encode( 5, [2, 2, 2, 2] )
    => 0 1 0 1

    print encode( 13, [2, 2, 2, 2] )
    => 1 1 0 1

    print encode( 62, [16, 16, 16] )
    => 0 3 14

The second argument is called the base list. The length of the
base list determines the number of digits in the representation of
the first argument. No error occurs if the length is insufficient to
give a proper representation of the number. Exploring this situation
will suggest other uses of encode, and may clarify the use of encode
with mixed number bases. 

    # The representation of 75 in base 4
    print encode( 75, [4, 4, 4, 4] )
    => 1 0 2 3

    # At least four digits are needed for the full representation
    print encode( 75, [4, 4, 4] )
    => 0 2 3

    # If fewer elements are in the second argument,
    # leading digits do not appear in the representation.
    print encode( 75, [4, 4] )
    => 2 3

    # If the second argument is a one-element list, encode is identical
    # to modulus (%)
    print encode( 75, [4] )
    => 3
    print encode( 76, [4] )
    => 0

    # The expression encode( Q, [0] ) always yields Q as the result
    print encode ( 75, [0] )
    => 75

    # This usage returns quotient and remainder
    print encode( 75, [0, 4] )
    => 18 3

    # The first quotient (18) is again divided by 4,
    # yielding a second quotient and remainder
    print encode( 75, [0, 4, 4] )
    => 4 2 3

    # The process is repeated again. Since the last quotient
    # is less than 4, the result is the same as encode(75,[4,4,4,4])
    print encode( 75, [0, 4, 4, 4] )
    => 1 0 2 3

Now consider a mixed number base: convert 175 inches into yards, feet,
inches. 

    # 175 inches is 14 feet, 7 inches (quotient and remainder). 
    print encode( 175, [0, 12] )
    => 14 7

    # 14 feet is 4 yards, 2 feet,
    print encode( 14, [0, 3] )
    => 4 2
       
    # so 175 inches is 4 yards, 2 feet, 7 inches.
    print encode( 175, [0, 3, 12] )
    => 4 2 7

=head1 &decode

Decode (or base-value) is used to determine the value of the
representation of a quantity in some number base. If B<R> is a list
representation (perhaps produced by the encode function described above)
of some quantity B<Q> in a number base defined by the radix list B<B> (i.e.,
C<@R = encode($Q,@B)>, then the expression C<decode(@R,@B)> yields C<$Q>: 

    print decode( [0, 0, 1, 0], [2, 2, 2, 2] )
    => 2

    print decode( [0, 1, 0, 1], [2, 2, 2, 2] )
    => 5

    print decode( [0, 3, 14], [16, 16, 16]
    => 62

The length of the representation list must be less than or equal to
that of the base list.

    print decode( [1, 1, 1, 1], [2, 2, 2, 2] )
    => 15

    print decode( [1, 1, 1, 1], [2] )
    => 15

    print decode( [1], [2, 2, 2, 2] )
    => 15

    print decode( [1, 1, 1, 1], [2, 2, 2] )
    => (void) 
    raises a LENGTH ERROR

As with the encode function, mixed number bases can be used:

    # Convert 4 yards, 2 feet, 7 inches to inches.
    print decode( [4, 2, 7], [0, 3, 12] )
    => 175


    # Convert 2 days, 3 hours, 5 minutes, and 27 seconds to seconds 
    print decode( [2, 3, 5, 27], [0, 24, 60, 60] )
    => 183927

    # or to minutes.
    print decode( [2, 3, 5, 27], [0, 24, 60, 60] ) / 60
    => 3065.45

The first element of the radix list (second argument) is not used; it is
required only to make the lengths match and so can be any value. 

=head1 EXPORT

  use Math::BaseArith;
   &encode
   &decode

  use Math::BaseArith ':all';
   &encode
   &decode
   BaseArith::debug

=head1 DEBUGGING

Import the global $Math::BaseArith::debug to print debugging information to STDERR.

If set to 1, function names and parameters are printed.

If set to 2, intermediate results are also printed.

=head1 LIMITATIONS

The APL encode function allows both arguments to be a list, in which case the
function evaluates in dot-product fashion, generating a matrix whose columns
are the representation vectors for each value in the value list; i.e. a call
such as encode([15,31,32,33,75],[4,4,4,4]) would generate the following matrix;

	0 0 0 0 1
	0 1 2 2 0
	3 3 0 0 2
	3 3 0 1 3

This version of encode supports only a scalar value as the first argument.

The APL version of decode support non-integer values.  This version doesn't.

=head1 AUTHOR

Gary Puckering E<lt>gary.puckering@cognos.comE<gt>

=head1 SEE ALSO

L<http://www.acm.org/sigapl/encode.htm>.

=cut
