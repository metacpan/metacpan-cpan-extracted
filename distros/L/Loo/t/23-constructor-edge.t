use strict;
use warnings;
use Test::More;
use Loo;

# ── new() with no arguments ──────────────────────────────────────
{
    my $dd = Loo->new;
    isa_ok($dd, 'Loo', 'new() with no args');
    is(ref $dd->{values}, 'ARRAY', 'values is arrayref');
    is(scalar @{$dd->{values}}, 0, 'values empty');
    is(ref $dd->{names}, 'ARRAY', 'names is arrayref');
    is(scalar @{$dd->{names}}, 0, 'names empty');
}

# ── new() with empty arrayrefs ───────────────────────────────────
{
    my $dd = Loo->new([], []);
    isa_ok($dd, 'Loo', 'new([], [])');
    is(scalar @{$dd->{values}}, 0, 'empty values');
    is(scalar @{$dd->{names}}, 0, 'empty names');
}

# ── new() with undef arguments ───────────────────────────────────
{
    my $dd = Loo->new(undef, undef);
    isa_ok($dd, 'Loo', 'new(undef, undef)');
    is(ref $dd->{values}, 'ARRAY', 'undef values becomes arrayref');
    is(ref $dd->{names}, 'ARRAY', 'undef names becomes arrayref');
}

# ── new() values only ────────────────────────────────────────────
{
    my $dd = Loo->new([42, 'hello']);
    is(scalar @{$dd->{values}}, 2, 'values count');
    is(scalar @{$dd->{names}}, 0, 'names defaults to empty');
}

# ── Dump from no-arg constructor ──────────────────────────────────
{
    my $dd = Loo->new;
    $dd->{use_colour} = 0;
    my $out = $dd->Dump;
    is($out, '', 'Dump with no values produces empty string');
}

# ── All defaults present ─────────────────────────────────────────
{
    my $dd = Loo->new;
    is($dd->Indent, 2, 'default indent');
    is($dd->Pad, '', 'default pad');
    is($dd->Varname, 'VAR', 'default varname');
    is($dd->Terse, 0, 'default terse');
    is($dd->Purity, 0, 'default purity');
    is($dd->Useqq, 0, 'default useqq');
    is($dd->Quotekeys, 1, 'default quotekeys');
    is($dd->Sortkeys, 0, 'default sortkeys');
    is($dd->Maxdepth, 0, 'default maxdepth');
    is($dd->Maxrecurse, 1000, 'default maxrecurse');
    is($dd->Pair, ' => ', 'default pair');
    is($dd->Trailingcomma, 0, 'default trailingcomma');
    is($dd->Deepcopy, 0, 'default deepcopy');
    is($dd->Freezer, '', 'default freezer');
    is($dd->Toaster, '', 'default toaster');
    is($dd->Bless, 'bless', 'default bless');
    is($dd->Deparse, 0, 'default deparse');
    is($dd->Sparseseen, 0, 'default sparseseen');
    is($dd->Theme, 'default', 'default theme');
    is(ref $dd->Colour, 'HASH', 'colour is hashref');
}

done_testing;
