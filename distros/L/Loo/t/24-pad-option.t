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

# ── Pad prepended to each line ────────────────────────────────────
{
    my $out = dd([1, 2, 3], pad => '>> ');
    my @lines = split /\n/, $out;
    for my $line (@lines) {
        like($line, qr/^>> /, "pad: line starts with '>> '");
    }
}

# ── Pad with hash ────────────────────────────────────────────────
{
    my $dd = Loo->new([{a => 1}]);
    $dd->{use_colour} = 0;
    $dd->Pad('  ')->Sortkeys(1);
    my $out = $dd->Dump;
    my @lines = split /\n/, $out;
    for my $line (@lines) {
        like($line, qr/^  /, "pad hash: line starts with '  '");
    }
}

# ── Pad with nested structure ─────────────────────────────────────
{
    my $out = dd({a => [1, 2]}, pad => '| ', sortkeys => 1);
    my @lines = split /\n/, $out;
    for my $line (@lines) {
        like($line, qr/^\| /, "pad nested: line starts with '| '");
    }
}

# ── Pad with terse mode ──────────────────────────────────────────
{
    my $out = dd(42, pad => '@@', terse => 1);
    like($out, qr/^\@\@42/, 'pad + terse');
}

# ── Empty pad (default behavior) ─────────────────────────────────
{
    my $out = dd(42, pad => '');
    like($out, qr/^\$VAR1/, 'empty pad: no prefix');
}

done_testing;
