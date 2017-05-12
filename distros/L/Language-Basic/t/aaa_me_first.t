# This test is done first, just to check that 'use' works at all.
# Test LB::Program::input method while we're at it, though.
#

######################### We start with some black magic to print on failure.

BEGIN { $| = 1; print "1..5\n"; }
END {print "not ok 1\n" unless $loaded;}
use Language::Basic;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

my $f = "aaa.bas";
open(BASIC, ">$f") or print "not ok 2\n",exit;
while(<DATA>) {print BASIC $_}
close(BASIC);

my $Program = new Language::Basic::Program;
print "ok 2\n";

$Program->input($f); # Read the lines from a file
print "ok 3\n";

$Program->parse; # Parse the lines
print "ok 4\n";

$Program->implement; # Implement the program
print "ok 5\n";

# We don't actually care about output. Worry about that in all the other tests.
unlink $f;

__DATA__
10 PRINT "HELLO, WORLD!"
20 END
