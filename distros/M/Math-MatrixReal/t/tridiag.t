use Test::More tests => 5;
use File::Spec;
use lib File::Spec->catfile("..","lib");
use Math::MatrixReal;
use strict;
do 'funcs.pl';

my $zero = sprintf '%E', 0;
my ($pad) = $zero =~ /E00(\d+)$/;

my $b = Math::MatrixReal->new_from_string(<<XXX);
[ 1 1 0 0 ]
[ 1 2 2 0 ]
[ 0 2 3 3 ]
[ 0 0 3 4 ]
XXX

my $a = Math::MatrixReal->new_tridiag( [1, 2, 3], [1, 2, 3, 4], [1, 2, 3] );
unless ($@){
	ok(1, 'new_tridiag exists');
} else {
	ok(0, 'new_tridiag fails');
}
ok( ref $a eq 'Math::MatrixReal', 'new_tridiag returns correct object' );
ok_matrix( $a, $b, 'new_tridiag seems to work' );
my ($r,$c) = $a->dim;
ok( $r == 4 && $c == 4, 'new_tridiag returns a matrix of the correct size' );

my $matrix = Math::MatrixReal->new_tridiag( [ 6, 4, 2 ], [1,2,3,4], [1, 8, 9] );

my $correct = <<'MAT';
[  1.000000000000E+00  1.000000000000E+00  0.000000000000E+00  0.000000000000E+00 ]
[  6.000000000000E+00  2.000000000000E+00  8.000000000000E+00  0.000000000000E+00 ]
[  0.000000000000E+00  4.000000000000E+00  3.000000000000E+00  9.000000000000E+00 ]
[  0.000000000000E+00  0.000000000000E+00  2.000000000000E+00  4.000000000000E+00 ]
MAT

# Determine number of digits in exponents beyond the libc 'standard' of two
# and pad out the expected result.
my $zero = sprintf '%E', 0;
my ($pad) = $zero =~ m/E\+00(\d+)$/;
$correct =~ s/([eE])([+-])(\d\d)/$1$2$pad$3/g if defined $pad;

ok( "$matrix" eq $correct, 'new_tridiag' );

