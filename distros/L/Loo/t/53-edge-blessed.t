use strict;
use warnings;
use Test::More;
use Loo qw(ncDump);

# ── Blessed code ref ─────────────────────────────────────────────
{
    my $obj = bless sub { 42 }, 'My::Func';
    my $out = ncDump($obj);
    like($out, qr/bless/, 'blessed coderef: has bless');
    like($out, qr/'My::Func'/, 'blessed coderef: class name');
}

# ── Blessed regex ───────────────────────────────────────────────
{
    my $obj = bless qr/test/, 'My::Pat';
    my $out = ncDump($obj);
    like($out, qr/bless/, 'blessed regex: has bless');
    like($out, qr/'My::Pat'/, 'blessed regex: class name');
    like($out, qr/test/, 'blessed regex: pattern content present');
}

# ── Blessed ref to ref ──────────────────────────────────────────
{
    my $inner = [1, 2];
    my $obj = bless \$inner, 'My::Wrapper';
    my $out = ncDump($obj);
    like($out, qr/bless/, 'blessed ref-to-ref: has bless');
    like($out, qr/'My::Wrapper'/, 'blessed ref-to-ref: class name');
}

# ── Deeply nested blessed objects ───────────────────────────────
{
    my $l3 = bless {val => 'deep'}, 'L3';
    my $l2 = bless {child => $l3}, 'L2';
    my $l1 = bless {child => $l2}, 'L1';
    my $dd = Loo->new([$l1]);
    $dd->{use_colour} = 0;
    $dd->Sortkeys(1);
    my $out = $dd->Dump;
    like($out, qr/'L1'/, 'deep blessed: L1');
    like($out, qr/'L2'/, 'deep blessed: L2');
    like($out, qr/'L3'/, 'deep blessed: L3');
    like($out, qr/'deep'/, 'deep blessed: leaf value');
}

# ── Blessed empty hash ──────────────────────────────────────────
{
    my $obj = bless {}, 'Empty::Obj';
    my $out = ncDump($obj);
    like($out, qr/bless/, 'blessed empty hash: has bless');
    like($out, qr/'Empty::Obj'/, 'blessed empty hash: class name');
}

# ── Blessed empty array ─────────────────────────────────────────
{
    my $obj = bless [], 'Empty::List';
    my $out = ncDump($obj);
    like($out, qr/bless/, 'blessed empty array: has bless');
    like($out, qr/'Empty::List'/, 'blessed empty array: class name');
}

# ── Custom bless function name ──────────────────────────────────
{
    my $obj = bless {x => 1}, 'Foo';
    my $dd = Loo->new([$obj]);
    $dd->{use_colour} = 0;
    $dd->Bless('construct');
    my $out = $dd->Dump;
    like($out, qr/construct/, 'custom bless: uses custom function name');
    unlike($out, qr/\bbless\b/, 'custom bless: default bless not used');
}

# ── Blessed with circular ref ───────────────────────────────────
{
    my $obj = bless {name => 'self_ref'}, 'Circ::Obj';
    $obj->{self} = $obj;
    my $dd = Loo->new([$obj]);
    $dd->{use_colour} = 0;
    $dd->Sortkeys(1);
    my $out = $dd->Dump;
    like($out, qr/'Circ::Obj'/, 'blessed circular: class');
    like($out, qr/\$VAR1/, 'blessed circular: back-ref');
}

done_testing;
