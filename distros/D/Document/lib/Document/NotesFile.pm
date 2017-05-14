#=============================== NotesFile.pm ================================
# Filename:            NotesFile.pm
# Description:         NotesFile file manager.
# Original Author:     Dale Amon
# Revised by:          $Author: amon $ 
# Date:                $Date: 2008-08-28 23:26:17 $ 
# Version:             $Revision: 1.5 $
# License:	       LGPL 2.1, Perl Artistic or BSD
#
#=============================================================================
use strict;
use Fault::ErrorHandler;
use DMA::ISODate;
use File::Spec::DatedPage;

package Document::NotesFile;
use vars qw{@ISA};
@ISA = qw( UNIVERSAL );

#=============================================================================
#				Class Methods
#=============================================================================

sub new {
  my ($class,$directory) = @_;
  my $self = bless {}, $class;

  $directory || 
    (Fault::ErrorHandler->warn ("NotesFile->new: Missing directory path."),
     return undef);

  my $dir = $self->_setdirobj ($directory);
  $dir || return undef;

  $self->{'directory'} = $dir;

  # Read in our own values if the .log already exists, create it if it 
  # doesn't and failure if we can't
  #
  my $log = $dir->pathname . "/.log";
  if (!-f $log) {$self->log("Initialized .notes file for " . $dir->filename);}

  return $self;
}

#=============================================================================
#			Object Methods
#=============================================================================

sub log {
  my ($self,$note,$user) = @_;
  defined $note || ($note="<Empty note>");
  defined $user || ($user="Unknown");

  my $fd;
  my $path = $self->{'directory'}->pathname;
  my $utc  = DMA::ISODate->utc;
  my $msg  = sprintf "%s\n[%s %s%s]", $note, $user,$utc->date,$utc->time;

  # First write the new values to a tmp file.
  if (!open ($fd, ">>$path/.notes")) {
    Fault::ErrorHandler->warn ("Failed to open .notes file at ($path)!");
    return 0;
  }
  
  if (!printf $fd "$msg\n") {
    Fault::ErrorHandler->warn 
	("Failed to write note from user $user: ($note) to ($path)!");
    close $fd; 
    return 0;
  }
  close $fd;
  return 1;
}

#=============================================================================
#			Internal Methods
#=============================================================================
# Check the type of the filename argument. If it is an object of the right
# Class, use it; otherwise return undef

sub _setdirobj {
    my ($self, $dir) = @_;
    my $obj = $dir;

    # If it is not a reference, assume it is a filename string and parse it.
    (ref($dir)) || ($obj = File::Spec::DatedPage->new ($dir));

    ($obj->isa ('File::Spec::DatedPage')) || (return undef);
    return $obj;
}

#=============================================================================
#                       Pod Documentation
#=============================================================================
# You may extract and format the documention section with the 'perldoc' cmd.

=head1 NAME

 Document::NotesFile - NotesFile file manager.

=head1 SYNOPSIS

 use Document::NotesFile;
 $obj  = Document::NotesFile->new ($filespecobj);
 $obj  = Document::NotesFile->new ($filename)
 $okay = $obj->note               ($note,$user);

=head1 Inheritance

 UNIVERSAL

=head1 Description

This Class manages .note files contained within a Document directory. Notes
are special historical or other information about the document added by the
user of a program.

=head1 Examples

 use Document::NotesFile;
 my $baz       = Document::NotesFile->new ($filespecobj);
 my $baz       = Document::NotesFile->new ($pathname);
 my $waslogged = $baz->note ("Washington slept in this file", "BenF" );

=head1 Class Variables

 None.

=head1 Instance Variables

 None.

=head1 Class Methods

=over 4

=item B<$obj = Document::NotesFile-E<gt>new ($filespecobj)>

=item B<$obj = Document::NotesFile-E<gt>new ($filename)>

Create an object to allow communications with a notes file object of a
Document directory defined by $filename or $filespecobj. If there is
currently no file in it named .note, create one and emit a log creation
message about it.

Objects of this Class may be used as inputs to the Fault::Logger class.

All of the path information comes either from a preparsed filename in
$filespecobj, a File::Spec::DatedPage object, or a string containing a
pathname to the target Document directory.

[Can we get by with a File::Spec::Dated object?]

=back 4

=head1 Instance Methods

=over 4

=item B<$okay = $obj-E<gt>log ($note, $user)>

Write a time-stamped message into the .note file of the form:

       $note\n
       [$user 20021207223010]\n

and return true if we succeeded in doing so.

=back 4

=head1 Private Class Methods

 None.

=head1 Private Instance Methods

 None.

=head1 KNOWN BUGS

 See TODO.

=head1 SEE ALSO

Fault::ErrorHandler, DMA::ISODate, File::Spec::DatedPage

=head1 AUTHOR

Dale Amon <amon@vnl.com>

=cut

#=============================================================================
#                                CVS HISTORY
#=============================================================================
# $Log: NotesFile.pm,v $
# Revision 1.5  2008-08-28 23:26:17  amon
# perldoc section regularization.
#
# Revision 1.4  2008-08-13 21:04:32  amon
# Third phase of reformatting to current standard.
#
# Revision 1.3  2008-08-13 20:56:53  amon
# Second phase of reformatting to current standard.
#
# Revision 1.2  2008-08-13 14:50:02  amon
# First phase of reformatting to current standard.
#
# Revision 1.1.1.1  2004-09-27 15:57:01  amon
# Manages a Document directory
#
# 20040927	Dale Amon <amon@islandone.org>
#		Created.
1;
