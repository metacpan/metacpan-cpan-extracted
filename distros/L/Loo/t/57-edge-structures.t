use strict;
use warnings;
use Test::More;
use Loo qw(ncDump);

# ── Empty nested structures ──────────────────────────────────────
{
    my $out = ncDump([[], {}, []]);
    like($out, qr/\[\]/, 'empty array in array');
    like($out, qr/\{\}/, 'empty hash in array');
}

{
    my $dd = Loo->new([{a => [], b => {}}]);
    $dd->{use_colour} = 0;
    $dd->Sortkeys(1);
    my $out = $dd->Dump;
    like($out, qr/'a' => \[\]/, 'empty array in hash');
    like($out, qr/'b' => \{\}/, 'empty hash in hash');
}

# ── Deeply nested empty ─────────────────────────────────────────
{
    my $out = ncDump([[[[]]]], );
    like($out, qr/\[\n\s+\[\n\s+\[\n\s+\[\]/, 'deeply nested empty arrays');
}

# ── Mixed type array ────────────────────────────────────────────
{
    my $obj = bless {v => 1}, 'M';
    my $out = ncDump([42, 'str', undef, \1, qr/x/, [1], {a => 2}, $obj]);
    like($out, qr/42/, 'mixed array: integer');
    like($out, qr/'str'/, 'mixed array: string');
    like($out, qr/undef/, 'mixed array: undef');
    like($out, qr/\\1/, 'mixed array: scalar ref');
    like($out, qr/qr\//, 'mixed array: regex');
    like($out, qr/\[/, 'mixed array: nested array');
    like($out, qr/'a'/, 'mixed array: nested hash');
    like($out, qr/'M'/, 'mixed array: blessed');
}

# ── Large array ──────────────────────────────────────────────────
{
    my @big;
    push @big, $_ for 1..100;
    my $out = ncDump(\@big);
    like($out, qr/1/, 'large array: first element');
    like($out, qr/100/, 'large array: last element');
}

# ── Large hash ──────────────────────────────────────────────────
{
    my %big;
    for my $i (1..50) { $big{"key$i"} = $i; }
    my $dd = Loo->new([\%big]);
    $dd->{use_colour} = 0;
    $dd->Sortkeys(1);
    my $out = $dd->Dump;
    like($out, qr/'key1' => /, 'large hash: first key');
    like($out, qr/'key50' => /, 'large hash: last key');
}

# ── Hash with empty string key ──────────────────────────────────
{
    my $dd = Loo->new([{'' => 'empty_key'}]);
    $dd->{use_colour} = 0;
    my $out = $dd->Dump;
    like($out, qr/'' => 'empty_key'/, 'empty string as hash key');
}

# ── Hash with newline in key ────────────────────────────────────
{
    my $dd = Loo->new([{"a\nb" => 1}]);
    $dd->{use_colour} = 0;
    $dd->Useqq(1);
    my $out = $dd->Dump;
    like($out, qr/a\\nb/, 'newline in hash key with useqq');
}

# ── Single element array ────────────────────────────────────────
{
    my $out = ncDump([42]);
    like($out, qr/\[\n\s+42\n\s*\]/, 'single element array');
}

# ── Single element hash ─────────────────────────────────────────
{
    my $dd = Loo->new([{only => 1}]);
    $dd->{use_colour} = 0;
    my $out = $dd->Dump;
    like($out, qr/'only' => 1/, 'single element hash');
}

# ── Nested arrays of different depths ───────────────────────────
{
    my $out = ncDump([1, [2, [3, [4]]]]);
    like($out, qr/1/, 'nested depth: level 0');
    like($out, qr/2/, 'nested depth: level 1');
    like($out, qr/3/, 'nested depth: level 2');
    like($out, qr/4/, 'nested depth: level 3');
}

# ── Array of hashes ─────────────────────────────────────────────
{
    my $dd = Loo->new([[{a => 1}, {b => 2}]]);
    $dd->{use_colour} = 0;
    $dd->Sortkeys(1);
    my $out = $dd->Dump;
    like($out, qr/'a' => 1/, 'array of hashes: first hash');
    like($out, qr/'b' => 2/, 'array of hashes: second hash');
}

# ── Hash of arrays ──────────────────────────────────────────────
{
    my $dd = Loo->new([{x => [1, 2], y => [3, 4]}]);
    $dd->{use_colour} = 0;
    $dd->Sortkeys(1);
    my $out = $dd->Dump;
    like($out, qr/'x' => \[/, 'hash of arrays: first key');
    like($out, qr/'y' => \[/, 'hash of arrays: second key');
}

# ── Indent 0 with complex nested structure ──────────────────────
{
    my $dd = Loo->new([{a => [1, {b => 2}]}]);
    $dd->{use_colour} = 0;
    $dd->Indent(0)->Sortkeys(1);
    my $out = $dd->Dump;
    like($out, qr/\{'a' => \[1, \{'b' => 2\}\]\}/, 'indent 0: complex nested on one line');
}

done_testing;
