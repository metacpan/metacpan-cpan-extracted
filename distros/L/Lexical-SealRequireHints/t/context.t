use warnings;
use strict;

use Test::More tests => 27;

BEGIN { use_ok "Lexical::SealRequireHints"; }
BEGIN { unshift @INC, "./t/lib"; }

my $retval;

eval { $retval = require t::context_0; 1 };
is $@, "";
is $retval, "t::context_0 return";

eval { $retval = require t::context_0; 1 };
is $@, "";
is $retval, 1;

eval { $retval = [ require t::context_1 ]; 1 };
is $@, "";
is_deeply $retval, ["t::context_1 return"];

eval { $retval = [ require t::context_1 ]; 1 };
is $@, "";
is_deeply $retval, [1];

eval { require t::context_2; 1 };
is $@, "";

eval { require t::context_2; 1 };
is $@, "";

eval { $retval = do "t/context_d0.pl"; 1 };
is $@, "";
is $retval, "t::context_d0 return";

eval { $retval = do "t/context_d0.pl"; 1 };
is $@, "";
is $retval, "t::context_d0 return";

eval { $retval = [ do "t/context_d1.pl" ]; 1 };
is $@, "";
is_deeply $retval, [
	("$]" >= 5.007001 ? ("t::context_d1 return", "in three") : ()),
	"parts",
];

eval { $retval = [ do "t/context_d1.pl" ]; 1 };
is $@, "";
is_deeply $retval, [
	("$]" >= 5.007001 ? ("t::context_d1 return", "in three") : ()),
	"parts",
];

eval { do "t/context_d2.pl"; 1 };
is $@, "";

eval { do "t/context_d2.pl"; 1 };
is $@, "";

sub diecxt() {
	die wantarray ? "ARRAY\n" : defined(wantarray) ? "SCALAR\n" : "VOID\n";
}
eval { $retval = require(diecxt()); 1 };
is $@, "SCALAR\n";
eval { $retval = [ require(diecxt()) ]; 1 };
is $@, "SCALAR\n";
eval { require(diecxt()); 1 };
is $@, "SCALAR\n";
eval { $retval = do(diecxt()); 1 };
is $@, "SCALAR\n";
eval { $retval = [ do(diecxt()) ]; 1 };
is $@, "SCALAR\n";
eval { do(diecxt()); 1 };
is $@, "SCALAR\n";

1;
