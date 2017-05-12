# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
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

package Dist::Metadata::Archive;
our $AUTHORITY = 'cpan:RWSTAUNER';
# ABSTRACT: Base class for Dist::Metadata archive files
$Dist::Metadata::Archive::VERSION = '0.927';
use Carp (); # core
use parent 'Dist::Metadata::Dist';

push(@Dist::Metadata::CARP_NOT, __PACKAGE__);


sub new {
  my $class = shift;
  my $self = $class->SUPER::new(@_);

  if( $class eq __PACKAGE__ ){
    my $subclass = 'Dist::Metadata::' .
      ( $self->{file} =~ /\.zip$/ ? 'Zip' : 'Tar' );

    eval "require $subclass"
      or Carp::croak $@;

    # rebless into format specific subclass
    bless $self, $subclass;
  }

  return $self;
}

sub required_attribute { 'file' }


sub archive {
  my ($self) = @_;
  return $self->{archive} ||= do {
    my $file = $self->file;

    Carp::croak "File '$file' does not exist"
      unless -e $file;

    $self->read_archive($file); # return
  };
}


sub default_file_spec { 'Unix' }


sub determine_name_and_version {
  my ($self) = @_;
  $self->set_name_and_version( $self->parse_name_and_version( $self->file ) );
  return $self->SUPER::determine_name_and_version(@_);
}


sub file {
  return $_[0]->{file};
}


sub read_archive {
  Carp::croak q[Method 'read_archive' not defined];
}

1;

__END__

=pod

=encoding UTF-8

=for :stopwords Randy Stauner ACKNOWLEDGEMENTS TODO dist dists dir unix checksum checksums

=head1 NAME

Dist::Metadata::Archive - Base class for Dist::Metadata archive files

=head1 VERSION

version 0.927

=for test_synopsis my $path_to_archive;

=head1 SYNOPSIS

  my $dist = Dist::Metadata->new(file => $path_to_archive);

=head1 DESCRIPTION

This is a subclass of L<Dist::Metadata::Dist>
to enable determining the metadata from an archive file.

It is a base class for archive file formats:

=over 4

=item *

L<Dist::Metadata::Tar>

=item *

L<Dist::Metadata::Zip>

=back

It's not useful on it's own
and should be used from L<Dist::Metadata/new>.

=head1 METHODS

=head2 new

  $dist = Dist::Metadata::Archive->new(file => $path);

Accepts a single C<file> argument that should be a path to a file.

If called from this base class
C<new()> will delegate to a subclass based on the filename
and return a blessed instance of that subclass.

=head2 archive

Returns an object representing the archive file.

=head2 default_file_spec

Returns C<Unix> since most archive files are be in unix format.

=head2 determine_name_and_version

Attempts to parse name and version from file name.

=head2 file

The C<file> attribute passed to the constructor,
used to load L</archive>.

=head2 read_archive

  $dist->read_archive($file);

Returns a format-specific object representing the specified file.

This B<must> be defined by subclasses.

=head1 AUTHOR

Randy Stauner <rwstauner@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Randy Stauner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
