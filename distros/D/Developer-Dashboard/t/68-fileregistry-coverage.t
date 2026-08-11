#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use File::Spec;
use File::Temp qw(tempdir);
use Test::More;

use lib 'lib';

use Developer::Dashboard::PathRegistry;
use Developer::Dashboard::FileRegistry;

# Hermetic runtime: an isolated HOME whose deepest .developer-dashboard layer is
# the config root, entered via chdir so layer discovery resolves against it.
my $home = tempdir( CLEANUP => 1 );
local $ENV{HOME} = $home;
chdir $home or die "Unable to chdir to $home: $!";

my $paths = Developer::Dashboard::PathRegistry->new( home => $home );
my $files = Developer::Dashboard::FileRegistry->new( paths => $paths );

# --- register_named_files: non-hash argument short-circuits (line 38 true) -----
{
    my $same = $files->register_named_files( [ 'not', 'a', 'hash' ] );
    is( $same, $files, 'register_named_files ignores a non-hash argument and returns the invocant' );
    is_deeply( $files->{named_files}, {}, 'register_named_files stored nothing for a non-hash argument' );
}

# --- register_named_files: empty key + undef/empty values are skipped ----------
# Drives the "next" branch on line 40 (empty key) and both operands of the
# line 42 value guard (undef value and empty-string value), while a normal
# alias exercises the stored path.
{
    $files->register_named_files(
        {
            ''        => '/skip/empty/key',
            good_name => '/registered/value',
            undef_val => undef,
            empty_val => '',
        }
    );
    is( $files->{named_files}{good_name}, '/registered/value', 'register_named_files stores a normal alias' );
    ok( !exists $files->{named_files}{''}, 'register_named_files skips an empty alias name' );
    ok( !exists $files->{named_files}{undef_val}, 'register_named_files skips an undefined alias path' );
    ok( !exists $files->{named_files}{empty_val}, 'register_named_files skips an empty alias path' );
}

# --- unregister_named_file: undef and empty names short-circuit (line 54) ------
{
    is( $files->unregister_named_file(undef), $files, 'unregister_named_file returns the invocant for an undef name' );
    is( $files->unregister_named_file(''),    $files, 'unregister_named_file returns the invocant for an empty name' );
    $files->unregister_named_file('good_name');
    ok( !exists $files->{named_files}{good_name}, 'unregister_named_file removes a real alias' );
}

# --- named_files merges configured + explicit aliases (lines 66-70) ------------
{
    $files->register_named_files( { merged_alias => '/merged/value' } );
    my $named = $files->named_files;
    is( ref($named), 'HASH', 'named_files returns a hash reference' );
    is( $named->{merged_alias}, '/merged/value', 'named_files exposes explicitly registered aliases' );
}

# --- locate_files: undef term is filtered, leaving no terms (lines 111-112) ----
{
    is_deeply( [ $files->locate_files(undef) ], [], 'locate_files filters an undef term and returns nothing when no terms remain' );
    is_deeply( [ $files->locate_files( '', undef ) ], [], 'locate_files filters empty and undef terms alike' );
}

# --- locate_files_under: root/term guards (line 122 term filter, line 123) -----
{
    my $tree = File::Spec->catdir( $home, 'searchtree' );
    mkdir $tree or die "Unable to create $tree: $!";

    my $match_path = File::Spec->catfile( $tree, 'ddfrneedle_alpha.txt' );
    my $miss_path  = File::Spec->catfile( $tree, 'plain_beta.txt' );
    for my $file ( $match_path, $miss_path ) {
        open my $fh, '>', $file or die "Unable to create $file: $!";
        print {$fh} "content\n";
        close $fh;
    }

    # Each guard operand of line 123 is driven to its short-circuit value.
    is_deeply( [ $files->locate_files_under( undef, 'ddfrneedle' ) ], [], 'locate_files_under rejects an undef root' );
    is_deeply( [ $files->locate_files_under( '', 'ddfrneedle' ) ], [], 'locate_files_under rejects an empty root' );
    is_deeply(
        [ $files->locate_files_under( File::Spec->catdir( $home, 'no-such-root' ), 'ddfrneedle' ) ],
        [],
        'locate_files_under rejects a non-directory root',
    );
    # undef term is filtered (line 122), leaving no terms so the valid directory
    # still returns nothing (line 123 term guard).
    is_deeply( [ $files->locate_files_under( $tree, undef ) ], [], 'locate_files_under returns nothing when every term is filtered away' );

    # Functional match: one file whose path contains the term is returned; a
    # non-matching sibling is skipped (line 134 both branch outcomes and both
    # reachable condition combinations).
    is_deeply(
        [ $files->locate_files_under( $tree, 'ddfrneedle' ) ],
        [$match_path],
        'locate_files_under returns matching files and skips non-matching siblings',
    );

    # The cwd-rooted entry point delegates to locate_files_under (line 113).
    my @cwd_hits = $files->locate_files('ddfrneedle');
    ok( ( grep { $_ eq $match_path } @cwd_hits ), 'locate_files searches the current directory and finds the matching file' );
}

# --- resolve_file behaviours --------------------------------------------------
{
    my $abs = File::Spec->catfile( $home, 'absolute.txt' );
    is( $files->resolve_file($abs), $abs, 'resolve_file returns absolute paths unchanged' );

    $files->register_named_files( { resolvable => '/resolved/target' } );
    is( $files->resolve_file('resolvable'), '/resolved/target', 'resolve_file returns a registered alias path' );

    like( $files->resolve_file('global_config'), qr/config\.json$/, 'resolve_file dispatches to a known runtime accessor' );

    my $unknown = eval { $files->resolve_file('definitely-unknown-alias'); 1 } ? '' : $@;
    like( $unknown, qr/Unknown file name 'definitely-unknown-alias'/, 'resolve_file dies for an unknown name' );
}

# --- read/write/append/touch/remove happy paths -------------------------------
{
    my $target = File::Spec->catfile( $home, 'roundtrip.txt' );

    is( $files->read($target), undef, 'read returns undef for a file that does not exist' );

    is( $files->write( $target, 'hello' ), $target, 'write returns the written path' );
    is( $files->read($target), 'hello', 'read returns written content' );

    is( $files->append( $target, ' world' ), $target, 'append returns the appended path' );
    is( $files->read($target), 'hello world', 'append adds to existing content' );

    my $touched = File::Spec->catfile( $home, 'touched.txt' );
    is( $files->touch($touched), $touched, 'touch returns the touched path' );
    ok( -f $touched, 'touch creates an empty file' );

    is( $files->write( $target, undef ), $target, 'write tolerates undef content' );
    is( $files->read($target), '', 'write with undef content truncates the file' );

    is( $files->remove($target), $target, 'remove returns the removed path' );
    ok( !-e $target, 'remove deletes the file' );
    is( $files->remove($target), $target, 'remove is a no-op when the file is already gone' );
}

# --- read failure: an existing but unreadable file dies (line 182) ------------
# This host runs as a non-root user, so a mode-0000 owned file cannot be opened
# for reading and the failure side of the open is genuinely reachable.
{
    my $noperm_dir = File::Spec->catdir( $home, 'noperm' );
    mkdir $noperm_dir or die "Unable to create $noperm_dir: $!";
    my $secret = File::Spec->catfile( $noperm_dir, 'secret.txt' );
    open my $fh, '>', $secret or die "Unable to create $secret: $!";
    print {$fh} "secret\n";
    close $fh;
    chmod 0000, $secret or die "Unable to chmod $secret: $!";

    my $read_err = eval { $files->read($secret); 1 } ? '' : $@;
    like( $read_err, qr/Unable to read \Q$secret\E/, 'read dies when an existing file cannot be opened for reading' );

    chmod 0700, $secret;    # restore so tempdir cleanup can reclaim it
}

# --- write/append/touch failure: a missing parent directory dies --------------
# These fail structurally (ENOENT on the parent directory) regardless of user,
# driving the failure side of the write, append, and touch opens.
{
    my $bad = File::Spec->catfile( $home, 'missing-parent-dir', 'child.txt' );

    my $write_err = eval { $files->write( $bad, 'x' ); 1 } ? '' : $@;
    like( $write_err, qr/Unable to write \Q$bad\E/, 'write dies when the parent directory is missing' );

    my $append_err = eval { $files->append( $bad, 'x' ); 1 } ? '' : $@;
    like( $append_err, qr/Unable to append \Q$bad\E/, 'append dies when the parent directory is missing' );

    my $touch_err = eval { $files->touch($bad); 1 } ? '' : $@;
    like( $touch_err, qr/Unable to touch \Q$bad\E/, 'touch dies when the parent directory is missing' );
}

# Line 134 per-term filter, both branch sides in isolation: a directory whose
# only file matches the term drives the continue/push side, and a directory
# whose only file does not match drives the return/skip side.
{
    my $match_tree = File::Spec->catdir( $home, 'ddfrmatchtree' );
    mkdir $match_tree or die "Unable to create $match_tree: $!";
    my $only_match = File::Spec->catfile( $match_tree, 'ddfrhit_only.txt' );
    open my $mfh, '>', $only_match or die "Unable to create $only_match: $!";
    print {$mfh} "x\n";
    close $mfh;
    is_deeply(
        [ $files->locate_files_under( $match_tree, 'ddfrhit' ) ],
        [$only_match],
        'locate_files_under returns a file when the term matches (continue side of the per-term filter)',
    );

    my $miss_tree = File::Spec->catdir( $home, 'ddfrmisstree' );
    mkdir $miss_tree or die "Unable to create $miss_tree: $!";
    open my $nfh, '>', File::Spec->catfile( $miss_tree, 'unrelated_file.txt' ) or die "Unable to create miss file: $!";
    print {$nfh} "x\n";
    close $nfh;
    is_deeply(
        [ $files->locate_files_under( $miss_tree, 'ddfrnosuchterm' ) ],
        [],
        'locate_files_under returns nothing when no file matches the term (return side of the per-term filter)',
    );
}

done_testing;

__END__

=head1 NAME

t/68-fileregistry-coverage.t - branch and condition coverage for the logical file registry

=head1 PURPOSE

This test is the executable coverage contract for
C<Developer::Dashboard::FileRegistry>. It drives the guard clauses of alias
registration, the search-term and root guards of the file locator, and the
success and failure sides of the read, write, append, and touch helpers so that
every reachable branch and boolean condition of the module is exercised.

=head1 WHY IT EXISTS

It exists because the registry's defensive guards - non-hash alias input,
empty or undefined alias names and paths, filtered search terms, invalid search
roots, and files that cannot be opened - are hard to reach from the higher
level CLI and web flows, yet each guard is load-bearing for safe file handling.
A dedicated hermetic test keeps those guards honest under the repository's
all-metrics coverage gate and documents the exact behaviour each one protects.

=head1 WHEN TO USE

Use this file when changing how the file registry registers aliases, resolves
logical names, locates files beneath a directory, or reads and writes runtime
files, and whenever a coverage run reports an uncovered branch or condition in
the file registry.

=head1 HOW TO USE

Run C<perl -Ilib t/68-fileregistry-coverage.t> or C<prove -lv
t/68-fileregistry-coverage.t> while iterating on the module, then keep it green
under C<prove -lr t> and the coverage gate before release. The test builds its
own temporary HOME and never touches the developer's real runtime tree.

=head1 WHAT USES IT

Developers during TDD, the full C<prove -lr t> suite, and the Devel::Cover
coverage gate all rely on this file to keep the file registry's guard clauses
and file-access helpers from regressing.

=head1 EXAMPLES

Example 1:

  perl -Ilib t/68-fileregistry-coverage.t

Run the coverage test standalone while changing the file registry.

Example 2:

  prove -lv t/68-fileregistry-coverage.t

Run the same test through the harness with verbose per-assertion output.

Example 3:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lr t

Recheck the module under the repository coverage gate after a change.

=cut
