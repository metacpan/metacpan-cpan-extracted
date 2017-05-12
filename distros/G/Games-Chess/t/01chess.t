# Test Games::Chess constants and functions (-*- cperl -*-)

BEGIN { $| = 1; print "1..2\n"; }
END {print "not ok 1\n" unless $loaded;}
use Games::Chess qw(:constants :functions debug);
debug(1);
$loaded = 1;
print "ok 1\n";

use strict;
use UNIVERSAL 'isa';
$^W = 1;
my $n = 1;
my $success;

sub do_test (&) {
  my ($test) = @_;
  ++ $n;
  $success = 1;
  &$test;
  print 'not ' unless $success;
  print "ok $n\n";
}

sub fail {
  my ($mesg) = @_;
  print STDERR $mesg, "\n";
  $success = 0;
}

# Test algebraic_to_xy, xy_to_algebraic, xy_valid

do_test {
  my @squares = 
    qw(a1 0 0 a2 0 1 a3 0 2 a4 0 3 a5 0 4 a6 0 5 a7 0 6 a8 0 7
       b1 1 0 b2 1 1 b3 1 2 b4 1 3 b5 1 4 b6 1 5 b7 1 6 b8 1 7
       c1 2 0 c2 2 1 c3 2 2 c4 2 3 c5 2 4 c6 2 5 c7 2 6 c8 2 7
       d1 3 0 d2 3 1 d3 3 2 d4 3 3 d5 3 4 d6 3 5 d7 3 6 d8 3 7
       e1 4 0 e2 4 1 e3 4 2 e4 4 3 e5 4 4 e6 4 5 e7 4 6 e8 4 7
       f1 5 0 f2 5 1 f3 5 2 f4 5 3 f5 5 4 f6 5 5 f7 5 6 f8 5 7
       g1 6 0 g2 6 1 g3 6 2 g4 6 3 g5 6 4 g6 6 5 g7 6 6 g8 6 7
       h1 7 0 h2 7 1 h3 7 2 h4 7 3 h5 7 4 h6 7 5 h7 7 6 h8 7 7);
  my @non_squares = qw(a0 a9 @1 @8 h0 h9 i1 i8 A1 A8 H1 H8);
  while (@squares) {
    my ($sq,$x,$y) = splice @squares, 0, 3;
    my $SQ = xy_to_algebraic($x,$y);
    $sq eq $SQ
      or fail("xy_to_algebraic($x,$y) = $SQ (should be $sq)");
    my ($X,$Y) = algebraic_to_xy($sq);
    $x == $X and $y == $Y
      or fail("algebraic_to_xy($sq) = $X,$Y (should be $x,$y)");
    my $v = xy_valid($x,$y);
    defined $v and $v == 1
      or fail("xy_valid($x,$y) is $v (should be 1)");
  }
  local $Games::Chess::DEBUG = 0;
  foreach (@non_squares) {
    my @sq = algebraic_to_xy($_);
    @sq == 0 or fail("algebraic_to_xy($_) is (@sq) (should be none)");
  }
  foreach (0 .. 100) {
    my ($x,$y) = (rand(1000)-500,rand(1000)-500);
    next if $x==int $x and $y==int $y and 0<=$x and $x<8 and 0<=$y and $y<8;
    my $sq = xy_to_algebraic($x,$y);
    not defined $sq or fail("xy_to_algebraic($x,$y) = $sq (should be undef)");
    my $v = xy_valid($x,$y);
    not defined $v or fail("xy_valid($x,$y) is $v (should be undef)");
  }
};
