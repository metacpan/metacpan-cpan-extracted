use warnings;
use strict;

use Test::More tests => 19;

BEGIN { use_ok "Lexical::SealRequireHints"; }

no warnings "portable";

foreach(
	q{ use 5.006; },
	q{ use 5.6.0; },
	q{ use v5.6.0; },
	q{ require 5.006; },
	q{ require 5.6.0; },
	q{ require v5.6.0; },
	q{ require(5.006); },
	("$]" >= 5.009002 ? (
		q{ my $v = 5.6.0; require($v); },
		q{ my $v = 5.6.0; require($v); },
	) : ("", "")),
) {
	eval $_;
	is $@, "";
}

foreach(
	q{ use 6.006; },
	q{ use 6.6.0; },
	q{ use v6.6.0; },
	q{ require 6.006; },
	q{ require 6.6.0; },
	q{ require v6.6.0; },
	q{ require(6.006); },
	("$]" >= 5.009002 ? (
		q{ my $v = 6.6.0; require($v); },
		q{ my $v = 6.6.0; require($v); },
	) : ("use 6.006;", "use 6.006;")),
) {
	eval $_;
	like $@, qr/\APerl v6\.6\.0 required/;
}

1;
