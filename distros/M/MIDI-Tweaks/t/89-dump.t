#! perl

my $id = "89-dump";

# Test midi-dump

use strict;
use warnings;
use Test::More tests => 1;
use File::Spec;
-d "t" && chdir "t";
require "./tools.pl";

# Get platform-independent file names.
my $dumper = File::Spec->catfile("../blib/script", "midi-dump");

my @cln = ("$id.out");

unlink(@cln);
system("$^X $dumper $id.mid > $id.out");

if ( differ("$id.out", "$id.ref", 1) ) {
    fail("compare");
}
else {
    pass("compare");
    # Cleanup.
    unlink(@cln);
}



