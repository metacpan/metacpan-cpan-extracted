use strict;
use warnings;
use Test::More;
use Loo qw(ncDump);

# ── Circular array ref ────────────────────────────────────────────
{
    my @a = (1, 2);
    push @a, \@a;
    my $out = ncDump(\@a);
    like($out, qr/\$VAR1/, 'circular array: has $VAR1 back-ref');
    like($out, qr/1/, 'circular array: first element');
    like($out, qr/2/, 'circular array: second element');
}

# ── Circular hash ref ────────────────────────────────────────────
{
    my %h = (a => 1);
    $h{self} = \%h;
    my $dd = Loo->new([\%h]);
    $dd->{use_colour} = 0;
    $dd->Sortkeys(1);
    my $out = $dd->Dump;
    like($out, qr/'a' => 1/, 'circular hash: data present');
    like($out, qr/'self' => \$VAR1/, 'circular hash: back-ref');
}

# ── Shared reference (same ref seen twice) ────────────────────────
{
    my $shared = [42];
    my $out = ncDump([$shared, $shared]);
    like($out, qr/42/, 'shared ref: value present');
    like($out, qr/\$VAR1/, 'shared ref: back-ref to shared');
}

# ── Deeply circular ───────────────────────────────────────────────
{
    my $a = {};
    my $b = { parent => $a };
    $a->{child} = $b;
    my $dd = Loo->new([$a]);
    $dd->{use_colour} = 0;
    $dd->Sortkeys(1);
    my $out = $dd->Dump;
    like($out, qr/'child'/, 'deep circular: child key');
    like($out, qr/'parent'/, 'deep circular: parent key');
    like($out, qr/\$VAR1/, 'deep circular: back-ref');
}

done_testing;
