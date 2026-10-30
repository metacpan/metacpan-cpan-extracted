#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Test::More;
use File::Temp qw(tempdir);
use File::Spec;
use Cwd qw(abs_path getcwd);

use Developer::Dashboard::PathIdentity qw(_path_identity _same_or_descendant_path current_working_directory);

my $tmp = tempdir( CLEANUP => 1 );

# --- matching physical PWD uses one direct getcwd result --------------------
{
    my $physical = getcwd();
    my $original_getcwd = \&Developer::Dashboard::PathIdentity::getcwd;
    local $ENV{PWD} = $physical;
    my $getcwd_calls = 0;
    my $identity_checks = 0;
    {
        no warnings 'redefine';
        local *Developer::Dashboard::PathIdentity::getcwd = sub {
            $getcwd_calls++;
            return $original_getcwd->();
        };
        local *Developer::Dashboard::PathIdentity::_same_directory_identity = sub {
            $identity_checks++;
            return 0;
        };
        is( current_working_directory(), $physical,
            'current_working_directory returns the matching physical path' );
    }
    is( $getcwd_calls, 1, 'current_working_directory uses one native getcwd call on the common path' );
    is( $identity_checks, 0, 'matching PWD bypasses the logical-symlink identity check' );
}

# --- invalid PWD values fall back to the live Cwd lookup ---------------------
for my $invalid_pwd ( 'relative/path', File::Spec->catdir( $tmp, 'missing-pwd' ) ) {
    my $physical = getcwd();
    my $original_getcwd = \&Developer::Dashboard::PathIdentity::getcwd;
    local $ENV{PWD} = $invalid_pwd;
    my $getcwd_calls = 0;
    {
        no warnings 'redefine';
        local *Developer::Dashboard::PathIdentity::getcwd = sub {
            $getcwd_calls++;
            return $original_getcwd->();
        };
        is( current_working_directory(), $physical,
            'an invalid PWD falls back to the process working directory' );
    }
    is( $getcwd_calls, 1, 'an invalid PWD performs one live getcwd lookup' );
}

# --- a valid logical symlink PWD keeps its logical spelling ------------------
{
    my $physical = getcwd();
    my $target   = File::Spec->catdir( $tmp, 'cwd-target' );
    my $logical  = File::Spec->catdir( $tmp, 'cwd-logical' );
    mkdir $target or die "Unable to create cwd target $target: $!";
    if ( symlink $target, $logical ) {
        chdir $target or die "Unable to chdir to cwd target $target: $!";
        local $ENV{PWD} = $logical;
        is( current_working_directory(), $logical,
            'a device/inode-verified logical PWD preserves its symlink spelling' );
        chdir $physical or die "Unable to restore working directory $physical: $!";
    }
    else {
        pass('logical PWD symlink preservation is unavailable on this platform');
    }
}

# --- undef/empty path input returns '' regardless of empty_fallback ------------
{
    is( _path_identity( undef, empty_fallback => 1 ), '', '_path_identity(undef, empty_fallback=>1) returns empty string' );
    is( _path_identity( undef, empty_fallback => 0 ), '', '_path_identity(undef, empty_fallback=>0) returns empty string' );
    is( _path_identity( '',    empty_fallback => 1 ), '', '_path_identity("", empty_fallback=>1) returns empty string' );
    is( _path_identity( '',    empty_fallback => 0 ), '', '_path_identity("", empty_fallback=>0) returns empty string' );
}

# --- empty_fallback is required, no default -------------------------------------
{
    eval { _path_identity($tmp) };
    like( $@, qr/empty_fallback/, '_path_identity dies without an explicit empty_fallback parameter' );
}

# --- a real, existing path resolves to its abs_path() form under both modes -----
{
    my $resolved = abs_path($tmp);
    is( _path_identity( $tmp, empty_fallback => 1 ), $resolved, '_path_identity resolves a real existing path (empty_fallback=>1)' );
    is( _path_identity( $tmp, empty_fallback => 0 ), $resolved, '_path_identity resolves a real existing path (empty_fallback=>0)' );
}

# --- a nonexistent path falls back to File::Spec->canonpath under both modes ----
{
    my $nonexistent = File::Spec->catdir( $tmp, 'does-not-exist-at-all' );
    my $canon       = File::Spec->canonpath($nonexistent);
    is( _path_identity( $nonexistent, empty_fallback => 1 ), $canon, '_path_identity falls back to canonpath for a nonexistent path (empty_fallback=>1, undef abs_path)' );
    is( _path_identity( $nonexistent, empty_fallback => 0 ), $canon, '_path_identity falls back to canonpath for a nonexistent path (empty_fallback=>0, undef abs_path)' );
}

# --- the abs_path()-returns-empty-string edge case: THIS is where the two ------
# --- historical implementations genuinely diverged, and empty_fallback picks --
# --- which behavior a caller wants. -------------------------------------------
{
    no warnings 'redefine';
    local *Developer::Dashboard::PathIdentity::abs_path = sub { return '' };

    my $path  = File::Spec->catdir( $tmp, 'anything' );
    my $canon = File::Spec->canonpath($path);

    is( _path_identity( $path, empty_fallback => 1 ), $canon, 'empty_fallback=>1 falls back to canonpath when abs_path() returns empty string (PathRegistry.pm historical behavior)' );
    is( _path_identity( $path, empty_fallback => 0 ), '', 'empty_fallback=>0 returns the empty string as-is when abs_path() returns empty string (EnvLoader.pm historical behavior)' );
}

{
    no warnings 'redefine';
    local *Developer::Dashboard::PathIdentity::abs_path = sub { return undef };

    my $path  = File::Spec->catdir( $tmp, 'unresolved' );
    my $canon = File::Spec->canonpath($path);

    is( _path_identity( $path, empty_fallback => 1 ), $canon,
        'empty_fallback=>1 uses canonpath when abs_path() returns undef' );
    is( _path_identity( $path, empty_fallback => 0 ), $canon,
        'empty_fallback=>0 uses canonpath when abs_path() returns undef' );
}

# --- _same_or_descendant_path: undef/empty inputs are always false -------------
{
    is( _same_or_descendant_path( undef, $tmp, empty_fallback => 1 ), 0, '_same_or_descendant_path(undef, root) is false' );
    is( _same_or_descendant_path( $tmp, undef, empty_fallback => 1 ), 0, '_same_or_descendant_path(path, undef) is false' );
    is( _same_or_descendant_path( '', $tmp,    empty_fallback => 1 ), 0, '_same_or_descendant_path("", root) is false' );
    is( _same_or_descendant_path( $tmp, '',    empty_fallback => 1 ), 0, '_same_or_descendant_path(path, "") is false' );
}

# --- _same_or_descendant_path: identical paths are "same" ----------------------
{
    is( _same_or_descendant_path( $tmp, $tmp, empty_fallback => 1 ), 1, '_same_or_descendant_path returns true for identical paths' );
}

# --- identical path strings need no filesystem canonicalization ---------------
{
    my $calls = 0;
    no warnings 'redefine';
    local *Developer::Dashboard::PathIdentity::abs_path = sub {
        $calls++;
        return '/canonical/path';
    };

    is( _same_or_descendant_path( '/same/path', '/same/path', empty_fallback => 1 ), 1,
        '_same_or_descendant_path accepts identical path strings' );
    is( $calls, 0, '_same_or_descendant_path skips canonicalization for identical path strings' );
}

# --- distinct strings resolving to the same directory remain equivalent -----
{
    my $trailing_separator = $tmp . File::Spec->rootdir();
    isnt( $trailing_separator, $tmp, 'the canonical-identity fixture uses a distinct path spelling' );
    is( _same_or_descendant_path( $trailing_separator, $tmp, empty_fallback => 1 ), 1,
        '_same_or_descendant_path recognizes distinct strings with the same canonical identity' );
}

# --- _same_or_descendant_path: a real child directory is a descendant ----------
{
    my $child = File::Spec->catdir( $tmp, 'child' );
    mkdir $child or die "mkdir $child: $!";
    is( _same_or_descendant_path( $child, $tmp, empty_fallback => 1 ), 1, '_same_or_descendant_path returns true for a real descendant path' );
    is( _same_or_descendant_path( $tmp, $child, empty_fallback => 1 ), 0, '_same_or_descendant_path returns false when path and root are swapped (parent is not a descendant of its child)' );
}

# --- _same_or_descendant_path: an unrelated path is not a descendant -----------
{
    my $other = tempdir( CLEANUP => 1 );
    is( _same_or_descendant_path( $other, $tmp, empty_fallback => 1 ), 0, '_same_or_descendant_path returns false for an unrelated path' );
}

# --- already-normalized identity comparisons used by multi-root scans --------
{
    my $child = File::Spec->catdir( $tmp, 'identity-child' );
    my $sibling = File::Spec->catdir( $tmp, 'identity-sibling' );
    is( Developer::Dashboard::PathIdentity::_same_or_descendant_identity( undef, $tmp ), 0,
        'identity comparison rejects an undefined candidate' );
    is( Developer::Dashboard::PathIdentity::_same_or_descendant_identity( '', $tmp ), 0,
        'identity comparison rejects an empty candidate' );
    is( Developer::Dashboard::PathIdentity::_same_or_descendant_identity( $tmp, undef ), 0,
        'identity comparison rejects an undefined root' );
    is( Developer::Dashboard::PathIdentity::_same_or_descendant_identity( $tmp, '' ), 0,
        'identity comparison rejects an empty root' );
    is( Developer::Dashboard::PathIdentity::_same_or_descendant_identity( $tmp, $tmp ), 1,
        'identity comparison accepts an exact match' );
    is( Developer::Dashboard::PathIdentity::_same_or_descendant_identity( $child, $tmp ), 1,
        'identity comparison accepts a child at a path boundary' );
    is( Developer::Dashboard::PathIdentity::_same_or_descendant_identity( $sibling, $tmp . '-other' ), 0,
        'identity comparison rejects a textual prefix that is not a child path' );
    my $win_separator = '\\';
    ok(
        Developer::Dashboard::PathIdentity::_same_or_descendant_identity(
            'C:\\Users\\Alice\\project', 'C:\\Users\\Alice',
            separator => $win_separator, case_tolerant => 1,
        ),
        'identity comparison recognizes a Win32 child path at a backslash boundary'
    );
    ok(
        Developer::Dashboard::PathIdentity::_same_or_descendant_identity(
            'c:\\users\\alice\\project', 'C:\\Users\\Alice',
            separator => $win_separator, case_tolerant => 1,
        ),
        'identity comparison honors case-tolerant Windows path volumes'
    );
    ok(
        Developer::Dashboard::PathIdentity::_same_or_descendant_identity(
            'C:\\Users\\Alice', 'C:\\',
            separator => $win_separator, case_tolerant => 1,
        ),
        'identity comparison handles a drive-root separator without duplicating it'
    );
    is(
        Developer::Dashboard::PathIdentity::_same_or_descendant_identity(
            'C:\\Users\\Alicia', 'C:\\Users\\Alice',
            separator => $win_separator, case_tolerant => 1,
        ),
        0,
        'identity comparison rejects a Windows textual prefix without a separator boundary'
    );
    is(
        Developer::Dashboard::PathIdentity::_same_or_descendant_identity(
            'c:\\users\\alice', 'C:\\Users\\Alice',
            separator => $win_separator, case_tolerant => 0,
        ),
        0,
        'identity comparison preserves case-sensitive semantics when requested'
    );
    eval {
        Developer::Dashboard::PathIdentity::_same_or_descendant_identity(
            'C:\\Users\\Alice', 'C:\\Users', separator => '',
        );
    };
    like( $@, qr/separator must be a nonempty string/,
        'identity comparison rejects an invalid path separator' );
    ok(
        Developer::Dashboard::PathIdentity::_same_or_descendant_identity(
            '/root/path/project', '/root/path',
            separator => undef, case_tolerant => 0,
        ),
        'identity comparison uses the active platform separator for an undefined override'
    );
    eval {
        Developer::Dashboard::PathIdentity::_same_or_descendant_identity(
            'C:\\Users\\Alice', 'C:\\Users', separator => [],
        );
    };
    like( $@, qr/separator must be a nonempty string/,
        'identity comparison rejects a reference separator' );
    my $tested_volume;
    {
        no warnings qw(redefine once);
        local *File::Spec::splitpath = sub { return ( 'D:', '', '' ) };
        local *File::Spec::case_tolerant = sub {
            $tested_volume = $_[1];
            return 1;
        };
        ok(
            Developer::Dashboard::PathIdentity::_same_or_descendant_identity(
                'd:\\workspace\\child', 'D:\\workspace', separator => $win_separator,
            ),
            'identity comparison delegates case handling to File::Spec for the root volume'
        );
    }
    is( $tested_volume, 'D:', 'case-tolerance lookup receives the root drive instead of a fixed default volume' );
}

# --- _same_or_descendant_path requires an explicit empty_fallback too ----------
{
    eval { _same_or_descendant_path( $tmp, $tmp ) };
    like( $@, qr/empty_fallback/, '_same_or_descendant_path dies without an explicit empty_fallback parameter' );
}

done_testing();

__END__

=head1 NAME

t/195-pathidentity-coverage.t - full-coverage test for Developer::Dashboard::PathIdentity

=head1 PURPOSE

Exercises C<Developer::Dashboard::PathIdentity>'s C<_path_identity>,
C<_same_or_descendant_path>, C<current_working_directory>, and internal
already-normalized identity comparison under both C<empty_fallback> modes,
and every edge case that previously distinguished C<PathRegistry.pm>'s and
C<EnvLoader.pm>'s own private copies (undef/empty input, a real existing
path, a nonexistent path, and the abs_path()-returns-empty-string case). It
also checks the one-native-C<getcwd> common path, logical symlink preservation,
fallback for stale or relative C<PWD> values, and Windows backslash,
case-tolerance, drive-root, and component-boundary comparisons.

=head1 WHY IT EXISTS

DD-903 extracted this pair out of C<PathRegistry.pm> and C<EnvLoader.pm>'s
own private, slightly-diverging copies. This file is the coverage gate for
the extraction itself, so the shared functions carry their own 100% rather
than relying on the two callers' coverage to exercise them indirectly.

=head1 WHEN TO USE

Run whenever C<PathIdentity.pm> changes.

=head1 HOW TO USE

  PERL5LIB="$HOME/perl5/lib/perl5" prove -lv t/195-pathidentity-coverage.t

=head1 WHAT USES IT

Nothing else calls this file; it is invoked by C<prove> directly or as
part of the full suite.

=head1 EXAMPLES

Example 1:

  _path_identity( '/tmp/does-not-exist', empty_fallback => 1 )

Returns C<File::Spec-E<gt>canonpath('/tmp/does-not-exist')> since the path
does not exist and C<abs_path()> returns undef.

Example 2:

  _same_or_descendant_path( '/home/me/project/sub', '/home/me/project', empty_fallback => 0 )

Returns C<1> (true).

Example 3:

  current_working_directory()

Returns the physical cwd for a matching absolute C<PWD>; a distinct absolute
C<PWD> is returned only after device/inode verification.

=cut
