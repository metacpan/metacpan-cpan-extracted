#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Raw;
use File::Raw::Separated;

# File::Raw::lines_iter($p, plugin => 'csv'|'tsv', ...) end-to-end
# through Separated's csv/tsv plugins.

my $dir = tempdir(CLEANUP => 1);

subtest 'csv iter walks parsed records' => sub {
    my $f = "$dir/data.csv";
    File::Raw::spew($f, "a,1\nb,2\nc,3\n");
    my $it = File::Raw::lines_iter($f, plugin => 'csv');
    my @rows;
    until ($it->eof) {
        my $r = $it->next;
        last unless defined $r;
        push @rows, $r;
    }
    is(scalar @rows, 3, 'three rows');
    is_deeply($rows[0], ['a', '1']);
    is_deeply($rows[2], ['c', '3']);
};

subtest 'csv iter with header => 1 yields hashrefs' => sub {
    my $f = "$dir/h.csv";
    File::Raw::spew($f, "name,age\nalice,30\nbob,25\n");
    my $it = File::Raw::lines_iter($f, plugin => 'csv', header => 1);
    my @rows;
    until ($it->eof) {
        my $r = $it->next;
        last unless defined $r;
        push @rows, $r;
    }
    is(scalar @rows, 2, 'header consumed, two data rows');
    is_deeply($rows[0], { name => 'alice', age => '30' });
};

subtest 'csv iter with explicit header => [...] yields hashrefs from row 0' => sub {
    my $f = "$dir/no-h.csv";
    File::Raw::spew($f, "alice,30\nbob,25\n");
    my $it = File::Raw::lines_iter(
        $f, plugin => 'csv', header => [qw(name age)],
    );
    my @rows;
    until ($it->eof) {
        my $r = $it->next;
        last unless defined $r;
        push @rows, $r;
    }
    is(scalar @rows, 2, 'no row consumed for header');
    is_deeply($rows[0], { name => 'alice', age => '30' });
    is_deeply($rows[1], { name => 'bob',   age => '25' });
};

subtest 'tsv iter walks tab-separated records' => sub {
    my $f = "$dir/data.tsv";
    File::Raw::spew($f, "x\t1\ny\t2\n");
    my $it = File::Raw::lines_iter($f, plugin => 'tsv');
    my @rows;
    until ($it->eof) {
        my $r = $it->next;
        last unless defined $r;
        push @rows, $r;
    }
    is(scalar @rows, 2);
    is_deeply($rows[0], ['x', '1']);
};

subtest 'iter with custom sep' => sub {
    my $f = "$dir/semi.csv";
    File::Raw::spew($f, "a;1\nb;2\n");
    my $it = File::Raw::lines_iter($f, plugin => 'csv', sep => ';');
    my @rows;
    until ($it->eof) {
        my $r = $it->next;
        last unless defined $r;
        push @rows, $r;
    }
    is_deeply($rows[0], ['a', '1']);
    is_deeply($rows[1], ['b', '2']);
};

subtest 'early close does not leak (AoA refcount drops cleanly)' => sub {
    my $f = "$dir/close.csv";
    File::Raw::spew($f, join("\n", map "row$_,$_", 1..100) . "\n");
    {
        my $it = File::Raw::lines_iter($f, plugin => 'csv');
        $it->next for 1..10;   # take some
        $it->close;            # drop the rest unread
    }
    pass('explicit close + scope exit clean');
};

done_testing;
