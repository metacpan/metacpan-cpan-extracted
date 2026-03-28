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

# ── Useqq: dollar sign escaped ──────────────────────────────────
{
    my $out = dd('$foo', useqq => 1);
    like($out, qr/\\\$foo/, 'useqq: dollar sign escaped');
}

# ── Useqq: at sign escaped ─────────────────────────────────────
{
    my $out = dd('@bar', useqq => 1);
    like($out, qr/\\\@bar/, 'useqq: at sign escaped');
}

# ── Useqq: double quote escaped ────────────────────────────────
{
    my $out = dd('say "hi"', useqq => 1);
    like($out, qr/\\"hi\\"/, 'useqq: double quotes escaped');
}

# ── Useqq: backslash escaped ───────────────────────────────────
{
    my $out = dd('C:\\path\\file', useqq => 1);
    like($out, qr/\\\\path\\\\file/, 'useqq: backslashes escaped');
}

# ── Useqq: form feed ───────────────────────────────────────────
{
    my $out = dd("page\fbreak", useqq => 1);
    like($out, qr/\\f/, 'useqq: form feed escaped');
}

# ── Useqq: bell ────────────────────────────────────────────────
{
    my $out = dd("ding\a", useqq => 1);
    like($out, qr/\\a/, 'useqq: bell escaped');
}

# ── Useqq: escape char ────────────────────────────────────────
{
    my $out = dd("esc\033", useqq => 1);
    like($out, qr/\\e/, 'useqq: escape char');
}

# ── Useqq: backspace ──────────────────────────────────────────
{
    my $out = dd("back\b", useqq => 1);
    like($out, qr/\\b/, 'useqq: backspace escaped');
}

# ── Useqq: control char (^A) ──────────────────────────────────
{
    my $out = dd("ctrl\x01x", useqq => 1);
    like($out, qr/\\x01/, 'useqq: control char \\x01');
}

# ── Useqq: DEL char ───────────────────────────────────────────
{
    my $out = dd("del\x7Fx", useqq => 1);
    like($out, qr/\\x7f/i, 'useqq: DEL char \\x7f');
}

# ── Single quote mode: only \ and ' escaped ────────────────────
{
    my $out = dd("hello\nworld\t!", useqq => 0);
    # In single-quote mode, \n and \t are literal bytes, not escaped
    like($out, qr/'hello/, 'single quote: starts with quote');
    unlike($out, qr/\\n/, 'single quote: no \\n escape');
}

# ── String with all special chars ──────────────────────────────
{
    my $out = dd("\\\'\"\$\@", useqq => 0);
    like($out, qr/\\\\/, 'single quote: backslash escaped');
    like($out, qr/\\'/, 'single quote: single quote escaped');
}

# ── Hash key with single quotes ────────────────────────────────
{
    my $dd = Loo->new([{"it's" => 1}]);
    $dd->{use_colour} = 0;
    my $out = $dd->Dump;
    like($out, qr/it\\'s/, 'hash key with embedded single quote');
}

# ── String containing only backslash ───────────────────────────
{
    my $out = dd("\\");
    like($out, qr/\\\\/, 'string with just backslash');
}

# ── Empty string in useqq mode ─────────────────────────────────
{
    my $out = dd('', useqq => 1);
    like($out, qr/""/, 'useqq: empty string as ""');
}

done_testing;
