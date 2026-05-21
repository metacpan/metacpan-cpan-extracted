#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Raw;
use File::Raw::Separated;

# File::Raw::spew / append / atomic_spew via plugin => 'csv' or 'tsv'
# are routed through sep_write, which serialises an arrayref of
# arrayrefs into bytes following RFC 4180 (doubled-quote escape) or
# the configured `escape` byte.

my $dir = tempdir(CLEANUP => 1);

subtest 'spew(plugin => csv) round-trips' => sub {
    my $f = "$dir/spew.csv";
    my $rows = [
        ['a', '1'],
        ['b', '2'],
        ['c', '3'],
    ];
    File::Raw::spew($f, $rows, plugin => 'csv');
    is(File::Raw::slurp($f), "a,1\nb,2\nc,3\n", 'expected bytes on disk');
    is_deeply(File::Raw::slurp($f, plugin => 'csv'), $rows,
        'round-trips through slurp');
};

subtest 'spew quotes fields containing sep / quote / newline' => sub {
    my $f = "$dir/quoted.csv";
    my $rows = [
        ['plain'],
        ['has,comma'],
        ['has "quote'],
        ["has\nnewline"],
        ['both "and",too'],
    ];
    File::Raw::spew($f, $rows, plugin => 'csv');
    my $back = File::Raw::slurp($f, plugin => 'csv');
    is_deeply($back, $rows, 'all five quoting cases round-trip');
};

subtest 'spew handles undef fields as empty' => sub {
    my $f = "$dir/undef.csv";
    File::Raw::spew($f, [['a', undef, 'c']], plugin => 'csv');
    is(File::Raw::slurp($f), "a,,c\n", 'undef emits empty between commas');
};

subtest 'append(plugin => csv) adds rows to existing file' => sub {
    my $f = "$dir/append.csv";
    File::Raw::spew($f,   [['a', '1'], ['b', '2']], plugin => 'csv');
    File::Raw::append($f, [['c', '3']],             plugin => 'csv');
    File::Raw::append($f, [['d', '4'], ['e', '5']], plugin => 'csv');
    my $back = File::Raw::slurp($f, plugin => 'csv');
    is(scalar @$back, 5, 'five rows after two appends');
    is_deeply($back->[-1], ['e', '5'], 'last row from second append');
};

subtest 'atomic_spew(plugin => csv) round-trips' => sub {
    my $f = "$dir/atomic.csv";
    my $rows = [['x', '1'], ['y', '2']];
    File::Raw::atomic_spew($f, $rows, plugin => 'csv');
    is_deeply(File::Raw::slurp($f, plugin => 'csv'), $rows,
        'atomic_spew round-trips');
};

subtest 'tsv plugin uses tab separator and skips quoting by default' => sub {
    my $f = "$dir/tsv.tsv";
    my $rows = [['a', '1'], ['b', '2'], ['c', '3']];
    File::Raw::spew($f, $rows, plugin => 'tsv');
    is(File::Raw::slurp($f), "a\t1\nb\t2\nc\t3\n", 'tab-separated bytes');
    is_deeply(File::Raw::slurp($f, plugin => 'tsv'), $rows,
        'tsv round-trips');
};

subtest 'eol => crlf emits CRLF terminators' => sub {
    my $f = "$dir/crlf.csv";
    File::Raw::spew($f, [['a', '1'], ['b', '2']],
                    plugin => 'csv', eol => 'crlf');
    is(File::Raw::slurp($f), "a,1\r\nb,2\r\n", 'crlf line endings');
};

subtest 'sep => ;  changes the separator' => sub {
    my $f = "$dir/semi.csv";
    File::Raw::spew($f, [['a', '1'], ['b', '2']],
                    plugin => 'csv', sep => ';');
    is(File::Raw::slurp($f), "a;1\nb;2\n", 'semicolon separator');
};

subtest 'non-arrayref payload croaks' => sub {
    my $f = "$dir/bad.csv";
    eval { File::Raw::spew($f, "not arrayref", plugin => 'csv') };
    like($@, qr/arrayref of rows/, 'scalar payload rejected');

    eval { File::Raw::spew($f, [['a'], 'notarow'], plugin => 'csv') };
    like($@, qr/row 1 is not an arrayref/, 'mixed row types rejected');
};

subtest 'unknown plugin option croaks before write' => sub {
    my $f = "$dir/bad2.csv";
    eval { File::Raw::spew($f, [['a']], plugin => 'csv', bogus_key => 1) };
    like($@, qr/unknown option/, 'typo-key rejected');
};

done_testing;
