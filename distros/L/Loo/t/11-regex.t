use strict;
use warnings;
use Test::More;
use Loo qw(ncDump);

# ── Simple regex ──────────────────────────────────────────────────
my $out = ncDump(qr/hello/);
like($out, qr|qr/|, 'simple regex: has qr/');
like($out, qr/hello/, 'simple regex: pattern present');

# ── Regex with flags ──────────────────────────────────────────────
$out = ncDump(qr/^test$/i);
like($out, qr|qr/|, 'regex with flags: has qr/');
like($out, qr/test/, 'regex with flags: pattern present');

# ── Regex with special chars ─────────────────────────────────────
$out = ncDump(qr/\d+\s+\w+/);
like($out, qr|qr/|, 'regex with metachar: has qr/');
like($out, qr/\\d/, 'regex with metachar: \\d present');

# ── Regex in array ────────────────────────────────────────────────
$out = ncDump([qr/a/, qr/b/]);
like($out, qr|qr/|, 'regex in array: has qr/');
like($out, qr/\ba\b/, 'regex in array: first pattern');
like($out, qr/\bb\b/, 'regex in array: second pattern');

# ── Regex in hash ─────────────────────────────────────────────────
{
    my $dd = Loo->new([{pat => qr/test/}]);
    $dd->{use_colour} = 0;
    $out = $dd->Dump;
    like($out, qr/pat/, 'regex in hash: key present');
    like($out, qr|qr/|, 'regex in hash: has qr/');
    like($out, qr/test/, 'regex in hash: pattern present');
}

done_testing;
