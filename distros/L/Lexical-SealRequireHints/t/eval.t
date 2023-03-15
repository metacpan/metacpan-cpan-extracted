use warnings;
use strict;

BEGIN {
	if("$]" < 5.006001) {
		require Test::More;
		Test::More::plan(skip_all => "core bug makes this test crash");
	}
}

use Test::More tests => 9;

BEGIN { use_ok "Lexical::SealRequireHints"; }
BEGIN { unshift @INC, "./t/lib"; }

use t::eval_0;

BEGIN {
	undef *t::eval_0::_ok_no_eval;
	undef *t::eval_0::import;
	ok +scalar(do "t/eval_0.pm");
	t::eval_0->import;
}

ok 1;

1;
