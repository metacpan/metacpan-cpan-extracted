#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use File::Temp qw(tempdir);
use File::Spec;

use FastGlob ();

# Test that wildcard detection works for leading-wildcard patterns.
#
# The wildcard detection regex on line 126 of FastGlob.pm determines
# whether a pattern contains glob metacharacters. If it fails to detect
# them, the pattern is returned as a literal string instead of being
# expanded against the filesystem.

my $dir = tempdir(CLEANUP => 1);

# Create test files
for my $name (qw(foo bar xfoo barfoo a.txt b.txt)) {
    open my $fh, '>', File::Spec->catfile($dir, $name) or die "Cannot create $name: $!";
    close $fh;
}

# Save and change to temp dir
my $orig_dir = do { require Cwd; Cwd::getcwd() };
chdir $dir or die "Cannot chdir to $dir: $!";

# --- Leading wildcard patterns must expand, not return as literals ---

my @got;

# *foo should match foo, xfoo, barfoo (not return literal "*foo")
@got = FastGlob::glob('*foo');
is_deeply([sort @got], ['barfoo', 'foo', 'xfoo'],
    'leading * wildcard expands: *foo');

# ?foo should match xfoo (single char + foo)
@got = FastGlob::glob('?foo');
is_deeply([sort @got], ['xfoo'],
    'leading ? wildcard expands: ?foo');

# [ab]foo should match nothing here but must NOT be returned as literal
@got = FastGlob::glob('[xy]foo');
is_deeply([sort @got], ['xfoo'],
    'leading [...] wildcard expands: [xy]foo');

# *.txt should match a.txt, b.txt
@got = FastGlob::glob('*.txt');
is_deeply([sort @got], ['a.txt', 'b.txt'],
    'leading * with suffix expands: *.txt');

# bare * should expand to all non-dot files
@got = FastGlob::glob('*');
is_deeply([sort @got], [sort qw(foo bar xfoo barfoo a.txt b.txt)],
    'bare * expands to all files');

# --- Escaped wildcards should NOT expand ---

# \*foo should be treated as literal (no expansion)
@got = FastGlob::glob('\*foo');
is_deeply(\@got, ['\*foo'],
    'escaped \\*foo is treated as literal');

# --- Non-wildcard patterns returned as-is ---

@got = FastGlob::glob('plainfile');
is_deeply(\@got, ['plainfile'],
    'non-wildcard pattern returned as literal');

chdir $orig_dir;

done_testing;
