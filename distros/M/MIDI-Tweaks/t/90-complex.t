#! perl

my $id = "90-complex";

# An operational example.

use strict;
use warnings;
use Test::More tests => 2;

use MIDI::Tweaks;

-d "t" && chdir "t";
require "./tools.pl";

my @cln = ( "$id.mid.dmp", "$id.out.dmp", "$id.out");
unlink(@cln);

my $op = new MIDI::Tweaks::Opus ({ from_file => "$id.mid" });
ok($op->check_sanity({ fail => 1 }), "sanity");

$op->dump_to_file("$id.mid.dmp");

$op->write_to_file("$id.out");

$op = new MIDI::Tweaks::Opus ({ from_file => "$id.out" });

$op->dump_to_file("$id.out.dmp");

if ( differ("$id.mid.dmp", "$id.out.dmp", 1) ) {
    fail("compare");
}
else {
    pass("compare");
    # Cleanup.
    unlink(@cln);
}
