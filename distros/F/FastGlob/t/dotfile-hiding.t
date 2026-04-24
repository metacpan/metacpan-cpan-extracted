#!/usr/bin/env perl
# Regression tests for dotfile hiding behavior.
#
# FastGlob should hide entries starting with '.' (when $hidedotfiles=1)
# unless the glob pattern explicitly starts with a literal dot, matching
# CORE::glob semantics.
#
# Bug: the old regex-based dotfile mangling (converting .* to (?:[^.].*)?
# at the regex level) failed for patterns like *.? and ** where the
# optional group could be skipped, allowing dotfiles through.

use strict;
use warnings;

use Test::More;
use File::Temp qw(tempdir);
use File::Path qw(mkpath);
use File::Basename qw(basename);

use FastGlob ();

# Save and set config
my $orig_hidedotfiles = $FastGlob::hidedotfiles;

my $dir = tempdir(CLEANUP => 1);
chdir $dir or die "Cannot chdir to $dir: $!";

# Create test structure with dotfiles
mkpath('.hidden');
for my $f (qw(foo.c bar.c .dotfile .hidden/secret visible.x)) {
    open my $fh, '>', $f or die "Cannot create $f: $!";
    close $fh;
}

# --- Tests with hidedotfiles=1 (default) ---

$FastGlob::hidedotfiles = 1;

{
    my @res = FastGlob::glob('*');
    ok(!grep { /\A\./ } @res, '* does not match dotfiles');
    ok(grep { $_ eq 'foo.c' } @res, '* matches regular files');
}

{
    # This was the main bug: *.? matched '..' because the regex
    # (?:[^.].*)?\.{regex} allowed skipping the dotfile guard
    my @res = FastGlob::glob('*.?');
    ok(!grep { /\A\./ } @res, '*.? does not match dotfiles or ..');
    ok(!grep { $_ eq '..' } @res, '*.? specifically does not match ..');
}

{
    my @res = FastGlob::glob('**');
    ok(!grep { /\A\./ } @res, '** does not match dotfiles');
    ok(!grep { $_ eq '.' } @res, '** does not match .');
    ok(!grep { $_ eq '..' } @res, '** does not match ..');
}

{
    my @res = FastGlob::glob('?o?.c');
    ok(!grep { /\A\./ } @res, '?o?.c does not match dotfiles');
}

{
    # Explicit dot patterns SHOULD show dotfiles
    my @res = FastGlob::glob('.*');
    ok(scalar @res > 0, '.* returns results');
    ok(grep { $_ eq '.dotfile' } @res, '.* matches .dotfile');
    ok(grep { $_ eq '.' } @res, '.* matches .');
    ok(grep { $_ eq '..' } @res, '.* matches ..');
    ok(grep { $_ eq '.hidden' } @res, '.* matches .hidden dir');
    ok(!grep { $_ eq 'foo.c' } @res, '.* does not match non-dotfiles');
}

{
    my @res = FastGlob::glob('.hidden/*');
    ok(grep { basename($_) eq 'secret' } @res,
        '.hidden/* matches files inside hidden directory');
}

{
    my @res = FastGlob::glob('.dotfile');
    is(scalar @res, 1, 'literal .dotfile matches exactly one entry');
    is($res[0], '.dotfile', 'literal .dotfile returns .dotfile');
}

# --- Tests with hidedotfiles=0 ---

$FastGlob::hidedotfiles = 0;

{
    my @res = FastGlob::glob('*');
    ok(grep { /\A\./ } @res, '* matches dotfiles when hidedotfiles=0');
}

{
    my @res = FastGlob::glob('*.?');
    ok(grep { $_ eq '..' } @res, '*.? matches .. when hidedotfiles=0');
}

# Restore
$FastGlob::hidedotfiles = $orig_hidedotfiles;

done_testing;
