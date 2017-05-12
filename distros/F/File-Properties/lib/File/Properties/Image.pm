# ----------------------------------------------------------------------------
#
# This module supports computing and caching of image file properties.
#
# Copyright © 2010,2011 Brendt Wohlberg <wohl@cpan.org>
# See distribution LICENSE file for license details.
#
# Most recent modification: 18 December 2011
#
# ----------------------------------------------------------------------------

package File::Properties::Image;
our $VERSION = 0.02;

use File::Properties::Error;
use File::Properties::Media;

require 5.005;
use strict;
use warnings;
use Error qw(:try);
use Image::Magick;


our $DCRawBin = 'dcraw'; # DCRaw utility binary
our $RawBufferSize = 1048576; # Buffer size for use in raw image handling
our $CacheTableName = 'ImageFileCache';
our $CacheTableCols = ['ContentDigest TEXT','ImageDigest TEXT'];


# ----------------------------------------------------------------------------
# Constructor
# ----------------------------------------------------------------------------
sub new {
  my $clss = shift;

  my $self = {};
  bless $self, $clss;
  $self->_init(@_);
  return $self;
}


# ----------------------------------------------------------------------------
# Initialiser
# ----------------------------------------------------------------------------
sub _init {
  my $self = shift;
  my $fpmr = shift; # File::Properties::Media reference
  my $fpcr = shift; # File::Properties::Cache reference

  # Ensure that a File::Properties::Media reference is specified
  throw File::Properties::Error("Init value is not defined")
    if not defined $fpmr;
  ## If File::Properties::Cache reference specified and the cache
  ## contains an entry with a matching digest value, set the image
  ## digest from the cache entry; otherwise the image digest must be
  ## computed.
  if (defined $fpcr and
      my $cent = $fpcr->cretrieve($CacheTableName,
				  {'ContentDigest' => $fpmr->cdigest})) {
    $self->idigest($cent->{'ImageDigest'});
    # Set flag indicating that this entry was obtained from the cache
    $self->_fromcache(1);
  } else {
    # Get a file handle to the file, or to uncompressed content if it
    # is compressed
    my $fcfh = $fpmr->cfilehandle; ## NB: requires attention
    # Image digest computation is handled differently for raw images
    my $idgs = ($fpmr->mmimetype eq 'image/x-raw')?
      _rawimagedigest($fcfh):_imagedigest($fcfh);
    # Record the computed image digest
    $self->idigest($idgs);
    # Set flag indicating that this entry was not obtained from the cache
    $self->_fromcache(0);
    ## If a File::Properties::Cache reference is specified, record the
    ## image digest entry in the cache
    if (defined $fpcr) {
      my $row = {'ContentDigest' => $fpmr->cdigest, 'ImageDigest' => $idgs};
      $fpcr->cinsert($CacheTableName, $row);
    }
  }
}


# ----------------------------------------------------------------------------
# Get (or set) image digest
# ----------------------------------------------------------------------------
sub idigest {
  my $self = shift;

  $self->{'idgs'} = shift if (@_);
  return $self->{'idgs'};
}


# ----------------------------------------------------------------------------
# Construct string representing properties hash
# ----------------------------------------------------------------------------
sub string {
  my $self = shift;
  my $levl = shift;

  $levl = 0 if (!defined $levl);
  my $lpfx = ' ' x (2*$levl);
  return  $lpfx . "   Image Digest: ".substr($self->idigest,0,40)."...\n";
}


# ----------------------------------------------------------------------------
# Initialise cache table for File::Properties::Image data
# ----------------------------------------------------------------------------
sub _cacheinit {
  my $fpcr = shift; # File::Properties::Cache reference

  $fpcr->define($CacheTableName, $CacheTableCols,
	       {'TableVersion' => [__PACKAGE__.'::Version', $VERSION]});
}


# ----------------------------------------------------------------------------
# Clear invalid entries in cache table for File::Properties::Image data
# ----------------------------------------------------------------------------
sub _cacheclean {
  my $self = shift;
  my $fpcr = shift; # File::Properties::Cache reference

  my $itbl = $CacheTableName;
  my $mtbl = $File::Properties::Media::CacheTableName;
  # Remove any entries in the File::Properties::Image cache table
  # for which there is not a corresponding entry with the same content
  # digest in the File::Properties::Media cache table
  $fpcr->remove($itbl, {'Where' => "NOT EXISTS (SELECT * FROM $mtbl " .
		               "WHERE ContentDigest = $itbl.ContentDigest)"});
}


# ----------------------------------------------------------------------------
# Get or set flag indicating whether data was retrieved from the cache
# ----------------------------------------------------------------------------
sub _fromcache {
  my $self = shift;

  $self->{'rfcf'} = shift if (@_);
  return $self->{'rfcf'};
}


# ----------------------------------------------------------------------------
# Compute digest of image file image data
# ----------------------------------------------------------------------------
sub _imagedigest {
  my $fhnd = shift; # File handle

  # Ensure that $fhnd is an IO::Handle object
  throw File::Properties::Error("Argument is not an IO::Handle",$fhnd)
    if (not defined $fhnd or not $fhnd->isa('IO::Handle'));
  # Ensure that file handle position is at the start of the file
  _seek0($fhnd) or
    throw File::Properties::Error("Seek on file handle failed",$fhnd);
  ## Initialise Image::Magick object, read in image pointed to by
  ## $fhnd, and check for errors
  my $imgk = Image::Magick->new;
  my $err = $imgk->Read(file=>$fhnd);
  throw File::Properties::Error("ImageMagick error: $err") if 0+$err < 1;
  ## Construct temporary file and write image data to it
  my $tmp = File::Temp->new;
  $err = $imgk->Write(file=>$tmp,filename=>"rgb:");
  # Return file handle position to start of file
  _seek0($tmp) or
    throw File::Properties::Error("Seek on file handle failed",$tmp);
  ## Compute SHA-512 digest on file containing image data
  my $sha = Digest::SHA->new(512);
  $sha->addfile($tmp, 'b');
  return $sha->hexdigest;
}


# ----------------------------------------------------------------------------
# Compute digest of raw image file image data
# ----------------------------------------------------------------------------
sub _rawimagedigest {
  my $fhnd = shift; # File handle

  # Ensure that $fhnd is an IO::Handle object
  throw File::Properties::Error("Argument is not an IO::Handle",$fhnd)
    if (not defined $fhnd or not $fhnd->isa('IO::Handle'));
  # Ensure that file handle position is at the start of the file
  _seek0($fhnd) or
    throw File::Properties::Error("Seek on file handle failed",$fhnd);
  ## Construct a temporary file and write the content of the file
  ## pointed to by $fhnd into it (the name of the file associated with
  ## the file handle is not necessarily known, but the DCRaw interface
  ## requires a filename).
  my $tmp = File::Temp->new;
  my ($rsz,$buf);
  while ($rsz = $fhnd->read($buf, $RawBufferSize)) {
    $tmp->write($buf, $rsz);
  }
  ## Apply DCRaw to the temporary file and receive the output via a pipe
  my $cmd = "$DCRawBin -D -c " . $tmp->filename . "  |";
  my $pipe = IO::File->new($cmd);
  throw File::Properties::Error("Failed to open pipe from dcraw",
				{'cmd' => $cmd})
    if not defined $pipe;
  # Compute the image digest for the pipe file handle
  return _imagedigest($pipe);
}


# ----------------------------------------------------------------------------
# Ensure file handle position is at start of file
# ----------------------------------------------------------------------------
sub _seek0 {
  my $fhnd = shift; # IO::Handle reference

  return ($fhnd->tell > 0)?$fhnd->seek(0,0):1;
}


# ----------------------------------------------------------------------------
# End of method definitions
# ----------------------------------------------------------------------------


1;
__END__

=head1 NAME

File::Properties::Image - Perl module representing information
specific to an image file

=head1 SYNOPSIS

  use File::Properties::Cache;
  use File::Properties::Image;

  my $fpc = File::Properties::Media->cache('cache.db');
  File::Properties::Image::_cacheinit($fpc);

  my $fpm = File::Properties::Media->new('image.jpg', $fpc);

  my $fpi = File::Properties::Image->new($fpm, $fpc);
  print "Image digest: " . $fpi->idigest . "\n";


=head1 ABSTRACT

  File::Properties::Image is a Perl module representing information
  specific to an image file (currently just a digest computed on the
  image pixel values). If a reference to a File::Properties::Cache
  object is specified in the constructor, access to the properties is
  via the cache.

=head1 DESCRIPTION

  File::Properties::Image is a Perl module representing information
  specific to an image file (currently just a digest computed on the
  image pixel values). The digest for RAW files is computed on the raw
  data so that the digest does not depend on the demosaicing
  algorithm.

=over 4

=item B<new>

  my $fpi = File::Properties::Image->new($fpm, $fpc);

Constructs a new File::Properties::Image object.

=item B<idigest>

  print "Image digest: " . $fpi->idigest . "\n";

Determine the image pixel value digest for the represented file.

=item B<string>

  print $fpi->string . "\n";

Construct a string representing the object data.

=item B<_cacheinit>

  File::Properties::Image::_cacheinit($fpc);

Initialise the image properties cache table in the cache referred to
by the File::Properties::Cache reference argument.

=back

=head1 SEE ALSO

L<File::Properties>, L<File::Properties::Cache>, L<File::Properties::Media>,
L<Image::Magick>

=head1 AUTHOR

Brendt Wohlberg E<lt>wohl@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010,2011 by Brendt Wohlberg

This library is available under the terms of the GNU General Public
License (GPL), described in the LICENSE file included in this
distribution.

=cut
