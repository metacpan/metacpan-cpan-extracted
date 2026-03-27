use strict;
use warnings;
use Test::More;
use Loo qw(ncDump);

# ── Very long string ──────────────────────────────────────────────
{
    my $long = 'x' x 10000;
    my $out = ncDump($long);
    like($out, qr/x{100}/, 'long string: content present');
}

# ── Deeply nested ─────────────────────────────────────────────────
{
    my $deep = 42;
    for (1..50) { $deep = [$deep] }
    my $out = ncDump($deep);
    like($out, qr/42/, 'deeply nested: leaf value present');
}

# ── Empty values list ─────────────────────────────────────────────
{
    my $dd = Loo->new([]);
    $dd->{use_colour} = 0;
    my $out = $dd->Dump;
    is($out, '', 'empty values: empty output');
}

# ── Boolean-like values ───────────────────────────────────────────
{
    is(ncDump(0), "\$VAR1 = 0;\n", 'numeric false: 0');
    is(ncDump(''), "\$VAR1 = '';\n", 'string false: empty');
    is(ncDump(1), "\$VAR1 = 1;\n", 'numeric true: 1');
}

# ── Hash with numeric key ────────────────────────────────────────
{
    my $dd = Loo->new([{42 => 'answer'}]);
    $dd->{use_colour} = 0;
    my $out = $dd->Dump;
    like($out, qr/42/, 'numeric hash key');
    like($out, qr/'answer'/, 'numeric key value');
}

# ── Accessor chaining ────────────────────────────────────────────
{
    my $dd = Loo->new([42]);
    my $ret = $dd->Indent(0)->Terse(1)->Sortkeys(1);
    isa_ok($ret, 'Loo', 'chaining returns self');
    $dd->{use_colour} = 0;
    is($dd->Dump, "42\n", 'chained options work');
}

# ── Multiple values ───────────────────────────────────────────────
{
    my $dd = Loo->new([1, 'two', [3]]);
    $dd->{use_colour} = 0;
    my $out = $dd->Dump;
    like($out, qr/\$VAR1 = 1/, 'multi: VAR1');
    like($out, qr/\$VAR2 = 'two'/, 'multi: VAR2');
    like($out, qr/\$VAR3 = \[/, 'multi: VAR3');
}

done_testing;
