# ----------------------------------------------------------------------------
#
# This module provides cached access to file SHA-2 digests and mime
# types. Additional information is available for bzip2 and gzip
# compressed files, and digital media files, particularly digital
# images.
#
# Copyright © 2010,2011 Brendt Wohlberg <wohl@cpan.org>
# See distribution LICENSE file for license details.
#
# Most recent modification: 22 December 2011
#
# ----------------------------------------------------------------------------

package File::Properties;
our $VERSION = 0.02;

use File::Properties::Cache;
use File::Properties::Media;
use File::Properties::Image;
use base qw(File::Properties::Media);

require 5.005;
use strict;
use warnings;
use Error qw(:try);


# ----------------------------------------------------------------------------
# Initialiser
# ----------------------------------------------------------------------------
sub _init {
  my $self = shift;
  my $path = shift; # File path
  my $fpcr = shift; # File::Properties::Cache reference

  $self->SUPER::_init($path, $fpcr);
  $self->_image(File::Properties::Image->new($self, $fpcr))
    if ($self->isimage);
}


# ----------------------------------------------------------------------------
# Get digest string of image file content
# ----------------------------------------------------------------------------
sub idigest {
  my $self = shift;

  return $self->isimage?$self->_image->idigest:undef;
}


# ----------------------------------------------------------------------------
# Get (or set) image object
# ----------------------------------------------------------------------------
sub _image {
  my $self = shift;

  $self->{'fpir'} = shift if (@_);
  return $self->{'fpir'};
}


# ----------------------------------------------------------------------------
# Determine whether file properties represent an image file
# ----------------------------------------------------------------------------
sub isimage {
  my $self = shift;

  return (defined $self->mediatype and $self->mediatype eq 'image');
}


# ----------------------------------------------------------------------------
# Construct string representing properties hash
# ----------------------------------------------------------------------------
sub string {
  my $self = shift;
  my $levl = shift;

  $levl = 0 if (!defined $levl);
  my $lpfx = ' ' x (2*$levl);
  my $s = $self->SUPER::string($levl);
  $s .=  $self->_image->string($levl) if ($self->isimage);
  return $s;
}

# ----------------------------------------------------------------------------
# Get flag indicating whether data was retrieved from the cache
# ----------------------------------------------------------------------------
sub cachestatus {
  my $self = shift;

  my $mkey = (@_)?shift:undef;
  if (defined $mkey) {
    if ($mkey eq $File::Properties::Image::CacheTableName) {
      return $self->_image->_fromcache;
    } else {
      return $self->_fromcache($mkey);
    }
  } else {
    return (not $self->isimage or $self->_image->_fromcache) and
           (not $self->isreg or $self->_fromcache(
		       $File::Properties::Regular::CacheTableName)) and
	   (not $self->iscompressed or $self->_fromcache(
		       $File::Properties::Compressed::CacheTableName)) and
	   (not $self->ismedia or $self->_fromcache(
		       $File::Properties::Media::CacheTableName));
  }
}


# ----------------------------------------------------------------------------
# Initialise cache table for File::Properties data
# ----------------------------------------------------------------------------
sub _cacheinit {
  my $self = shift;
  my $fpcr = shift; # File::Properties::Cache reference
  my $opts = shift; # Options hash

  $self->SUPER::_cacheinit($fpcr, $opts);
  File::Properties::Image::_cacheinit($fpcr);
}


# ----------------------------------------------------------------------------
# Remove all cache data older (based on insertion date) than the
# specified number of days
# ----------------------------------------------------------------------------
sub _cacheexpire {
  my $self = shift;
  my $fpcr = shift; # File::Properties::Cache reference
  my $nday = shift; # Expiry age in number of days

  $fpcr->expire($File::Properties::Regular::CacheTableName, $nday);
  File::Properties::Compressed->_cacheclean($fpcr);
  File::Properties::Media->_cacheclean($fpcr);
  File::Properties::Image::->_cacheclean($fpcr);
}


# ----------------------------------------------------------------------------
# Remove all cache data for which the corresponding files can no
# longer be found on disk
# ----------------------------------------------------------------------------
sub _cacheclean {
  my $self = shift;
  my $fpcr = shift; # File::Properties::Cache reference

  if (File::Properties::Regular->_cacheclean($fpcr)) {
    File::Properties::Compressed->_cacheclean($fpcr);
    File::Properties::Media->_cacheclean($fpcr);
    File::Properties::Image::->_cacheclean($fpcr);
  }
}


# ----------------------------------------------------------------------------
# End of method definitions
# ----------------------------------------------------------------------------


1;
__END__

=head1 NAME

File::Properties - Perl module representing properties of a disk file

=head1 SYNOPSIS

  use File::Properties;

  my $fpc = File::Properties->cache('cache.db');

  my $fp = File::Properties->new('/path/to/file', $fpc);
  print "File properties:\n" . $fp->string . "\n";


  An alternative approach is to use the File::Properties::PropsCache
  module for construction of the cache and File::Properties objects:

  use File::Properties::PropsCache;

  my $fpc = File::Properties::PropsCache->new('cache.db');

  my $fp = $fpc->properties('/path/to/file');
  print "File properties:\n" . $fp->string . "\n";


=head1 ABSTRACT

  File::Properties is a Perl module representing properties of
  a disk file, with emphasis on media files.

=head1 DESCRIPTION

  This module provides a class representing properties of a disk file,
  with particular emphasis on media (image, video, and audio)
  files. The mime type and a SHA-2 digest can be computed for any
  regular file, and these properties are also available for the
  content of bzip2 and gzip compressed files. Media file properties
  consist of mime type and file type as extracted by Image::Exiftool,
  the media type ('image', 'video', or 'audio'), the modification
  date, and a hash representing the full EXIF data. For image files, a
  digest of the image pixel data is also available. If a reference to
  a File::Properties::Cache object is specified in the constructor,
  access to the properties is via the cache. Most of the methods are
  inherited from File::Properties::Media, from which it is derived.

=over 4

=item B<new>

  my $fp = File::Properties->new($path, $fpc);

Constructs a new File::Properties object.

=item B<path>

  print "Canonical path: " . $fp->path . "\n";

Determine the canonical path of the represented file. This method is
inherited from the File::Properties::Generic base class.

=item B<device>

  print "Device number: " . $fp->device . "\n";

Determine the device number of the represented file. This method is
inherited from the File::Properties::Generic base class.

=item B<inode>

  print "Inode number: " . $fp->inode . "\n";

Determine the inode number of the represented file. This method is
inherited from the File::Properties::Generic base class.

=item B<size>

  print "File size: " . $fp->size . "\n";

Determine the size of the represented file. This method is inherited
from the File::Properties::Generic base class.

=item B<mtime>

  print "Modification time: " . $fp->mtime . "\n";

Determine the modification time of the represented file. This method
is inherited from the File::Properties::Generic base class.

=item B<mode>

  print "File mode: " . $fp->mode . "\n";

Determine the file mode integer (representing permissions and type)
for the represented file. This method is inherited from the
File::Properties::Generic base class.

=item B<children>

  my $chsh = $fpg->children;

If the represented file is a directory, return a hash mapping file
names within that directory to corresponding File::Properties object
references. This method is inherited from the
File::Properties::Generic base class.

=item B<isreg>

  print (($fp->isreg)?"Is regular file\n":"Not regular file\n");

Determine if the represented file is a regular file. This method is
inherited from the File::Properties::Generic base class.

=item B<isdir>

  print (($fp->isdir)?"Is directory\n":"Not directory\n");

Determine if the represented file is a directory. This method is
inherited from the File::Properties::Generic base class.

=item B<mmimetype>

  print "Media mime type: " . $fp->mmimetype . "\n";

Determine the media mime type of the represented file. This is the
mime type determined by Image::Exiftool if the file is a media file,
otherwise it is the same as the value returned by the cmimetype
method. This method is inherited from the File::Properties::Media base
class.

=item B<cmimetype>

  print "Content mime type: " . $fp->cmimetype . "\n";

Determine the content mime type of the represented file. This is the
mime type of the compressed content for a gzip or bzip2 compressed
file, otherwise it is the same as the value returned by the mimetype
method. This method is inherited from the File::Properties::Compressed
base class.

=item B<mimetype>

  print "Mime type: " . $fp->mimetype . "\n";

Determine the mime type of the represented file. This method is
inherited from the File::Properties::Regular base class.

=item B<mfiletype>

  print "Media file type: " . $fp->mfiletype . "\n";

Determine the media file type, determined by Image::Exiftool, of the
represented file. This method is inherited from the
File::Properties::Media base class.

=item B<mediatype>

  print "Media type: " . $fp->mediatype . "\n";

Determine the media type (the initial part of mime type, e.g. 'image')
of the represented file. This method is inherited from the
File::Properties::Media base class.

=item B<idigest>

  print "Image digest: " . $fp->idigest . "\n";

Determine a SHA-2 digest of the pixel data in an image file.

=item B<cdigest>

  print "Content digest: " . $fp->cdigest . "\n";

Determine the file content digest for the represented file. This is a
SHA-2 digest of the compressed content for a gzip or bzip2 compressed
file, otherwise it is the same as the value returned by the digest
method. This method is inherited from the File::Properties::Compressed
base class.

=item B<digest>

  print "File digest: " . $fp->digest . "\n";

Determine a SHA-2 digest of the represented file. This method is
inherited from the File::Properties::Regular base class.

=item B<datemod>

  print "Modification date: " . $fp->datemod . "\n";

Determine the EXIF modification date. This method is inherited from
the File::Properties::Media base class.

=item B<exifhash>

  my $exh = $fpm->exifhash;

Return a hash mapping EXIF tags names to their values. This method is
inherited from the File::Properties::Media base class.

=item B<iscompressed>

  print "Is a compressed file\n" if ($fp->iscompressed);

Determine whether the file is a gzip or bzip2 compressed file. This
method is inherited from the File::Properties::Compressed base class.

=item B<ismedia>

  print "Is a media file\n" if ($fp->ismedia);

Determine whether the file is a media file. This method is inherited
from the File::Properties::Media base class.

=item B<isimage>

  print "Is an image file\n" if ($fp->isimage);

Determine whether the file is an image file.

=item B<string>

  print $fp->string . "\n";

Construct a string representing the object data.

=item B<cachestatus>

  if ($fp->cachestatus) {
    printf("All properties were retrieved from cache\n");
  } elsif ($fp->cachestatus(
                     $File::Properties::Regular::CacheTableName) {
    printf("Regular file properties were retrieved from cache\n");
  }

Determine whether properties were retrieved from the cache

=item B<_cacheinit>

  $fp->_cacheinit($fpc, $options_hash);

Initialise the regular file properties cache table in the cache
referred to by the File::Properties::Cache reference argument.

=item B<_cacheexpire>

  $fp->_cacheexpire($fpc, 365);

Remove all cache data older (based on insertion date) than the
specified number of days.

=item B<_cacheclean>

  $fp->_cacheclean($fpc);

Remove all cache data for which the corresponding files can no longer
be found on disk.

=back

=head1 WARNING

This initial release of the module has not been extensively tested,
but is released in its current state in the hope that others may find
it useful. While they will be avoided as far as possible, incompatible
interface changes may become necessary in a later release.

=head1 SEE ALSO

L<File::Properties::Cache>, L<File::Properties::Media>,
L<File::Properties::Image>

=head1 AUTHOR

Brendt Wohlberg E<lt>wohl@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010,2011 by Brendt Wohlberg

This library is available under the terms of the GNU General Public
License (GPL), described in the LICENSE file included in this
distribution.

=cut
