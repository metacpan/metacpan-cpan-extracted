use warnings;
use strict;

BEGIN {
	if("$]" < 5.006001) {
		require Test::More;
		Test::More::plan(skip_all => "core bug makes this test crash");
	}
}

use Test::More tests => 5;

BEGIN { use_ok "Lexical::SealRequireHints"; }

use t::eval_0;

ok 1;

1;
