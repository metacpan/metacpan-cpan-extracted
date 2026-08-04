use strict;
use warnings;
use Test::More tests => 3;
use JSON::Schema::Fast;

# The arena self-test (Fast.xs): interns two identical + one distinct string,
# then forces a realloc with a large alloc and confirms the first string's
# offset still resolves to the right bytes after the grow.
my $r = JSON::Schema::Fast::_arena_selftest();
my ($dedup, $bytes) = split /:/, $r;

is($dedup, 1, 'arena interns dedup identical strings and grow the index');
is($bytes, 1, 'interned bytes survive a realloc (offset-based, no fixups)');

# Compiled lifecycle: compile() builds the arena IR, blesses a pointer, and
# DESTROY frees it (leak-checked separately).
{
    my $c = JSON::Schema::Fast->compile({ type => 'object' });
    isa_ok($c, 'JSON::Schema::Fast::Compiled', 'compiled object');
}   # DESTROY fires here
