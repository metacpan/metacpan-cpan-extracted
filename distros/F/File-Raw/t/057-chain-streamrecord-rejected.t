#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use File::Raw;
use File::Temp qw(tempdir);

# STREAM dispatch (each_line) doesn't support chains in v1: composing
# two streams means buffering one plugin's per-record output as the
# next plugin's chunk input, which needs a record→chunk adapter that's
# its own design problem. Document the limitation and check the
# dispatcher actually rejects the call shape.
#
# RECORD-derived XSUBs (grep_lines / count_lines / find_line /
# map_lines) actually go through file_plugin_dispatch_READ under the
# hood — they slurp+transform the file into a record array first, then
# apply the predicate. So they DO support chains; verify that too as a
# positive companion test, so the asymmetry is explicit.

my $dir = tempdir(CLEANUP => 1);

# Plugin that reads bytes -> AoA-of-words. Chain-friendly as the LAST
# read plugin (output is structured).
File::Raw::register_plugin('words', {
    read => sub {
        my ($p, $bytes, $opts) = @_;
        return [ map { [$_] } split /\s+/, $bytes ];
    },
});

# Pure-byte transform; chain-friendly anywhere.
File::Raw::register_plugin('strip_pipes', {
    read => sub { my ($p, $bytes, $o) = @_; my $x = $bytes; $x =~ tr/|//d; $x },
});

my $f = "$dir/r.txt";
File::Raw::spew($f, "alpha|beta gamma|delta epsilon|zeta\n");

subtest 'each_line with chain is rejected' => sub {
    eval {
        File::Raw::each_line($f, sub {}, plugin => ['strip_pipes', 'words']);
    };
    like($@, qr/plugin chains are not supported/i,
        'each_line rejects multi-plugin chain');

    # Single-element arrayref is also a chain — same rule applies.
    eval {
        File::Raw::each_line($f, sub {}, plugin => ['words']);
    };
    like($@, qr/plugin chains are not supported/i,
        'each_line rejects [name] (one-element chain) too');
};

subtest 'grep_lines DOES support chains (uses READ dispatch)' => sub {
    # strip_pipes removes |, then words splits into AoA. The predicate
    # runs over the resulting record list. This is the desirable
    # asymmetry: record-derived XSUBs piggyback on READ chaining for
    # free.
    my $rows = File::Raw::grep_lines($f,
        sub { ${$_[0]}[0] =~ /e/ },
        plugin => ['strip_pipes', 'words']);
    isa_ok($rows, 'ARRAY', 'grep_lines returned an arrayref');
    ok(scalar(@$rows) > 0,
        'chain ran end-to-end through grep_lines (records produced)');
};

done_testing;
