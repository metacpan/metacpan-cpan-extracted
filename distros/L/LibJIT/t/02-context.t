use strict;
use warnings;

use Test::More;

BEGIN {
    use_ok("LibJIT", ":all");
}

my $ctx = jit_context_create;
isa_ok $ctx, "jit_context_t";

done_testing;
