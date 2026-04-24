#!/usr/bin/env perl

# Test POSIX [!...] bracket negation in glob patterns.
# Regression: FastGlob treated ! as a literal character inside brackets
# instead of converting [!...] to regex [^...] for negation.

use strict;
use warnings;

use Test::More;
use File::Temp qw(tempdir);
use File::Basename qw(basename);
use FastGlob ();

my $dir = tempdir( DIR => '.', CLEANUP => 1 );

# Create single-letter files: a.txt through e.txt
for my $letter ('a' .. 'e') {
    open my $fh, '>', "$dir/$letter.txt" or die "Cannot create $dir/$letter.txt: $!";
    close $fh;
}

# Compare on basenames only — output path format (separator, drive prefix) varies
# by platform, but the matched filenames should be deterministic.
sub got_basenames {
    return [ sort map { basename($_) } @_ ];
}

# [!abc].txt — should match d.txt and e.txt (negation)
{
    my @got = FastGlob::glob("$dir/[!abc].txt");
    is_deeply( got_basenames(@got), [ 'd.txt', 'e.txt' ],
        '[!abc] negation matches files NOT in the set' );
}

# [abc].txt — positive match should still work
{
    my @got = FastGlob::glob("$dir/[abc].txt");
    is_deeply( got_basenames(@got), [ 'a.txt', 'b.txt', 'c.txt' ],
        '[abc] positive match still works' );
}

# [!a-c].txt — negated range
{
    my @got = FastGlob::glob("$dir/[!a-c].txt");
    is_deeply( got_basenames(@got), [ 'd.txt', 'e.txt' ],
        '[!a-c] negated range works' );
}

# [a-c].txt — positive range should still work
{
    my @got = FastGlob::glob("$dir/[a-c].txt");
    is_deeply( got_basenames(@got), [ 'a.txt', 'b.txt', 'c.txt' ],
        '[a-c] positive range still works' );
}

# Edge: [!] should not break (single ! in brackets)
{
    my @got = eval { FastGlob::glob("$dir/[!].txt") };
    # [!] with no chars after ! is degenerate — just ensure no crash
    ok( !$@, '[!] degenerate case does not crash' );
}

done_testing;
