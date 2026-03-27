use strict;
use warnings;
use Test::More;
use Loo qw(ncDump);

# ── Standalone undef ──────────────────────────────────────────────
is(ncDump(undef), "\$VAR1 = undef;\n", 'standalone undef');

# ── Undef in array ────────────────────────────────────────────────
my $out = ncDump([undef]);
like($out, qr/undef/, 'undef in array');

# ── Undef in hash ─────────────────────────────────────────────────
$out = ncDump({a => undef});
like($out, qr/'a' => undef/, 'undef in hash');

# ── Multiple undefs ───────────────────────────────────────────────
$out = ncDump([undef, undef]);
my @undefs = ($out =~ /undef/g);
is(scalar @undefs, 2, 'two undefs in array');

# ── Ref to undef ──────────────────────────────────────────────────
$out = ncDump(\undef);
like($out, qr/\\undef/, 'ref to undef');

# ── Undef alongside values ───────────────────────────────────────
$out = ncDump([1, undef, 'hello']);
like($out, qr/1/, 'mixed with undef: integer present');
like($out, qr/undef/, 'mixed with undef: undef present');
like($out, qr/'hello'/, 'mixed with undef: string present');

done_testing;
