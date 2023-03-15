use warnings;
use strict;

BEGIN {
	if("$]" >= 5.012) {
		require Test::More;
		Test::More::plan(skip_all => "no problem on this Perl");
	}
}

# This test checks whether L:SRH is properly handling delayed loads in
# modules that are liable to be loaded during the loading of L:SRH.
# Our test case is the delayed load of Exporter::Heavy by Exporter.
# Exporter is likely to be loaded during the loading of L:SRH, and
# to ensure that we're performing the test we actually force it to be
# loaded before we load L:SRH.  The delayed load of Exporter::Heavy is
# unlikely to be executed by loading of L:SRH, Exporter, or stricture,
# but it likely would be executed by loading Test::More, so we don't
# use Test::More.

BEGIN { print "1..1\n"; }

use Exporter ();

my %early_loaded;
BEGIN { %early_loaded = %INC; }

use Lexical::SealRequireHints;

if(exists($early_loaded{"Exporter/Heavy.pm"})) {
	print "ok 1 # skip Exporter::Heavy loaded early\n";
} elsif(exists($INC{"Exporter/Heavy.pm"})) {
	print "ok 1\n";
} else {
	print "not ok 1\n";
}

1;
