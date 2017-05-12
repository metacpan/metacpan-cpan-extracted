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

package Dist::Metadata::Zip;
our $AUTHORITY = 'cpan:RWSTAUNER';
# ABSTRACT: Enable Dist::Metadata for zip files
$Dist::Metadata::Zip::VERSION = '0.927';
use Archive::Zip 1.30 ();
use Carp (); # core

use parent 'Dist::Metadata::Archive';

push(@Dist::Metadata::CARP_NOT, __PACKAGE__);

sub file_content {
  my ($self, $file) = @_;
  my ($content, $status) = $self->archive->contents( $self->full_path($file) );
  Carp::croak "Failed to get content of '$file' from archive"
    if $status != Archive::Zip::AZ_OK();
  return $content;
}

sub find_files {
  my ($self) = @_;
  return
    map  {  $_->fileName    }
    grep { !$_->isDirectory }
      $self->archive->members;
}

sub read_archive {
  my ($self, $file) = @_;

  my $archive = Archive::Zip->new();
  $archive->read($file) == Archive::Zip::AZ_OK()
    or Carp::croak "Failed to read zip file!";

  return $archive;
}

1;

__END__

=pod

=encoding UTF-8

=for :stopwords Randy Stauner ACKNOWLEDGEMENTS TODO dist dists dir unix checksum checksums

=head1 NAME

Dist::Metadata::Zip - Enable Dist::Metadata for zip files

=head1 VERSION

version 0.927

=for test_synopsis my $path_to_archive;

=head1 SYNOPSIS

  my $dist = Dist::Metadata->new(file => $path_to_archive);

=head1 DESCRIPTION

This is a subclass of L<Dist::Metadata::Dist>
(actually of L<Dist::Metadata::Archive>)
to enable determining the metadata from a zip file.

It's probably not very useful on it's own
and should be used from L<Dist::Metadata/new>.

=head1 AUTHOR

Randy Stauner <rwstauner@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Randy Stauner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
