#!perl
# (Hey vim! use Perl syntax highlighting... vim: filetype=Perl 

# Ugly hack to run a Z-code file that's been translated into Perl.
# I need to call with -r 255 -t dumb to make sure that the system
# simply prints its "ok ..." results to STDOUT (without [MORE] prompts
# that seem to fail under Test::Harness).
# So this file just runs that file.

use strict;
use warnings;
# Don't 'use Test'. The program we call will use that.
use File::Basename;

use constant ZROOT => "big_test";

# TODO use output streams if they work. 
# read in output files, compare line-by-line to test output files. 
# Should be identical to the character IF we designate -c 80 -r 255
# Overwriting y/n depends on GetKey, though? Delete in this program?
# unlink ZROOT . ".cmd", ZROOT . "out";
#
# TODO Now that we're printing "|perl big_test.pl", can we use -r 24
# and send \n's?

my $test_file = ZROOT . ".pl";
# Use fileparse because dirname can have different behavior sometimes.
my $dir = (fileparse $0)[1];
$test_file = $dir . $test_file;

unless (-r $test_file) { 
    print "1..0 # Skipped: '$test_file' not found\n";
    exit 
}

# Get around LZ bug: can't use Windows input files on Unix
# so build the test input file on the same platform it's being tested on.
my $test_str = qq{ask Hitchhiker's ABOUT bAbel fish\n hello,Sailor. \n\ntype"012 345 678 9!? _#' /\\- :()"\n};
my $in_file = $dir . ZROOT . ".in";
open (TEST_IN, ">$in_file") or die "Opening input file '$in_file': $!\n";
print TEST_IN $test_str;
close TEST_IN;

#system("$^X -Mblib $test_file -r 255 -t dumb");
open(FOO, "|$^X -Mblib $test_file -r 255 -t dumb");
print FOO "$in_file\n";
close FOO;
