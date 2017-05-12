use Test::Most tests => 2;
use strict;
use warnings;
use File::Spec;
use lib File::Spec->catfile("..","lib");
use Math::MatrixReal;
do 'funcs.pl';

{
my $latex1=<<'LATEX';
$\left( \begin{array}{cc}
1.41e-05&1 \\
6.82e-06&3 \\
3.18e-06&4
\end{array} \right)
$
LATEX
chomp $latex1;

# Determine number of digits in exponents beyond the libc 'standard' of two
# and pad out the expected result.
my $zero = sprintf '%E', 0;
my ($pad) = $zero =~ m/E\+00(\d+)$/;
$latex1 =~ s/([eE])([+-])(\d\d)/$1$2$pad$3/g if defined $pad;

    my $a = Math::MatrixReal->new_from_cols([[ 1.41E-05, 6.82E-06, 3.18E-06 ],[1,3,4]]);
    eq_or_diff( lc $a->as_latex, lc $latex1, 'as_latex seems to work');
}
{
my $latex2=<<'LATEX';
$A = \left( \begin{array}{ll}
1.23&1.00 \\
5.68&2.00 \\
9.10&3.00
\end{array} \right)
$
LATEX
chomp $latex2;

    my $b = Math::MatrixReal->new_from_cols([[ 1.234, 5.678, 9.1011],[1,2,3]] );
    my $s = $b->as_latex( ( format => "%.2f", align => "l",name => "A" ) );
    eq_or_diff(lc $s, lc $latex2,'as_latex format options seem to work');
}

