#!./perl -w

# Test::Harness uses Carp so this isn't a very good test.
use Devel::Carp;
print "1..1\n";

print "not " if !$INC{'Carp.pm'};
print "ok 1\n";

