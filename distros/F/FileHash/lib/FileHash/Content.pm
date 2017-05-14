#=============================== Content.pm ==================================
# Filename:  	       Content.pm
# Description:         Generalized hash by md5sum and length of file info.
# Original Author:     Dale M. Amon
# Revised by:          $Author: amon $ 
# Date:                $Date: 2008-08-28 23:35:28 $ 
# Version:             $Revision: 1.7 $
# License:	       LGPL 2.1, Perl Artistic or BSD
#
#=============================================================================
use strict;
use FileHash::Base;
use FileHash::Entry;

package FileHash::Content;
use vars qw{@ISA};
@ISA = qw( FileHash::Base );

#=============================================================================
#                           FAMILY METHODS
#=============================================================================

sub _genKey {
  my ($s,$entry) = @_; 
  my ($md5,$size) = ($entry->md5sum, $entry->sizeBytes);
  return "$md5,$size";
}

#=============================================================================
#                          POD DOCUMENTATION                                
#=============================================================================
# You may extract and format the documention section with the 'perldoc' cmd.

=head1 NAME

 FileHash::Content - A Hash of file data keyed by the file's md5sum.

=head1 SYNOPSIS

 use FileHash::Content;
 $obj = FileHash::Content->alloc;

=head1 Inheritance

 FileHash::Base

=head1 Description

This is a container for lists of file name entries. It modifies the 
definition of hash to to be a combination of an MD5 hash of a file and the 
length of the file in bytes, a string which will almost certainly be unique 
on your file system although theoretically you could have collisions:

	"$hash,$size"

Files with the same size and content will be hashed with the same key so that 
all such instances will be added to the same bucket.

Other than the hash key definition, it inherits its behavior from FileHash::Base.

=head1 Examples

 use FileHash::Content;
 my $a = FileHash::Content->alloc;
 $a->initFromTree ("/root");

=head1 Class Variables

 None.

=head1 Instance Variables

 None.

=head1 Class Methods

=over 4

=item B<$obj = FileHash::Content-E<gt>alloc>

Allocate an empty instance of FileHash::Content.

=back 4

=head1 Instance Methods

 See FileHash::Base.

=head1 Private Class Method

 None.

=head1 Private Instance Methods

=over 4

=item B<$key = $obj-E<gt>_genKey($entry)>

Create an appropriate hash key. If needed values are undef,
it will generate an md5sum or length of 0 for use in constructing
the key. 

=back 4

=head1 Errors and Warnings

 Lots.

=head1 KNOWN BUGS

 See TODO.

=head1 SEE ALSO

 FileHash::Base, FileHash::Entry.

=head1 AUTHOR

Dale Amon <amon@vnl.com>

=cut

#=============================================================================
#                                CVS HISTORY
#=============================================================================
# $Log: Content.pm,v $
# Revision 1.7  2008-08-28 23:35:28  amon
# perldoc section regularization.
#
# Revision 1.6  2008-08-04 12:14:34  amon
# Syntax bug fix.
#
# Revision 1.5  2008-07-27 15:16:17  amon
# Wrote lexical parse for Entry; error checking on eval and other minor issues.
#
# Revision 1.4  2008-07-25 14:30:42  amon
# Documentation improvements and corrections.
#
# Revision 1.3  2008-07-24 13:35:26  amon
# switch to NeXT style alloc/init format for FileHash and Entry classes.
#
# Revision 1.2  2008-07-23 21:12:24  amon
# Moved notes out of file headers; a few doc updates; added assertion checks;
# minor bug fixes.
#
# 20080717	Dale Amon <amon@vnl.com>
#		Split FilenameHash, formerly Directory class, into FileHash
#		FileHash::Name and FileHash::Content. FileHash::Content uses
#		code from DirTreeHash class I wrote in February.
# 20080716	Dale Amon <amon@vnl.com>
#		Created.
# 20080216	Dale Amon <amon@vnl.com>
#		Created DirTreeHash.
1;

