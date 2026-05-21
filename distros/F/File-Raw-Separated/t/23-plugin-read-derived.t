#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Raw;
use File::Raw::Separated;

# File::Raw functions that go through plugin READ phase to obtain
# records: lines, head, tail, grep_lines, count_lines, find_line,
# map_lines. All of these should yield parsed CSV rows when called with
# plugin => 'csv'. (slurp itself is covered by t/20.)

my $dir = tempdir(CLEANUP => 1);
my $f   = "$dir/data.csv";
File::Raw::spew($f, join("\n",
    "a,1",
    "b,2",
    "c,3",
    "d,4",
    "e,5"
) . "\n");

subtest 'lines() returns plugin AoA verbatim' => sub {
    my $rows = File::Raw::lines($f, plugin => 'csv');
    is(scalar @$rows, 5, '5 records');
    is_deeply($rows->[0], ['a', '1'], 'first row parsed');
    is_deeply($rows->[-1], ['e', '5'], 'last row parsed');
};

subtest 'head() with plugin slices first N records' => sub {
    my $h = File::Raw::head($f, 2, plugin => 'csv');
    is(scalar @$h, 2, 'returned 2 records');
    is_deeply($h->[0], ['a', '1'], 'first record');
    is_deeply($h->[1], ['b', '2'], 'second record');
};

subtest 'tail() with plugin slices last N records' => sub {
    my $t = File::Raw::tail($f, 2, plugin => 'csv');
    is(scalar @$t, 2, 'returned 2 records');
    is_deeply($t->[0], ['d', '4'], 'penultimate record');
    is_deeply($t->[1], ['e', '5'], 'last record');
};

subtest 'grep_lines filters parsed records' => sub {
    my $kept = File::Raw::grep_lines(
        $f, sub { $_[0][1] % 2 == 0 }, plugin => 'csv',
    );
    is(scalar @$kept, 2, 'two even rows');
    is_deeply([map { $_->[0] } @$kept], ['b', 'd'], 'b and d kept');
};

subtest 'count_lines counts matching records' => sub {
    my $n = File::Raw::count_lines(
        $f, sub { $_[0][0] gt 'b' }, plugin => 'csv',
    );
    is($n, 3, 'three rows match c, d, e');
};

subtest 'count_lines with undef predicate counts all records' => sub {
    my $n = File::Raw::count_lines($f, undef, plugin => 'csv');
    is($n, 5, 'all five rows');
};

subtest 'find_line returns first match' => sub {
    my $row = File::Raw::find_line(
        $f, sub { $_[0][0] eq 'c' }, plugin => 'csv',
    );
    is_deeply($row, ['c', '3'], 'found c row');
};

subtest 'find_line returns undef when no match' => sub {
    my $row = File::Raw::find_line($f, sub { 0 }, plugin => 'csv');
    is($row, undef, 'no match returns undef');
};

subtest 'map_lines transforms records' => sub {
    my $cols = File::Raw::map_lines(
        $f, sub { $_[0][0] }, plugin => 'csv',
    );
    is_deeply($cols, ['a', 'b', 'c', 'd', 'e'], 'first column extracted');
};

subtest 'tsv plugin works through the same pipeline' => sub {
    my $tf = "$dir/data.tsv";
    File::Raw::spew($tf, "a\t1\nb\t2\nc\t3\n");
    my $rows = File::Raw::lines($tf, plugin => 'tsv');
    is(scalar @$rows, 3, 'three rows from tsv lines');
    is_deeply($rows->[1], ['b', '2'], 'tab-separated row parsed');
};

done_testing;
