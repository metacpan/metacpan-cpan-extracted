use strict;
use warnings;
use Test::More;
use Loo qw(ncDump);

# ── Scalar ref ────────────────────────────────────────────────────
is(ncDump(\42), "\$VAR1 = \\42;\n", 'scalar ref');
is(ncDump(\"hello"), "\$VAR1 = \\'hello';\n", 'string ref');

# ── Ref to ref ────────────────────────────────────────────────────
is(ncDump(\\42), "\$VAR1 = \\\\42;\n", 'ref to ref');

# ── Ref to undef ──────────────────────────────────────────────────
is(ncDump(\undef), "\$VAR1 = \\undef;\n", 'ref to undef');

# ── Array ref ─────────────────────────────────────────────────────
like(ncDump(\[1,2]), qr/\\\[/, 'ref to array ref');

# ── Hash ref ──────────────────────────────────────────────────────
like(ncDump(\{a=>1}), qr/\\\{/, 'ref to hash ref');

done_testing;
