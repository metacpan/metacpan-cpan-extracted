use strict;
use warnings;

use Test::More;
use Test::Fatal;

use GCCJIT qw/:all/;

require_ok("GCCJIT::Context");

my $ctx = GCCJIT::Context->acquire;
can_ok($ctx, qw/get_type new_child_context/);

my $int = $ctx->get_type(GCC_JIT_TYPE_INT);
can_ok($int, qw/as_object/);

my $obj = $int->as_object;
can_ok($obj, qw/get_context get_debug_string/);
is $obj->get_context, $ctx, "derived child's get_context still returns correct perl object";
is $obj->get_debug_string, "int", "get_debug_string works";

my $const = $int->get_const;
is $const->as_object->get_debug_string(), "const int", "const ok";

my $volatile = $const->get_volatile;
is $volatile->as_object->get_debug_string(), "volatile const int", "volatile ok";

my $sub = $ctx->new_child_context();
can_ok($sub, qw/get_type new_child_context/);

$ctx = undef;

is exception { $sub->get_type(GCC_JIT_TYPE_INT) }, undef, "subcontext is alive when parent is out of scope";
is exception { $volatile->as_object }, undef, "subcontext keeps parent's objects alive";

$sub = undef;

like exception { $volatile->as_object }, qr/this type is no longer usable/, "when all contexts are destroyed, objects become invalid";

done_testing;
