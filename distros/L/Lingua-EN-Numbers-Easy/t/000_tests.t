# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..3\n"; }
END {print "not ok 1\n" unless $loaded;}
use Lingua::EN::Numbers::Easy;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

my @tests = ([1                    => 'one'],
             [2                    => 'two'],
             [0                    => 'zero'],
             [17                   => 'seventeen'],
             [-23                  => 'negative twenty-three'],
             ["-23.4"              => 'negative twenty-three point four'],
);


my $flag = 0;
foreach my $test (@tests) {
    if ($test -> [1] ne $N {$test -> [0]}) {$flag = 1}
}
print $flag ? "not ok 2\n" : "ok 2\n";

our %Nums;

Lingua::EN::Numbers::Easy -> import (American => '%Nums');

   @tests = ([4                    => 'four'],
             [5                    => 'five'],
             [0                    => 'zero'],
             [19                   => 'nineteen'],
             [-22                  => 'negative twenty-two'],
             [-22.4                => 'negative twenty-two point four'],
);

   $flag = 0;
foreach my $test (@tests) {
    if ($test -> [1] ne $Nums {$test -> [0]}) {$flag = 1}
}

print $flag ? "not ok 3\n" : "ok 3\n";
