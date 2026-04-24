#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use File::Temp qw(tempdir);
use File::Spec;

use FastGlob ();

# Test that regex metacharacters in filenames are matched correctly
# when used with wildcard glob patterns.
# Bug: ( ) $ { } were not escaped during glob-to-regex conversion,
# causing them to be interpreted as regex syntax instead of literals.

# Use DIR => '.' to avoid Windows 8.3 short path names in the system
# temp directory (e.g. RUNNER~1) which don't match readdir long names.
my $tmpdir = tempdir( DIR => '.', CLEANUP => 1 );

# Helper: create an empty file and return its path
sub touch {
    my ($name) = @_;
    my $path = File::Spec->catfile( $tmpdir, $name );
    open my $fh, '>', $path or die "Cannot create $path: $!";
    close $fh;
    return $path;
}

# Create test files with regex metacharacters in names
touch('foo(1).txt');
touch('foo(2).txt');
touch('bar.txt');
touch('a+b.log');

# --- Parentheses ---

{
    my @got = FastGlob::glob("$tmpdir/foo(1)*");
    is( scalar @got, 1, 'foo(1)* matches exactly one file' );
    like( $got[0], qr/foo\(1\)\.txt$/, 'foo(1)* matches foo(1).txt' );
}

{
    my @got = FastGlob::glob("$tmpdir/foo(*");
    is( scalar @got, 2, 'foo(* matches both foo(1).txt and foo(2).txt' )
        or diag "got: @got";
}

# --- Plus sign (already escaped, regression check) ---

{
    my @got = FastGlob::glob("$tmpdir/a+b*");
    is( scalar @got, 1, 'a+b* matches exactly one file' );
    like( $got[0], qr/a\+b\.log$/, 'a+b* matches a+b.log' );
}

# --- Pipe (already escaped, regression check) ---

SKIP: {
    skip 'pipe in filenames is illegal on Windows', 2
        if $^O eq 'MSWin32';

    touch('x|y.dat');

    my @got = FastGlob::glob("$tmpdir/x|y*");
    is( scalar @got, 1, 'x|y* matches exactly one file' );
    like( $got[0], qr/x\|y\.dat$/, 'x|y* matches x|y.dat' );
}

# --- Dollar sign (skip on Windows where $ in filenames is problematic) ---

SKIP: {
    skip 'dollar in filenames unreliable on Windows', 2
        if $^O eq 'MSWin32';

    touch('price$5.txt');

    my @got = FastGlob::glob("$tmpdir/" . 'price$5*');
    is( scalar @got, 1, 'price$5* matches exactly one file' );
    like( $got[0], qr/price\$5\.txt$/, 'price$5* matches price$5.txt' );
}

# --- No false positives: patterns should not match files they shouldn't ---

{
    touch('fooXbar.txt');

    my @got = FastGlob::glob("$tmpdir/foo(X)bar*");
    # Should match literal foo(X)bar, not regex-group fooXbar
    is( scalar @got, 0, 'foo(X)bar* does not match fooXbar.txt (parens are literal)' )
        or diag "unexpected matches: @got";
}

done_testing;
