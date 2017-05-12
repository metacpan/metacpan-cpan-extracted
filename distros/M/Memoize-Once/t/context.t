use warnings;
use strict;

use Test::More tests => 6;

BEGIN { use_ok "Memoize::Once", qw(once); }

our $ctxt;
sub save_context() {
	$ctxt = !defined(wantarray) ? "VOID" : wantarray ? "LIST" : "SCALAR";
	return 123, 456;
}

$ctxt = undef;
is scalar(once(save_context())), 456;
is $ctxt, "SCALAR";

$ctxt = undef;
is_deeply [ "a", once(save_context()), "b" ], [ "a", 456, "b" ];
is $ctxt, "SCALAR";

$ctxt = undef;
{ no warnings "void"; once(save_context()); }
is $ctxt, "SCALAR";

1;
