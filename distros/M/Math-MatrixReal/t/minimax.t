use Test::More tests => 6;
use File::Spec;
use lib File::Spec->catfile("..","lib");
use Math::MatrixReal qw/:all/;
use strict;
use warnings;

do 'funcs.pl';

my ($x,$y) = (7,42);

ok( min($x ,$x + $y ** 2) == $x, 'min works');
ok( max($y,$x * $y) == $x*$y, 'max works');

my $a = Math::MatrixReal->new_diag( [ 1 .. 10 ] );
my $min = $a->min;
ok( similar($min,0), '$a->min works, $min=' . $min);

$a = Math::MatrixReal->new_diag( [ 1 .. 10 ] );
my $max = $a->max;
ok( similar($max,10) , '$a->max works, $max=' . $max);

$a = Math::MatrixReal->new_random( 20, 20, { symmetric => 1 }  );
$max = $a->max;
$min = $a->min;
my $eps = 1e-8;
ok( $max <= 10 , 'symmetric random matrix adheres to bounded_by, max=' . $max);
ok( $min >= 0  , 'symmetric random matrix adheres to bounded_by, min=' . $min);

