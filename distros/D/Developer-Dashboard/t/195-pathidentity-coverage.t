#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Test::More;
use File::Temp qw(tempdir);
use File::Spec;
use Cwd qw(abs_path);

use Developer::Dashboard::PathIdentity qw(_path_identity _same_or_descendant_path);

my $tmp = tempdir( CLEANUP => 1 );

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

Exercises C<Developer::Dashboard::PathIdentity>'s C<_path_identity> and
C<_same_or_descendant_path> under both C<empty_fallback> modes, and every
edge case that previously distinguished C<PathRegistry.pm>'s and
C<EnvLoader.pm>'s own private copies (undef/empty input, a real existing
path, a nonexistent path, and the abs_path()-returns-empty-string case).

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

=cut
