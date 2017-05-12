use Test::More tests => 2;
use File::Spec;
use lib File::Spec->catfile("..","lib");
use Math::MatrixReal;
do 'funcs.pl';

# Determine number of digits in exponents beyond the libc 'standard' of two
# and pad out the expected result.
my $zero = sprintf '%E', 0;
my ($pad) = $zero =~ m/E\+00(\d+)$/;

my $correct=<<ERE;
[  1.000000000000E+00  0.000000000000E+00  0.000000000000E+00 ]
[  0.000000000000E+00  2.000000000000E+00  0.000000000000E+00 ]
[  0.000000000000E+00  0.000000000000E+00  3.000000000000E+00 ]
ERE
$correct =~ s/([eE])([+-])(\d\d)/$1$2$pad$3/g if defined $pad;
my $matrix = Math::MatrixReal->new_diag( [ 1, 2, 3] );
my $str = "$matrix";
ok( $str eq $correct, 'stringification');

my $correct2=<<ERE;
[  1.000000000000E+00  0.000000000000E+00  0.000000000000E+00 ]
[  0.000000000000E+00  2.000000000000E+00  0.000000000000E+00 ]
[  0.000000000000E+00  0.000000000000E+00  3.000000000000E+00 ]

Blah blah blah
ERE
$correct2 =~ s/([eE])([+-])(\d\d)/$1$2$pad$3/g if defined $pad;
my $stuff = $matrix . "\nBlah blah blah\n";
ok( $stuff eq $correct2, 'implied stringification with concat');
