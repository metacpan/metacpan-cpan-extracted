# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

BEGIN { $| = 1; print "1..1\n"; }
END {print "not ok 1\n" unless $loaded;}
use Devel::Trace;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

open S, "< sample" or die "Couldn't open sample demo file: $!; aborting";
print while <S>;
close S;
print "\n";
print "Press enter to execute this file.  \n";
<STDIN>;
system("perl -I./blib/lib -d:Trace sample");
$? and die "Problem running sample program: $? exit status\n";
