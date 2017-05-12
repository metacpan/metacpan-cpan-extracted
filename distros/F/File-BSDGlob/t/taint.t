#!perl -T
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

## why do I have to do this?!?
use lib qw( ./blib/lib ./blib/arch );
BEGIN {print "1..2\n";}
END {print "not ok 1\n" unless $loaded;}
use File::BSDGlob;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# all filenames should be tainted
@a = File::BSDGlob::glob("*");
eval { $a = join("",@a), kill 0; 1 };
unless ($@ =~ /Insecure dependency/) {
    print "not ";
}
print "ok 2\n";
