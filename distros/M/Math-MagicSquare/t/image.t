#                              -*- Mode: Perl -*- 
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

print "1..1\n";

print "Testing Math::MagicSquare-", $Math::MagicSquare::VERSION, "\n";

use Math::MagicSquare;

$E = Math::MagicSquare -> new ([5,31,35,60,57,34,8,30],
                               [19,9,53,46,47,56,18,12],
                               [16,22,42,39,52,61,27,1],
                               [63,37,25,24,3,14,44,50],
                               [26,4,64,49,38,43,13,23],
                               [41,51,15,2,21,28,62,40],
                               [54,48,20,11,10,17,55,45],
                               [36,58,6,29,32,7,33,59]);

$E->printimage();
print "ok 1\n";
