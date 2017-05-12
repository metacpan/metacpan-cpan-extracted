# ----------------------------------------------------------------------------
#
# This module provides a class representing properties of a generic
# disk file.
#
# Copyright © 2010,2011 Brendt Wohlberg <wohl@cpan.org>
# See distribution LICENSE file for license details.
#
# Most recent modification: 5 November 2011
#
# ----------------------------------------------------------------------------

package File::Properties::Generic;
our $VERSION = 0.01;

use File::Properties::Error;

require 5.005;
use strict;
use warnings;
use Error qw(:try);
use Cwd;
use File::stat;
use Fcntl ':mode';
use File::Spec;
use DirHandle;

# This approach copied from File::Spec
my $OSTypes = {MacOS   => 'Mac',   MSWin32 => 'Win32',
	       os2     => 'OS2',   VMS     => 'VMS',
	       epoc    => 'Epoc',  NetWare => 'Win32',
	       symbian => 'Win32', dos     => 'OS2',
	       cygwin  => 'Cygwin'};
my $OSType = $OSTypes->{$^O} || 'Unix';
# Flag indicating whether stat is fully supported. Currently only set
# true for Unix, since other operating systems not available for
# testing.
our $FullStatSupport = ($OSType eq 'Unix')?1:0;


# ----------------------------------------------------------------------------
# Constructor
# ----------------------------------------------------------------------------
sub new {
  my $this = shift;
  my $clss = ref($this) || $this;
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
  my $path = shift; # File path
  my $fpcr = shift; # File::Properties::Cache reference

  # Ensure path specified
  throw File::Properties::Error("Path is not defined")
    if not defined $path;
  # Ensure specified path is readable
  throw File::Properties::Error("Path $path is not readable")
    if not -r $path;
  # Convert specified path to canonical, absolute path
  $self->path(Cwd::realpath($path));
  ## Get file properties via stat call
  my $fstt = stat($path);
  throw File::Properties::Error("Stat failed on $path") if not defined $fstt;
  $self->device($fstt->dev) if ($FullStatSupport);
  $self->inode($fstt->ino) if ($FullStatSupport);
  $self->size($fstt->size);
  $self->mtime($fstt->mtime);
  $self->mode($fstt->mode);
  ## If specified path is a directory, construct child properties
  ## objects for each directory entry
  if ($self->isdir) {
    $self->children($self->_scandir($path, $fpcr));
  } else {
    $self->children(undef);
  }
}


# ----------------------------------------------------------------------------
# Get file path
# ----------------------------------------------------------------------------
sub path {
  my $self = shift;

  $self->{'path'} = shift if (@_);
  return $self->{'path'};
}


# ----------------------------------------------------------------------------
# Get file device number
# ----------------------------------------------------------------------------
sub device {
  my $self = shift;

  if ($FullStatSupport) {
    $self->{'devc'} = shift if (@_);
    return $self->{'devc'};
  } else {
    throw File::Properties::Error("Stat not fully supported");
  }
}


# ----------------------------------------------------------------------------
# Get file inode number
# ----------------------------------------------------------------------------
sub inode {
  my $self = shift;

  if ($FullStatSupport) {
    $self->{'inod'} = shift if (@_);
    return $self->{'inod'};
  } else {
    throw File::Properties::Error("Stat not fully supported");
  }
}


# ----------------------------------------------------------------------------
# Get file size
# ----------------------------------------------------------------------------
sub size {
  my $self = shift;

  $self->{'size'} = shift if (@_);
  return $self->{'size'};
}


# ----------------------------------------------------------------------------
# Get file modification time
# ----------------------------------------------------------------------------
sub mtime {
  my $self = shift;

  $self->{'mtim'} = shift if (@_);
  return $self->{'mtim'};
}


# ----------------------------------------------------------------------------
# Get file mode
# ----------------------------------------------------------------------------
sub mode {
  my $self = shift;

  $self->{'mode'} = shift if (@_);
  return $self->{'mode'};
}


# ----------------------------------------------------------------------------
# Get directory content
# ----------------------------------------------------------------------------
sub children {
  my $self = shift;

  $self->{'chld'} = shift if (@_);
  return $self->{'chld'};
}



# ----------------------------------------------------------------------------
# Test whether file is a regular (plain) file
# ----------------------------------------------------------------------------
sub isreg {
  my $self = shift;

  return $FullStatSupport?S_ISREG($self->mode):(-f $self->path);
}


# ----------------------------------------------------------------------------
# Test whether file is a directory
# ----------------------------------------------------------------------------
sub isdir {
  my $self = shift;

  return $FullStatSupport?S_ISDIR($self->mode):(-d $self->path);
}


# ----------------------------------------------------------------------------
# Construct string description of object
# ----------------------------------------------------------------------------
sub string {
  my $self = shift;
  my $levl = shift;

  $levl = 0 if (!defined $levl);
  my $lpfx = ' ' x (2*$levl);
  my $s;
  $s = $lpfx . "Path: ".$self->path."\n";
  $s .= $lpfx . "Device: ".$self->device." Inode: ".$self->inode." "
    if $FullStatSupport;
  $s .= "Size: ".$self->size." MTime: ".$self->mtime."\n";
  $s .= $self->_dirstring($levl) if ($self->isdir);

  return $s;
}


# ----------------------------------------------------------------------------
# Scan a directory, constructing a hash mapping file basenames to
# File::Properties::Generic objects
# ----------------------------------------------------------------------------
sub _scandir {
  my $self = shift;
  my $path = shift; # Directory path
  my $fpcr = shift; # File::Properties::Cache reference

  throw File::Properties::Error("Path $path is not readable")
    if (not -r $path);
  throw File::Properties::Error("Path $path is not a directory")
    if (not -d $path);
  my $dh = new DirHandle $path;
  throw File::Properties::Error("Error constructing DirHandle for $path")
    if (!defined $dh);
  my $dhsh = {};
  my ($dp, $fp);
  ## Create File::Properties::Generic object for each directory entry
  while (defined($dp = $dh->read)) {
    # Skip . and .. directory entries
    next if ($dp =~ /^\.{1,2}$/);
    # Total path of current directory entry
    $fp = File::Spec->catdir($path, $dp);
    # Add hash entry for current directory entry
    $dhsh->{$dp} = $self->new($fp, $fpcr);
  }
  return $dhsh;
}


# ----------------------------------------------------------------------------
# Construct a string description of an object representing a directory file
# ----------------------------------------------------------------------------
sub _dirstring {
  my $self = shift;
  my $levl = shift;

  $levl = 0 if (!defined $levl);
  my $s = '';
  my $chsh = $self->children;
  if (defined $chsh) {
    my $chld;
    foreach $chld ( sort keys %$chsh ) {
      $s .= $chsh->{$chld}->string($levl + 1);
    }
  }
  return $s;
}


# ----------------------------------------------------------------------------
# End of method definitions
# ----------------------------------------------------------------------------


1;
__END__

=head1 NAME

File::Properties::Generic - Perl module representing properties of a
generic disk file

=head1 SYNOPSIS

  use File::Properties::Generic;

  my $fpg = File::Properties::Generic->new('/path/to/file');
  print $fpg->string . "\n";

=head1 ABSTRACT

  File::Properties::Generic is a Perl module representing properties
  of a generic disk file.

=head1 DESCRIPTION

  File::Properties::Generic is a Perl module representing properties
  of a generic disk file. On architectures on which stat is fully
  supported, indicated by the value of flag
  $File::Properties::Generic::FullStatSupport, these properties
  include device and inode numbers. This flag is currently only set
  true for Unix operating systems (since others were not available for
  testing); on other platforms on which stat does indeed provide
  meaningful device and inode numbers, this value can be forced by
  including a line

  $File::Properties::Generic::FullStatSupport = 1;

  before initialisation of any File::Properties objects.

=over 4

=item B<new>

  my $fpg = File::Properties::Generic->new('/path/to/file');

Constructs a new File::Properties::Generic object.

=item B<path>

  print "Canonical path: " . $fpg->path . "\n";

Determine the canonical path of the represented file.

=item B<device>

  print "Device number: " . $fpg->device . "\n";

Determine the device number of the represented file.

=item B<inode>

  print "Inode number: " . $fpg->inode . "\n";

Determine the inode number of the represented file.

=item B<size>

  print "File size: " . $fpg->size . "\n";

Determine the size of the represented file.

=item B<mtime>

  print "Modification time: " . $fpg->mtime . "\n";

Determine the modification time of the represented file.

=item B<mode>

  print "File mode: " . $fpg->mode . "\n";

Determine the file mode integer (representing permissions and type)
for the represented file.

=item B<children>

  my $chsh = $fpg->children;

If the represented file is a directory, return a hash mapping file
names within that directory to corresponding File::Properties::Generic
object references.

=item B<isreg>

  print (($fpg->isreg)?"Is regular file\n":"Not regular file\n");

Determine if the represented file is a regular file.

=item B<isdir>

  print (($fpg->isdir)?"Is directory\n":"Not directory\n");

Determine if the represented file is a directory.

=item B<string>

  print $fpg->string . "\n";

Construct a string representing the object data.

=back

=head1 SEE ALSO

L<File::Properties>, L<Cwd>, L<File::stat>, L<Fcntl>

=head1 AUTHOR

Brendt Wohlberg E<lt>wohl@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010,2011 by Brendt Wohlberg

This library is available under the terms of the GNU General Public
License (GPL), described in the LICENSE file included in this
distribution.

=cut
