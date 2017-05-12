use warnings;
use strict;

use Test::More tests => 2;

require_ok "Devel::CallParser";

SKIP: {
	skip "callparser1.h available", 1 if "$]" >= 5.013008;
	eval { &Devel::CallParser::callparser1_h() };
	like $@, qr/\Acallparser1\.h not available on this version of Perl/;
}

1;
