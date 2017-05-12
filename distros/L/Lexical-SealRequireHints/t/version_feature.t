use warnings;
use strict;

BEGIN {
	if("$]" < 5.009005) {
		require Test::More;
		Test::More::plan(skip_all =>
			"no version-implied features on this perl");
	}
}

use Test::More tests => 4;

BEGIN { use_ok "Lexical::SealRequireHints"; }

eval q{
	use 5.009005;
	sub t0 { say "foo"; }
};
is $@, "";

eval q{
	no warnings "portable";
	use 5.9.5;
	sub t1 { say "foo"; }
};
is $@, "";

eval q{
	no warnings "portable";
	use v5.9.5;
	sub t2 { say "foo"; }
};
is $@, "";

1;
