# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..1\n"; }
END {print "not ok 1\n" unless $loaded;}
use IO::SendFile qw( sendfile );
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

open(IN,"./test.pl") or die $!;
open(OUT,">./test2.pl") or die $!;
#IO::SendFile::sendfile( fileno(OUT), fileno(IN), 0, -s "./test.pl" );
sendfile( fileno(OUT), fileno(IN), 0, -s "./test.pl" );
close(IN);
close(OUT);

undef($/);
open(IN,"./test.pl") or die $!;
open(OUT,"./test2.pl") or die $!;
$check=<IN>;
$check2=<OUT>;
die "copy not same as original!" if $check cmp $check2;
