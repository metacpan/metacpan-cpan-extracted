#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Test::More;
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);

use lib 'lib';

use Developer::Dashboard::PathRegistry;
use Developer::Dashboard::Housekeeper;

# Hermetic runtime rooted entirely under a throwaway HOME, with the CWD moved
# inside it. The CWD matters more here than in most files: the defect under
# test is that a temp-file candidate can be a RELATIVE pattern, which the
# shell-glob resolves against the process working directory, so the decoy files
# below are deliberately planted underneath this sandbox CWD.
my $home = tempdir( CLEANUP => 1 );
local $ENV{HOME}                           = $home;
local $ENV{DEVELOPER_DASHBOARD_STATE_ROOT} = tempdir( CLEANUP => 1 );
local $ENV{DEVELOPER_DASHBOARD_BOOKMARKS};
local $ENV{DEVELOPER_DASHBOARD_CONFIGS};
local $ENV{DEVELOPER_DASHBOARD_CHECKERS};
# Read the shipped implementation while the process is still in the repository
# root. Everything below runs from a throwaway HOME, so a repo-relative path
# stops resolving the moment the chdir happens.
my $HOUSEKEEPER_SOURCE = do {
    my $path = File::Spec->catfile( 'lib', 'Developer', 'Dashboard', 'Housekeeper.pm' );
    open my $fh, '<', $path or die "Unable to read $path: $!";
    local $/;
    my $text = <$fh>;
    close $fh or die "Unable to close $path: $!";
    $text;
};

chdir $home or die "Unable to chdir to $home: $!";

my $paths = Developer::Dashboard::PathRegistry->new( home => $home );

my $AGED = 7200;

# _write_file($path, $text)
# Writes one small fixture file, creating nothing implicitly.
# Input: destination path string and payload text.
# Output: the written path string.
sub _write_file {
    my ( $path, $text ) = @_;
    open my $fh, '>', $path or die "Unable to write $path: $!";
    print {$fh} $text;
    close $fh or die "Unable to close $path: $!";
    return $path;
}

# _write_aged_file($path)
# Writes one fixture file and backdates it past any realistic minimum age, so
# the housekeeper treats it as reclaimable.
# Input: destination path string.
# Output: the written path string.
sub _write_aged_file {
    my ($path) = @_;
    _write_file( $path, "fixture payload for $path" );
    utime time - $AGED, time - $AGED, $path or die "Unable to age $path: $!";
    return $path;
}

# ---------------------------------------------------------------------------
# A temp directory whose path contains a space. Perl's built-in glob() splits
# its argument on whitespace, so the pattern
#
#     <sandbox>/spaced dir/developer-dashboard-ajax-*
#
# becomes two patterns: the absolute, metacharacter-free "<sandbox>/spaced",
# and the RELATIVE "dir/developer-dashboard-ajax-*". The first matches nothing
# real; the second is resolved against the process working directory. So the
# genuine temp files are never seen and unrelated files below the CWD are.
#
# Both halves are asserted here: the real files must be reclaimed, and the
# decoy files outside the temp directory must survive.
# ---------------------------------------------------------------------------
{
    my $sandbox = tempdir( CLEANUP => 1 );
    my $spaced  = File::Spec->catdir( $sandbox, 'spaced dir' );
    make_path($spaced);

    my $real_ajax   = _write_aged_file( File::Spec->catfile( $spaced, 'developer-dashboard-ajax-real' ) );
    my $real_result = _write_aged_file( File::Spec->catfile( $spaced, 'dashboard-result-real' ) );
    my $fresh_ajax  = _write_file( File::Spec->catfile( $spaced, 'developer-dashboard-ajax-fresh' ), 'fresh' );

    # The exact paths the trailing whitespace fragment resolves to from here.
    my $decoy_dir = File::Spec->catdir( $home, 'dir' );
    make_path($decoy_dir);
    my $decoy_ajax   = _write_aged_file( File::Spec->catfile( $decoy_dir, 'developer-dashboard-ajax-DECOY' ) );
    my $decoy_result = _write_aged_file( File::Spec->catfile( $decoy_dir, 'dashboard-result-DECOY' ) );

    my $keeper = Developer::Dashboard::Housekeeper->new( paths => $paths );

    my ( @candidates, @removed, $scanned );
    {
        no warnings qw(redefine once);
        local *File::Spec::tmpdir = sub { return $spaced };
        @candidates = $keeper->_temp_file_candidates;
        $scanned    = { ajax_temp_files => 0, result_temp_files => 0 };
        @removed    = $keeper->_cleanup_temp_files(
            min_age_seconds => 3600,
            scanned         => $scanned,
        );
    }

    my @outside = grep { !_is_inside( $spaced, $_ ) } @candidates;
    is_deeply( \@outside, [], '_temp_file_candidates never proposes a path outside the temp directory when that path contains a space' )
      or diag( "escaping candidates: " . join( ', ', @outside ) );

    ok( !-e $real_ajax,   '_cleanup_temp_files reclaims an aged ajax temp file from a temp directory whose path contains a space' );
    ok( !-e $real_result, '_cleanup_temp_files reclaims an aged runtime result temp file from a temp directory whose path contains a space' );
    ok( -e $fresh_ajax,   '_cleanup_temp_files still keeps a not-yet-aged candidate in a spaced temp directory' );

    ok( -e $decoy_ajax,   '_cleanup_temp_files leaves an unrelated ajax-prefixed file below the working directory untouched' );
    ok( -e $decoy_result, '_cleanup_temp_files leaves an unrelated result-prefixed file below the working directory untouched' );

    my @removed_paths = sort map { $_->{path} } @removed;
    is_deeply(
        \@removed_paths,
        [ sort( $real_result, $real_ajax ) ],
        '_cleanup_temp_files reports exactly the two genuine temp files it removed, and nothing from outside the temp directory'
    );

    is( $scanned->{ajax_temp_files},   2, 'the ajax scan counter counts the two ajax entries actually present in the spaced temp directory' );
    is( $scanned->{result_temp_files}, 1, 'the result scan counter counts the one result entry actually present in the spaced temp directory' );
}

# ---------------------------------------------------------------------------
# The same guarantee through the public run() entrypoint, so the fix is not
# only true of the private helper.
# ---------------------------------------------------------------------------
{
    my $sandbox = tempdir( CLEANUP => 1 );
    my $spaced  = File::Spec->catdir( $sandbox, 'another spaced dir' );
    make_path($spaced);

    my $real_ajax = _write_aged_file( File::Spec->catfile( $spaced, 'developer-dashboard-ajax-runtime' ) );

    my $decoy_dir = File::Spec->catdir( $home, 'another' );
    make_path($decoy_dir);
    my $decoy_ajax = _write_aged_file( File::Spec->catfile( $decoy_dir, 'developer-dashboard-ajax-RUNDECOY' ) );

    my $keeper = Developer::Dashboard::Housekeeper->new( paths => $paths );

    my $summary;
    {
        no warnings qw(redefine once);
        local *File::Spec::tmpdir = sub { return $spaced };
        $summary = $keeper->run( min_age_seconds => 3600 );
    }

    is( $summary->{ok}, 1, 'run reports success over a temp directory whose path contains a space' );
    ok( !-e $real_ajax, 'run reclaims the aged ajax temp file inside a spaced temp directory' );
    ok( -e $decoy_ajax, 'run leaves the unrelated file below the working directory untouched' );
    is(
        scalar( grep { $_->{kind} eq 'ajax-temp-file' } @{ $summary->{removed} } ),
        1,
        'run removes exactly one ajax temp file, the genuine one'
    );
}

# ---------------------------------------------------------------------------
# A backslash in the temp path must not be read as a glob escape either. This
# is the shape a Windows temp path takes, and it is asserted on every platform
# because the mechanism (pattern escaping) is not platform-specific: a literal
# backslash in a directory name is legal on this host and must be listed, not
# interpreted.
# ---------------------------------------------------------------------------
SKIP: {
    my $sandbox = tempdir( CLEANUP => 1 );
    my $odd     = File::Spec->catdir( $sandbox, 'back\\slash dir' );
    skip 'this filesystem does not accept a literal backslash in a directory name', 2
      if !eval { make_path($odd); -d $odd };

    my $real_ajax = _write_aged_file( File::Spec->catfile( $odd, 'developer-dashboard-ajax-escaped' ) );

    my $keeper = Developer::Dashboard::Housekeeper->new( paths => $paths );
    my @candidates;
    {
        no warnings qw(redefine once);
        local *File::Spec::tmpdir = sub { return $odd };
        @candidates = $keeper->_temp_file_candidates;
        $keeper->_cleanup_temp_files(
            min_age_seconds => 3600,
            scanned         => { ajax_temp_files => 0, result_temp_files => 0 },
        );
    }

    is_deeply( [@candidates], [$real_ajax], '_temp_file_candidates lists a temp file under a directory name containing a backslash' );
    ok( !-e $real_ajax, '_cleanup_temp_files reclaims an aged temp file under a directory name containing a backslash' );
}

# ---------------------------------------------------------------------------
# Regression guard: the ordinary space-free temp directory keeps behaving
# exactly as it did before, including skipping entries that are not plain
# files and entries that do not carry a dashboard-owned prefix.
# ---------------------------------------------------------------------------
{
    my $tmp = tempdir( CLEANUP => 1 );

    my $aged_ajax   = _write_aged_file( File::Spec->catfile( $tmp, 'developer-dashboard-ajax-aged' ) );
    my $aged_result = _write_aged_file( File::Spec->catfile( $tmp, 'dashboard-result-aged' ) );
    my $fresh_ajax  = _write_file( File::Spec->catfile( $tmp, 'developer-dashboard-ajax-fresh' ), 'fresh' );
    my $unrelated   = _write_aged_file( File::Spec->catfile( $tmp, 'some-other-tool-tempfile' ) );

    my $ajax_dir = File::Spec->catdir( $tmp, 'developer-dashboard-ajax-dir' );
    make_path($ajax_dir);
    utime time - $AGED, time - $AGED, $ajax_dir or die "Unable to age $ajax_dir: $!";

    my $keeper = Developer::Dashboard::Housekeeper->new( paths => $paths );

    my ( @removed, $scanned );
    {
        no warnings qw(redefine once);
        local *File::Spec::tmpdir = sub { return $tmp };
        $scanned = { ajax_temp_files => 0, result_temp_files => 0 };
        @removed = $keeper->_cleanup_temp_files(
            min_age_seconds => 3600,
            scanned         => $scanned,
        );
    }

    ok( !-e $aged_ajax,   'an aged ajax temp file is still removed from a space-free temp directory' );
    ok( !-e $aged_result, 'an aged runtime result temp file is still removed from a space-free temp directory' );
    ok( -e $fresh_ajax,   'a fresh candidate is still kept in a space-free temp directory' );
    ok( -e $unrelated,    'a file with no dashboard-owned prefix is still ignored' );
    ok( -d $ajax_dir,     'a prefixed directory is still skipped rather than removed' );
    is( scalar @removed, 2, 'exactly the two aged files are still reported as removed from a space-free temp directory' );
    is( $scanned->{ajax_temp_files},   2, 'the ajax scan counter is unchanged for a space-free temp directory' );
    is( $scanned->{result_temp_files}, 1, 'the result scan counter is unchanged for a space-free temp directory' );
}

# ---------------------------------------------------------------------------
# An empty temp directory must report zero because it held nothing, and a
# temp directory that cannot be listed must not silently read as empty.
# ---------------------------------------------------------------------------
{
    my $keeper = Developer::Dashboard::Housekeeper->new( paths => $paths );

    my $empty = tempdir( CLEANUP => 1 );
    my @none;
    {
        no warnings qw(redefine once);
        local *File::Spec::tmpdir = sub { return $empty };
        @none = $keeper->_temp_file_candidates;
    }
    is_deeply( \@none, [], '_temp_file_candidates returns nothing for an empty temp directory' );

    my $missing = File::Spec->catdir( tempdir( CLEANUP => 1 ), 'never-created' );
    my @absent;
    {
        no warnings qw(redefine once);
        local *File::Spec::tmpdir = sub { return $missing };
        @absent = $keeper->_temp_file_candidates;
    }
    is_deeply( \@absent, [], '_temp_file_candidates returns nothing when the temp directory does not exist' );

    # A temp directory that exists but cannot be listed must be loud. Silently
    # reporting nothing would be indistinguishable from a clean sweep.
    my $locked = tempdir( CLEANUP => 1 );
    if ( $> == 0 ) {
        pass('_temp_file_candidates unreadable-directory branch is skipped under root');
    }
    else {
        chmod 0100, $locked or die "Unable to chmod $locked: $!";
        my $error = '';
        eval {
            no warnings qw(redefine once);
            local *File::Spec::tmpdir = sub { return $locked };
            $keeper->_temp_file_candidates;
            1;
        } or $error = $@;
        chmod 0700, $locked or die "Unable to restore $locked: $!";
        like( $error, qr/Unable to read temp directory/, '_temp_file_candidates dies rather than reporting an empty scan when the temp directory cannot be listed' );
    }
}

# _is_inside($root, $path)
# Reports whether one candidate path is a direct entry of the given directory.
# Input: directory path string and candidate path string.
# Output: boolean true when the candidate's parent directory is that directory.
sub _is_inside {
    my ( $root, $path ) = @_;
    return 0 if !defined $path || $path eq '';
    return 0 if !File::Spec->file_name_is_absolute($path);
    my ( $volume, $directories ) = File::Spec->splitpath($path);
    my $parent = File::Spec->catpath( $volume, $directories, '' );
    $parent =~ s{[/\\]\z}{};
    my $wanted = $root;
    $wanted =~ s{[/\\]\z}{};
    return $parent eq $wanted ? 1 : 0;
}

# ---------------------------------------------------------------------------
# Anti-drift guard on the mechanism itself.
#
# Every assertion above is about observable behaviour, and behaviour assertions
# cannot see a rewrite that reintroduces the defect on a path they happen not to
# exercise. That is not a hypothetical: this is exactly how the defect survived
# in the first place, because the pre-existing housekeeper coverage was green
# while only ever building space-free temp directories. So the mechanism is
# pinned directly -- a future rewrite that goes back to expanding a pattern
# fails here rather than failing an operator whose temp path contains a space.
#
# POD and comments are stripped before the check, because both deliberately
# discuss the glob that must not come back.
# ---------------------------------------------------------------------------
{
    my $code = $HOUSEKEEPER_SOURCE;
    $code =~ s/^__END__.*\z//ms;    # the POD names glob on purpose
    $code =~ s/#[^\n]*$//mg;        # so do the explanatory comments

    unlike( $code, qr/\bglob\b/, 'no shell-glob expansion remains anywhere in the Housekeeper implementation' );
    like(
        $HOUSEKEEPER_SOURCE,
        qr/opendir\s+my\s+\$dh,\s*\$tmpdir/,
        'the temp directory is enumerated with opendir rather than an expanded pattern'
    );
}

done_testing();

__END__

=head1 NAME

t/147-housekeeper-temp-path-whitespace.t - housekeeper temp-file candidates must
be a listing of the temp directory, not a shell glob

=head1 DESCRIPTION

This file pins the contract that
C<Developer::Dashboard::Housekeeper::_temp_file_candidates> enumerates the
system temp directory itself rather than expanding a shell-glob pattern built
from its path.

Perl's built-in C<glob> is C<csh_glob>: it splits its argument on whitespace and
treats each fragment as an independent pattern, and it honours backslash
escapes. A temp directory whose path contains a space therefore produced two
patterns, neither of them the intended one. The first fragment matched nothing,
so the genuine dashboard-owned temp files were never reclaimed and the cleanup
service reported success while doing nothing. The second fragment was relative,
so it was resolved against the housekeeper process's current working directory,
and because the temp-file classifier matches on the basename alone, any file
below that directory whose name carried a dashboard temp prefix was accepted as
dashboard-owned and unlinked.

Both halves are asserted directly: the genuine files inside a spaced temp
directory must be reclaimed, and decoy files planted at exactly the paths the
trailing fragment resolves to must survive. A backslash-bearing directory name
is covered for the same reason, because that is the shape a Windows temp path
takes. The final blocks are regression guards holding the pre-existing
space-free behaviour and the empty/missing directory outcomes unchanged, so a
future rewrite cannot trade one correctness property for another.

A last block pins the mechanism rather than the behaviour, asserting that no
shell-glob expansion remains in the implementation and that the temp directory
is enumerated with C<opendir>. That guard exists because behaviour assertions
cannot see a rewrite that reintroduces the defect on a path they do not happen
to exercise, which is precisely how this defect survived: the pre-existing
housekeeper coverage measured green while only ever building space-free temp
directories.

=head1 PURPOSE

This file's purpose is to hold the housekeeper's temp-file discovery to two
properties that the temp path itself must never be able to break: every
candidate it proposes is an entry of the system temp directory, and every
dashboard-owned temp file in that directory is actually found. It asserts those
properties against temp paths containing a space and a backslash, keeps the
plain space-free behaviour pinned as a regression guard, and separates an empty
temp directory from one that could not be listed at all.

=head1 WHY IT EXISTS

The pre-existing housekeeper coverage only ever built space-free temp
directories, so an entire class of platform-dependent failure measured green.
This file exists so the temp path itself is treated as data.

=head1 WHEN TO USE

Run this file when changing how the housekeeper discovers, classifies, or
removes dashboard-owned temp files, or when changing the temp-file naming
prefixes.

=head1 HOW TO USE

  PERL5LIB="$HOME/perl5/lib/perl5" prove -lv t/147-housekeeper-temp-path-whitespace.t

=head1 WHAT USES IT

The repository test suite runs it as part of C<prove -lr t> and under the
Devel::Cover all-metric coverage gate.

=head1 EXAMPLES

Example 1:

  PERL5LIB="$HOME/perl5/lib/perl5" prove -lv t/147-housekeeper-temp-path-whitespace.t

Run this file alone with verbose output while changing the housekeeper.

Example 2:

  PERL5LIB="$HOME/perl5/lib/perl5" prove -lv t/77-housekeeper-coverage.t t/147-housekeeper-temp-path-whitespace.t

Run it beside the broader housekeeper coverage file, which owns the rest of the
service's behaviour.

Example 3:

  PERL5LIB="$HOME/perl5/lib/perl5" prove -lr t

Put the whole suite back through the default correctness gate.

Example 4:

  PERL5LIB="$HOME/perl5/lib/perl5" HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lr t

Recheck the change under the repository coverage gate.

=cut
