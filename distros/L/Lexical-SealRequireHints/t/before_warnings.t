# This script checks whether L:SRH takes effect sufficiently early.  It is
# specifically concerned with the "require Carp" or "require Carp::Heavy"
# that warnings.pm may execute in a delayed manner.  Either it must
# be possible to delay loading warnings.pm until after L:SRH has taken
# effect, so that its require statements will be appropriately altered
# to avoid hint leakage, or L:SRH must cause Carp to load, so that it's
# loaded without problematic hints in existence.  We test this by loading
# L:SRH first thing, and checking what's been loaded.  This script,
# as a result, can't use warnings.pm or anything that might load it.
# The test is only applied on Perls where L:SRH makes a difference,
# so that infrastructure modules can start using warnings in the future.

BEGIN {
	if("$]" >= 5.012) {
		print "1..0 # SKIP no problem on this Perl\n";
		exit 0;
	}
}

BEGIN { print "1..1\n"; }

use Lexical::SealRequireHints;
BEGIN {
	if(exists($INC{"warnings.pm"}) &&
			!(exists($INC{"Carp.pm"}) &&
				exists($INC{"Carp/Heavy.pm"}))) {
		print "not ok 1\n";
		exit 1;
	}
}

print "ok 1\n";
exit 0;

1;
