use warnings;
use strict;

BEGIN {
	if("$]" < 5.008) {
		require Test::More;
		Test::More::plan(skip_all =>
			"swash loading disagrees with infrastructure");
	}
}

use Test::More tests => 6;

use Lexical::SealRequireHints;

BEGIN {
	SKIP: {
		skip "Perl 5.11 doesn't work with localised hint bit", 2
			if "$]" >= 5.011 && "$]" < 5.012;
		$^H = 0;
		is $^H, 0;
		require t::package_0;
		is $^H, 0;
	}
}

BEGIN {
	%^H = ( foo=>1, bar=>2 );
	$^H |= 0x20000;
	is_deeply [ sort keys(%^H) ], [qw(bar foo)];
	if(exists $INC{"utf8.pm"}) {
		SKIP: {
			skip "utf8.pm loaded too early ".
				"(breaking following tests)", 1;
		}
	} else {
		pass;
	}
}
BEGIN {
	# Up to Perl 5.7.0, it is the compilation of this regexp match
	# that triggers swash loading.	From Perl 5.7.1 onwards, it
	# is the execution.  Hence for this test we must arrange for
	# both to occur between the surrounding segments of test code.
	# A BEGIN block achieves this nicely.
	my $x = "foo\x{666}";
	$x =~ /foo\p{Alnum}/;
}
BEGIN {
	ok exists($INC{"utf8.pm"});
	is_deeply [ sort keys(%^H) ], [qw(bar foo)];
}

1;
