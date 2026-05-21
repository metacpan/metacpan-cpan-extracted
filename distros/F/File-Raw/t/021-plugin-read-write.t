#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use File::Raw;
use File::Temp qw(tempdir);

# READ + WRITE phases via slurp / spew / append / atomic_spew / lines.

my $dir = tempdir(CLEANUP => 1);

# Plugin that round-trips: READ uppercases, WRITE lowercases.
File::Raw::register_plugin('case', {
    read  => sub { my ($p, $b, $o) = @_; uc $b },
    write => sub { my ($p, $r, $o) = @_; lc $r },
});

# Plugin whose READ returns an arrayref (used by lines()).
File::Raw::register_plugin('split_pipe', {
    read => sub {
        my ($p, $b, $o) = @_;
        return [ split /\|/, $b ];
    },
});

subtest 'slurp without plugin is unchanged' => sub {
    my $f = "$dir/a.txt";
    File::Raw::spew($f, "Hello");
    is(File::Raw::slurp($f), "Hello", 'no plugin returns raw bytes');
};

subtest 'slurp with plugin runs READ phase' => sub {
    my $f = "$dir/b.txt";
    File::Raw::spew($f, "Hello World");
    is(File::Raw::slurp($f, plugin => 'case'), "HELLO WORLD",
        'plugin uppercases on read');
};

subtest 'spew with plugin runs WRITE phase' => sub {
    my $f = "$dir/c.txt";
    File::Raw::spew($f, "MIXED Case", plugin => 'case');
    is(File::Raw::slurp($f), "mixed case",
        'plugin lowercases bytes before writing');
};

subtest 'append with plugin runs WRITE phase' => sub {
    my $f = "$dir/d.txt";
    File::Raw::spew($f, "abc");
    File::Raw::append($f, "DEF", plugin => 'case');
    is(File::Raw::slurp($f), "abcdef",
        'append transforms then concatenates');
};

subtest 'atomic_spew with plugin runs WRITE phase' => sub {
    my $f = "$dir/e.txt";
    File::Raw::atomic_spew($f, "ATOMIC", plugin => 'case');
    is(File::Raw::slurp($f), "atomic", 'atomic_spew transforms');
};

subtest 'lines returns plugin arrayref directly' => sub {
    my $f = "$dir/f.txt";
    File::Raw::spew($f, "a|b|c|d");
    my $rows = File::Raw::lines($f, plugin => 'split_pipe');
    is_deeply($rows, [qw(a b c d)], 'lines() returns the plugin AoA verbatim');
};

subtest 'lines splits plugin bytes when not arrayref' => sub {
    my $f = "$dir/g.txt";
    File::Raw::spew($f, "alpha\nbeta\ngamma");
    my $lines = File::Raw::lines($f, plugin => 'case');
    is_deeply($lines, ['ALPHA', 'BETA', 'GAMMA'],
        'lines() splits the plugin\'s byte result on \n');
};

subtest 'unknown plugin croaks before any I/O' => sub {
    eval { File::Raw::slurp("$dir/no.txt", plugin => 'unknown_xyz') };
    like($@, qr/unknown plugin 'unknown_xyz'/, 'slurp errors');

    eval { File::Raw::spew("$dir/no.txt", "x", plugin => 'unknown_xyz') };
    like($@, qr/unknown plugin 'unknown_xyz'/, 'spew errors');
};

subtest 'options without plugin key croak' => sub {
    eval { File::Raw::slurp("$dir/a.txt", sep => ',') };
    like($@, qr/without 'plugin' key/, 'options-but-no-plugin caught');
};

subtest 'odd parity tail croaks' => sub {
    eval { File::Raw::slurp("$dir/a.txt", 'stray') };
    like($@, qr/odd number/, 'odd parity caught');
};

subtest 'plugin cancellation returns undef / no-op' => sub {
    File::Raw::register_plugin('cancel_read', {
        read  => sub { return },                    # undef -> cancel
        write => sub { return },
    });
    my $f = "$dir/h.txt";
    File::Raw::spew($f, "before");
    is(File::Raw::slurp($f, plugin => 'cancel_read'), undef,
        'slurp returns undef when plugin cancels');
    ok(!File::Raw::spew($f, "after", plugin => 'cancel_read'),
        'spew returns false when plugin cancels');
    is(File::Raw::slurp($f), "before", 'file unchanged after cancelled spew');
    File::Raw::unregister_plugin('cancel_read');
};

subtest 'phase missing on plugin croaks' => sub {
    File::Raw::register_plugin('read_only', { read => sub { $_[1] } });
    eval { File::Raw::spew("$dir/x.txt", "data", plugin => 'read_only') };
    like($@, qr/no write phase/, 'missing write phase croaks');
    File::Raw::unregister_plugin('read_only');
};

subtest 'function-style aliases also accept plugin tail' => sub {
    File::Raw->import(qw(slurp spew lines));
    my $f = "$dir/fn.txt";
    main::file_spew($f, "hi");
    is(main::file_slurp($f, plugin => 'case'), "HI",
        'imported file_slurp accepts plugin');
};

done_testing;
