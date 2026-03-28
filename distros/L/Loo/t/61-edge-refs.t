use strict;
use warnings;
use Test::More;
use Loo qw(ncDump);

# ── Ref to ref to ref ───────────────────────────────────────────
{
    my $out = ncDump(\\\42);
    like($out, qr/\\\\\\42/, 'triple ref: three backslashes');
}

# ── Ref to empty string ────────────────────────────────────────
{
    my $s = '';
    my $out = ncDump(\$s);
    is($out, "\$VAR1 = \\'';\n", 'ref to empty string');
}

# ── Ref to undef ────────────────────────────────────────────────
{
    my $out = ncDump(\undef);
    is($out, "\$VAR1 = \\undef;\n", 'ref to undef');
}

# ── Ref to array ref ───────────────────────────────────────────
{
    my $aref = [1, 2];
    my $out = ncDump(\$aref);
    like($out, qr/\\/, 'ref to arrayref: has backslash');
    like($out, qr/1/, 'ref to arrayref: value present');
}

# ── Ref to hash ref ────────────────────────────────────────────
{
    my $href = {a => 1};
    my $out = ncDump(\$href);
    like($out, qr/\\/, 'ref to hashref: has backslash');
    like($out, qr/'a'/, 'ref to hashref: key present');
}

# ── Ref to code ref ────────────────────────────────────────────
{
    my $cref = sub { 42 };
    my $out = ncDump(\$cref);
    like($out, qr/\\/, 'ref to coderef: has backslash');
    like($out, qr/sub|DUMMY/, 'ref to coderef: sub or DUMMY present');
}

# ── Ref to regex ────────────────────────────────────────────────
{
    my $rx = qr/test/i;
    my $out = ncDump(\$rx);
    like($out, qr/\\/, 'ref to regex: has backslash');
    like($out, qr/qr\/|test/, 'ref to regex: pattern present');
}

# ── Scalar ref in array ────────────────────────────────────────
{
    my $out = ncDump([\1, \2, \3]);
    like($out, qr/\\1/, 'scalar ref in array: first');
    like($out, qr/\\2/, 'scalar ref in array: second');
    like($out, qr/\\3/, 'scalar ref in array: third');
}

# ── Scalar ref in hash ─────────────────────────────────────────
{
    my $dd = Loo->new([{r => \42}]);
    $dd->{use_colour} = 0;
    my $out = $dd->Dump;
    like($out, qr/'r' => \\42/, 'scalar ref in hash value');
}

# ── Negative number ref ────────────────────────────────────────
{
    my $out = ncDump(\-5);
    like($out, qr/\\-5/, 'ref to negative number');
}

# ── Float ref ──────────────────────────────────────────────────
{
    my $out = ncDump(\3.14);
    like($out, qr/\\3\.14/, 'ref to float');
}

done_testing;
