#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use File::Temp qw(tempdir);
use File::Path qw(make_path);
use File::Spec;

use FastGlob ();

# Test recursive globbing through directory trees, brace expansion
# with real files, and dotfile hiding behavior.
# These are the most complex code paths in FastGlob with no prior
# dedicated test coverage.

# Use DIR => '.' to avoid Windows 8.3 short path names in the system
# temp directory (e.g. RUNNER~1) which don't match readdir long names.
my $tmpdir = tempdir( DIR => '.', CLEANUP => 1 );

# Build a controlled directory tree:
#   $tmpdir/
#     alpha/
#       one.c
#       two.c
#       .hidden
#     beta/
#       three.c
#       deep/
#         four.c
#     gamma/
#       five.h
#       six.c
#     .dotdir/
#       secret.txt

my @dirs = (
    "$tmpdir/alpha",
    "$tmpdir/beta",
    "$tmpdir/beta/deep",
    "$tmpdir/gamma",
    "$tmpdir/.dotdir",
);
make_path(@dirs);

my @files = (
    "$tmpdir/alpha/one.c",
    "$tmpdir/alpha/two.c",
    "$tmpdir/alpha/.hidden",
    "$tmpdir/beta/three.c",
    "$tmpdir/beta/deep/four.c",
    "$tmpdir/gamma/five.h",
    "$tmpdir/gamma/six.c",
    "$tmpdir/.dotdir/secret.txt",
);
for my $f (@files) {
    open my $fh, '>', $f or die "Cannot create $f: $!";
    close $fh;
}

# Helper to get basenames relative to $tmpdir for readable assertions
sub rel {
    my @sorted = sort @_;
    my @out;
    for (@sorted) {
        my $r = $_;
        $r =~ s/\Q$tmpdir\E[\/\\]//;
        # Normalize to forward slashes for portable assertions
        $r =~ s/\\/\//g;
        push @out, $r;
    }
    return @out;
}

# ---- Recursive directory patterns ----

subtest 'single-level directory wildcard' => sub {
    my @got = FastGlob::glob("$tmpdir/alpha/*.c");
    is_deeply( [rel(@got)], ['alpha/one.c', 'alpha/two.c'],
        'alpha/*.c finds .c files in alpha/' );
};

subtest 'wildcard in directory component' => sub {
    my @got = FastGlob::glob("$tmpdir/*/three.c");
    is_deeply( [rel(@got)], ['beta/three.c'],
        '*/three.c finds three.c in any subdir' );
};

subtest 'wildcard in both directory and file' => sub {
    my @got = FastGlob::glob("$tmpdir/*/*.c");
    is_deeply( [rel(@got)],
        ['alpha/one.c', 'alpha/two.c', 'beta/three.c', 'gamma/six.c'],
        '*/*.c finds all .c files one level deep' );
};

subtest 'two-level deep pattern' => sub {
    my @got = FastGlob::glob("$tmpdir/beta/deep/*.c");
    is_deeply( [rel(@got)], ['beta/deep/four.c'],
        'beta/deep/*.c finds four.c' );
};

subtest 'deep wildcard: */deep/*' => sub {
    my @got = FastGlob::glob("$tmpdir/*/deep/*");
    is_deeply( [rel(@got)], ['beta/deep/four.c'],
        '*/deep/* traverses into nested directory' );
};

subtest 'question mark in directory component' => sub {
    my @got = FastGlob::glob("$tmpdir/alph?/*.c");
    is_deeply( [rel(@got)], ['alpha/one.c', 'alpha/two.c'],
        'alph?/*.c matches alpha/' );
};

subtest 'character class in directory component' => sub {
    my @got = FastGlob::glob("$tmpdir/[ab]*/*.c");
    is_deeply( [rel(@got)],
        ['alpha/one.c', 'alpha/two.c', 'beta/three.c'],
        '[ab]*/*.c matches alpha/ and beta/' );
};

# ---- Brace expansion with real files ----

subtest 'brace expansion selects specific dirs' => sub {
    my @got = FastGlob::glob("$tmpdir/{alpha,gamma}/*.c");
    is_deeply( [rel(@got)],
        ['alpha/one.c', 'alpha/two.c', 'gamma/six.c'],
        '{alpha,gamma}/*.c expands to both directories' );
};

subtest 'brace expansion in filename' => sub {
    my @got = FastGlob::glob("$tmpdir/alpha/{one,two}.c");
    is_deeply( [rel(@got)], ['alpha/one.c', 'alpha/two.c'],
        'alpha/{one,two}.c expands to both files' );
};

subtest 'brace expansion with non-matching entry' => sub {
    my @got = FastGlob::glob("$tmpdir/{alpha,nonexistent}/*.c");
    is_deeply( [rel(@got)], ['alpha/one.c', 'alpha/two.c'],
        '{alpha,nonexistent}/*.c returns only matches' );
};

subtest 'nested brace expansion' => sub {
    # Nested braces expand inside-out: {alpha/{one,two},gamma/six}
    # becomes {alpha/one,gamma/six} and {alpha/two,gamma/six},
    # so gamma/six.c appears twice — correct brace semantics.
    my @got = FastGlob::glob("$tmpdir/{alpha/{one,two},gamma/six}.c");
    my @unique = rel(@got);
    ok( (grep { $_ eq 'alpha/one.c' } @unique), 'nested brace finds alpha/one.c' );
    ok( (grep { $_ eq 'alpha/two.c' } @unique), 'nested brace finds alpha/two.c' );
    ok( (grep { $_ eq 'gamma/six.c' } @unique), 'nested brace finds gamma/six.c' );
    is( scalar @got, 4, 'nested brace produces 4 results (gamma/six.c duplicated)' );
};

# ---- Dotfile hiding ----

subtest 'dotfiles hidden by default' => sub {
    local $FastGlob::hidedotfiles = 1;
    my @got = FastGlob::glob("$tmpdir/alpha/*");
    is_deeply( [rel(@got)], ['alpha/one.c', 'alpha/two.c'],
        '* hides .hidden when hidedotfiles=1' );
};

subtest 'dotfiles visible when hidedotfiles=0' => sub {
    local $FastGlob::hidedotfiles = 0;
    my @got = FastGlob::glob("$tmpdir/alpha/*");
    # With hidedotfiles=0, readdir returns . and .. as well as .hidden
    my @rel = rel(@got);
    ok( (grep { $_ eq 'alpha/.hidden' } @rel), '.hidden is visible when hidedotfiles=0' );
    ok( (grep { $_ eq 'alpha/one.c' } @rel),   'one.c still present' );
    ok( (grep { $_ eq 'alpha/two.c' } @rel),   'two.c still present' );
};

subtest 'dot-dirs hidden in wildcard dir component' => sub {
    local $FastGlob::hidedotfiles = 1;
    my @got = FastGlob::glob("$tmpdir/*/*.c");
    my @dirs_seen = map { (split m{[/\\]}, $_)[0] } rel(@got);
    ok( !grep { /^\./ } @dirs_seen,
        'wildcard dir component hides .dotdir' );
};

subtest 'dot-dirs visible when hidedotfiles=0' => sub {
    local $FastGlob::hidedotfiles = 0;
    my @got = FastGlob::glob("$tmpdir/.dotdir/*.txt");
    is_deeply( [rel(@got)], ['.dotdir/secret.txt'],
        'explicit .dotdir/*.txt finds secret.txt when hidedotfiles=0' );
};

# ---- Edge cases ----

subtest 'no match returns empty list' => sub {
    my @got = FastGlob::glob("$tmpdir/nonexistent/*.xyz");
    is_deeply( \@got, [], 'non-matching pattern returns empty list' );
};

subtest 'literal path without wildcards' => sub {
    my @got = FastGlob::glob("$tmpdir/alpha/one.c");
    is_deeply( [rel(@got)], ['alpha/one.c'],
        'literal path passed through unchanged' );
};

subtest 'literal path to nonexistent file' => sub {
    my @got = FastGlob::glob("$tmpdir/alpha/nope.c");
    is_deeply( [rel(@got)], ['alpha/nope.c'],
        'nonexistent literal path returned as-is (glob semantics)' );
};

subtest 'multiple file extensions via brace' => sub {
    my @got = FastGlob::glob("$tmpdir/gamma/*.{c,h}");
    is_deeply( [rel(@got)], ['gamma/five.h', 'gamma/six.c'],
        '*.{c,h} matches both extensions' );
};

subtest 'double separator in path' => sub {
    # Patterns like /usr//tmp/* should work (empty component between separators)
    my @got = FastGlob::glob("$tmpdir//alpha/*.c");
    # Double separator may produce paths with extra separator — just verify correct files found
    is( scalar @got, 2, 'double separator finds 2 files' );
    ok( (grep { /alpha[\/\\]one\.c$/ } @got), 'double separator finds one.c' );
    ok( (grep { /alpha[\/\\]two\.c$/ } @got), 'double separator finds two.c' );
};

done_testing;
