# ----------------------------------------------------------------------------
#
# This module provides cached access to file SHA-2 digests and mime
# types. Additional information is available for bzip2 and gzip
# compressed files, and digital media files.
#
# Copyright © 2010,2011 Brendt Wohlberg <wohl@cpan.org>
# See distribution LICENSE file for license details.
#
# Most recent modification: 18 December 2011
#
# ----------------------------------------------------------------------------

package File::Properties::Media;
our $VERSION = 0.02;

use File::Properties::Compressed;
use base qw(File::Properties::Compressed);

require 5.005;
use strict;
use warnings;
use Error qw(:try);
use Storable qw(freeze thaw);
use Image::ExifTool;


our $CacheTableName = 'MediaFileCache';
our $CacheTableCols = ['ContentDigest TEXT','MediaMimeType TEXT',
		      'MediaFileType TEXT','MediaType TEXT',
		      'DateModified DATE', 'ExifHash BLOB'];


# ----------------------------------------------------------------------------
# Initialiser
# ----------------------------------------------------------------------------
sub _init {
  my $self = shift;
  my $path = shift; # File path or File::Properties::Generic reference
  my $fpcr = shift; # File::Properties::Cache reference

  # Initialisation for base
  $self->SUPER::_init($path, $fpcr);
  ## Remainder of initialisation only necessary for regular files (in
  ## particular, it should not be performed for directories)
  if ($self->isreg) {
    ## Initialisation is complicated because it is only possible to
    ## reliably determine whether a file is a media file *after* using
    ## Image::ExifTool to determine its mime type (the mime type
    ## returned by Properties::Regular is less reliable for this
    ## purpose). The strategy to avoid inefficient multiple uses of
    ## Image::ExifTool (potentially resulting in uncompressing a
    ## compressed file more than once) is as follows. If the
    ## already-initialised base part of the object is marked as having
    ## been retrieved from the cache, assume that the file has been
    ## previously seen, and would therefore already have a media file
    ## cache entry if it were a media file: try to retrieve the media
    ## file details from the cache, and assume it is not a media file
    ## if the retrieval fails. If the already-initialised base part
    ## was not retrieved from the cache, assume the file has not been
    ## previously seen, and use Image::ExifTool to determine its
    ## medial file properties, which are then inserted into the media
    ## file cache.
    if ($self->_fromcache($File::Properties::Regular::CacheTableName)) {
      if (my $cent = $fpcr->cretrieve($CacheTableName,
				 {'ContentDigest' => $self->SUPER::cdigest})) {
	$self->mmimetype($cent->{'MediaMimeType'});
	$self->mfiletype($cent->{'MediaFileType'});
	$self->mediatype($cent->{'MediaType'});
	$self->datemod($cent->{'DateModified'});
	$self->exifhash(thaw $cent->{'ExifHash'});
	# Set flag indicating that this entry was obtained from the cache
	$self->_fromcache($CacheTableName, 1);
      }
    } else {
      ## Attempt to extract EXIF properties from file content
      my $exft = new Image::ExifTool;
      my $info = $exft->ImageInfo($self->cfilehandle, qw(*),
				  {PrintConv => 1,
				   DateFormat => "%Y-%m-%d %H:%M:%S",
				   CoordFormat => "%.8f"});
      my $ierr = $exft->GetValue('Error');
      ## If attempt to extract EXIF properties fails with error 'Unknown
      ## file type', then the file is not a media file and the general
      ## file properties are returned. If the attempt fails with any
      ## other error, throw an exception.
      throw File::Properties::Error("ExifTool error: ".$ierr, $exft)
	if (defined $ierr and $ierr ne 'Unknown file type');

      if (not defined $ierr) {
	## Determine media mime type, file type, and media type from EXIF data
	$self->mmimetype($exft->GetValue('MIMEType'));
	$self->mfiletype($exft->GetValue('FileType'));
	my $mtyp = $self->mmimetype;
	$mtyp =~ s+\/.*$++;
	$self->mediatype($mtyp);
	$self->datemod(_fixdatestr($info->{'ModifyDate'}));
	## Construct hash of EXIF tag data and freeze it for storage in cache
	my $exfh = {};
	my ($tag, $group, $val);
	foreach $tag ($exft->GetFoundTags('Group0')) {
	  $group = $exft->GetGroup($tag);
	  $val = $info->{$tag};
	  $exfh->{"$group:".Image::ExifTool::GetTagName($tag)} = $val
	    if (defined $val and not ref($val));
	}
	$self->exifhash($exfh);

	# Set flag indicating that this entry was not obtained from the cache
	$self->_fromcache($CacheTableName, 0);

	if (defined $fpcr) {
	  my $row = {'ContentDigest' => $self->SUPER::cdigest,
		     'MediaMimeType' => $self->mmimetype,
		     'MediaFileType' => $self->mfiletype,
		     'MediaType' => $self->mediatype,
		     'DateModified' => $self->datemod,
		     'ExifHash' => freeze \%{$self->exifhash}};
	  $fpcr->cinsert($CacheTableName, $row);
	}
      }
    }
  }
}


# ----------------------------------------------------------------------------
# Get (or set) media mime type
# ----------------------------------------------------------------------------
sub mmimetype {
  my $self = shift;

  $self->{'mmtp'} = shift if (@_);
  return (defined $self->{'mmtp'})?$self->{'mmtp'}:$self->cmimetype;
}


# ----------------------------------------------------------------------------
# Get (or set) media file type
# ----------------------------------------------------------------------------
sub mfiletype {
  my $self = shift;

  $self->{'mftp'} = shift if (@_);
  return $self->{'mftp'};
}


# ----------------------------------------------------------------------------
# Get (or set) media type (initial part of mime type, e.g. 'image')
# ----------------------------------------------------------------------------
sub mediatype {
  my $self = shift;

  $self->{'mtyp'} = shift if (@_);
  return $self->{'mtyp'};
}


# ----------------------------------------------------------------------------
# Get (or set) EXIF modification date
# ----------------------------------------------------------------------------
sub datemod {
  my $self = shift;

  $self->{'mddt'} = shift if (@_);
  return $self->{'mddt'};
}


# ----------------------------------------------------------------------------
# Get (or set) hash of EXIF tags and values
# ----------------------------------------------------------------------------
sub exifhash {
  my $self = shift;

  $self->{'exif'} = shift if (@_);
  return $self->{'exif'};
}


# ----------------------------------------------------------------------------
# Determine whether file properties represent a media file
# ----------------------------------------------------------------------------
sub ismedia {
  my $self = shift;

  return (defined $self->mediatype and ($self->mediatype eq 'image' or
					$self->mediatype eq 'video' or
					$self->mediatype eq 'audio'));
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
  if ($self->ismedia) {
    $s .= $lpfx . "   Media Mime Type: ".$self->mmimetype."\n";
    $s .= $lpfx . "   Media File Type: ".$self->mfiletype."\n";
    $s .= $lpfx . "   Media Type: ".$self->mediatype."\n";
    $s .= $lpfx .
      "   Date Modified: ".((defined $self->datemod)?$self->datemod:'')."\n";
  }
  return $s;
}


# ----------------------------------------------------------------------------
# Initialise cache table for File::Properties::Media data
# ----------------------------------------------------------------------------
sub _cacheinit {
  my $self = shift;
  my $fpcr = shift; # File::Properties::Cache reference
  my $opts = shift; # Options hash

  $self->SUPER::_cacheinit($fpcr, $opts);
  $fpcr->define($CacheTableName, $CacheTableCols,
	       {'TableVersion' => [__PACKAGE__.'::Version', $VERSION]});
}


# ----------------------------------------------------------------------------
# Clear invalid entries in cache table for File::Properties::Media data
# ----------------------------------------------------------------------------
sub _cacheclean {
  my $self = shift;
  my $fpcr = shift; # File::Properties::Cache reference

  my $mtbl = $CacheTableName;
  my $ctbl = $File::Properties::Compressed::CacheTableName;
  # Remove any entries in the File::Properties::Media cache table
  # for which there is not a corresponding entry with the same content
  # digest in the File::Properties::Compressed cache table
  $fpcr->remove($mtbl, {'Where' => "NOT EXISTS (SELECT * FROM $ctbl " .
		               "WHERE ContentDigest = $mtbl.ContentDigest)"});
}


# ----------------------------------------------------------------------------
# Standardise date format from EXIF data
# ----------------------------------------------------------------------------
sub _fixdatestr {
  my $dstr = shift;

  return undef if (not defined $dstr);
  if ($dstr =~ /(\d+)[^\d](\d+)[^\d](\d+)[^\d](\d+)[^\d](\d+)[^\d](\d+)/) {
    $dstr = "$1-$2-$3 $4:$5:$6";
  }

  return $dstr;
}


# ----------------------------------------------------------------------------
# End of method definitions
# ----------------------------------------------------------------------------


1;
__END__

=head1 NAME

File::Properties::Media - Perl module representing properties of a
media file

=head1 SYNOPSIS

  use File::Properties::Cache;
  use File::Properties::Media;

  my $fpc = File::Properties::Media->cache('cache.db');

  my $fpm = File::Properties::Media->new('/path/to/file', $fpc);
  print "Media mime type: " . $fpm->mmimetype . "\n";


=head1 ABSTRACT

  File::Properties::Media is a Perl module representing properties of
  a media file, in addition to the properties stored in
  File::Properties::Compressed from which it is derived.

=head1 DESCRIPTION

  File::Properties::Media is a Perl module representing properties of
  a media file, in addition to the properties stored in
  File::Properties::Compressed from which it is derived. These media
  file properties consist of mime type and file type as extracted by
  Image::Exiftool, the media type ('image', 'video', or 'audio'), the
  modification date, and a hash representing the full EXIF data. If a
  reference to a File::Properties::Cache object is specified in the
  constructor, access to the properties is via the cache.

=over 4

=item B<new>

  my $fpm = File::Properties::Media->new($path, $fpc);

Constructs a new File::Properties::Media object.

=item B<mmimetype>

  print "Media mime type: " . $fpm->mmimetype . "\n";

Determine the media mime type of the represented file.

=item B<mfiletype>

  print "Media file type: " . $fpm->mfiletype . "\n";

Determine the media file type of the represented file.

=item B<mediatype>

  print "Media type: " . $fpm->mediatype . "\n";

Determine the media type (the initial part of mime type, e.g. 'image')
of the represented file.

=item B<datemod>

  print "Modification date: " . $fpm->datemod . "\n";

Determine the EXIF modification date.

=item B<exifhash>

  my $exh = $fpm->exifhash;

Return a hash mapping EXIF tags names to their values.

=item B<ismedia>

  print "Is a media file\n" if ($fpm->ismedia);

Determine whether the file is a media file.

=item B<string>

  print $fpm->string . "\n";

Construct a string representing the object data.

=item B<_cacheinit>

  $fpm->_cacheinit($fpc, $options_hash);

Initialise the regular file properties cache table in the cache
referred to by the File::Properties::Cache reference argument.

=back

=head1 SEE ALSO

L<File::Properties>, L<File::Properties::Cache>,
L<File::Properties::Compressed>, L<Image::ExifTool>

=head1 AUTHOR

Brendt Wohlberg E<lt>wohl@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010,2011 by Brendt Wohlberg

This library is available under the terms of the GNU General Public
License (GPL), described in the LICENSE file included in this
distribution.

=cut
