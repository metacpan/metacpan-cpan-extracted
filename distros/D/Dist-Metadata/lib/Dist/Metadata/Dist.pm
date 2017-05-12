#
# This file is part of Dist-Metadata
#
# This software is copyright (c) 2011 by Randy Stauner.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use strict;
use warnings;

package Dist::Metadata::Dist;
our $AUTHORITY = 'cpan:RWSTAUNER';
# ABSTRACT: Base class for format-specific implementations
$Dist::Metadata::Dist::VERSION = '0.927';
use Carp qw(croak carp);     # core
use CPAN::DistnameInfo 0.12 ();
use Path::Class 0.24 ();
use Try::Tiny 0.09;


sub new {
  my $class = shift;
  my $self  = {
    @_ == 1 ? %{ $_[0] } : @_
  };

  bless $self, $class;

  my $req = $class->required_attribute;
  croak qq['$req' parameter required]
    if $req && !$self->{$req};

  if ( exists $self->{file_spec} ) {
    # we just want the OS name ('Unix' or '')
    $self->{file_spec} =~ s/^File::Spec(::)?//
      if $self->{file_spec};
    # blank is no good, use "Native" hack
    $self->{file_spec} = 'Native'
      if !$self->{file_spec};
  }

  return $self;
}


sub default_file_spec { 'Native' }


sub determine_name_and_version {
  my ($self) = @_;
  $self->set_name_and_version( $self->parse_name_and_version( $self->root ) );
  return;
}


sub determine_packages {
  my ($self, @files) = @_;

  my $determined = try {
    my @dir_and_files = $self->physical_directory(@files);

    # return
    $self->packages_from_directory(@dir_and_files);
  }
  catch {
    carp("Error determining packages: $_[0]");
    +{}; # return
  };

  return $determined;
}


sub extract_into {
  my ($self, $dir, @files) = @_;

  @files = $self->list_files
    unless @files;

  require File::Basename;

  my @disk_files;
  foreach my $file (@files) {
    my $ff = $self->path_class_file->new_foreign( $self->file_spec, $file );
    # Translate dist format (relative path) to disk/OS format and prepend $dir.
    # This dir_list + basename hack is probably ok because the paths in a dist
    # should always be relative (if there *was* a volume we wouldn't want it).
    my $path = $self->path_class_file
      ->new( $dir, $ff->dir->dir_list, $ff->basename );

    $path->dir->mkpath(0, oct(700));

    my $full_path = $path->stringify;
    open(my $fh, '>', $full_path)
      or croak "Failed to open '$full_path' for writing: $!";
    print $fh $self->file_content($file);

    # do we really want full path or do we want relative?
    push(@disk_files, $full_path);
  }

  return (wantarray ? ($dir, @disk_files) : $dir);
}


sub file_content {
  croak q[Method 'file_content' not defined];
}


sub file_checksum {
  my ($self, $file, $type) = @_;
  $type ||= 'md5';

  require Digest; # core

  # md5 => MD5, sha256 => SHA-256
  (my $impl = uc $type) =~ s/^(SHA|CRC)([0-9]+)$/$1-$2/;

  my $digest = Digest->new($impl);

  $digest->add( $self->file_content($file) );
  return $digest->hexdigest;
}


sub find_files {
  croak q[Method 'find_files' not defined];
}


sub file_spec {
  my ($self) = @_;

  $self->{file_spec} = $self->default_file_spec
    if !exists $self->{file_spec};

  return $self->{file_spec};
}


sub full_path {
  my ($self, $file) = @_;

  return $file
    unless my $root = $self->root;

  # don't re-add the root if it's already there
  return $file
    # FIXME: this regexp is probably not cross-platform...
    # FIXME: is there a way to do this with File::Spec?
    if $file =~ m@^\Q${root}\E[\\/]@;

  # FIXME: does this foreign_file work w/ Dir ?
  return $self->path_class_file
    ->new_foreign($self->file_spec, $root, $file)->stringify;
}


sub list_files {
  my ($self) = @_;

  $self->{_list_files} = do {
    my @files = sort $self->find_files;
    my ($root, @rel) = $self->remove_root_dir(@files);
    $self->{root} = $root;
    \@rel; # return
  }
    unless $self->{_list_files};

  return @{ $self->{_list_files} };
}


{
  no strict 'refs'; ## no critic (NoStrict)
  foreach my $method ( qw(
    name
    version
  ) ){
    *$method = sub {
      my ($self) = @_;

      $self->determine_name_and_version
        if !exists $self->{ $method };

      return $self->{ $method };
    };
  }
}


sub packages_from_directory {
  my ($self, $dir, @files) = @_;

  my @pvfd = ($dir);
  # M::M::p_v_f_d expects full paths for \@files
  push @pvfd, [map {
    $self->path_class_file->new($_)->is_absolute
      ? $_ : $self->path_class_file->new($dir, $_)->stringify
  } @files]
    if @files;

  require Module::Metadata;

  my $provides = try {
    my $packages = Module::Metadata->package_versions_from_directory(@pvfd);
    while ( my ($pack, $pv) = each %$packages ) {
      # M::M::p_v_f_d returns files in native OS format (obviously);
      # CPAN::Meta expects file paths in Unix format
      $pv->{file} = $self->path_class_file
        ->new($pv->{file})->as_foreign('Unix')->stringify;
    }
    $packages; # return
  }
  catch {
    carp("Failed to determine packages: $_[0]");
    +{}; # return
  };
  return $provides || {};
}


sub parse_name_and_version {
  my ($self, $path) = @_;
  my ( $name, $version );
  if ( $path ){
    # try a simple regexp first
    $path =~ m!
      ([^\\/]+)             # name (anything below final directory)
      -                     # separator
      (v?[0-9._]+)          # version
      (?:                   # possible file extensions
          \.t(?:ar\.)?gz
      )?
      $
    !x and
      ( $name, $version ) = ( $1, $2 );

    # attempt to improve data with CPAN::DistnameInfo (but ignore any errors)
    # TODO: also grab maturity and cpanid ?
    # release_status = $dist->maturity eq 'released' ? 'stable' : 'unstable';
    # -(TRIAL|RC) => 'testing', '_' => 'unstable'
    eval {
      # DistnameInfo expects any directories in unix format (thanks jeroenl)
      my $dnifile = $self->path_class_file
        ->new($path)->as_foreign('Unix')->stringify;
      # if it doesn't appear to have an extension fake one to help DistnameInfo
      $dnifile .= '.tar.gz' unless $dnifile =~ /\.[a-z]\w+$/;

      my $dni  = CPAN::DistnameInfo->new($dnifile);
      my $dni_name    = $dni->dist;
      my $dni_version = $dni->version;
      # if dni matched both name and version, or previous regexp didn't match
      if ( $dni_name && $dni_version || !$name ) {
        $name    = $dni_name    if $dni_name;
        $version = $dni_version if $dni_version;
      }
    };
    warn $@ if $@;
  }
  return ($name, $version);
}


sub path_class_dir  { $_[0]->{path_class_dir}  ||= 'Path::Class::Dir'  }
sub path_class_file { $_[0]->{path_class_file} ||= 'Path::Class::File' }


sub path_classify_dir  {
  my ($self, $dir) = @_;
  $self->path_class_dir->new_foreign($self->file_spec, $dir)
}

sub path_classify_file {
  my ($self, $file) = @_;
  $self->path_class_file->new_foreign($self->file_spec, $file)
}


sub perl_files {
  return
    grep { /\.pm$/ }
    $_[0]->list_files;
}


sub physical_directory {
  my ($self, @files) = @_;

  require   File::Temp;
  # dir will be removed when return value goes out of scope (in caller)
  my $dir = File::Temp->newdir();

  return $self->extract_into($dir, @files);
}


sub remove_root_dir {
  my ($self, @files) = @_;
  return unless @files;

  # FIXME: can we use File::Spec for these regexp's instead of [\\/] ?

  # grab the root dir from the first file
  $files[0] =~ m{^([^\\/]+)[\\/]}
    # if not matched quit now
    or return (undef, @files);

  my $dir = $1;
  my @rel;

  # strip $dir from each file
  for (@files) {

    m{^\Q$dir\E[\\/](.+)$}
      # if the match failed they're not all under the same root so just return now
      or return (undef, @files);

    push @rel, $1;
  }

  return ($dir, @rel);

}


sub required_attribute { return }


sub root {
  my ($self) = @_;

  # call list_files instead of find_files so that it caches the result
  $self->list_files
    unless exists $self->{root};

  return $self->{root};
}


sub set_name_and_version {
  my ($self, @values) = @_;
  my @fields = qw( name version );

  foreach my $i ( 0 .. $#fields ){
    $self->{ $fields[$i] } = $values[$i]
      if !exists $self->{ $fields[$i] } && defined $values[$i];
  }
  return;
}


# version() defined with name()

1;

__END__

=pod

=encoding UTF-8

=for :stopwords Randy Stauner ACKNOWLEDGEMENTS TODO dist dists dir unix checksum checksums
customizable

=head1 NAME

Dist::Metadata::Dist - Base class for format-specific implementations

=head1 VERSION

version 0.927

=head1 SYNOPSIS

  # don't use this, use a subclass

=head1 DESCRIPTION

This is a base class for different dist formats.

The following methods B<must> be defined by subclasses:

=over 4

=item *

L</file_content>

=item *

L</find_files>

=back

=head1 METHODS

=head2 new

Simple constructor that subclasses can inherit.
Ensures the presence of L</required_attribute>
if defined by the subclass.

=head2 default_file_spec

Defaults to C<'Native'> in the base class
which will let L<File::Spec> determine the value.

=head2 determine_name_and_version

Some dist formats may define a way to determine the name and version.

=head2 determine_packages

  $packages = $dist->determine_packages(@files);

Search the specified files (or all files if unspecified)
for perl packages.

Extracts the files to a temporary directory if necessary
and uses L<Module::Metadata> to discover package names and versions.

=head2 extract_into

  $ddir = $dist->extract_into($dir);
  ($ddir, @dfiles) = $dist->extract_into($dir, @files);

Extracts the specified files (or all files if not specified)
into the specified directory.

In list context this returns a list of the directory
(which may be a subdirectory of the C<$dir> passed in)
and the files extracted (in native OS (on-disk) format).

In scalar context just the directory is returned.

=head2 file_content

Returns the content for the specified file from the dist.

This B<must> be defined by subclasses.

=head2 file_checksum

  $dist->file_checksum('lib/Mod/Name.pm', 'sha256');

Returns a checksum (hex digest) of the file content.

The L<Digest> module is used to generate the checksums.
The value specified should be one accepted by C<< Digest->new >>.
A small effort is made to translate simpler names like
C<md5> into C<MD5> and C<sha1> into C<SHA-1>
(which are the names L<Digest> expects).

If the type of checksum is not specified C<md5> will be used.

=head2 find_files

Determine the files contained in the dist.

This is called from L</list_files> and cached on the object.

This B<must> be defined by subclasses.

=head2 file_spec

Returns the OS name of the L<File::Spec> module used for this format.
This is mostly so subclasses can define a specific one
(as L</default_file_spec>) if necessary.

A C<file_spec> attribute can be passed to the constructor
to override the default.

B<NOTE>: This is used for the internal format of the dist.
Tar archives, for example, are always in unix format.
For operations outside of the dist,
the format determined by L<File::Spec> will always be used.

=head2 full_path

  $dist->full_path("lib/Mod.pm"); # "root-dir/lib/Mod.pm"

Used internally to put the L</root> directory back onto the file.

=head2 list_files

Returns a list of the files in the dist starting at the dist root.

This calls L</find_files> to get a listing of the contents of the dist,
determines (and caches) the root directory (if any),
caches and returns the list of files with the root dir stripped.

  @files = $dist->list_files;
  # something like qw( README META.yml lib/Mod.pm )

=head2 name

The dist name if it could be determined.

=head2 packages_from_directory

  $provides = $dist->packages_from_directory($dir, @files);

Determines the packages provided by the perl modules found in a directory.
This is thin wrapper around
L<Module::Metadata/package_versions_from_directory>.
It returns a hashref like L<CPAN::Meta::Spec/provides>.

B<NOTE>: C<$dir> must be a physical directory on the disk,
therefore C<@files> (if specified) must be in native OS format.
This function is called internally from L</determine_packages>
(which calls L<physical_directory> (which calls L</extract_into>))
which manages these requirements.

=head2 parse_name_and_version

  ($name, $version) = $dist->parse_name_and_version($path);

Attempt to parse name and version from the provided string.
This will work for dists named like "Dist-Name-1.0".

=head2 path_class_dir

Returns the class name used for L<Path::Class::Dir> objects.

=head2 path_class_file

Returns the class name used for L<Path::Class::File> objects.

=head2 path_classify_dir

This is a shortcut for returning an object representing the provided
dir utilizing L</path_class_dir> and L</file_spec>.

=head2 path_classify_file

This is a shortcut for returning an object representing the provided
file utilizing L</path_class_file> and L</file_spec>.

=head2 perl_files

Returns the subset of L</list_files> that look like perl files.
Currently returns anything matching C</\.pm$/>

B<TODO>: This should probably be customizable.

=head2 physical_directory

  $dir = $dist->physical_directory();
  ($dir, @dir_files) = $dist->physical_directory(@files);

Returns the path to a physical directory on the disk
where the specified files (if any) can be found.

For in-memory formats this will make a temporary directory
and write the specified files (or all files) into it.

The return value is the same as L</extract_into>:
In scalar context the path to the directory is returned.
In list context the (possibly adjusted) paths to any specified files
are appended to the return value.

=head2 remove_root_dir

  my ($dir, @rel) = $dm->remove_root_dir(@files);

If all the C<@files> are beneath the same root directory
(as is normally the case) this will strip the root directory off of each file
and return a list of the root directory and the stripped files.

If there is no root directory the first element of the list will be C<undef>.

=head2 required_attribute

A single attribute that is required by the class.
Subclasses can define this to make L</new> C<croak> if it isn't present.

=head2 root

Returns the root directory of the dist (if there is one).

=head2 set_name_and_version

This is a convenience method for setting the name and version
if they haven't already been set.
This is often called by L</determine_name_and_version>.

=head2 version

Returns the version if it could be determined from the dist.

=head1 SEE ALSO

=over 4

=item *

L<Dist::Metadata::Tar> - for examining a tar file

=item *

L<Dist::Metadata::Dir> - for a directory already on the disk

=item *

L<Dist::Metadata::Struct> - for mocking up a dist with perl data structures

=back

=head1 AUTHOR

Randy Stauner <rwstauner@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Randy Stauner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
