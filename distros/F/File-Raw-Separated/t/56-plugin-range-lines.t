#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Raw;
use File::Raw::Separated;

# File::Raw::range_lines($p, $from, $count, plugin => 'csv'|'tsv', ...)
# slices the plugin's parsed AoA. Verifies that the plugin tail,
# header modes, and dialect-specific defaults all flow through.

my $dir = tempdir(CLEANUP => 1);

subtest 'csv plugin: range over parsed rows' => sub {
    my $f = "$dir/data.csv";
    File::Raw::spew($f, join("\n", map "row$_,$_", 1..10) . "\n");
    my $rows = File::Raw::range_lines($f, 3, 4, plugin => 'csv');
    is(scalar @$rows, 4, 'four rows');
    is_deeply($rows->[0], ['row3', '3']);
    is_deeply($rows->[3], ['row6', '6']);
};

subtest 'csv plugin + header => 1 (consume row 0)' => sub {
    my $f = "$dir/h.csv";
    File::Raw::spew(
        $f,
        "name,age\nalice,30\nbob,25\ncarol,40\ndave,35\n",
    );
    # rows after header are 0..3; range 2,2 picks rows at positions 2,3
    my $r = File::Raw::range_lines($f, 2, 2, plugin => 'csv', header => 1);
    is(scalar @$r, 2);
    is_deeply($r->[0], { name => 'bob',   age => '25' });
    is_deeply($r->[1], { name => 'carol', age => '40' });
};

subtest 'csv plugin + explicit header (no row consumed)' => sub {
    my $f = "$dir/no-h.csv";
    File::Raw::spew($f, "alice,30\nbob,25\ncarol,40\n");
    my $r = File::Raw::range_lines(
        $f, 2, 2, plugin => 'csv', header => [qw(name age)],
    );
    is(scalar @$r, 2);
    is_deeply($r->[0], { name => 'bob',   age => '25' });
    is_deeply($r->[1], { name => 'carol', age => '40' });
};

subtest 'csv plugin + custom sep' => sub {
    my $f = "$dir/semi.csv";
    File::Raw::spew($f, "a;1\nb;2\nc;3\nd;4\n");
    my $r = File::Raw::range_lines($f, 2, 2, plugin => 'csv', sep => ';');
    is_deeply($r->[0], ['b', '2']);
    is_deeply($r->[1], ['c', '3']);
};

subtest 'tsv plugin: range over tab-separated rows' => sub {
    my $f = "$dir/data.tsv";
    File::Raw::spew($f, "a\t1\nb\t2\nc\t3\n");
    my $r = File::Raw::range_lines($f, 2, 1, plugin => 'tsv');
    is(scalar @$r, 1);
    is_deeply($r->[0], ['b', '2']);
};

subtest 'count past available rows clamps' => sub {
    my $f = "$dir/short.csv";
    File::Raw::spew($f, "a,1\nb,2\n");
    my $r = File::Raw::range_lines($f, 1, 100, plugin => 'csv');
    is(scalar @$r, 2, 'only the rows that exist are returned');
};

subtest 'from past total returns empty' => sub {
    my $f = "$dir/short.csv";
    File::Raw::spew($f, "a,1\nb,2\n");
    my $r = File::Raw::range_lines($f, 50, 5, plugin => 'csv');
    is_deeply($r, []);
};

done_testing;
