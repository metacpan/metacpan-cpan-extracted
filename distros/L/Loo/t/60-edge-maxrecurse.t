use strict;
use warnings;
use Test::More;
use Loo;

# ── Maxrecurse with deeply nested structure (exceeds limit → dies) ─
{
    my $deep = 'leaf';
    for (1..100) { $deep = [$deep] }
    my $dd = Loo->new([$deep]);
    $dd->{use_colour} = 0;
    $dd->Maxrecurse(50);
    eval { $dd->Dump };
    like($@, qr/[Rr]ecursion/, 'maxrecurse 50 exceeded: dies with recursion error');
}

# ── Maxrecurse with shallow structure (within limit) ────────────
{
    my $deep = 42;
    for (1..5) { $deep = [$deep] }
    my $dd = Loo->new([$deep]);
    $dd->{use_colour} = 0;
    $dd->Maxrecurse(50);
    my $out = $dd->Dump;
    like($out, qr/42/, 'maxrecurse 50 with shallow: reaches leaf');
}

# ── Maxrecurse default (1000) handles deep structures ──────────
{
    my $deep = 42;
    for (1..20) { $deep = [$deep] }
    my $dd = Loo->new([$deep]);
    $dd->{use_colour} = 0;
    # Default maxrecurse is 1000, so 20 levels is fine
    my $out = $dd->Dump;
    like($out, qr/42/, 'default maxrecurse: reaches leaf at depth 20');
}

# ── Maxdepth truncates with DUMMY ──────────────────────────────
{
    my $deep = {a => {b => {c => {d => 1}}}};
    my $dd = Loo->new([$deep]);
    $dd->{use_colour} = 0;
    $dd->Maxdepth(2)->Sortkeys(1);
    my $out = $dd->Dump;
    like($out, qr/'b'/, 'maxdepth 2: level 2 present');
    like($out, qr/DUMMY/, 'maxdepth 2: truncated');
}

# ── Maxdepth 1 with array ──────────────────────────────────────
{
    my $dd = Loo->new([[1, [2, [3]]]]);
    $dd->{use_colour} = 0;
    $dd->Maxdepth(1);
    my $out = $dd->Dump;
    like($out, qr/1/, 'maxdepth 1 array: level 1 present');
    like($out, qr/DUMMY/, 'maxdepth 1 array: truncated');
}

done_testing;
