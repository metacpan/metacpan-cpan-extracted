use File::Spec;
use lib File::Spec->catfile("..","lib");
use Math::MatrixReal;
do 'funcs.pl';

print "1..21\n";
print "ok 1\n";
my $verbose = grep @ARGV, '--verbose';

# below we are basically checking the
# various ways that the new_from_* methods 
# are supposed to work--with strings, array refs,
# or Math::MatrixReal vectors.  They are also
# supposed to work for mixtures of those things,
# so we are checking that too.

my $matrix2 = Math::MatrixReal->new_from_cols([[11,21], [12,22]]); 
print &check_matrix($matrix2) ? "ok 2\n" : "not ok 2\n";

my $col1 = $matrix2->column(1);
my $col2 = $matrix2->column(2);

my $matrix3 = $matrix2->new_from_columns( [$col1, $col2]);

print &check_matrix($matrix3) ? "ok 3\n" : "not ok 3\n";

my $string1 = "[ 11 ]\n[ 21 ]\n[ 31 ]\n";
my $string2 = "[ 12 ]\n[ 22 ]\n[ 32 ]\n";
my $string3 = "[ 13 ]\n[ 23 ]\n[ 33 ]\n";

my $matrix4 = Math::MatrixReal->new_from_cols( [$string1, $string2, $string3] );
print &check_matrix($matrix4) ? "ok 4\n" : "not ok 4\n";

my $col52 = $matrix4->column(2);
my $matrix5 = Math::MatrixReal->new_from_cols( [$string1, $col52, [13,23,33]]);
print &check_matrix($matrix5) ? "ok 5\n" : "not ok 5\n";

my $matrix6 = Math::MatrixReal->new_from_rows( [[11,12,13], [21,22,23], [31,32,33]]);
print &check_matrix($matrix6) ? "ok 6\n" : "not ok 6\n";

my $matrix7 = Math::MatrixReal->new_from_rows( ["[ 11 12 13 ]\n", "[ 21 22 23 ]\n", "[ 31 32 33 ]\n"]);
print &check_matrix($matrix7) ? "ok 7\n" : "not ok 7\n";

my ($row81, $row82, $row83) = ($matrix4->row(1), $matrix4->row(2), $matrix4->row(3));
my $matrix8 = Math::MatrixReal->new_from_rows( [$row81, $row82, $row83] );
print &check_matrix($matrix8) ? "ok 8\n" : "not ok 8\n";

my $matrix9 = Math::MatrixReal->new_from_rows( ["[ 11 12 13 ]\n", $row82, $matrix8->row(3)] );
print &check_matrix($matrix9) ? "ok 9\n" : "not ok 9\n";

# testing for pre-0.05 problem where if ref( $vec ) 
# didn't start with Math::MatrixReal
# new_from_* wouldn't recognize it
package Foo;

use base qw/Math::MatrixReal/;

package main;

my $foo_string = "[ 11 12 13 ]\n";
my $foo_matrix = Foo->new_from_string($foo_string);

my $matrix10 = Math::MatrixReal->new_from_rows( [$foo_matrix, $row82, $matrix8->row(3)] );

print &check_matrix($matrix10) ? "ok 10\n" : "not ok 10\n";

# make sure it dies with our error message if you pass in a
# hash ref
eval{ Math::MatrixReal->new_from_cols( [{ foo=> 'bar'}] ) };
if ($@ =~ /things that inherit from Math::MatrixReal/) {
    warn $@ if $verbose;
    print "ok 11\n";
}
else {
    print "not ok 11\n";
}

# make sure it dies correctly on passing of a solo hash ref
eval{ Math::MatrixReal->new_from_cols( { foo=> 'bar'} ) };
warn $@ if $@ && $verbose;
if ($@ =~ /array of columns/) {
    print "ok 12\n";
}
else {
    print "not ok 12\n";
}

# same as above but for *rows version
eval{ Math::MatrixReal->new_from_rows( { foo=> 'bar'} ) };
warn $@ if $@ && $verbose;
if ($@ =~ /array of rows/) {
    print "ok 13\n";
}
else {
    print "not ok 13\n";
}

# handing *rows a column should die
eval { Math::MatrixReal->new_from_rows( [$foo_matrix, $row82, $matrix8->column(3)] ) };
warn $@ if $@ && $verbose;
if ($@ =~ /new_from_rows.* don't accept column vectors/) {
    print "ok 14\n";
}
else {
    print "not ok 14\n";
}

# opposite of previous test, making sure error messages
# print appropriately
eval { Math::MatrixReal->new_from_cols( [$foo_matrix, $row82, ] ) };
warn $@ if $@ && $verbose;
if ($@ =~ /new_from_col(umn)?s.* don't accept row vectors/) {
    print "ok 15\n";
}
else {
    print "not ok 15\n";
}

# mixed dimensions are supposed to die
eval { Math::MatrixReal->new_from_rows( [$foo_matrix, $row82,  [ 1 ]] ) };
warn $@ if $@ && $verbose;
if ($@ =~ /all of the rows passed in must have the same dimension/ ) {
    print "ok 16\n";
}
else {
    print "not ok 16\n";
}

# same as above but error message should say 'colunmns'
eval { Math::MatrixReal->new_from_columns( [ [ 1, 2, 3], [ 1, 2], ] ) };
warn $@ if $@ && $verbose;
if ($@ =~ /all of the columns passed in must have the same dimension/ ) {
    print "ok 17\n";
}
else {
    print "not ok 17\n";
}

# empty array ref passed in generates a weird message from MatrixReal,
# I'm putting something less mysterious there
eval { Math::MatrixReal->new_from_columns( [ [ 1, 2, 3], [], ] ) };
warn $@ if $@ && $verbose;
if ($@ =~ /no elements/ ) {
    print "ok 18\n";
}
else {
    print "not ok 18\n";
}

# making sure we get the MatrixReal error passed through
eval { Math::MatrixReal->new_from_columns( [ [ 1, 2, 3], '', ] ) };
warn $@ if $@ && $verbose;
if ($@ =~ /empty input string/ ) {
    print "ok 19\n";
}
else {
    print "not ok 19\n";
}

$matrix1 = Math::MatrixReal->new_from_string(<<"MATRIX");
[ 1 2 3 ]
[ 4 5 6 ]
[ 7 8 9 ]
MATRIX
$matrix2 = Math::MatrixReal->new_from_rows( [ [ 1, 2, 3 ], [ 4, 5, 6 ], [ 7, 8 ,9 ] ] );
 similar($matrix1,$matrix2) ? print "ok 20\n" : print "not ok 20\n";
##################################
$matrix3 =  Math::MatrixReal->new_from_cols( [ [ 1, 4, 7], [ 2, 5, 8], [3, 6, 9] ] );
similar($matrix1,$matrix3)  ? print "ok 21\n" : print "not ok 21\n";


# ok, the matrix we're making in every case is like
# this (or possibly a different-sized/shaped version):
#  
#  11  12  13
#  21  22  23
#  31  32  33
#
# so, all we have to do to check them is
# to make sure that 10 times the row plus
# the column of each given element is equal
# to the value of the element (they're
# floats, though, so check using tolerance)
#

sub check_matrix {
    my $matrix = shift;
    my ($rows, $cols) = $matrix->dim;
    my $success = 1;
    foreach my $row (1..$rows) {
        foreach my $col (1..$cols) {
            my $element = $matrix->element($row,$col) ;
            $success = 0 unless ( abs ( $element - (10*$row + $col) ) < .00001 ) ;
        }
    }
    return $success;
}
