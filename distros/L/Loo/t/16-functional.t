use strict;
use warnings;
use Test::More;
use Loo qw(Dump cDump ncDump);

# ── ncDump ────────────────────────────────────────────────────────
{
    my $out = ncDump(42);
    is($out, "\$VAR1 = 42;\n", 'ncDump scalar');
    unlike($out, qr/\e\[/, 'ncDump: no ANSI');
}

{
    my $out = ncDump([1, 2]);
    like($out, qr/\$VAR1 = \[/, 'ncDump array');
}

{
    my $out = ncDump({a => 1});
    like($out, qr/\$VAR1 = \{/, 'ncDump hash');
}

# ── cDump ─────────────────────────────────────────────────────────
{
    my $out = cDump(42);
    like($out, qr/\e\[/, 'cDump: has ANSI escapes');
    my $stripped = Loo::strip_colour($out);
    is($stripped, "\$VAR1 = 42;\n", 'cDump stripped matches plain');
}

# ── Multiple values via ncDump ────────────────────────────────────
{
    my $out = ncDump(1, 'hello', [3]);
    like($out, qr/\$VAR1 = 1/, 'multi ncDump: first');
    like($out, qr/\$VAR2 = 'hello'/, 'multi ncDump: second');
    like($out, qr/\$VAR3/, 'multi ncDump: third');
}

done_testing;
