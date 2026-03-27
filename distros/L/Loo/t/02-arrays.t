use strict;
use warnings;
use Test::More;
use Loo qw(ncDump);

# ── Empty array ───────────────────────────────────────────────────
is(ncDump([]), "\$VAR1 = [];\n", 'empty array ref');

# ── Simple arrays ─────────────────────────────────────────────────
is(ncDump([1, 2, 3]), "\$VAR1 = [\n  1,\n  2,\n  3\n];\n", 'integer array');

is(ncDump(['a', 'b']), "\$VAR1 = [\n  'a',\n  'b'\n];\n", 'string array');

# ── Mixed array ──────────────────────────────────────────────────
is(ncDump([1, 'two', 3]), "\$VAR1 = [\n  1,\n  'two',\n  3\n];\n", 'mixed array');

# ── Single element ────────────────────────────────────────────────
is(ncDump([42]), "\$VAR1 = [\n  42\n];\n", 'single element array');

# ── Nested arrays ─────────────────────────────────────────────────
my $expected = "\$VAR1 = [\n  [\n    1,\n    2\n  ],\n  [\n    3,\n    4\n  ]\n];\n";
is(ncDump([[1,2],[3,4]]), $expected, 'nested arrays');

# ── Array with undef ──────────────────────────────────────────────
is(ncDump([1, undef, 3]), "\$VAR1 = [\n  1,\n  undef,\n  3\n];\n", 'array with undef');

done_testing;
