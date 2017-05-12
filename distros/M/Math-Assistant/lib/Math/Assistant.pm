package Math::Assistant;

use 5.008004;
use strict;
use warnings;

use Carp;
use Math::BigInt qw( bgcd );

require Math::BigFloat;
require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(
			Rank Det Solve_Det Gaussian_elimination test_matrix
			) ],
		    'algebra' => [ qw( Rank Det Solve_Det ) ],
);

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw( );

our $VERSION = '0.05';

use base qw(Exporter);


# Rank of any integer matrix
# input:
#	$Dimention
# return:
#	$rank (order)
sub Rank{
    my $M = &Gaussian_elimination; # triangular matrix
    my $rank = 0;

    for( @$M ){ # rows
	for( @{$_} ){ # element in row
	    $rank++, last if $_
	}
    }
    $rank;
}


# Method of Gaussian elimination
# input:
#	$Dimention
# return:
#	$elimination_Dimention
sub Gaussian_elimination{
    my $M_ini = shift;

    my $t = &test_matrix( $M_ini );
    if( $t > 3 ){
	croak("Use of uninitialized value in matrix");

    }elsif( $t > 1 ){
	croak("Bad matrix");
    }

    my $rows = $#{$M_ini}; # number of rows
    my $cols = $#{$M_ini->[0]}; # number of columns

    my %zr; # for rows with 0
    my %zc; # for columns with 0

    my $M; # copy
    # search of rows with 0
    for( my $i = 0; $i <= $rows; $i++ ){
	for( my $j = 0; $j <= $cols; $j++ ){
	    $M->[$i][$j] = $M_ini->[$i][$j];
	    unless($M->[$i][$j]){ # zero element
		$zr{$i}++;
		$zc{$j}++;
	    }
	}
    }

    # Check Float (Fraction)
    for my $i ( @$M ){
	my $max_frac = &_max_len_frac($i, 0);

	if($max_frac){
	    $_ *= 10**$max_frac for @$i;
	}
    }

    if(keys %zr){ # yes, zero rows (columns)

	# I supplement indexes of nonzero rows
	for( my $i = 0; $i <= $rows; $i++ ){
	    $zr{$i} += 0;
	}

	my $R; # temp copy of matrix M
	my $v = 0;
	# replacement of rows
	for my $i ( sort { $zr{$a} <=> $zr{$b} } keys %zr ){
	    for( my $j = 0; $j <= $cols; $j++ ){
		$R->[$v][$j] = $M->[$i][$j];
	    }
	    $v++;
	}

	# I supplement indexes of non zero columns
	for( my $j = 0; $j <= $cols; $j++ ){
	    $zc{$j} += 0;
	}

	$v = 0;
	# replacement of columns
	for my $j ( sort { $zc{$b} <=> $zc{$a} } keys %zc ){
	    for( my $i = 0; $i <= $rows; $i++ ){
		$M->[$i][$v] = $R->[$i][$j];
	    }
	    $v++;
	}
    }

    undef %zr;
    undef %zc;

    for(my $n = 0; $n < $rows; $n++){
	last if $n > $cols; # other zero rows

	# Replacement of zero diagonal element
        my $s = 0;
M_Gauss1:
	while( $M->[$n][$n] == 0 && $s < $rows - $n ){
	    $s++;
	    for( my $j = $n + 1; $j <= $cols; $j++ ){

		if( $M->[$n][$j] ){ # no zero element
		    # shift of columns $n <-> $j
		    for( my $i = 0; $i <= $rows; $i++ ){
			($M->[$i][$j], $M->[$i][$n]) = ($M->[$i][$n], $M->[$i][$j]);
		    }
		    last M_Gauss1;
		}
	    }

	    # all zero elements in row
	    for( my $j = $n; $j <= $cols; $j++ ){
		# shift of rows $n <-> $n+1
		($M->[$n][$j], $M->[$n+$s][$j]) = ($M->[$n+$s][$j], $M->[$n][$j]);
	    }
	}

	last unless $M->[$n][$n]; # zero elements of rows

	for( my $i = $n+1; $i <= $rows; $i++ ){

	    # Divisibility check totally
	    my($k,$d);
	    my $b = $M->[$i][$n] / $M->[$n][$n];
	    if($b == int($b)){
		$k = -$b;
		$d = 1;
	    }else{
		$k = -$M->[$i][$n];
		$d = $M->[$n][$n];
	    }

	    # column (element in row)
	    for( my $j = $n; $j <= $cols; $j++ ){
		$M->[$i][$j] = $M->[$i][$j]*$d + $k*$M->[$n][$j];
	    }
	}

	my $gcd = bgcd( @{$M->[$n]}[$n..$cols] );
	if($gcd > 1){
	    $_ = $_ / $gcd for @{$M->[$n]}[$n..$cols];
	}
    }
    $M;
}


# Interger determinant for quadratic matrix
# input:
#	$Dimention
#	facultative parameter
# return:
#	determinant
#	undef
sub Det{
    my( $M_ini, $opt ) = @_;

    my $dm = $#{ $M_ini }; # dimension of matrix

    return $M_ini->[0][0] if $dm < 1; # dim matrix = 1

    # Check Float (Fraction)
    my $fraction = 0;
    unless( exists $opt->{'int'} && $opt->{'int'} ){
	for my $i ( @$M_ini ){
	    $fraction = &_max_len_frac($i, $fraction);
	}
    }

    my $M = $fraction ? [ map{ [ map{ $_ * 10**$fraction } @$_ ] } @$M_ini ] :
			[ map{ [ @$_ ] } @$M_ini ]; # copy

    my $exch = 0; # number of permutations
    my $denom = 1;

    for( my $i = 0; $i < $dm; $i++ ){ # take all the matrix rows except 1st
	my $minV = abs( $M->[$i][$i] );

	if( ! $minV && $i < $dm - 1 ){
	    my $minN = $i;

	    # Search of row with abs minimal element on the diagonal
	    for( my $j = $i + 1; $j <= $dm; $j++ ){
		my $v = abs( $M->[$j][$i] );

		if( $v && ($v < $minV || ! $minV) ){
		    $minN = $j;
		    $minV = $v;
		}
	    }

	    return 0 unless $minV; # determinant = 0

	    ( $M->[$i], $M->[$minN] ) = ( $M->[$minN], $M->[$i] );
	    $exch++;
	}

	my $v1 = $M->[$i][$i];

	for( my $j = $i + 1; $j <= $dm; $j++ ){
	    my $v2 = $M->[$j][$i];

	    for( my $k = $i + 1; $k <= $dm; $k++ ){
		$M->[$j][$k] = ( $M->[$j][$k] * $v1 - $M->[$i][$k] * $v2 ) / $denom;
	    }
	}
	$denom = $v1;
    }

    for( $M->[$dm][$dm] ){
	if( $_ < 0 ){
	    $_ = abs;
	    $exch++;
	}
	$_ = 1 + int if abs($_ - int ) >= 0.5;	# Rounding
	$_ *= -1 if $exch%2;

	return $fraction ? $_ / 10**($fraction * ($dm + 1)) : $_;
    }
}


sub Solve_Det{
    my $M = shift || croak("Missing matrix");
    my $B = shift || croak("Missing vector");
    my $opts = shift;

    my $rows = $#{ $M };	# number of rows
    my $cols = $#{ $M->[0] };	# number of columns

    my $t = &test_matrix( $M );
    if( $t > 3 ){
	croak("Use of uninitialized value in matrix");

    }elsif( $t ){
	croak("Matrix is not quadratic");
    }

    croak("Vector doesn't correspond to a matrix") if $rows != $#{$B};
    croak("Use of uninitialized value in vector") if scalar( grep ! defined $_, @$B );

    if( defined $opts ){
	if( exists $opts->{'eqs'} ){
	    die "Unknown parameter \'$opts->{'eqs'}\'!\n"
		unless $opts->{'eqs'}=~/^(?:row|column)/i;
	}else{
	    $opts->{'eqs'} = 'row';
	}
    }else{
	$opts->{'eqs'} = 'row';
    }

    my $solve;

    # main determinant
    my $det_main = &Det( $M, $opts ) || return undef; # no one solution

    for( my $v = 0; $v <= $cols; $v++ ){

	my $R; # copy of matrix M
	for( my $i = 0; $i <= $rows; $i++ ){

	    if($opts->{'eqs'}=~/^col/i){
		$R->[$i] = $v == $i ? $B : $M->[$i];

	    }else{
		for( my $j = 0; $j <= $cols; $j++ ){
		    $R->[$i][$j] = $v == $j ? $B->[$i] : $M->[$i][$j];
		}
	    }

	}

	my $det = &Det( $R, $opts );
	my $dm = $det_main;

	if( $det ){
	    if( $dm < 0 ){
		$dm *= -1;
		$det *= -1;
	    }

	    # Check Float (Fraction)
	    my $max_frac = &_max_len_frac([$dm, $det], 0);

	    if($max_frac){
		$_ *= 10**$max_frac for($dm, $det);
	    }

	    my $gcd = bgcd(abs($det), abs($dm));
	    if($gcd > 1){
		$det = $det / $gcd;
		$dm = $dm / $gcd;
	    }

	    $solve->[$v] = $dm == 1 ? $det : "$det/$dm";

	}else{
	    $solve->[$v] = 0;
	}
    }
    $solve;
}


sub test_matrix{
    my $M = shift;

    return 4 if scalar( grep{ grep ! defined $_, @{$_} } @$M );

    my $res = scalar( grep $#{$_} != $#{ $M }, @$M ) ? 1 : 0;	# quadra
    $res += 2 if scalar( grep $#{$_} != $#{ $M->[0] }, @$M );	# reqtan;

    $res;
}


sub _max_len_frac{
    my($M, $max_frac) = @_;

    for( @$M ){
	next if Math::BigInt::is_int($_);
	my(undef, $frac) = Math::BigFloat->new($_)->length();
	$max_frac = $frac if $frac > $max_frac;
    }
    $max_frac;
}

1;
__END__

=head1 NAME

Math::Assistant - functions for various exact algebraic calculations

=head1 SYNOPSIS

  use Math::Assistant qw(:algebra);

  my $M = [ [4,1,4,3], [3,-4,7,5], [4,-9,8,5], [-3,2,-5,3], [2,2,-1,0] ];

  # Rank of rectangular matrix
  my $rank = Rank( $M );
  print "Rank = $rank\n";

  shift @$M; # Now a quadratic matrix

  # Determinant of quadratic (integer) matrix
  my $determinant = Det( $M, {'int' => 1} );
  print "Determinant = $determinant\n";

  # Solve an equation system
  my $B = [ 1, 2, 3, 4 ];
  my $solve = Solve_Det($M, $B, {'int' => 1} ); # 'eqs' => 'row' (default)
  print "Equations is rows of matrix:\n", map{ "$_\n" } @$solve;

  use Math::BigRat;
  print(Math::BigRat->new("$_")->numify(),"\n") for @$solve;

  print "Equations is columns of matrix:\n";
  print "$_\n" for @{ Solve_Det( $M, $B, {'eqs' => 'column', 'int' => 1} ) ;


will print

    Rank = 4
    Determinant = -558
    Equations is rows of matrix:
	433/279
	-32/279
	-314/279
	70/93

    1.55197132616487
    -0.114695340501792
    -1.12544802867384
    0.752688172043011

    Equations is columns of matrix:
	283/186
	-77/93
	11/62
	13/93


=head1 DESCRIPTION

The module contains important algebraic operations: matrix rank, determinant and
solve an equation system. The integer values are accepted.
Calculations with the raised accuracy.


=head1 SUBROUTINES

Math::Assistant provides these subroutines:

    Rank( \@matrix )
    Det( \@matrix [, { int => 1 }] )
    Solve_Det( \@A_matrix, \@b_vector [, { eqs => 'row|column', int => 1 }] )
    Gaussian_elimination( \@matrix )
    test_matrix( \@matrix )

All of them are context-sensitive.


=head2 Rank( \@matrix )

Calculates rank of rectangular (quadratic or non-quadratic) C<@matrix>.
Rank is a measure of the number of linear independent row and column
(or number of linear independent equations in the case of a matrix representing
an equation system).


=head2 Det( \@matrix [, { int => 1 }] )

This subroutine returns the determinant of the C<@matrix>.
Only quadratic matrices have determinant.
Subroutine test_matrix uses for testing of non-quadratic C<@matrix>.

If all elements of C<@matrix> are integers then are using the facultative 
parameter C<'int'>. This causes subroutine to be a bit faster.


=head2 test_matrix( \@matrix )

Use this subroutine for testing of C<@matrix>.
This subroutine returns: 0 (Ok), 1..4 (Error).
E.g.:

    my $t = Math::Assistant::test_matrix( $M );
    if( $t > 3 ){
	print "Use of uninitialized value in matrix\n";

    }elsif( $t ){
	croak("Matrix is not quadratic");
    }


=head2 Solve_Det(\@A_matrix, \@b_vector [, {eqs => 'row|column', int => 1}] )

Use this subroutine to actually solve an equation system.

Matrix "C<@A_matrix>" must be quadratic matrix of your equation system
C<A * x = b>. By default the equations are in rows.

The input vector "C<@b_vector>" is the vector "b" in your equation system
C<A * x = b>, which must be a row vector and have the same number of
elements as the input matrix "C<@A_matrix>" have rows (columns).

The subroutine returns the solution vector "C<$x>"
(which is the vector "x" of your equation system C<A * x = b>) or C<undef>
is no solution.

    # Equation system:
    # x1 + x2 + x3 + x4 + x5 + x6 + x7 = 4
    # 64*x1 + 32*x2 + 16*x3 + 8*x4 + 4*x5 + 2*x6 + x7 = 85
    # ...................................
    # 7**6*x1 + 7**5*x2 + 7**4*x3 + 7**3*x4 + 7**2*x5 + 7*x6 + x7 = 120100

    my $M = [
	[1,1,1,1,1,1,1],
	[64,32,16,8,4,2,1],
	[729,243,81,27,9,3,1],
	[4**6, 4**5, 256,64,16,4,1],
	[5**6, 5**5, 5**4, 5**3, 5**2, 5, 1],
	[6**6, 6**5, 6**4, 6**3, 6**2, 6, 1],
	[7**6, 7**5, 7**4, 7**3, 7**2, 7, 1],
	 ];

    my $B = [ 4, 85, 820, 4369, 16276, 47989, 120100 ];

    print "$_\t" for @{ Solve_Det( $M, $B, {int => 1} ) };

will print:

    1 0 1 0 1 0 1

Other example:

    # Equation system:
    # 1.3*x1 + 2.1*x2 + 34*x3 + 78*x4 = 1.1
    # 2.5*x1 + 4.7*x2 + 8.2*x3 + 16*x4 = 2.2
    # 3.1*x1 + 6.2*x2 + 12*x3 + 24*x4 = 3.3
    # 4.2*x1 + 8.7*x2 + 16*x3 + 33*x4 = 4.4

    $M = [  [1.3, 2.5, 3.1, 4.2],
	    [2.1, 4.7, 6.2, 8.7],
	    [34,  8.2, 12,  16],
	    [78,  16,  24,  33] ];
    print "$_\t" for @{ Solve_Det($M, [ 1.1, 2.2, 3.3, 4.4 ], {eqs => 'column'} ) };

will print:

    -38049/17377  22902/17377  35101/34754  -36938/86885


=head2 Gaussian_elimination( \@matrix )

This subroutine returns matrix Gaussian elimination of the C<@matrix>.
The initial C<@matrix> does not vary.


=head1 EXPORT

Math::Assistant exports nothing by default.
Each of the subroutines can be exported on demand, as in

  use Math::Assistant qw( Rank );

the tag C<algebra> exports the subroutines C<Rank>, C<Det>, C<Solve_Det>:

  use Math::Assistant qw(:algebra);

and the tag C<all> exports them all:

  use Math::Assistant qw(:all);


=head1 DEPENDENCIES

Math::Assistant is known to run under perl 5.12.4 on Linux.
The distribution uses L<Math::BigInt>, L<Math::BigFloat>, L<Test::More> and L<Carp>.


=head1 SEE ALSO

L<Math::MatrixReal> is a Perl module that offers similar features.


=head1 AUTHOR

Alessandro Gorohovski, E<lt>an.gorohovski@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010-2013 by A. N. Gorohovski

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
