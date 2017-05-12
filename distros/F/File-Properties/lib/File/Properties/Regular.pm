# ----------------------------------------------------------------------------
#
# This module supports computing and caching of file SHA-2 digests and
# mime types.
#
# Copyright © 2010,2011 Brendt Wohlberg <wohl@cpan.org>
# See distribution LICENSE file for license details.
#
# Most recent modification: 18 December 2011
#
# ----------------------------------------------------------------------------

package File::Properties::Regular;
our $VERSION = 0.02;

use File::Properties::Error;
use File::Properties::Generic;
use base qw(File::Properties::Generic);

require 5.005;
use strict;
use warnings;
use Error qw(:try);
use File::Type; # Perhaps use File::MMagic::XS, File::MimeInfo
use Digest::SHA;

our $SHADigestType = 512;
our $CacheTableName = 'RegFileCache';


# ----------------------------------------------------------------------------
# Initialiser
# ----------------------------------------------------------------------------
sub _init {
  my $self = shift;
  my $path = shift; # File path
  my $fpcr = shift; # File::Properties::Cache reference

  # Call base class _init method
  $self->SUPER::_init($path, $fpcr);
  ## Remainder of initialisation only necessary for regular files (in
  ## particular, it should not be performed for directories)
  if ($self->isreg) {
    # Set flag indicating whether file path is cached
    my $cptf = defined $fpcr?
      $fpcr->cproperties($CacheTableName, 'CachedPath'):1;
    # Initialisation for _fromcache method
    $self->{'rfcf'} = {};
    my $cent;
    ## If File::Properties::Cache reference specified and the cache
    ## contains an entry matching the base Generic object, set the mime
    ## type and file digest from the cache entry, otherwise compute
    ## these values.
    if (defined $fpcr and ($cent = $fpcr->cretrieve($CacheTableName,
						    $self->cachekey($cptf)))) {
      $self->mimetype($cent->{'MimeType'});
      $self->digest($cent->{'Digest'});
      # Set flag indicating that this entry was obtained from the cache
      $self->_fromcache($CacheTableName, 1);
    } else {
      $self->mimetype(_mimetype($self->path));
      $self->digest(_digest($self->path));
      # Set flag indicating that this entry was not obtained from the cache
      $self->_fromcache($CacheTableName, 0);
      ## If a File::Properties::Cache reference is specified, record the
      ## mime type and digest in the cache
      if (defined $fpcr) {
	my $row = $self->cachekey($cptf);
	$row->{'MimeType'} = $self->mimetype;
	$row->{'Digest'} = $self->digest;
	$fpcr->cinsert($CacheTableName, $row);
      }
    }
  }
}


# ----------------------------------------------------------------------------
# Get (or set) file mime type
# ----------------------------------------------------------------------------
sub mimetype {
  my $self = shift;

  $self->{'fmtp'} = shift if (@_);
  return $self->{'fmtp'};
}


# ----------------------------------------------------------------------------
# Get (or set) file digest
# ----------------------------------------------------------------------------
sub digest {
  my $self = shift;

  $self->{'fdgs'} = shift if (@_);
  return $self->{'fdgs'};
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

  if (not $self->isdir) {
    $s .= $lpfx . "   File Mime Type: ".$self->mimetype."\n";
    $s .= $lpfx . "   File Digest:    ".substr($self->digest,0,40)."...\n";
  }

  return $s;
}


# ----------------------------------------------------------------------------
# Compute cache key array for this object
# ----------------------------------------------------------------------------
sub cachekey {
  my $self = shift;
  my $cptf = shift; # Cache path flag

  my $key = {'Size' => $self->size, 'ModTime' => $self->mtime};
  # Insert path into key data if path is cached
  $key->{'Path'} = $self->path if ($cptf);
  # Insert device and inode numbers into key data if stat is fully supported
  if ($File::Properties::Generic::FullStatSupport) {
    $key->{'Device'} = $self->device;
    $key->{'Inode'} = $self->inode;
  }
  return $key;
}


# ----------------------------------------------------------------------------
# Create initialised cache object
# ----------------------------------------------------------------------------
sub cache {
  my $self = shift;
  my $dbfp = shift; # Database file path
  my $opts = shift; # Options hash

  # Construct a File::Properties::Cache object attached to the
  # specified database file
  my $fpcr = File::Properties::Cache->new($dbfp, $opts);
  # Initialise the cache table for this class
  $self->_cacheinit($fpcr, $opts);
  return $fpcr;
}


# ----------------------------------------------------------------------------
# Initialise cache table for File::Properties::Regular data
# ----------------------------------------------------------------------------
sub _cacheinit {
  my $self = shift;
  my $fpcr = shift; # File::Properties::Cache reference
  my $opts = shift; # Options hash

  ## Flag determining caching of file path
  my $cptf = 1;
  $cptf = $opts->{'CachedPath'} if (defined $opts->{'CachedPath'});
  $cptf = 1 if (not $File::Properties::Generic::FullStatSupport);
  ## If cache table exists, check that it is compatible with current
  ## options, otherwise initialise it according to options
  if ($fpcr->tableexists($CacheTableName)) {
    # Get array of cache table column names
    my $cnam = $fpcr->columns($CacheTableName);
    # Determine whether cache table column names include 'Path'
    my $ecpt = File::Properties::Cache::_inarray($cnam, 'Path');
    # Throw error if file path caching is requested in options but not
    # configured in cache database
    throw File::Properties::Error("Path caching requested but is not " .
				  "configured in existing cache database")
      if ($cptf and not $ecpt);
    # Set file path caching flag if configured in cache database
    $cptf = 1 if ($ecpt);
    # Determine whether cache table column names include 'Device' and 'Inode'
    my $ecsf = File::Properties::Cache::_inarray($cnam, 'Device') and
               File::Properties::Cache::_inarray($cnam, 'Inode');
    # Throw error if File::Properties::Generic::FullStatSupport flag
    # value does not match flag indicating inclusion of 'Device' and
    # 'Inode' entries in cache table
    throw File::Properties::Error("Mismatch between stat support in current ".
				  "architecture and existing database")
      if (!!$File::Properties::Generic::FullStatSupport != !!$ecsf);
  }
  my $ctbk = []; # Cache table keys
  my $ctbc = []; # Cache table columns
  ## Construct array describing cache table definition
  my $cols = [];
  push @$cols, 'Path TEXT' if ($cptf);
  push @$cols, ('Device INTEGER','Inode INTEGER')
    if ($File::Properties::Generic::FullStatSupport);
  push @$cols,('Size INTEGER','ModTime INTEGER');
  # Construct cache table keys array by removing type specifications
  # from a copy of $cols array
  $ctbk = [map { /^[^\s]+/; $& } @$cols];
  ## Construct final cache table specification array by appending
  ## column definitions for MimeType and Digest to copy of $cols array
  $ctbc = [@$cols];
  push @$ctbc, ('MimeType TEXT','Digest TEXT');
  # Define cache table
  $fpcr->define($CacheTableName, $ctbc, {'IncludeInsertDate' => 1,
	       'TableVersion' => [__PACKAGE__.'::Version', $VERSION]});
  # Make temporary record of path caching flag
  $fpcr->cproperties($CacheTableName, 'CachedPath', $cptf);
}


# ----------------------------------------------------------------------------
# Clear invalid entries in cache table for File::Properties::Regular data
# ----------------------------------------------------------------------------
sub _cacheclean {
  my $self = shift;
  my $fpcr = shift; # File::Properties::Cache reference

  # This operation is only possible if file paths are included in the
  # cache
  if ($fpcr->cproperties($CacheTableName, 'CachedPath')) {
    # Initialise array of paths found not to exist
    my $clst = [];
    # Set the number of database rows retrieved in each database access
    my $nblk = 100;
    # Get the total number of rows in the database
    my $nrow = $fpcr->numrows($CacheTableName);
    my ($k, $l);
    ## Iterate over all database rows, accessing them in blocks of
    ## $nblk rows at a time. Within each block of rows, push any paths
    ## that no longer exist onto the array of paths to be cleared from
    ## the cache.
    for ($k = 0; $k < $nrow / $nblk; $k++) {
      # Compute the number of rows in the current block
      my $lmax = (int($nrow / $nblk) == $k)?($nrow % $nblk):$nblk;
      # Compute the row index of the first row in the current block
      my $ridx = $k * $nblk;
      # Retrieve the current block of rows from the database
      my $rdat = $fpcr->retrieve($CacheTableName,
				 {'ReturnType' => 'Array',
				  'Suffix' => "LIMIT $ridx, $lmax"});
      ## Push any paths that no longer exist onto the clean list
      for ($l = 0; $l < $lmax; $l++) {
	push @$clst, $rdat->[$l]->[0] if (! -f $rdat->[$l]->[0]);
      }
    }
    my $pth;
    ## Iterate over array of non-existent paths and remove the
    ## corresponding cache entry
    foreach $pth (@$clst) {
      $fpcr->remove($CacheTableName, {'Where' => {'Path' => $pth}});
    }
    return 1;
  } else {
    return 0;
  }
}


# ----------------------------------------------------------------------------
# Get or set flag indicating whether data was retrieved from the cache
# ----------------------------------------------------------------------------
sub _fromcache {
  my $self = shift;

  my $mkey = shift;
  $mkey = eval('$' . ref($self) . "::CacheTableName") if not defined $mkey;
  $self->{'rfcf'}->{$mkey} = shift if (@_);
  return $self->{'rfcf'}->{$mkey};
}


# ----------------------------------------------------------------------------
# Compute mime type of file specified by path
# ----------------------------------------------------------------------------
sub _mimetype {
  my $path = shift; # File path

  my $ft = File::Type->new();
  return $ft->checktype_filename($path);
}


# ----------------------------------------------------------------------------
# Compute digest of file specified by path
# ----------------------------------------------------------------------------
sub _digest {
  my $path = shift; # File path

  my $sha = Digest::SHA->new($SHADigestType);
  $sha->addfile($path, 'b');
  return $sha->hexdigest;
}


# ----------------------------------------------------------------------------
# End of method definitions
# ----------------------------------------------------------------------------


1;
__END__

=head1 NAME

File::Properties::Regular - Perl module representing properties of a
regular file

=head1 SYNOPSIS

  use File::Properties::Cache;
  use File::Properties::Regular;

  my $fpc = File::Properties::Regular->cache('cache.db');

  my $fpr = File::Properties::Regular->new('/path/to/file', $fpc);
  print "File digest: " . $fpr->digest . "\n";


=head1 ABSTRACT

  File::Properties::Regular is a Perl module representing properties
  of a regular file; specifically, the mime type and SHA-2 digest of
  the file content, in addition to the properties stored in
  File::Properties::Generic from which it is derived.

=head1 DESCRIPTION

  File::Properties::Regular is a Perl module representing properties
  of a regular file; specifically, the mime type and SHA-2 digest of
  the file content, in addition to the properties stored in
  File::Properties::Generic from which it is derived. If a reference to
  a File::Properties::Cache object is specified in the constructor,
  access to the properties is via the cache.

=over 4

=item B<new>

  my $fpr = File::Properties::Regular->new($path, $fpc);

Constructs a new File::Properties::Regular object.

=item B<mimetype>

  print "File mime type: " . $fpr->mimetype . "\n";

Determine the mime type of the represented file.

=item B<digest>

  print "File digest: " . $fpr->digest . "\n";

Determine the file digest for the represented file.

=item B<string>

  print $fpr->string . "\n";

Construct a string representing the object data.

=item B<cachekey>

  my $cka = $fpr->cachekey($path_is_cached_flag);

Construct an array representing the key for the cache table for this class.

=item B<cache>

  my $fpc = $fpr->cache('cache.db', $options_hash);

Construct a File::Properties::Cache object attached to the specified
database file. If $options_hash includes the key 'CachedPath', its
value determines whether the file path is cached. Note that path
caching is enabled by default, and will also be enabled, ignoring the
'CachedPath' option, if $File::Properties::Generic::FullStatSupport is
false (indicating that file device and inode numbers can not be
determined). All other $options_hash entries are passed on to the
constructor for the File::Properties::Cache class.

=item B<_cacheinit>

  $fpr->_cacheinit($fpc, $options_hash);

Initialise the regular file properties cache table in the cache
referred to by the File::Properties::Cache reference argument.

=back

=head1 SEE ALSO

L<File::Properties>, L<File::Properties::Cache>,
L<File::Properties::Generic>

=head1 AUTHOR

Brendt Wohlberg E<lt>wohl@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010,2011 by Brendt Wohlberg

This library is available under the terms of the GNU General Public
License (GPL), described in the LICENSE file included in this
distribution.

=cut
