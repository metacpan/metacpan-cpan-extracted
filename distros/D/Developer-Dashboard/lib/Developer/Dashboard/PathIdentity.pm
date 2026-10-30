package Developer::Dashboard::PathIdentity;

use strict;
use warnings;

our $VERSION = '6.06';

use Exporter 'import';
use Cwd qw(abs_path cwd getcwd);
use File::Spec;

our @EXPORT_OK = qw(_path_identity _same_or_descendant_path current_working_directory);

# current_working_directory()
# Uses native getcwd for the common physical-PWD case, verifies distinct
# absolute PWD values by device/inode to preserve logical symlinks, then falls
# back to Cwd::cwd if getcwd cannot resolve the process directory.
# Input: none; reads PWD only as an untrusted candidate.
# Output: verified logical absolute path, physical cwd, or Cwd::cwd fallback.
sub current_working_directory {
    my $physical = eval { getcwd() };
    if ( defined $physical && $physical ne '' ) {
        my $logical = $ENV{PWD};
        return $physical if defined $logical && $logical eq $physical;

        if ( defined $logical && $logical ne '' && File::Spec->file_name_is_absolute($logical) ) {
            my @logical_stat  = stat $logical;
            my @current_stat = stat q{.};
            return $logical if _same_directory_identity( \@logical_stat, \@current_stat );
        }

        return $physical;
    }

    return cwd();
}

# _same_directory_identity($candidate_stat, $current_stat)
# Compares device and inode fields returned by stat, rejecting failed stats
# and the all-zero sentinel.
# Input: references to stat-result arrays, each containing device and inode.
# Output: boolean true when both arrays identify the same nonempty directory.
sub _same_directory_identity {
    my ( $candidate_stat, $current_stat ) = @_;
    return 0 if !@{$candidate_stat} || !@{$current_stat};
    return 0 if $candidate_stat->[0] == 0 && $candidate_stat->[1] == 0;
    return 0 if $candidate_stat->[0] != $current_stat->[0];
    return 0 if $candidate_stat->[1] != $current_stat->[1];
    return 1;
}

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
# Output: boolean; exact string matches return before filesystem resolution.
sub _same_or_descendant_path {
    my ( $path, $root, %args ) = @_;
    return 0 if !defined $path || $path eq '' || !defined $root || $root eq '';

    my $empty_fallback = $args{empty_fallback};
    die "_same_or_descendant_path requires an explicit empty_fallback => 1|0 parameter\n"
        if !defined $empty_fallback;

    return 1 if $path eq $root;

    my $path_id = _path_identity( $path, empty_fallback => $empty_fallback );
    my $root_id = _path_identity( $root, empty_fallback => $empty_fallback );
    return _same_or_descendant_identity( $path_id, $root_id );
}

# _same_or_descendant_identity($path_id, $root_id, %platform_options)
# Compares two already-normalized path identities using the same boundary rule
# as _same_or_descendant_path, allowing callers that scan several roots to
# normalize a shared candidate only once. Optional separator and case_tolerant
# values make the platform rule deterministic in tests; production defaults
# come from File::Spec for the active operating system.
# Input: canonical-or-fallback candidate and root identity strings; optional
# separator => root separator and case_tolerant => boolean.
# Output: boolean true when the identities are equal or the candidate is below
# the root at a path-component boundary.
sub _same_or_descendant_identity {
    my ( $path_id, $root_id, %platform_options ) = @_;
    return 0 if !defined $path_id || $path_id eq '' || !defined $root_id || $root_id eq '';
    my $separator = $platform_options{separator};
    $separator = File::Spec->rootdir if !defined $separator;
    die "Path identity separator must be a nonempty string\n"
      if ref($separator) || $separator eq '';
    my $case_tolerant;
    if ( exists $platform_options{case_tolerant} ) {
        $case_tolerant = $platform_options{case_tolerant};
    }
    else {
        my ($volume) = File::Spec->splitpath($root_id);
        $case_tolerant = $volume ne '' ? File::Spec->case_tolerant($volume) : 0;
    }
    my ( $candidate, $root ) = $case_tolerant ? ( lc($path_id), lc($root_id) ) : ( $path_id, $root_id );
    return 1 if $candidate eq $root;
    my $prefix = $root;
    $prefix .= $separator if substr( $prefix, -length($separator) ) ne $separator;
    return index( $candidate, $prefix ) == 0 ? 1 : 0;
}

1;

__END__

=head1 NAME

Developer::Dashboard::PathIdentity - shared canonical path identity helper

=head1 SYNOPSIS

  use Developer::Dashboard::PathIdentity qw(
      _path_identity _same_or_descendant_path current_working_directory
  );

  my $id = _path_identity( $path, empty_fallback => 1 );
  my $is_descendant = _same_or_descendant_path( $path, $root, empty_fallback => 1 );
  my $cwd = current_working_directory();

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

The internal C<_same_or_descendant_identity> helper compares already-resolved
identities. It is used when one candidate must be checked against several
runtime roots, so the candidate can be canonicalized once while each root
still receives its own filesystem-aware resolution.
Component-boundary matching uses the active C<File::Spec> root separator and
case-sensitivity policy for the root's volume. This is required on Windows,
where canonical paths use backslashes and ordinary volumes are case-tolerant;
the relevant drive is queried rather than assuming C<C:>, and drive roots are
handled without adding a duplicate separator.

=head1 WHAT USES IT

C<Developer::Dashboard::PathRegistry> (via C<empty_fallback =E<gt> 1>) and
C<Developer::Dashboard::EnvLoader> (via C<empty_fallback =E<gt> 0>). The
current-directory helper is used by the switchboard and path and prompt helpers.
It calls native C<Cwd::getcwd> on each lookup. An exact C<PWD> match returns
that physical result immediately; a distinct absolute C<PWD> is accepted only
when device/inode identity matches the process directory, preserving logical
symlinks. Invalid values use the physical path, and C<Cwd::cwd> is the fallback
when C<getcwd> cannot resolve the directory.

=head1 EXAMPLES

  _path_identity( '/var/tmp', empty_fallback => 1 );
  # => '/private/var/tmp' on macOS (a real existing path resolves via abs_path)

  _same_or_descendant_path( '/home/me/project/sub', '/home/me/project', empty_fallback => 0 );
  # => 1 (true)

  current_working_directory();
  # => matching physical $ENV{PWD}, validated logical symlink path, or physical cwd

=cut
