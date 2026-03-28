use strict;
use warnings;
use Test::More;
use Loo;

# ── Deepcopy: modifying original after dump doesn't affect output ─
{
    my $data = {a => [1, 2, 3]};
    my $dd = Loo->new([$data]);
    $dd->{use_colour} = 0;
    $dd->Deepcopy(1)->Sortkeys(1);
    my $out = $dd->Dump;
    like($out, qr/'a' => \[/, 'deepcopy: data present');
    like($out, qr/1/, 'deepcopy: array values present');
}

# ── Deepcopy with circular ref ──────────────────────────────────
{
    my %h = (x => 1);
    $h{self} = \%h;
    my $dd = Loo->new([\%h]);
    $dd->{use_colour} = 0;
    $dd->Deepcopy(1)->Sortkeys(1);
    my $out = $dd->Dump;
    like($out, qr/'x' => 1/, 'deepcopy circular: data present');
}

# ── Sparseseen: only repeated refs tracked ──────────────────────
{
    my $shared = [42];
    my $dd = Loo->new([[$shared, $shared]]);
    $dd->{use_colour} = 0;
    $dd->Sparseseen(1);
    my $out = $dd->Dump;
    like($out, qr/42/, 'sparseseen: shared ref value present');
}

# ── Sparseseen with unique refs (no back-refs needed) ───────────
{
    my $a = [1];
    my $b = [2];
    my $dd = Loo->new([[$a, $b]]);
    $dd->{use_colour} = 0;
    $dd->Sparseseen(1);
    my $out = $dd->Dump;
    like($out, qr/1/, 'sparseseen unique: first ref');
    like($out, qr/2/, 'sparseseen unique: second ref');
    unlike($out, qr/\$VAR1->[^;]/, 'sparseseen unique: no internal back-refs');
}

# ── Deepcopy off (default) ──────────────────────────────────────
{
    my $data = [1, 2];
    my $dd = Loo->new([$data]);
    $dd->{use_colour} = 0;
    $dd->Deepcopy(0);
    my $out = $dd->Dump;
    like($out, qr/1/, 'deepcopy off: data present');
}

done_testing;
