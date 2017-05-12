use Test::More tests => 2;
use File::Spec;
use lib File::Spec->catfile("..","lib");
use Math::MatrixReal;
use strict;
do 'funcs.pl';

my ($a,$b);
$a = Math::MatrixReal->new_from_cols([[ 1.41E-05, 6.82E-06, 3.18E-06 ],[1,3,4]]);
my $correct = '{{1.41e-05,1},{6.82e-06,3},{3.18e-06,4}}';

# Determine number of digits in exponents beyond the libc 'standard' of two
# and pad out the expected result.
my $zero = sprintf '%E', 0;
my ($pad) = $zero =~ m/E\+00(\d+)$/;
$correct =~ s/([eE])([+-])(\d\d)/$1$2$pad$3/g if defined $pad;

ok($a->as_yacas eq $correct, 'as_yacas works' );

$b = Math::MatrixReal->new_from_cols([[ 1.234, 5.678, 9.1011],[1,2,3]] );
my $s = $b->as_yacas( ( format => "%.2f", align => "l",name => "A" ) );
ok( $s eq 'A := {{1.23,1.00},{5.68,2.00},{9.10,3.00}}', 'as_yacas formatting works' );

