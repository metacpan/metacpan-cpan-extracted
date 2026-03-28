use strict;
use warnings;
use Test::More;
use Loo qw(ncDump);

# ── Triple circular (A→B→C→A) ──────────────────────────────────
{
    my $a = {name => 'a'};
    my $b = {name => 'b'};
    my $c = {name => 'c'};
    $a->{next} = $b;
    $b->{next} = $c;
    $c->{next} = $a;
    my $dd = Loo->new([$a]);
    $dd->{use_colour} = 0;
    $dd->Sortkeys(1);
    my $out = $dd->Dump;
    like($out, qr/'a'/, 'triple circular: node a');
    like($out, qr/'b'/, 'triple circular: node b');
    like($out, qr/'c'/, 'triple circular: node c');
    like($out, qr/\$VAR1/, 'triple circular: back-ref');
}

# ── Array self-ref at multiple positions ────────────────────────
{
    my @a = (1, 2, 3);
    push @a, \@a, \@a;
    my $out = ncDump(\@a);
    like($out, qr/1/, 'multi self-ref array: data present');
    like($out, qr/\$VAR1/, 'multi self-ref array: back-ref');
}

# ── Shared ref appearing in multiple containers ─────────────────
{
    my $shared = {key => 'shared'};
    my $out = ncDump({a => $shared, b => $shared});
    like($out, qr/'shared'/, 'shared ref in hash: value present');
    like($out, qr/\$VAR1/, 'shared ref in hash: back-ref for second occurrence');
}

# ── Circular blessed array ──────────────────────────────────────
{
    my $obj = bless [1, 2], 'Circ::Arr';
    push @$obj, $obj;
    my $out = ncDump($obj);
    like($out, qr/'Circ::Arr'/, 'circular blessed array: class');
    like($out, qr/\$VAR1/, 'circular blessed array: back-ref');
}

# ── Hash where value is ref to the hash itself ──────────────────
{
    my %h;
    $h{self} = \%h;
    $h{data} = 42;
    my $dd = Loo->new([\%h]);
    $dd->{use_colour} = 0;
    $dd->Sortkeys(1);
    my $out = $dd->Dump;
    like($out, qr/42/, 'hash self-ref: data present');
    like($out, qr/'self' => \$VAR1/, 'hash self-ref: back-ref');
}

# ── Purity mode with circular ───────────────────────────────────
{
    my %h = (x => 1);
    $h{me} = \%h;
    my $dd = Loo->new([\%h]);
    $dd->{use_colour} = 0;
    $dd->Purity(1)->Sortkeys(1);
    my $out = $dd->Dump;
    like($out, qr/\$VAR1/, 'purity circular: VAR1 present');
    like($out, qr/'x' => 1/, 'purity circular: data present');
}

done_testing;
