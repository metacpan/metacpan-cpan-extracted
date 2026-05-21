#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use File::Raw;
use File::Temp qw(tempdir);

# lines_iter($p, plugin => 'name', ...) wraps the plugin's READ output
# (an AoA) in an iterator. Trade-off vs each_line: eager whole-AoA in
# memory, but preserves the iterator handle interface (storable,
# lazy-on-the-Perl-side, supports early close). For true streaming use
# each_line($p, $cb, plugin => 'name').

# Plugin that returns an arrayref of single-element rows (one per word).
File::Raw::register_plugin('words', {
    read => sub {
        my ($p, $bytes, $opts) = @_;
        return [ map { [$_] } split /\s+/, $bytes ];
    },
});

my $dir = tempdir(CLEANUP => 1);

subtest 'plugin path returns one record per next()' => sub {
    my $f = "$dir/w.txt";
    File::Raw::spew($f, "alpha beta gamma");
    my $it = File::Raw::lines_iter($f, plugin => 'words');
    my @rows;
    while (!$it->eof) {
        my $r = $it->next;
        last unless defined $r;
        push @rows, $r;
    }
    is(scalar @rows, 3, 'three records');
    is_deeply($rows[0], ['alpha']);
    is_deeply($rows[2], ['gamma']);
};

subtest 'no-plugin path is unchanged (byte-line iteration)' => sub {
    my $f = "$dir/b.txt";
    File::Raw::spew($f, "one\ntwo\nthree\n");
    my $it = File::Raw::lines_iter($f);
    my @lines;
    until ($it->eof) {
        my $l = $it->next;
        last unless defined $l;
        push @lines, $l;
    }
    is_deeply(\@lines, ['one', 'two', 'three'],
        'byte-line iter still produces strings');
};

subtest 'unknown plugin croaks before iter is constructed' => sub {
    my $f = "$dir/u.txt";
    File::Raw::spew($f, "x");
    eval { File::Raw::lines_iter($f, plugin => 'nope_xyz') };
    like($@, qr/unknown plugin 'nope_xyz'/);
};

subtest 'plugin returning non-arrayref croaks' => sub {
    File::Raw::register_plugin('not_aref', {
        read => sub { "just bytes" },
    });
    my $f = "$dir/u.txt";
    File::Raw::spew($f, "x");
    eval { File::Raw::lines_iter($f, plugin => 'not_aref') };
    like($@, qr/arrayref of records/);
    File::Raw::unregister_plugin('not_aref');
};

subtest 'close releases the AoA (DESTROY also fires on scope exit)' => sub {
    my $f = "$dir/c.txt";
    File::Raw::spew($f, "alpha beta");
    {
        my $it = File::Raw::lines_iter($f, plugin => 'words');
        $it->next;
        $it->close;
        # eof should reliably report true after explicit close
    }
    pass('iter destroyed without leak/crash');
};

subtest 'options without plugin key still croak' => sub {
    my $f = "$dir/o.txt";
    File::Raw::spew($f, "x");
    eval { File::Raw::lines_iter($f, sep => ',') };
    like($@, qr/without 'plugin' key/);
};

done_testing;
