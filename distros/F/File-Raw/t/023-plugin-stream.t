#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use File::Raw;
use File::Temp qw(tempdir);

# STREAM phase - exercised via each_line. Perl plugins cannot implement
# 'stream', so we register a passthrough record-only plugin and assert
# the missing-stream-phase error path. C-level stream coverage will land
# alongside the Separated rewrite.

my $dir = tempdir(CLEANUP => 1);

subtest 'each_line without plugin still iterates per-line' => sub {
    my $f = "$dir/a.txt";
    File::Raw::spew($f, "one\ntwo\nthree\n");
    my @collected;
    File::Raw::each_line($f, sub { push @collected, $_ });
    is_deeply(\@collected, ['one', 'two', 'three'], 'legacy per-line path intact');
};

subtest 'each_line with no-stream plugin croaks' => sub {
    File::Raw::register_plugin('rec_only', { record => sub { $_[1] } });
    eval { File::Raw::each_line("$dir/a.txt", sub {}, plugin => 'rec_only') };
    like($@, qr/no stream phase/,
        'plugin without stream phase rejected');
    File::Raw::unregister_plugin('rec_only');
};

subtest 'each_line with unknown plugin croaks' => sub {
    eval { File::Raw::each_line("$dir/a.txt", sub {}, plugin => 'unknown_qq') };
    like($@, qr/unknown plugin 'unknown_qq'/, 'unknown plugin caught');
};

subtest 'each_line bad arity' => sub {
    eval { File::Raw::each_line("$dir/a.txt") };
    like($@, qr/Usage/, 'missing callback caught');
};

subtest 'each_line callback type-checked' => sub {
    eval { File::Raw::each_line("$dir/a.txt", "notacoderef") };
    like($@, qr/code reference/, 'non-coderef callback caught');
};

done_testing;
