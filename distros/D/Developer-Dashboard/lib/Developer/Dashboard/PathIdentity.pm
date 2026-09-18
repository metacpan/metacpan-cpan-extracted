package Developer::Dashboard::PathIdentity;

use strict;
use warnings;

our $VERSION = '4.45';

use Exporter 'import';
use Cwd qw(abs_path);
use File::Spec;

our @EXPORT_OK = qw(_path_identity _same_or_descendant_path);

# _path_identity($path, empty_fallback => 1|0)
# Normalizes a path for identity and ancestry comparisons without requiring
# the caller to care about symlink aliases such as /var versus /private/var
# on macOS.
# Input: path string, empty_fallback => boolean (required, no default).
# Output: canonical existing path, a stable canonpath string, or ''.
sub _path_identity {
    my ( $path, %args ) = @_;
    return '' if !defined $path || $path eq '';

    my $empty_fallback = $args{empty_fallback};
    die "_path_identity requires an explicit empty_fallback => 1|0 parameter\n"
        if !defined $empty_fallback;

    my $resolved = eval { abs_path($path) };
    if ($empty_fallback) {
        return $resolved if defined $resolved && $resolved ne '';
        return File::Spec->canonpath($path);
    }
    return defined $resolved ? $resolved : File::Spec->canonpath($path);
}

# _same_or_descendant_path($path, $root, empty_fallback => 1|0)
# Checks whether one path is identical to or nested beneath another path
# after canonical normalization.
# Input: candidate path string, root path string, empty_fallback => boolean
# (required, no default).
# Output: boolean.
sub _same_or_descendant_path {
    my ( $path, $root, %args ) = @_;
    return 0 if !defined $path || $path eq '' || !defined $root || $root eq '';

    my $empty_fallback = $args{empty_fallback};
    die "_same_or_descendant_path requires an explicit empty_fallback => 1|0 parameter\n"
        if !defined $empty_fallback;

    my $path_id = _path_identity( $path, empty_fallback => $empty_fallback );
    my $root_id = _path_identity( $root, empty_fallback => $empty_fallback );
    return 1 if $path_id eq $root_id;
    return index( $path_id, $root_id . '/' ) == 0 ? 1 : 0;
}

1;

__END__

=head1 NAME

Developer::Dashboard::PathIdentity - shared canonical path identity helper

=head1 SYNOPSIS

  use Developer::Dashboard::PathIdentity qw(_path_identity _same_or_descendant_path);

  my $id = _path_identity( $path, empty_fallback => 1 );
  my $is_descendant = _same_or_descendant_path( $path, $root, empty_fallback => 1 );

=head1 DESCRIPTION

Provides C<_path_identity> and C<_same_or_descendant_path>, the single home
for a path-normalization pair that used to be written out twice, once in
C<Developer::Dashboard::PathRegistry> (as instance methods) and once in
C<Developer::Dashboard::EnvLoader> (as class methods) (DD-903) - the same
"small helper reimplemented per file instead of shared" pattern this
project already fixed in C<Developer::Dashboard::DirEntries> (DD-762),
C<Developer::Dashboard::TextUtils> (DD-891), C<Developer::Dashboard::TimeUtils>
(DD-894), and C<Developer::Dashboard::IsoTimestamp> (DD-904).

=head1 PURPOSE

Give every module that needs to compare filesystem paths for identity or
ancestry one canonical implementation to call, in either of the two edge-case
behaviors this project's two former copies actually used, rather than each
maintaining its own private copy that can silently drift.

=head1 WHY IT EXISTS

C<PathRegistry.pm>'s C<_path_identity> and C<EnvLoader.pm>'s C<_path_identity>
were nearly byte-identical, differing only in invocation style ($self vs
$class) - except for one genuine behavioral divergence: when
C<Cwd::abs_path()> returns an empty string (as opposed to C<undef>) for a
path, C<PathRegistry.pm>'s version falls back to
C<File::Spec-E<gt>canonpath($path)>, while C<EnvLoader.pm>'s version returns
the empty string as-is. Both versions already agreed on the C<undef> case
(both fall back to C<canonpath>).

Rather than silently pick one behavior and risk changing the other file's
real (if rare) semantics, this module takes an explicit
C<empty_fallback =E<gt> 1|0> parameter with no default, mirroring this
project's C<TimeUtils.pm> C<tz> and C<IsoTimestamp.pm> C<on_error>
precedent: C<empty_fallback =E<gt> 1> reproduces C<PathRegistry.pm>'s
historical behavior, C<empty_fallback =E<gt> 0> reproduces C<EnvLoader.pm>'s.

=head1 WHEN TO USE

Whenever code needs to compare two filesystem paths for identity or
ancestry across possible symlink aliases (e.g. C</var> vs C</private/var>
on macOS), rather than comparing raw path strings.

=head1 HOW TO USE

  use Developer::Dashboard::PathIdentity qw(_path_identity _same_or_descendant_path);

  my $id = _path_identity( $path, empty_fallback => 1 );
  if ( _same_or_descendant_path( $candidate, $root, empty_fallback => 1 ) ) {
      ...
  }

Both functions require C<empty_fallback> to be passed explicitly; there is
no default, so a caller cannot silently inherit the wrong edge-case
behavior for its own historical call sites.

=head1 WHAT USES IT

C<Developer::Dashboard::PathRegistry> (via C<empty_fallback =E<gt> 1>) and
C<Developer::Dashboard::EnvLoader> (via C<empty_fallback =E<gt> 0>).

=head1 EXAMPLES

  _path_identity( '/var/tmp', empty_fallback => 1 );
  # => '/private/var/tmp' on macOS (a real existing path resolves via abs_path)

  _same_or_descendant_path( '/home/me/project/sub', '/home/me/project', empty_fallback => 0 );
  # => 1 (true)

=cut
