use strict;
use warnings;
use Test::More;
use Loo;

sub dd {
    my ($data, %opts) = @_;
    my $dd = Loo->new([$data]);
    $dd->{use_colour} = 0;
    while (my ($k, $v) = each %opts) {
        my $method = ucfirst($k);
        $dd->$method($v) if $dd->can($method);
    }
    return $dd->Dump;
}

# ── Maxdepth = 1: only top-level ─────────────────────────────────
{
    my $out = dd({a => {b => 1}}, maxdepth => 1, sortkeys => 1);
    like($out, qr/'a'/, 'maxdepth 1: top key present');
    like($out, qr/DUMMY/, 'maxdepth 1: nested truncated');
}

# ── Maxdepth = 2: two levels ─────────────────────────────────────
{
    my $out = dd({a => {b => {c => 1}}}, maxdepth => 2, sortkeys => 1);
    like($out, qr/'b'/, 'maxdepth 2: second level present');
    like($out, qr/DUMMY/, 'maxdepth 2: third level truncated');
}

# ── Maxdepth = 0: unlimited ──────────────────────────────────────
{
    my $deep = {a => {b => {c => {d => 1}}}};
    my $out = dd($deep, maxdepth => 0, sortkeys => 1);
    like($out, qr/'d' => 1/, 'maxdepth 0: all levels');
    unlike($out, qr/DUMMY/, 'maxdepth 0: no truncation');
}

# ── Maxdepth with array nesting ──────────────────────────────────
{
    my $out = dd([[['deep']]], maxdepth => 2);
    like($out, qr/DUMMY/, 'maxdepth 2 array: third level truncated');
}

# ── Maxrecurse: set low and hit limit ────────────────────────────
{
    # Build a structure that recurses deeply
    my $depth = 0;
    my $structure = {};
    my $current = $structure;
    for (1..20) {
        my $next = {};
        $current->{n} = $next;
        $current = $next;
    }

    my $dd = Loo->new([$structure]);
    $dd->{use_colour} = 0;
    $dd->Maxrecurse(5);
    eval { $dd->Dump };
    like($@, qr/Recursion limit/, 'maxrecurse 5: croak on deep structure');
}

# ── Maxrecurse: default 1000 is high enough ──────────────────────
{
    my $dd = Loo->new([{a => {b => {c => 1}}}]);
    $dd->{use_colour} = 0;
    my $out;
    eval { $out = $dd->Dump };
    is($@, '', 'default maxrecurse: no croak on 3 levels');
    like($out, qr/'c' => 1/, 'default maxrecurse: full output');
}

# ── Maxrecurse accessor ──────────────────────────────────────────
{
    my $dd = Loo->new;
    is($dd->Maxrecurse, 1000, 'maxrecurse getter default');
    $dd->Maxrecurse(50);
    is($dd->Maxrecurse, 50, 'maxrecurse set to 50');
}

done_testing;
