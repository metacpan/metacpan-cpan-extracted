#================================= Name.pm ===================================
# Filename:  	       Name.pm
# Description:         Generalized hash by full path of file information.
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

package FileHash::Name;
use vars qw{@ISA};
@ISA = qw( FileHash::Base );

#=============================================================================
#                           FAMILY METHODS
#=============================================================================

sub _genKey {my ($s,$entry) = @_; return $entry->file;}

#=============================================================================
#                          POD DOCUMENTATION                                
#=============================================================================
# You may extract and format the documention section with the 'perldoc' cmd.

=head1 NAME

 FileHash::Name - A Hash of file data keyed by the file's name.

=head1 SYNOPSIS

 use FileHash::Name;
 $obj = FileHash::Name->alloc;

=head1 Inheritance

 FileHash::Base

=head1 Description

This is a container for lists of file name entries. It modifies the 
definition of hash to to be the file name portion of the absolute path. For 
instance:

	/my/directory/foo.jpg

would be hashed as foo.jpg so that all instances of that name will be 
added to the same bucket.

Other than the hash key definition, it inherits its behavior from FileHash::Base.

=head1 Examples

 use FileHash::Content;
 my $a = FileHash::Name->alloc;
 $a->initFromTree ("/root");

=head1 Class Variables

 None.

=head1 Instance Variables

 None.

=head1 Class Methods

=over 4

=item B<$obj = FileHash::Name-E<gt>alloc>

Allocate an empty instance of FileHash::Name.

=back 4

=head1 Instance Methods

 See FileHash::Base.

=head1 Private Class Method

 None.

=head1 Private Instance Methods

=over 4

=item B<$key = $obj-E<gt>_genKey($entry)>

Create an appropriate hash key. If needed values are undef,
it will generate a name of "" for the key.

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
# $Log: Name.pm,v $
# Revision 1.7  2008-08-28 23:35:28  amon
# perldoc section regularization.
#
# Revision 1.6  2008-08-04 12:15:12  amon
# Changed 'use' list.
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
#		FileHash::Name and FileHash::Content.
# 20080625	Dale Amon <amon@vnl.com>
# 		Created Directory class.
1;
