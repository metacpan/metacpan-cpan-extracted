use strict;
use warnings;
use Test::More;
use Loo qw(ncDump);

# ── Infinity ─────────────────────────────────────────────────────
{
    my $inf = 9**9**9;
    my $out = ncDump($inf);
    like($out, qr/'Inf'/, 'positive infinity');
}

{
    my $ninf = -(9**9**9);
    my $out = ncDump($ninf);
    like($out, qr/'-Inf'/, 'negative infinity');
}

# ── NaN ──────────────────────────────────────────────────────────
{
    my $nan = 9**9**9 - 9**9**9;
    my $out = ncDump($nan);
    like($out, qr/'NaN'/, 'NaN value');
}

# ── Very small float ────────────────────────────────────────────
{
    my $out = ncDump(0.000001);
    like($out, qr/\d/, 'very small float has digits');
}

# ── Negative zero ───────────────────────────────────────────────
{
    my $nz = -0.0;
    my $out = ncDump($nz);
    like($out, qr/0/, 'negative zero renders');
}

# ── Very large integer (may render as scientific notation) ──────
{
    my $out = ncDump(2**53);
    like($out, qr/\d/, 'very large integer has digits');
}

# ── Scientific notation string ──────────────────────────────────
{
    my $out = ncDump("1e10");
    like($out, qr/1e10/, 'scientific notation string');
}

# ── NaN and Inf in data structures ──────────────────────────────
{
    my $inf = 9**9**9;
    my $nan = $inf - $inf;
    my $out = ncDump([$inf, $nan, -$inf]);
    like($out, qr/'Inf'/, 'Inf in array');
    like($out, qr/'NaN'/, 'NaN in array');
    like($out, qr/'-Inf'/, '-Inf in array');
}

{
    my $dd = Loo->new([{val => 9**9**9}]);
    $dd->{use_colour} = 0;
    my $out = $dd->Dump;
    like($out, qr/'Inf'/, 'Inf in hash value');
}

done_testing;
