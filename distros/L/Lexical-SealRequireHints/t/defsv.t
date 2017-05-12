use warnings;
use strict;

use Test::More tests => 5;

BEGIN { use_ok "Lexical::SealRequireHints"; }

SKIP: {
	skip "CORE::GLOBAL::require breaks require() on this perl", 4
		if defined(&CORE::GLOBAL::require) && "$]" < 5.015005;
	my $retval;
	eval q{ our $_ = "t/context_0.pm"; $retval = require; 1 };
	is $@, "";
	is $retval, "t::context_0 return";
	SKIP: {
		skip "no lexical \$_ on this perl", 2
			if "$]" < 5.009001 || "$]" >= 5.023004;
		eval q{
			no warnings "$]" >= 5.017009 ? "experimental" :
							"deprecated";
			my $_ = "t/context_1.pm";
			$retval = require;
			1;
		};
		is $@, "";
		is $retval, "t::context_1 return";
	}
}

1;
