use strict;
use warnings;
use Test::More;
use Loo qw(ncDump);

# ── Blessed hash ──────────────────────────────────────────────────
{
    my $obj = bless {x => 1}, 'Foo::Bar';
    my $out = ncDump($obj);
    like($out, qr/bless/, 'blessed hash: has bless');
    like($out, qr/'Foo::Bar'/, 'blessed hash: class name');
    like($out, qr/'x' => 1/, 'blessed hash: contents');
}

# ── Blessed array ─────────────────────────────────────────────────
{
    my $obj = bless [1, 2], 'My::List';
    my $out = ncDump($obj);
    like($out, qr/bless/, 'blessed array: has bless');
    like($out, qr/'My::List'/, 'blessed array: class name');
    like($out, qr/1/, 'blessed array: contents');
}

# ── Blessed scalar ref ───────────────────────────────────────────
{
    my $val = 42;
    my $obj = bless \$val, 'My::Num';
    my $out = ncDump($obj);
    like($out, qr/bless/, 'blessed scalar ref: has bless');
    like($out, qr/'My::Num'/, 'blessed scalar ref: class name');
}

# ── Nested blessed ────────────────────────────────────────────────
{
    my $inner = bless {val => 1}, 'Inner';
    my $outer = bless {child => $inner}, 'Outer';
    my $dd = Loo->new([$outer]);
    $dd->{use_colour} = 0;
    $dd->Sortkeys(1);
    my $out = $dd->Dump;
    like($out, qr/'Inner'/, 'nested blessed: inner class');
    like($out, qr/'Outer'/, 'nested blessed: outer class');
}

done_testing;
