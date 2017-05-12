#! perl

use strict;
use warnings;
use Test::More tests => 1;
use MIDI::Tweaks;
-d "t" && chdir "t";
require "./tools.pl";

# Actually, this is more a verification of MIDI functionality that
# we're going to rely on.

my $id = "90-complex";
my @cln = ( "$id.mid.dmp", "$id.out", "$id.out.dmp");

# Cleanup.
unlink(@cln);

# Load MIDI file.
my $op = new MIDI::Tweaks::Opus ({ from_file => "$id.mid" });

# Dump it.
$op->dump_to_file("$id.mid.dmp");

# Write it out.
$op->write_to_file("$id.out");

# Load the freshly written file.
$op = new MIDI::Tweaks::Opus ({ from_file => "$id.out" });

# Dump it.
$op->dump_to_file("$id.out.dmp");

# Compare the dumps.
if ( differ("$id.mid.dmp", "$id.out.dmp", 1) ) {
    fail("compare");
}
else {
    pass("compare");
    # Cleanup.
    unlink(@cln);
}
