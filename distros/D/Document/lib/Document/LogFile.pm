#================================ LogFile.pm =================================
# Filename:            LogFile.pm
# Description:         LogFile file manager.
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

package Document::LogFile;
use vars qw{@ISA};
@ISA = qw( UNIVERSAL );

#=============================================================================
#				Class Methods
#=============================================================================

sub new {
  my ($class,$directory) = @_;
  my $self = bless {}, $class;

  $directory || 
    (Fault::ErrorHandler->warn ("LogFile->new: Missing directory path."),
     return undef);

  my $dir = $self->_setdirobj ($directory);
  $dir || return undef;

  $self->{'directory'} = $dir;

  # Read in our own values if the .log already exists, create it if it 
  # doesn't and failure if we can't.
  #
  my $log = $dir->pathname . "/.log";
  if (!-f $log) {$self->log("Initialized logfile for ". $dir->filename);}

  return $self;
}

#=============================================================================
#			Object Methods
#=============================================================================

sub log {
  my ($self,$str) = @_;
  defined $str || ($str="<Null log message>");

  my $fd;
  my $path = $self->{'directory'}->pathname;
  my $utc  = DMA::ISODate->utc;
  my $msg  = sprintf "%s %s UTC> %s", $utc->date,$utc->time,$str;

  # First write the new values to a tmp file.
  if (!open ($fd, ">>$path/.log")) {
    Fault::ErrorHandler->warn ("Failed to open .log file at ($path)!");
    return 0;
  }
  
  if (!printf $fd "$msg\n") {
    Fault::ErrorHandler->warn ("Failed log write: ($str) to ($path)!");
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

 Document::LogFile - LogFile file manager.

=head1 SYNOPSIS

 use Document::LogFile;
 $obj = Document::LogFile->new ($filespecobj);
 $obj = Document::LogFile->new ($filename)
 $okay = $obj->log ($string);

=head1 Inheritance

 UNIVERSAL

=head1 Description

This Class manages .log files contained within a Document directory. Every time
something changes or of interest happens, a message may be written to .log.

=head1 Examples

 use Document::LogFile;
 my $baz       = Document::LogFile->new ($filespecobj);
 my $baz       = Document::LogFile->new ($pathname);
 my $waslogged = $baz->log ( Arf! Arf! );

=head1 Class Variables

 None.

=head1 Instance Variables

 None.

=head1 Class Methods

=over 4

=item B<$obj = Document::LogFile-E<gt>new ($filespecobj)>

=item B<$obj = Document::LogFile-E<gt>new ($filename)>

Create an object to allow communications with a log file object of a Document
directory defined by $filename or $filespecobj. If there is currently no file
in it named .log, create one and emit a log creation message to it.

Objects of this Class may be used as inputs to the Fault::Logger class.

All of the path information comes either from a preparsed filename in
$filespecobj, a File::Spec::DatedPage object, or a string containing a
pathname to the target Document directory.

[Can we get by with a File::Spec::Dated object?]

=back 4

=head1 Instance Methods

=over 4

=item B<$okay = $obj-E<gt>log ($string)>

Write a time-stamped message into the .log file of the form:

       20021207223010 $string\n

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
# $Log: LogFile.pm,v $
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
# Revision 1.1.1.1  2004-08-29 17:04:56  amon
# Manages a Document directory
#
# 20040813      Dale Amon <amon@islandone.org>
#               Moved to Document: from Archivist::
#               to make it easier to enforce layers.
#
# 20040812	Dale Amon <amon@islandone.org>
#		*** NON-COMPATIBLE CHANGE TO API ***
#		Dropped the use of Archivist::File::Directory and such
#		so the class is more indendant and thus more portable
#		to other applications.
#
# 20030108	Dale Amon <amon@vnl.com>
#		Modified log method to check its' args, use ISODate and 
#		return t/f
#
# 20021207	Dale Amon <amon@vnl.com>
#		Created.
1;
