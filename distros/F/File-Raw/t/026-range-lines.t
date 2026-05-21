#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use File::Raw qw/range_lines/;
use File::Temp qw(tempdir);

# range_lines($p, $from, $count) - 1-based, half-open in count style.
# range_lines($p, 5, 3) returns lines 5, 6, 7 (or fewer at EOF).
# Plugin tail (plugin => 'csv', etc.) slices the parsed AoA.

my $dir = tempdir(CLEANUP => 1);
my $f   = "$dir/data.txt";
File::Raw::spew($f, join("\n", map "line$_", 1..20) . "\n");

subtest 'first N (equivalent to head)' => sub {
    is_deeply(File::Raw::range_lines($f, 1, 3),
              ['line1', 'line2', 'line3']);
};

subtest 'mid-file range' => sub {
    is_deeply(file_range_lines($f, 5, 3),
              ['line5', 'line6', 'line7']);
};

subtest 'range to end-of-file' => sub {
    is_deeply(File::Raw::range_lines($f, 18, 3),
              ['line18', 'line19', 'line20']);
};

subtest 'count past EOF clamps silently' => sub {
    is_deeply(File::Raw::range_lines($f, 15, 100),
              ['line15', 'line16', 'line17',
               'line18', 'line19', 'line20'],
              'returns up to EOF, no error');
};

subtest 'from past EOF returns empty' => sub {
    is_deeply(File::Raw::range_lines($f, 100, 5), []);
};

subtest 'count == 0 returns empty' => sub {
    is_deeply(File::Raw::range_lines($f, 5, 0), []);
};

subtest 'count < 0 returns empty (no croak)' => sub {
    is_deeply(File::Raw::range_lines($f, 5, -3), []);
};

subtest 'from < 1 returns empty' => sub {
    is_deeply(File::Raw::range_lines($f, 0, 5), []);
    is_deeply(File::Raw::range_lines($f, -3, 5), []);
};

subtest 'arity is enforced' => sub {
    eval { File::Raw::range_lines($f) };
    like($@, qr/Usage/, 'no from/count');
    eval { File::Raw::range_lines($f, 1) };
    like($@, qr/Usage/, 'no count');
};

subtest 'plugin path: slices parsed records' => sub {
    # Plugin that turns lines into AoA-of-words.
    File::Raw::register_plugin('one_per_word', {
        read => sub {
            my (undef, $bytes, undef) = @_;
            return [ map { [$_] } split /\s+/, $bytes ];
        },
    });
    my $wf = "$dir/words.txt";
    File::Raw::spew($wf, "alpha beta gamma delta epsilon zeta");

    my $r = File::Raw::range_lines($wf, 2, 3, plugin => 'one_per_word');
    is(scalar @$r, 3, 'three records');
    is_deeply($r->[0], ['beta']);
    is_deeply($r->[2], ['delta']);
    File::Raw::unregister_plugin('one_per_word');
};

subtest 'plugin path: count past records clamps' => sub {
    File::Raw::register_plugin('three_words', {
        read => sub { [ map { [$_] } qw(a b c) ] },
    });
    my $tf = "$dir/three.txt";
    File::Raw::spew($tf, "ignored");
    my $r = File::Raw::range_lines($tf, 2, 100, plugin => 'three_words');
    is(scalar @$r, 2, 'returned 2 of 3');
    is_deeply($r->[1], ['c']);
    File::Raw::unregister_plugin('three_words');
};

subtest 'unknown plugin croaks' => sub {
    eval { File::Raw::range_lines($f, 1, 5, plugin => 'nope_xyz') };
    like($@, qr/unknown plugin/);
};

subtest 'options without plugin key croak' => sub {
    eval { File::Raw::range_lines($f, 1, 5, sep => ',') };
    like($@, qr/without 'plugin' key/);
};

subtest 'odd parity in tail croaks' => sub {
    eval { File::Raw::range_lines($f, 1, 5, 'stray') };
    like($@, qr/odd number/);
};

done_testing;
