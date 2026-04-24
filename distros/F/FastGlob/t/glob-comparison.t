#!/usr/bin/env perl

# Comprehensive comparison test: FastGlob::glob() vs CORE::glob()
#
# Creates a controlled directory structure and verifies that FastGlob
# produces the same results as CORE::glob for a wide variety of patterns.
# Divergences are documented as TODO tests so they serve as a roadmap
# for fixes without blocking CI.

use strict;
use warnings;

use Test::More;
use File::Temp qw(tempdir);
use File::Path qw(make_path);
use File::Spec;
use File::Basename qw(basename);
use Cwd qw(getcwd abs_path);

use FastGlob ();

# --- Build a controlled directory tree ---

# Use DIR => '.' to avoid 8.3 short path issues on Windows
my $root = tempdir( DIR => '.', CLEANUP => 1 );
$root = abs_path($root);

# Helper: create a file (and parent dirs if needed)
sub touch {
    my ($relpath) = @_;
    my $full = File::Spec->catfile( $root, split m{/}, $relpath );
    my $dir  = File::Basename::dirname($full);
    make_path($dir) unless -d $dir;
    open my $fh, '>', $full or die "Cannot create $full: $!";
    close $fh;
}

# Helper: create a directory
sub mkd {
    my ($relpath) = @_;
    my $full = File::Spec->catdir( $root, split m{/}, $relpath );
    make_path($full) unless -d $full;
}

# Build the tree:
#   root/
#     alpha.c
#     beta.c
#     gamma.h
#     delta.txt
#     README
#     .hidden
#     .dotdir/
#       secret.txt
#     src/
#       main.c
#       util.c
#       helper.h
#       lib/
#         core.c
#         extra.c
#     docs/
#       guide.txt
#       notes.txt
#     empty/

touch('alpha.c');
touch('beta.c');
touch('gamma.h');
touch('delta.txt');
touch('README');
touch('.hidden');
mkd('.dotdir');
touch('.dotdir/secret.txt');
mkd('src');
touch('src/main.c');
touch('src/util.c');
touch('src/helper.h');
mkd('src/lib');
touch('src/lib/core.c');
touch('src/lib/extra.c');
mkd('docs');
touch('docs/guide.txt');
touch('docs/notes.txt');
mkd('empty');

# --- Helpers ---

# Compare FastGlob and CORE::glob, using basenames on Windows
# to avoid separator/drive-prefix mismatches.
sub compare_glob {
    my ($pattern, $description, %opts) = @_;

    my @fast = FastGlob::glob($pattern);
    my @core = do { my @r = CORE::glob($pattern); sort @r };

    if ( $^O eq 'MSWin32' ) {
        # On Windows, compare basenames only — FastGlob uses \, CORE::glob uses /
        @fast = sort map { basename($_) } @fast;
        @core = sort map { basename($_) } @core;
    } else {
        @fast = sort @fast;
        @core = sort @core;
    }

    if ( $opts{todo} ) {
        local $TODO = $opts{todo};
        is_deeply( \@fast, \@core, $description )
            or diag "FastGlob: [@fast]\nCORE:     [@core]";
    } else {
        is_deeply( \@fast, \@core, $description )
            or diag "FastGlob: [@fast]\nCORE:     [@core]";
    }
}

# Save original dir and chdir into our test root
my $orig_dir = getcwd();
chdir $root or die "Cannot chdir to $root: $!";

# =================================================================
# Section 1: Basic wildcard patterns
# =================================================================

compare_glob( '*.c',
    'star-dot-ext matches .c files' );

compare_glob( '*.h',
    'star-dot-ext matches .h files' );

compare_glob( '*.txt',
    'star-dot-ext matches .txt files' );

compare_glob( '*',
    'bare star matches all non-dot entries' );

compare_glob( '?????.*',
    'question marks match fixed-length names' );

compare_glob( 'README',
    'literal name without wildcards' );

compare_glob( 'nonexistent',
    'literal name that does not exist' );

# =================================================================
# Section 2: Character class patterns
# =================================================================

compare_glob( '[ab]*',
    'character class [ab]* matches a* and b* files' );

compare_glob( '[a-d]*',
    'character range [a-d]* matches a-d prefix files' );

compare_glob( '*[!.]*',
    'negation [!.]* excludes dot-containing names',
    todo => 'POSIX [!...] negation not yet converted to regex [^...]' );

# =================================================================
# Section 3: Brace expansion
# =================================================================

compare_glob( '{alpha,beta}.c',
    'brace expansion with two alternatives' );

compare_glob( '{*.c,*.h}',
    'brace expansion with wildcard alternatives' );

compare_glob( '{alpha,nonexistent}.c',
    'brace expansion with one missing alternative' );

# =================================================================
# Section 4: Directory traversal
# =================================================================

# Skip path-separator patterns on Windows — output format differs
SKIP: {
    skip 'path separator format differs on Windows', 6
        if $^O eq 'MSWin32';

    compare_glob( 'src/*.c',
        'subdir/star matches files in subdirectory' );

    compare_glob( 'src/*',
        'subdir/star matches all entries in subdir' );

    compare_glob( 'src/*.h',
        'subdir/star-dot-h matches headers in subdir' );

    compare_glob( 'docs/*',
        'docs/* matches all files in docs/' );

    compare_glob( 'src/lib/*.c',
        'nested subdir pattern matches' );

    compare_glob( 'empty/*',
        'empty directory returns no matches' );
}

# =================================================================
# Section 5: Dotfile handling
# =================================================================

compare_glob( '.*',
    'dot-star matches dotfiles and dotdirs' );

compare_glob( '.h*',
    'dot-prefix with wildcard matches .hidden' );

# =================================================================
# Section 6: Multi-component patterns
# =================================================================

SKIP: {
    skip 'path separator format differs on Windows', 3
        if $^O eq 'MSWin32';

    compare_glob( '*/*.c',
        'star/star.c matches .c files one level deep' );

    compare_glob( '*/*',
        'star/star matches all entries one level deep' );

    compare_glob( '*/*/*',
        'star/star/star matches entries two levels deep' );
}

# =================================================================
# Section 7: Patterns that should return as literals
# =================================================================

compare_glob( 'src',
    'directory name without wildcard returned as-is' );

# =================================================================
# Section 8: Edge cases
# =================================================================

{
    # Empty input — CORE::glob('') behavior varies across Perl versions
    # (some return (''), others return ()), so test FastGlob independently.
    my @fast = FastGlob::glob('');
    is_deeply( \@fast, [],
        'empty pattern returns empty list' );
}

{
    # Pattern with trailing separator
    SKIP: {
        skip 'path separator differences on Windows', 1
            if $^O eq 'MSWin32';

        my @fast = sort(FastGlob::glob('src/'));
        my @core = sort(CORE::glob('src/'));
        is_deeply( \@fast, \@core,
            'trailing slash pattern' )
            or diag "FastGlob: [@fast]\nCORE:     [@core]";
    }
}

# =================================================================
# Done
# =================================================================

chdir $orig_dir;
done_testing;
