# ----------------------------------------------------------------------------
#
# This module supports computing and caching of file SHA-2 digests and
# mime types. Files compressed using bzip2 and gzip are uncompressed,
# and their content SHA digests and mime types are also accessible.
#
# Copyright © 2010,2011 Brendt Wohlberg <wohl@cpan.org>
# See distribution LICENSE file for license details.
#
# Most recent modification: 18 December 2011
#
# ----------------------------------------------------------------------------

package File::Properties::Compressed;
our $VERSION = 0.02;

use File::Properties::Regular;
use base qw(File::Properties::Regular);

require 5.005;
use strict;
use warnings;
use Error qw(:try);
use IO::File;
use File::Temp;
use Compress::Bzip2 qw(bzopen  BZ_OK BZ_STREAM_END);
use Compress::Zlib qw(gzopen Z_OK Z_STREAM_END);

our $UncompressBufferSize = 1048576;
our $CacheTableName = 'CompFileCache';
our $CacheTableCols = ['FileDigest TEXT','ContentMimeType TEXT',
		       'ContentDigest TEXT'];


# ----------------------------------------------------------------------------
# Initialiser
# ----------------------------------------------------------------------------
sub _init {
  my $self = shift;
  my $path = shift; # File path
  my $fpcr = shift; # File::Properties::Cache reference

  # Initialisation for base
  $self->SUPER::_init($path, $fpcr);
  # Remainder of initialisation only required if file is a regular
  # file that is compressed
  if ($self->isreg and $self->iscompressed) {
    my $cent;
    ## If File::Properties::Cache reference has been specified, try to
    ## retrieve compressed file cache entry for this file. If
    ## retrieval fails, compute the relevant properties for this file
    ## and store them in the cache.
    if (defined $fpcr and ($cent = $fpcr->cretrieve($CacheTableName,
				    {'FileDigest' => $self->SUPER::digest}))) {
      $self->cmimetype($cent->{'ContentMimeType'});
      $self->cdigest($cent->{'ContentDigest'});
      # Set flag indicating that this entry was obtained from the cache
      $self->_fromcache($CacheTableName, 1);
    } else {
      my $fhnd = $self->cfilehandle;
      $self->cmimetype(File::Properties::Regular::_mimetype($fhnd->filename));
      $self->cdigest(File::Properties::Regular::_digest($fhnd->filename));
      # Set flag indicating that this entry was not obtained from the cache
      $self->_fromcache($CacheTableName, 0);
      if (defined $fpcr) {
	my $row = {'FileDigest' => $self->SUPER::digest,
		   'ContentMimeType' => $self->cmimetype,
		   'ContentDigest' => $self->cdigest};
	$fpcr->cinsert($CacheTableName, $row);
      }
    }
  }
}


# ----------------------------------------------------------------------------
# Get (or set) mime type of compressed file content
# ----------------------------------------------------------------------------
sub cmimetype {
  my $self = shift;

  $self->{'cmtp'} = shift if (@_);
  return (defined $self->{'cmtp'})?$self->{'cmtp'}:$self->mimetype;
}


# ----------------------------------------------------------------------------
# Get (or set) digest string of compressed file content
# ----------------------------------------------------------------------------
sub cdigest {
  my $self = shift;

  $self->{'cdgs'} = shift if (@_);
  return (defined $self->{'cdgs'})?$self->{'cdgs'}:$self->digest;
}


# ----------------------------------------------------------------------------
# Get file handle to file, or to file containing uncompressed content
# if file is compressed.
# ----------------------------------------------------------------------------
sub cfilehandle {
  my $self = shift;

  ## If a file handle for the file (or temporary file containing
  ## uncompressed file data, if it is a compressed file) is not
  ## stored, create one. The assumption is that this file handle will
  ## only need to be created and accessed on the initial pass through
  ## the class hierarchy for a specific file, before it has been
  ## cached. Any class derived from File::Properties::Compressed
  ## should cache all information that has to be computed from the
  ## file so that subsequent object constructions for the file can be
  ## done purely from the cache, without need for additional
  ## uncompressing of the data.
  if (not defined $self->{'cfhn'}) {
    # Open and store a file handle for the file, to the file itself if
    # it is not compressed, or to a temporary file containing
    # uncompressed file data if it is
    $self->{'cfhn'} = ($self->iscompressed)?
      $self->_tmpunzip:
      IO::File->new($self->path, 'r');
    throw File::Properties::Error("Error opening file handle")
      if (not (defined $self->{'cfhn'} and $self->{'cfhn'}->opened));
  }
  return $self->{'cfhn'};
}


# ----------------------------------------------------------------------------
# Determine whether file properties represent a compressed file
# ----------------------------------------------------------------------------
sub iscompressed {
  my $self = shift;

  return ((defined $self->SUPER::mimetype) and
    ($self->SUPER::mimetype eq 'application/x-bzip2' or
     $self->SUPER::mimetype eq 'application/x-gzip'));
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
  if ($self->iscompressed) {
    $s .= $lpfx . "   Content Mime Type: ".$self->cmimetype."\n";
    $s .= $lpfx . "   Content Digest:    ".substr($self->cdigest,0,40)."...\n";
  }
  return $s;
}


# ----------------------------------------------------------------------------
# Initialise cache table for File::Properties::Compressed objects
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
# Clear invalid entries in cache table for File::Properties::Compressed data
# ----------------------------------------------------------------------------
sub _cacheclean {
  my $self = shift;
  my $fpcr = shift; # File::Properties::Cache reference

  my $ctbl = $CacheTableName;
  my $rtbl = $File::Properties::Regular::CacheTableName;
  # Remove any entries in the File::Properties::Compressed cache table
  # for which there is not a corresponding entry with the same file
  # digest in the File::Properties::Regular cache table
  $fpcr->remove($ctbl, {'Where' => "NOT EXISTS (SELECT * FROM $rtbl " .
		                    "WHERE Digest = $ctbl.FileDigest)"});
}


# ----------------------------------------------------------------------------
# Return file handle and path to temporary file containing unzipped data
# ----------------------------------------------------------------------------
sub _tmpunzip {
  my $self = shift;

  my $fmtp = $self->SUPER::mimetype;
  # Path is specified in constructor argument, so it should be
  # available independent of whether base object was retrieved from
  # the cache
  my $path = $self->path;
  if ($fmtp eq 'application/x-bzip2') {
    return _tmpbunzip($path);
  } elsif ($fmtp eq 'application/x-gzip') {
    return _tmpgunzip($path);
  } else {
    return undef;
  }
}


# ----------------------------------------------------------------------------
# Return file handle to temporary file containing bunzipped data
# ----------------------------------------------------------------------------
sub _tmpbunzip {
  my $path = shift; # File path

  my $buf;
  my $bsz = $UncompressBufferSize;
  my $tpfh = File::Temp->new();
  throw File::Properties::Error("Error creating temporary file")
    if (not (defined $tpfh and $tpfh->opened));
  my $bz = bzopen($path, 'r') or
    throw File::Properties::Error("Error opening bzip2 file $path");
  while ($bz->bzread($buf, $bsz)) {
    print $tpfh $buf;
  }
  throw File::Properties::Error("Error reading bzip2 file $path: ".$bz->bzerror)
    if $bz->bzerror != BZ_OK and $bz->bzerror != BZ_STREAM_END;
  $bz->bzclose();
  $tpfh->seek(0,0);

  return $tpfh;
}


# ----------------------------------------------------------------------------
# Return file handle to temporary file containing gunzipped data
# ----------------------------------------------------------------------------
sub _tmpgunzip {
  my $path = shift; # File path

  my $buf;
  my $bsz = $UncompressBufferSize;
  my $tpfh = File::Temp->new();
  throw File::Properties::Error("Error creating temporary file")
    if (not (defined $tpfh and $tpfh->opened));
  my $gz = gzopen($path, 'r') or
    throw File::Properties::Error("Error opening gzip file $path");
  while ($gz->gzread($buf, $bsz)) {
    print $tpfh $buf;
  }
  throw File::Properties::Error("Error reading gzip file $path: ".$gz->gzerror)
    if $gz->gzerror != Z_OK and $gz->gzerror != Z_STREAM_END;
  $gz->gzclose();
  $tpfh->seek(0,0);

  return $tpfh;
}


# ----------------------------------------------------------------------------
# End of method definitions
# ----------------------------------------------------------------------------


1;
__END__

=head1 NAME

File::Properties::Compressed - Perl module representing properties of a
compressed file

=head1 SYNOPSIS

  use File::Properties::Cache;
  use File::Properties::Compressed;

  my $fpc = File::Properties::Compressed->cache('cache.db');

  my $fpr = File::Properties::Compressed->new('/path/to/file', $fpc);
  print "Content digest: " . $fpr->cdigest . "\n";


=head1 ABSTRACT

  File::Properties::Compressed is a Perl module representing
  properties of a gzip or bzip2 compressed file; specifically, the
  mime type and SHA-2 digest of the uncompressed content, in addition
  to the properties stored in File::Properties::Regular from which it
  is derived.

=head1 DESCRIPTION

  File::Properties::Compressed is a Perl module representing
  properties of a gzip or bzip2 compressed file; specifically, the
  mime type and SHA-2 digest of the uncompressed content, in addition
  to the properties stored in File::Properties::Regular from which it
  is derived. If a reference to a File::Properties::Cache object is
  specified in the constructor, access to the properties is via the
  cache.

=over 4

=item B<new>

  my $fpr = File::Properties::Compressed->new($path, $fpc);

Constructs a new File::Properties::Compressed object.

=item B<cmimetype>

  print "Content mime type: " . $fpr->cmimetype . "\n";

Determine the file content mime type of the represented file.

=item B<cdigest>

  print "Content digest: " . $fpr->cdigest . "\n";

Determine the file content digest for the represented file.

=item B<cfilehandle>

  my $fh = $fpr->cfilehandle;

Get file handle to the represented file, or to a temporary file
containing the uncompressed content if file is a gzip or bzip2
compressed file.

=item B<iscompressed>

  print "Is a compressed file\n" if ($fpr->iscompressed);

Determine whether the file is a gzip or bzip2 compressed file.

=item B<string>

  print $fpr->string . "\n";

Construct a string representing the object data.

=item B<_cacheinit>

  $fpr->_cacheinit($fpc, $options_hash);

Initialise the regular file properties cache table in the cache
referred to by the File::Properties::Cache reference argument.

=back

=head1 SEE ALSO

L<File::Properties>, L<File::Properties::Cache>,
L<File::Properties::Regular>

=head1 AUTHOR

Brendt Wohlberg E<lt>wohl@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010,2011 by Brendt Wohlberg

This library is available under the terms of the GNU General Public
License (GPL), described in the LICENSE file included in this
distribution.

=cut
