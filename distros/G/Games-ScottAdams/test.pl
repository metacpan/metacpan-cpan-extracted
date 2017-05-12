# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

# We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..5\n"; }
END {print "not ok 1\n" unless $loaded;}
use Games::ScottAdams;
$loaded = 1;
print "ok 1\n";

# End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

use strict;

# Test 2: create a new, empty, game
use IO::File;
my $g = new Games::ScottAdams::Game();
if (!defined $g) {
    print "not ok 2\n";
    exit;
}
print "ok 2\n";

# Test 3: parse a "Crystal of Chaos" sac-file (old version)
if (!$g->parse('dubbin/test.sac')) {
    print "not ok 3\n";
    exit;
}
print "ok 3\n";

# Test 4: write out Scott Adams format "compiled form"
my $tmp = '/tmp/test.sao';
#END { unlink $tmp }
open OLDOUT, ">&STDOUT";
open STDOUT, ">$tmp"
    or die "can't redirect stdout to '$tmp': $!";
$g->compile();
### Clearly this should return a status.  Currently test always "succeeds"
close STDOUT;
open STDOUT, '>&OLDOUT';
print "ok 4\n";

# Test 5: compare compiled file with our reference copy
my $ref = 'dubbin/test.sao';
open F1, $ref
    or die "can't open reference copy '$ref': $!";
open F2, $tmp
    or die "can't open homebrew copy '$tmp': $!";
my($ok, $l1, $l2) = (1, 'dummy');
while (defined $l1) {
    $l1 = <F1>;
    $l2 = <F2>;
    if ($l1 ne $l2) {
	$ok = 0;
	last;
    }
}

$ok = 0 if defined $l2;
print "not " if !$ok;
print "ok 5\n";
