#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Raw;
use File::Raw::Separated;

# File::Raw::each_line($p, $cb, plugin => 'csv') routes through
# sep_stream: File::Raw owns the file open + chunk-read loop, and
# sep_stream holds a separated_ctx_t* across calls in
# FilePluginContext::call_state. The user callback fires once per
# parsed record (arrayref under default mode, hashref under header).

my $dir = tempdir(CLEANUP => 1);

subtest 'each_line streams parsed records via plugin' => sub {
    my $f = "$dir/stream.csv";
    File::Raw::spew($f, "a,1\nb,2\nc,3\n");
    my @rows;
    File::Raw::each_line($f, sub { push @rows, [@{$_[0]}] }, plugin => 'csv');
    is(scalar @rows, 3, 'three records emitted');
    is_deeply($rows[0], ['a', '1'], 'first record');
    is_deeply($rows[2], ['c', '3'], 'last record');
};

subtest 'each_line via plugin matches in-memory parse_buf' => sub {
    my $f = "$dir/equiv.csv";
    File::Raw::spew($f, join("\n", map { "row$_,$_" } 1..50) . "\n");

    my @stream;
    File::Raw::each_line($f, sub { push @stream, [@{$_[0]}] }, plugin => 'csv');

    my $buf = File::Raw::Separated::csv_parse_buf(File::Raw::slurp($f));

    is(scalar @stream, scalar @$buf, 'same row count');
    is_deeply(\@stream, $buf, 'streaming output equivalent to in-memory');
};

subtest 'each_line handles fields with embedded separator and quote' => sub {
    my $f = "$dir/tricky.csv";
    File::Raw::spew(
        $f,
        qq(plain,1\n) .
        qq("has, comma",2\n) .
        qq("has ""quote",3\n),
    );
    my @rows;
    File::Raw::each_line($f, sub { push @rows, [@{$_[0]}] }, plugin => 'csv');
    is(scalar @rows, 3, 'three records');
    is_deeply($rows[0], ['plain',       '1'], 'plain field');
    is_deeply($rows[1], ['has, comma',  '2'], 'embedded comma unquoted');
    is_deeply($rows[2], ['has "quote',  '3'], 'doubled-quote escape collapsed');
};

subtest 'each_line via tsv plugin' => sub {
    my $f = "$dir/stream.tsv";
    File::Raw::spew($f, "a\t1\nb\t2\nc\t3\n");
    my @rows;
    File::Raw::each_line($f, sub { push @rows, [@{$_[0]}] }, plugin => 'tsv');
    is(scalar @rows, 3, 'three tsv records');
    is_deeply($rows[1], ['b', '2'], 'tab-separated row parsed');
};

subtest 'header => 1 emits hashrefs' => sub {
    my $f = "$dir/header.csv";
    File::Raw::spew($f, "name,age\nalice,30\nbob,25\n");
    my @rows;
    File::Raw::each_line(
        $f, sub { push @rows, { %{$_[0]} } }, plugin => 'csv', header => 1,
    );
    is(scalar @rows, 2, 'two data rows');
    is_deeply($rows[0], { name => 'alice', age => '30' }, 'alice hashref');
    is_deeply($rows[1], { name => 'bob',   age => '25' }, 'bob hashref');
};

subtest 'large file streams across multiple chunks' => sub {
    my $f = "$dir/big.csv";
    # ~200 KiB ensures > 1 chunk at File::Raw's 64 KiB default.
    my @lines;
    for my $i (1..10_000) {
        push @lines, sprintf('id%05d,name-%05d', $i, $i);
    }
    File::Raw::spew($f, join("\n", @lines) . "\n");

    my $count = 0;
    my $first;
    my $last;
    File::Raw::each_line($f, sub {
        $count++;
        $first ||= [@{$_[0]}];
        $last    = [@{$_[0]}];
    }, plugin => 'csv');

    is($count, 10_000, 'all 10k rows seen across chunks');
    is_deeply($first, ['id00001', 'name-00001'], 'first row intact');
    is_deeply($last,  ['id10000', 'name-10000'], 'last row intact');
};

subtest 'callback dies propagate from streaming dispatch' => sub {
    my $f = "$dir/die.csv";
    File::Raw::spew($f, "a,1\nb,2\nc,3\n");
    eval {
        File::Raw::each_line($f, sub {
            die "stop on row b\n" if $_[0][0] eq 'b';
        }, plugin => 'csv');
    };
    like($@, qr/stop on row b/, 'die in callback re-raised');
};

done_testing;
