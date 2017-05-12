#                              -*- Mode: Perl -*- 
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

use Math::MagicSquare;

print "1..7\n";

print "Testing Math::MagicSquare-", $Math::MagicSquare::VERSION, "\n";

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

$A = Math::MagicSquare -> new ([8,1,6],
                               [3,5,7],
                               [4,9,2]);

$B = Math::MagicSquare -> new ([4,14,15,1],
                               [9,7,6,12],
                               [5,11,10,8],
                               [16,2,3,13]);

$C = Math::MagicSquare -> new ([1,4],
                               [3,2]);

$D = Math::MagicSquare -> new ([1,1],
                               [1,1]);

$A->print("Magic Square A:");
print "ok 1\n";

$B->printhtml();
print "ok 2\n";

$i=$B->check;
if ($i == 0) {print "This isn't Magic\n";}
elsif ($i == 1) {print "This is a Semimagic Square\n";}
elsif ($i == 2) {print "This is a Magic Square\n";}
else {print "This is a Panmagic Square\n";}
print "ok 3\n";

$i=$C->check;
if ($i == 0) {print "This isn't Magic\n"}
elsif ($i == 1) {print "This is a Semimagic Square\n";}
elsif ($i == 2) {print "This is a Magic Square\n";}
else {print "This is a Panmagic Square\n";}
print "ok 4\n";

$i=$D->check;
if ($i == 0) {print "This isn't Magic\n";}
elsif ($i == 1) {print "This is a Semimagic Square\n";}
elsif ($i == 2) {print "This is a Magic Square\n";}
else {print "This is a Panmagic Square\n";}
print "ok 5\n";

$B->rotation();
$B->print("Rotation Magic Square B:\n");
print "ok 6\n";

$B->print("Before reflection:\n");
$B->reflection();
$B->print("After reflection:\n");
print "ok 7\n";
