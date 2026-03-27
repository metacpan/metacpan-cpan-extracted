use strict;
use warnings;
use Test::More;
use Loo qw(ncDump);

# ── Integers ──────────────────────────────────────────────────────
is(ncDump(42),  "\$VAR1 = 42;\n",   'positive integer');
is(ncDump(0),   "\$VAR1 = 0;\n",    'zero');
is(ncDump(-7),  "\$VAR1 = -7;\n",   'negative integer');
is(ncDump(100), "\$VAR1 = 100;\n",  'hundred');

# ── Floats ────────────────────────────────────────────────────────
like(ncDump(3.14), qr/\$VAR1 = 3\.14/, 'float 3.14');
like(ncDump(-2.5), qr/\$VAR1 = -2\.5/, 'negative float');

# ── Strings ───────────────────────────────────────────────────────
is(ncDump('hello'),     "\$VAR1 = 'hello';\n",     'simple string');
is(ncDump(''),          "\$VAR1 = '';\n",           'empty string');
is(ncDump('0'),         "\$VAR1 = '0';\n",          'string zero');
is(ncDump('with space'),"\$VAR1 = 'with space';\n", 'string with space');

# ── Large integers ────────────────────────────────────────────────
is(ncDump(999999999), "\$VAR1 = 999999999;\n", 'large integer');

done_testing;
