package File::DistDir;

use strict;
use warnings;

use Cwd qw(abs_path getcwd);
use English qw(-no_match_vars);
use File::Basename qw(basename dirname);
use File::Copy ();
use File::Path qw(make_path);
use File::ShareDir qw(dist_dir);
use File::Spec;

our $VERSION = '1.0.0';

########################################################################
sub new {
########################################################################
  my ( $class, %args ) = @_;

  my $distribution = $args{distribution};

  die "ERROR: distribution is required\n"
    if !defined $distribution || !length $distribution;

  my $root = abs_path( dist_dir($distribution) );

  die sprintf "ERROR: distribution share directory not found: %s\n", $distribution
    if !defined $root || !-d $root;

  return bless {
    distribution => $distribution,
    dir          => $root,
  }, $class;
}

########################################################################
sub dir {
########################################################################
  my ($self) = @_;
  return $self->{dir};
}

########################################################################
sub path {
########################################################################
  my ( $self, $relative ) = @_;

  $relative //= q{.};

  die "ERROR: source must be relative to the distribution directory\n"
    if File::Spec->file_name_is_absolute($relative);

  my $root      = $self->dir;
  my $candidate = File::Spec->catfile( $root, $relative );
  my $resolved  = abs_path($candidate);

  die sprintf "ERROR: source not found: %s\n", $relative
    if !defined $resolved;

  die sprintf "ERROR: source is outside distribution directory: %s\n", $relative
    if $resolved ne $root && index( $resolved, $root . q{/} ) != 0;

  return $resolved;
}

########################################################################
sub copy {
########################################################################
  my ( $self, $source, $destination, %options ) = @_;

  die "ERROR: copy requires a source\n"
    if !defined $source;

  die "ERROR: destination is required for file copying\n"
    if !defined $destination && $source ne q{.};

  $destination //= q{.};

  my $source_path = File::Spec->catfile( $self->dir, $source );
  _reject_symlink_components($source_path);

  my $resolved = $self->path($source);
  _reject_symlink_components($destination);

  if ( -d $resolved ) {
    die "ERROR: copying directories requires recursive => 1\n"
      if !$options{recursive};

    die sprintf "ERROR: destination is not a directory: %s\n", $destination
      if -e $destination && !-d $destination;

    my $dest_abs      = File::Spec->rel2abs($destination);
    my $dest_existing = abs_path($destination);
    if ( defined $dest_existing ) {
      $dest_abs = $dest_existing;
    }

    die sprintf "ERROR: destination is inside source directory: %s\n", $destination
      if $dest_abs eq $resolved || index( $dest_abs, $resolved . q{/} ) == 0;

    make_path($destination)
      if !-d $destination;

    _copy_directory_contents( $resolved, $destination );
    return 1;
  }

  die sprintf "ERROR: source is not a regular file: %s\n", $source
    if !-f $resolved;

  if ( -d $destination ) {
    $destination = File::Spec->catfile( $destination, basename($source) );
  }

  die sprintf "ERROR: destination directory does not exist: %s\n", dirname($destination)
    if !-d dirname($destination);

  die sprintf "ERROR: unable to copy %s => %s: %s\n", $resolved, $destination, $OS_ERROR
    if !File::Copy::copy( $resolved, $destination );

  return 1;
}

########################################################################
sub list {
########################################################################
  my ($self) = @_;

  my @files;
  _collect_entries( $self->dir, q{}, \@files );

  return @files;
}

########################################################################
sub _collect_entries {
########################################################################
  my ( $root, $prefix, $result ) = @_;

  opendir my $dh, $root
    or die sprintf "ERROR: cannot open directory %s: %s\n", $root, $OS_ERROR;

  my @entries = sort grep { $_ ne q{.} && $_ ne q{..} } readdir $dh;
  closedir $dh;

  foreach my $entry (@entries) {
    my $relative = length $prefix ? File::Spec->catfile( $prefix, $entry ) : $entry;
    my $full     = File::Spec->catfile( $root, $entry );

    push @{$result}, $relative;

    if ( -d $full && !-l $full ) {
      _collect_entries( $full, $relative, $result );
    }
  }

  return;
}

########################################################################
sub _reject_symlink_components {
########################################################################
  my ($path) = @_;

  # Preserve explicit .. components while inspecting the actual path walked
  # by the filesystem. rel2abs() would normalize them prematurely.
  my $absolute
    = File::Spec->file_name_is_absolute($path)
    ? $path
    : File::Spec->catfile( getcwd(), $path );
  my $current = File::Spec->rootdir;

  foreach my $part ( File::Spec->splitdir($absolute) ) {
    next if !length $part || $part eq q{.};

    $current = File::Spec->catdir( $current, $part );

    die sprintf "ERROR: symbolic links are not supported: %s\n", $current
      if -l $current;
  }

  return;
}

########################################################################
sub _copy_directory_contents {
########################################################################
  my ( $source, $destination ) = @_;

  opendir my $dh, $source
    or die sprintf "ERROR: cannot open directory %s: %s\n", $source, $OS_ERROR;

  my @entries = grep { $_ ne q{.} && $_ ne q{..} } readdir $dh;
  closedir $dh;

  foreach my $entry (@entries) {
    my $from = File::Spec->catfile( $source,      $entry );
    my $to   = File::Spec->catfile( $destination, $entry );

    _reject_symlink_components($to);

    die sprintf "ERROR: symbolic links are not supported: %s\n", $from
      if -l $from;

    if ( -d $from ) {
      die sprintf "ERROR: destination is not a directory: %s\n", $to
        if -e $to && !-d $to;

      make_path($to)
        if !-d $to;

      _copy_directory_contents( $from, $to );
      next;
    }

    die sprintf "ERROR: unsupported resource type: %s\n", $from
      if !-f $from;

    die sprintf "ERROR: unable to copy %s => %s: %s\n", $from, $to, $OS_ERROR
      if !File::Copy::copy( $from, $to );
  }

  return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

File::DistDir - locate and copy installed Perl distribution resources

=head1 SYNOPSIS

  use File::DistDir;

  my $dist = File::DistDir->new( distribution => 'Bedrock' );

  my $root = $dist->dir;
  my $file = $dist->path('config/tagx.xml');

  $dist->copy('config/tagx.xml', './config/tagx.xml');
  $dist->copy('config', './config', recursive => 1);
  $dist->copy('.', '.', recursive => 1);

  my @resources = $dist->list;

=head1 DESCRIPTION

C<File::DistDir> provides an object-oriented interface to the resources
installed in a distribution's share directory. Resource discovery uses
L<File::ShareDir>. The C<dist-dir> command is provided by
L<File::DistDir::CLI> in the same distribution.

=head1 METHODS

=head2 new(distribution => NAME)

Create an accessor for an installed distribution. C<NAME> is the
CPAN distribution name, not a Perl package name. A missing distribution
or share directory causes an exception.

=head2 dir

Return the absolute path to the installed share directory.

=head2 path(RELATIVE)

Resolve an existing resource path relative to the share directory.
Absolute source paths and paths resolving outside the share directory
are rejected. This method does not copy anything.

=head2 copy(SOURCE, DESTINATION, recursive => 1)

Copy a resource. For a file, C<DESTINATION> is required. An existing
destination directory receives the source basename; otherwise the parent
of the destination filename must already exist.

For directories, specify C<recursive =E<gt> 1>. The B<contents> of the
source directory are copied into C<DESTINATION>, which is created if
necessary. For C<copy('.', '.', recursive =E<gt> 1)>, the destination
may be omitted. Existing files are overwritten.

Sources outside the share directory are rejected. Copies reject
symbolic links in source or destination paths, including intermediate
path components. Recursive copies also reject non-file resources; this method does not copy
file permissions or provide atomic multi-file transactions. A failed
copy may leave a partially populated destination.

Returns a true value on success; failures throw exceptions.

=head2 list

Return a sorted list of paths relative to the share root, including
directory entries. Symlinked directories are listed but not traversed.
Paths are returned as data and are not printed.

=head1 SEE ALSO

L<File::DistDir::CLI>, L<File::ShareDir>

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. See
https://dev.perl.org/licenses/ for more information.

=head1 AUTHOR

Rob Lauer - <rlauer@treasurersbriefcase.com>

=cut
