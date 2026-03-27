use strict;
use warnings;
use Test::More;
use Loo;

# ── Named variables ───────────────────────────────────────────────
{
    my $dd = Loo->new([42, 'hello'], ['x', 'y']);
    $dd->{use_colour} = 0;
    my $out = $dd->Dump;
    like($out, qr/\$x = 42/, 'named: $x = 42');
    like($out, qr/\$y = 'hello'/, 'named: $y = hello');
}

# ── Single name ───────────────────────────────────────────────────
{
    my $dd = Loo->new([[1, 2]], ['data']);
    $dd->{use_colour} = 0;
    my $out = $dd->Dump;
    like($out, qr/\$data = \[/, 'single name: $data');
}

# ── Partial names (fewer names than values) ───────────────────────
{
    my $dd = Loo->new([1, 2, 3], ['a']);
    $dd->{use_colour} = 0;
    my $out = $dd->Dump;
    like($out, qr/\$a = 1/, 'partial: first named');
    like($out, qr/\$VAR2 = 2/, 'partial: second auto-named');
    like($out, qr/\$VAR3 = 3/, 'partial: third auto-named');
}

# ── No names (default VAR) ───────────────────────────────────────
{
    my $dd = Loo->new([1, 2]);
    $dd->{use_colour} = 0;
    my $out = $dd->Dump;
    like($out, qr/\$VAR1 = 1/, 'default: $VAR1');
    like($out, qr/\$VAR2 = 2/, 'default: $VAR2');
}

# ── Empty names array ────────────────────────────────────────────
{
    my $dd = Loo->new([42], []);
    $dd->{use_colour} = 0;
    my $out = $dd->Dump;
    like($out, qr/\$VAR1 = 42/, 'empty names: falls back to VAR');
}

done_testing;
