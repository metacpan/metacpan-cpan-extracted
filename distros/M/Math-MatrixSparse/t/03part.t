use lib qw(./blib/lib ../blib/lib);

use strict;
use Test;

BEGIN { $| = 1; print "1..16\n"; }
use Math::MatrixSparse;
my $loaded = 1;
END {print "not ok 1\n" unless $loaded;}
print "ok 1\n";

my $A = Math::MatrixSparse->newrandom(100000,100000,500,1);

my $succ = 1;
END {print "not ok 2\n" unless $succ;}
print "ok 2\n" if $succ;

my $symtest = $A->symmetrify()->is_symmetric();
print "not " unless $symtest;
print "ok 3\n";
my $skewsymtest = $A->skewsymmetrify()->is_skewsymmetric();
print "not " unless $skewsymtest;
print "ok 4\n";
my $symdec = ($A->symmetricpart() +$A->skewsymmetricpart()) == $A;
print "not " unless $symdec;
print "ok 5\n";
my $uptest = $A->nonlowerpart()->is_uppertriangular();
print "not " unless $uptest;
print "ok 6\n";
my $suptest = $A->upperpart()->is_strictuppertriangular();
print "not " unless $suptest;
print "ok 7\n";
my $lowtest = $A->nonupperpart()->is_lowertriangular();
print "not " unless $lowtest;
print "ok 8\n";
my $slowtest = $A->lowerpart()->is_strictlowertriangular();
print "not " unless $slowtest;
print "ok 9\n";
my $diagtest = $A->diagpart()->is_diagonal();
print "not " unless $diagtest;
print "ok 10\n";

my $diagdec = ($A->diagpart()+$A->nondiagpart()) == $A;
print "not " unless $diagdec;
print "ok 11\n";
my $ldudec = ($A->diagpart()+$A->lowerpart()+$A->upperpart()) == $A;
print "not " unless $ldudec;
print "ok 12\n";

my $trantest1 = $A->upperpart()->transpose()->is_strictlowertriangular();
my $trantest2 = $A->lowerpart()->transpose()->is_strictuppertriangular();
my $trantest3 = $A->nonlowerpart()->transpose()->is_lowertriangular();
print "not " unless $trantest1;
print "ok 13\n";
print "not " unless $trantest2;
print "ok 14\n";
print "not " unless $trantest3;
print "ok 15\n";

my $trantest4=$A->transpose()->transpose() == $A;
print "not " unless $trantest4;
print "ok 16\n";

