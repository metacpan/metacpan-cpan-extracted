#!/usr/bin/env perl

use FindBin qw($Bin);
use lib "$Bin/../lib";

use Data::Dumper;

use Test::More;
BEGIN {
    use_ok('Math::FastGF2::Matrix', ':all');
};

ok(Math::FastGF2::Matrix->can('new_vandermonde'),
	"Have Vandermonde constructor?");

my $v;



$v=Math::FastGF2::Matrix->
	new_vandermonde(width => 1, org => "rowwise",
                        xvals => [ 0..6 ],  # 7 rows
                        cols   => 3,
			);

ok (ref($v), 'Construct Vandermonde matrix?');
ok ($v->ROWS == 7, "7 rows");
ok ($v->COLS == 3, "3 cols");

# First column should be all ones, second should be x values
for my $row (0..6) {
    ok($v->getval($row,0) == 1,    "x^0 is 1 in row $row");
    ok($v->getval($row,1) == $row, "x^1 is x in row $row");
}

# Are all k x k sub-matrices invertible?
#
# We have 7 rows, so there are 7x6x5 = 210 permutations of 3 rows
my $perms = 7*6*5-1;
my %check_dup = ();
for my $p (0 .. $perms - 1) {

    # Pick the elements based on "factorising" the permutation number
    my $pp = $p;
    my $seven = $pp % 7; $pp /= 7;
    my $six   = $pp % 6; $pp /= 6;
    my $five  = int($pp);
    die if $five >= 5;
    my $check = "$seven:$six:$five";
    die if exists($check_dup{$check});
    $check_dup{$check} = undef;

    # Now select from one of seven, one of six and one of five...
    my @rows = (0..6);
    my @chosen = ();
    push @chosen, splice @rows, $seven, 1;
    push @chosen, splice @rows, $six,   1;
    push @chosen, splice @rows, $five,  1;
    #warn $check;

    die "Got scalar(@chosen)\n" unless @chosen == 3;
    my $submatrix = $v->copy_rows(@chosen);

    #warn "submatrix has ". $submatrix->ROWS ." rows\n";
    #warn "submatrix has ". $submatrix->COLS ." cols\n";
    
    my $inverse = $submatrix->invert;

    # We should get back a matrix object if submatrix was invertible 
    ok(ref($inverse), "was it solved?");

    # In case we got mixed up with our objects
    ok($inverse != $submatrix, "Different matrices");
    ok($inverse->ne($submatrix), "Deeply different");
    
    # invert it again to make sure we get original submatrix
    ok($submatrix->eq($inverse->invert), "invert back to original");
}

# That should complete the test since we've proved the linear
# independence property of all the possible 3x3 submatrices.

done_testing;
exit;
