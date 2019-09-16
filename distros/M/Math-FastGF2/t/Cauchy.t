#!/usr/bin/env perl

use FindBin qw($Bin);
use lib "$Bin/../lib";

use Data::Dumper;

use Test::More;
BEGIN {
    use_ok('Math::FastGF2::Matrix', ':all');
    eval { require Crypt::IDA };
    if ($@) {
	ok(1, "Skipping tests that require Crypt::IDA\n");
	done_testing;
	exit;
    }
};

use Crypt::IDA qw(:all);

# I'll be adding a new matrix inversion routine that relies on
# knowing the "key" that was used to set up the matrix in the
# first place.

# First, use Crypt::IDA->ida_key_to_matrix() to create a matrix 
my $key = [ 1,2,3,4,5,6,7,8 ];

# This will represent a key for a (3,5) scheme. I'm mixing option
# names for ida_key_to_matrix and the new new_inverse_cauchy
my @opts = (			# we can re-use to get inverse matrix
    quorum => 3,		# 
    size   => 3,		# was "quorum"
    shares => 5,		# n/a for new routine (=@xylist - @xvals)
    sharelist => [0..4],	# 
    xvals   => [0..4],		# was "sharelist"
    width  => 1,		# common
    key    => $key,		# 
    xylist => $key,		# was "key"
);
my $mat_from_key = ida_key_to_matrix(@opts);
my $inv_from_key = ida_key_to_matrix(@opts, 
				     "invert?" => 1,
				     "sharelist" => [0..2]);

# Invert the matrix the other way (manually)
my $top3 = $mat_from_key->copy_rows(0..2);
my $inv3 = $top3->invert;
#warn Dumper $inv_from_key;

# expect these to pass
ok(ref $mat_from_key, "create matrix from key?");
ok(ref $inv_from_key, "create inverse matrix from key?");
ok($inv_from_key->eq($inv3), "both old inverse paths agree?");

# Implement new new_inverse_cauchy; it will take args similar to
# the ida_key_to_matrix call above. (for now)
ok(Math::FastGF2::Matrix->can("new_inverse_cauchy"),
   "has method new_inverse_cauchy?");

my $inv_cauchy;
ok($inv_cauchy = Math::FastGF2::Matrix
   ->new_inverse_cauchy(@opts, "xvals" => [0..2]),
   "method new_inverse_cauchy returns something?");

ok($inv_from_key->eq($inv_cauchy), "New routine gets same result?");

# how about transposing it?
#my $trans = $inv_cauchy->transpose;
#ok($inv_from_key->eq($trans), "New routine gets transposed result?");

# Final sanity check.. invert back using regular Gaussian elimination
my $inv_back = $inv_cauchy->copy->invert;
ok($top3->eq($inv_back), "Inverse of inverse (3x3)?");

print "Expected Inverse:\n";                   $inv_from_key->print;
print "Got Inverse:\n";                        $inv_cauchy->print;
print "Original (uninverted):\n";              $top3->print;
print "Inverse of Inverse Cauchy from Key:\n"; $inv_back->print;

# The following are expected to work... treat the key as a (4,4) scheme
@opts = (			# we can re-use to get inverse matrix
    quorum => 4,		# for ida_key_to_matrix
    size   => 4,
    shares => 4,
    sharelist => [0..3],	# for ida_key_to_matrix
    xvals => [0..3],		# for new_inverse_cauchy
    width  => 1,
    key    => $key,
    xylist => $key,				
);
my $mat4_key = ida_key_to_matrix(@opts);
my $inv4_key = ida_key_to_matrix(@opts, 
				 "invert?" => 1,
				 "sharelist" => [0..3]);

ok(ref $mat4_key, "create matrix from key?");
ok(ref $inv4_key, "create inverse matrix from key?");

my $inv4_cauchy;
ok($inv4_cauchy = Math::FastGF2::Matrix
   ->new_inverse_cauchy(@opts, "xvals" => [0..3]),
   "method new_inverse_cauchy returns something?");

ok($inv4_key->eq($inv4_cauchy), "New routine gets same result?");

# Final sanity check..
my $inv4_back = $inv4_cauchy->copy->invert; # Gaussian
ok($mat4_key->eq($inv4_back), "Inverse of inverse (4x4)?");


print "Expected Inverse:\n"; $inv4_key->print;
print "Got Inverse:\n";      $inv4_cauchy->print;

print "Original (uninverted):\n"; $mat4_key->print;
print "Inverse of Inverse Cauchy from Key:\n"; $inv4_back->print;

# Test new Cauchy matrix constructor
ok(Math::FastGF2::Matrix->can("new_cauchy"),
   "has method new_cauchy?");

# The routine will have two ways of specifying the x's and y's:
#
# As two separate listref options, "xvals" and "yvals"
#
# As a combined xylist, but then also need to specify at least one
# of the following: "rows" "cols"
#
# To test these, we'll just plug in all valid combinations and check
# that we get and object back and that it has the right dimensions

# 7 rows and 3 columns
my @xvals = (1..7);
my @yvals = (8,9,10);
my $cauchy;
my $rows = scalar(@xvals);
my $cols = scalar(@yvals);
my @xyvals = (@xvals, @yvals);

# A: pass xvals, yvals separately
$cauchy = Math::FastGF2::Matrix->
    new_cauchy(xvals => \@xvals, yvals => \@yvals, width => 1);
ok(ref $cauchy,  "New Cauchy matrix from xvals, yvals?");
ok($cauchy->ROWS == $rows, "Has $rows rows?");
ok($cauchy->COLS == $cols, "Has $cols cols?");

# B: pass xyvals and rows
$cauchy = Math::FastGF2::Matrix->
    new_cauchy(xyvals => \@xyvals, rows => $rows, width => 1);
ok(ref $cauchy,  "New Cauchy matrix from xyvals, rows?");
ok($cauchy->ROWS == $rows, "Has $rows rows?");
ok($cauchy->COLS == $cols, "Has $cols cols?");

# C: pass xyvals and cols
$cauchy = Math::FastGF2::Matrix->
    new_cauchy(xyvals => \@xyvals, cols => $cols, width => 1);
ok(ref $cauchy,  "New Cauchy matrix from xyvals, cols?");
ok($cauchy->ROWS == $rows, "Has $rows rows?");
ok($cauchy->COLS == $cols, "Has $cols cols?");

# Make sure that constructed matrices match with old code
# Recall that we made these matrices already
# my $key = [ 1,2,3,4,5,6,7,8 ];
# my @opts = (
#    quorum => 3,
#    sharelist => [0..4],	#
#    ...
# );
# $mat_from_key = ida_key_to_matrix(@opts);
# $inv_from_key = ida_key_to_matrix(@opts, "invert?" => 1,
#				     "sharelist" => [0..2]);

# Create matching matrix
@xvals = (1..5); $rows = 5;
@yvals = (6..8); $cols = 3;
$cauchy = Math::FastGF2::Matrix->
    new_cauchy(xvals => \@xvals, yvals => \@yvals, width => 1);
ok(ref $cauchy,  "New Cauchy matrix from xvals, yvals?");
ok($cauchy->ROWS == $rows, "Has $rows rows?");
ok($cauchy->COLS == $cols, "Has $cols cols?");

ok($cauchy->eq($mat_from_key), "New (3,5) matrix same as for old code");

# We also created a 4x4 matrix $mat4_key
@xvals = (1..4); $rows = 4;
@yvals = (5..8); $cols = 4;
$cauchy = Math::FastGF2::Matrix->
    new_cauchy(xvals => \@xvals, yvals => \@yvals, width => 1);
ok(ref $cauchy,  "New Cauchy matrix from xvals, yvals?");
ok($cauchy->ROWS == $rows, "Has $rows rows?");
ok($cauchy->COLS == $cols, "Has $cols cols?");

ok($cauchy->eq($mat4_key), "New (4,4) matrix same as for old code");

# I can't see the need to do any more testing on new_cauchy ...  The
# above should have proved that it works as expected.

done_testing;
exit;




