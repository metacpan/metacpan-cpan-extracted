package Math::BaseArith;

use 5.006;
use strict;
use warnings;
use integer;
use Carp;

require Exporter;

our $VERSION = '1.04';

our $DEBUG = 0;     # set to 1 to enable debug printing

our @ISA = qw(Exporter);

# The primary functions of this module were originally named encode/decode.
# They were renamed encode_base and # decode_base as of version 1.02 so there 
# would be less chance of them colliding with other encode/decode functions
# from other modules.  However, since they were exported by default, it was
# necessary to keep them (and their default export) so as not to introduce
# an incompatible change.  But, they can be turned off using !:old.
our @EXPORT = ( qw(encode decode) );

# use Math::BaseArith qw(:all !:old) to get encode_base/decode_base
# and to keep encode/decode out of the namespace.
our %EXPORT_TAGS = ( 
    'all' => [
        'encode_base',
        'decode_base', 
        ],
    'old' => [
        'encode',
        'decode', 
        ], 
);

# use Math::BaseArith ( qw(!:old encode_base) ) to get just encode_base
our @EXPORT_OK = ( qw(
    encode_base
    decode_base
    encode
    decode
));

#######################################################################

sub encode_base {
    my ($value, $b_aref) = @_;

	croak 'Function called in void context' unless defined wantarray;

	my @b_list = @{ $b_aref }; # copy the base value list
	my @r_list;
	my @radix_list = (1);

	print {*STDERR} "encode_base($value ,[@{ $b_aref }])"
		if $Math::BaseArith::DEBUG >= 1;

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
	foreach my $b (@radix_list) {
		$i++;
		if ($b > $value) {
			printf {*STDERR} "%10d%10d%10d%10d\n", $b,$value,$r,$value%$b
				if $Math::BaseArith::DEBUG >= 2;
			push @r_list, 0 if $i > 1;
			next;
		}
		$r = $b ? int($value/$b) : 0;
		printf {*STDERR} "%10d%10d%10d%10d\n", $b,$value,$r,$b?$value%$b:0 if $Math::BaseArith::DEBUG >= 2;
		push @r_list, $r;
		$value %= $b if $b;
	}

	shift @r_list while ( scalar(@r_list) > scalar( @{ $b_aref } ) );

	return wantarray ? @r_list : \@r_list;
}

#######################################################################

sub decode_base {
    my ($r_aref, $b_aref) = @_;

	print {*STDERR} "decode_base( [ @{$r_aref} ],[ @{ $b_aref} ] )"
		if $Math::BaseArith::DEBUG >= 1;

	if ( scalar( @{ $r_aref } ) > scalar( @{ $b_aref } ) &&
		 scalar( @{ $b_aref} ) != 1 )
	{
		carp 'length error';
		return;
	}

	my $value = 0;
	my $bb = 1;
	my $base = 1;
	my $r;
	my @b_list = @{ $b_aref }; # copy the base value list
	my @r_list = @{ $r_aref }; # copy the representation value list

	do {
		$r = pop @r_list;
		$value += $r * $base;
		printf {*STDERR} "%10d%10d%10d%10d\n", $r,$b,$base,$value
			if $Math::BaseArith::DEBUG >= 2;
		$bb = pop @b_list || $bb;
		$base *= $bb;
	} while @r_list;

    return $value;
}

#######################################################################
# For signature compatibility with version < 1.02

sub encode { encode_base(@_) }
sub decode { decode_base(@_) }

#######################################################################

1;
__END__

=head1 NAME

Math::BaseArith - mixed-base number arithmetic (like APL encode/decode)

=head1 SYNOPSIS

  use Math::BaseArith qw( :all );

  encode_base( $value, \@base );

  decode_base( \@representation, \@base );
  
  my @yd_ft_in = (0, 3, 12);

  # convert 175 inches to 4 yards 2 feet 7 inches
  encode_base( 175, \@yd_ft_in ) 

  # convert 4 yards 2 feet 7 inches to 175 inches
  decode_base( [4, 2, 7], \@yd_ft_in )

=head1 DESCRIPTION

The inspiration for this module is a pair of functions in the APL 
programming language called encode (a.k.a. "represent" or "antibase)" 
and decode (a.k.a. base). Their principal use is to convert numbers from 
one number base to another. Mixed number bases are permitted. 

In this perl implementation, the representation of a number in a 
particular number base consists of a list reference whose 
elements are the digit values in that base. For example, the decimal 
number 31 would be expressed in binary as a list of five ones with any 
number of leading zeros: [0, 0, 0, 1, 1, 1, 1, 1]. The same number 
expressed as three hexadecimal (base 16) digits would be [0, 1, 15], 
while in base 10 it would be [0, 3, 1]. Fifty-one inches would be 
expressed in yards, feet, inches as [1, 1, 3], an example of a mixed 
number base. 

=head1 FUNCTIONS

In the following description of encode_base and decode_base, Q will mean 
an abstract value or quantity, R will be its representation and B will 
define the number base. Q will be a perl scalar; R and B are perl lists. 
The values in R correspond to the radix values in B. 

In the examples below, assume the function output is being printed by:
    
    sub echo { print '=> ', join ', ', @_ }

=head2 encode_base

Encode_base is used to represent a number in one or more number bases. 
The first argument is the number to be converted, and the second 
argument defines the base (or bases) to be used for the representation. 
Consider first the representation of a scalar in a single uniform number 
base: 

    encode_base( 2, [2, 2, 2, 2] )
    => 0 0 1 0

    encode_base( 5, [2, 2, 2, 2] )
    => 0 1 0 1

    encode_base( 13, [2, 2, 2, 2] )
    => 1 1 0 1

    encode_base( 62, [16, 16, 16] )
    => 0 3 14

The second argument is called the base list. The length of the base list 
determines the number of digits in the representation of the first 
argument. No error occurs if the length is insufficient to give a proper 
representation of the number. Exploring this situation will suggest 
other uses of encode_base, and may clarify the use of encode_base with 
mixed number bases. 

    # The representation of 75 in base 4
    encode_base( 75, [4, 4, 4, 4] )
    => 1 0 2 3

    # At least four digits are needed for the full representation
    encode_base( 75, [4, 4, 4] )
    => 0 2 3

    # If fewer elements are in the second argument,
    # leading digits do not appear in the representation.
    encode_base( 75, [4, 4] )
    => 2 3

    # If the second argument is a one-element list reference, encode_base 
    # is identical to modulus (%)
    encode_base( 75, [4] )
    => 3
    encode_base( 76, [4] )
    => 0

    # The expression encode_base( Q, [0] ) always yields Q as the result
    encode_base ( 75, [0] )
    => 75

    # This usage returns quotient and remainder
    encode_base( 75, [0, 4] )
    => 18 3

    # The first quotient (18) is again divided by 4,
    # yielding a second quotient and remainder
    encode_base( 75, [0, 4, 4] )
    => 4 2 3

    # The process is repeated again. Since the last quotient
    # is less than 4, the result is the same as encode_base(75,[4,4,4,4])
    encode_base( 75, [0, 4, 4, 4] )
    => 1 0 2 3

Now consider a mixed number base: convert 175 inches into yards, feet,
inches.

    # 175 inches is 14 feet, 7 inches (quotient and remainder).
    encode_base( 175, [0, 12] )
    => 14 7

    # 14 feet is 4 yards, 2 feet,
    encode_base( 14, [0, 3] )
    => 4 2

    # so 175 inches is 4 yards, 2 feet, 7 inches.
    encode_base( 175, [0, 3, 12] )
    => 4 2 7

=head2 decode_base

decode_base is used to determine the value of the representation of a 
quantity in some number base. If B<R> is a list representation (perhaps 
produced by the encode_base function described above) of some quantity 
B<Q> in a number base defined by the radix list B<B> (i.e., C<@R = 
encode_base($Q,@B)>, then the expression C<decode_base(@R,@B)> yields 
C<$Q>: 

    decode_base( [0, 0, 1, 0], [2, 2, 2, 2] )
    => 2

    decode_base( [0, 1, 0, 1], [2, 2, 2, 2] )
    => 5

    decode_base( [0, 3, 14], [16, 16, 16]
    => 62

The length of the representation list must be less than or equal to
that of the base list.

    decode_base( [1, 1, 1, 1], [2, 2, 2, 2] )
    => 15

    decode_base( [1, 1, 1, 1], [2] )
    => 15

    decode_base( [1], [2, 2, 2, 2] )
    => 15

    decode_base( [1, 1, 1, 1], [2, 2, 2] )
    => (void)
    raises a LENGTH ERROR

As with the encode_base function, mixed number bases can be used:

    # Convert 4 yards, 2 feet, 7 inches to inches.
    decode_base( [4, 2, 7], [0, 3, 12] )
    => 175

    # Convert 2 days, 3 hours, 5 minutes, and 27 seconds to seconds
    decode_base( [2, 3, 5, 27], [0, 24, 60, 60] )
    => 183927

    # or to minutes.
    decode_base( [2, 3, 5, 27], [0, 24, 60, 60] ) / 60
    => 3065.45

The first element of the radix list (second argument) is not used; it is
required only to make the lengths match and so can be any value.

=head1 DEPRECATED FUNCTIONS

=over 4

=item encode

=item decode

=back

Synonmous with encode_base/decode_base.  Imported by default.  
See COMPATIBILITY for details.

=head1 COMPATIBILITY

When this module was originally released on CPAN in 2002, it exported 
the functions encode and decode by default. These function names, 
however, are fairly common and so have a high probability of colliding 
in the global namespace with those from other modules. As of version 
1.02, the functions were renamed encode_base and decode_base in order to 
better distinguish them. 

For upward compatibility, encode/decode are provided as aliases for 
encode_base/decode_base and are still exported by default so scripts 
that include the module by:

    use Math::BaseArith;

will continue to work unchanged. See the EXPORT section for the 
preferred way to include the module from version 1.02 ownward. 

Note the the keyword :old can be used to specify the old function names 
(encode/decode). The most likely use of this is to exclude them from the 
namespace so you can then include just one of them.  For example, to get
decode without encode you can do this:

    use Math::BaseArith qw( !:old decode );

But, rather than this approach, consider altering your code to use the
new and preferred function names.

=head1 EXPORT

As of version 1.02 and above, the preferred way to include this module is
by using :all, or specifying you want either encode_base or decode_base:

    use Math::BaseArith ':all';
or
    use Math::BaseArith 'encode_base';
or
    use Math::BaseArith 'decode_base';
    
Do NOT include it without parameters, as that will automatically import
the old function names encode/decode.

=head1 DEBUGGING

Set the global variable $Math::BaseArith::DEBUG to print debugging 
information to STDERR. 

If set to 1, function names and parameters are printed.

If set to 2, intermediate results are also printed.

=head1 LIMITATIONS

The APL encode function allows both arguments to be a list, in which 
case the function evaluates in dot-product fashion, generating a matrix 
whose columns are the representation vectors for each value in the value 
list; i.e. a call such as encode_base([15,31,32,33,75],[4,4,4,4]) would 
generate the following matrix; 

	0 0 0 0 1
	0 1 2 2 0
	3 3 0 0 2
	3 3 0 1 3

This version of encode_base supports only a scalar value as the first 
argument. 

The APL version of decode support non-integer values. This version 
doesn't. 

=head1 SEE ALSO

L<https://aplwiki.com/wiki/Encode>

L<https://aplwiki.com/wiki/Decode>

=head1 AUTHOR

PUCKERING, Gary Puckering E<lt>jgpuckering@rogers.comE<gt>

=head1 BUGS

Please report any bugs or feature requests to C<bug-math-basearith at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Math-BaseArith>.  I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Math::BaseArith

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Math-BaseArith>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Math-BaseArith>

=item * Search CPAN

L<https://metacpan.org/release/Math-BaseArith>

=back


=head1 ACKNOWLEDGEMENTS

Kenneth E. Iverson, inventor of APL and author of "A Programming Language", John Wiley & Sons, 1962

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2002, Gary Puckering. All rights reserved. 

This module is free software; you can redistribute it and/or modify it 
under the same terms as Perl 5. For more details, see the full text 
of the licenses in the directory LICENSES. This program is distributed 
in the hope that it will be useful, but without any warranty; without 
even the implied warranty of merchantability or fitness for a particular 
purpose. 

=cut
