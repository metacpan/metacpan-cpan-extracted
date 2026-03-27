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

# ── Single quote escaping ────────────────────────────────────────
{
    my $out = dd("it's");
    like($out, qr/it\\'s/, 'single quote escaped');
}

# ── Backslash escaping ───────────────────────────────────────────
{
    my $out = dd("back\\slash");
    like($out, qr/back\\\\slash/, 'backslash escaped');
}

# ── Useqq: newline ───────────────────────────────────────────────
{
    my $out = dd("line1\nline2", useqq => 1);
    like($out, qr/"line1\\nline2"/, 'useqq: newline escaped');
}

# ── Useqq: tab ───────────────────────────────────────────────────
{
    my $out = dd("col1\tcol2", useqq => 1);
    like($out, qr/"col1\\tcol2"/, 'useqq: tab escaped');
}

# ── Useqq: carriage return ───────────────────────────────────────
{
    my $out = dd("line\r", useqq => 1);
    like($out, qr/\\r/, 'useqq: CR escaped');
}

# ── Non-useqq: newline in single quotes ──────────────────────────
{
    my $out = dd("hello\nworld", useqq => 0);
    like($out, qr/'hello/, 'non-useqq: single quoted');
}

# ── Empty string ──────────────────────────────────────────────────
{
    my $out = dd('');
    is($out, "\$VAR1 = '';\n", 'empty string');
}

# ── String with only spaces ──────────────────────────────────────
{
    my $out = dd('   ');
    is($out, "\$VAR1 = '   ';\n", 'spaces-only string');
}

done_testing;
