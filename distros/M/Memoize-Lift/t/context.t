use warnings;
use strict;

use Test::More tests => 6;

BEGIN { use_ok "Memoize::Lift", qw(lift); }

our $ctxt;
sub save_context() {
	$ctxt = !defined(wantarray) ? "VOID" : wantarray ? "LIST" : "SCALAR";
	return 123, 456;
}

BEGIN { $ctxt = undef; }
is scalar(lift(save_context())), 456;
BEGIN { is $ctxt, "SCALAR"; }

BEGIN { $ctxt = undef; }
is_deeply [ "a", lift(save_context()), "b" ], [ "a", 456, "b" ];
BEGIN { is $ctxt, "SCALAR"; }

BEGIN { $ctxt = undef; }
{ no warnings "void"; lift(save_context()); }
BEGIN { is $ctxt, "SCALAR"; }

1;
