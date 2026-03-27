use strict;
use warnings;
use Test::More;
use Loo;

# ── Purity with circular hash ref ────────────────────────────────
{
    my %h = (a => 1);
    $h{self} = \%h;
    my $dd = Loo->new([\%h]);
    $dd->{use_colour} = 0;
    $dd->Purity(1)->Sortkeys(1);
    my $out = $dd->Dump;
    like($out, qr/\$VAR1/, 'purity circular hash: VAR1 present');
    like($out, qr/'a' => 1/, 'purity circular hash: data present');
}

# ── Purity with circular array ref ───────────────────────────────
{
    my @a = (1, 2);
    push @a, \@a;
    my $dd = Loo->new([\@a]);
    $dd->{use_colour} = 0;
    $dd->Purity(1);
    my $out = $dd->Dump;
    like($out, qr/\$VAR1/, 'purity circular array: VAR1 present');
}

# ── Purity off: still works for circular ─────────────────────────
{
    my %h = (a => 1);
    $h{self} = \%h;
    my $dd = Loo->new([\%h]);
    $dd->{use_colour} = 0;
    $dd->Purity(0)->Sortkeys(1);
    my $out = $dd->Dump;
    like($out, qr/\$VAR1/, 'purity off: circular ref still noted');
}

# ── Purity with blessed circular ─────────────────────────────────
{
    my $obj = bless {}, 'Circ';
    $obj->{self} = $obj;
    my $dd = Loo->new([$obj]);
    $dd->{use_colour} = 0;
    $dd->Purity(1)->Sortkeys(1);
    my $out = $dd->Dump;
    like($out, qr/bless/, 'purity blessed circular: bless present');
    like($out, qr/'Circ'/, 'purity blessed circular: class name');
    like($out, qr/\$VAR1/, 'purity blessed circular: back-ref');
}

done_testing;
