use strict;
use warnings;

use Test::More;

BEGIN {
	use_ok("LibJIT", ":all");
}

my $ctx = jit_context_create;
my $sig = jit_type_create_signature jit_abi_cdecl, jit_type_int, [ jit_type_int, jit_type_int ], 1;
jit_type_set_names $sig, [ "foo", "bar" ];

is jit_type_get_name($sig, 0), "foo";
is jit_type_get_name($sig, 1), "bar";

done_testing;
