use strict;
use warnings;
use Test::More tests => 5;
use JSON::Schema::Fast;

# The arena self-test (Fast.xs): interns two identical + one distinct string,
# then forces a realloc with a large alloc and confirms the first string's
# offset still resolves to the right bytes after the grow.
my $r = JSON::Schema::Fast::_arena_selftest();
my ($dedup, $bytes, $base_align, $nodealign) = split /:/, $r;

is($dedup, 1, 'arena interns dedup identical strings and grow the index');
is($bytes, 1, 'interned bytes survive a realloc (offset-based, no fixups)');
is($base_align, 1, "arena base is aligned for a node (alignof = $nodealign)");

# Regression guard for the 0.05 crash. jsf_node_t holds five NVs, and on a perl
# built -Duselongdouble or -Dusequadmath an NV is a 16-byte-aligned type; the
# parser was asking the arena for a hardcoded alignment of 8, so every node sat
# on an odd 8-byte boundary. With NV = __float128 that faults the SSE load gcc
# emits for it. Invisible on an ordinary double-NV build, where 8 is all a node
# needs - so this has to check the nodes the PARSER laid down against
# alignof(jsf_node_t), not an allocation the test makes for itself.
{
    my $schema = {
        type       => 'object',
        properties => { a => { type => 'integer', minimum => 1 },
                        b => { type => 'string' } },
        items      => { type => 'number', maximum => 10 },
    };
    my ($ok, $alignof, $nodes) =
        split /:/, JSON::Schema::Fast::_node_align_selftest($schema);
    is($ok, 1, "parser-allocated nodes honour alignof(jsf_node_t) = $alignof "
             . "($nodes checked)");
}

# Compiled lifecycle: compile() builds the arena IR, blesses a pointer, and
# DESTROY frees it (leak-checked separately).
{
    my $c = JSON::Schema::Fast->compile({ type => 'object' });
    isa_ok($c, 'JSON::Schema::Fast::Compiled', 'compiled object');
}   # DESTROY fires here
