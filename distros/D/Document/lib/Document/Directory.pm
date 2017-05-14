#============================== Directory.pm =================================
# Filename:  	       Directory.pm
# Description:         Manage an archival Document directory.
# Original Author:     Dale M. Amon
# Revised by:          $Author: amon $ 
# Date:                $Date: 2008-08-28 23:26:17 $ 
# Version:             $Revision: 1.2 $
# License:	       LGPL 2.1, Perl Artistic or BSD
#
#=============================================================================
use strict;
use File::Spec;
use File::Spec::PublicationPage;
use Fault::ErrorHandler;

use Document::LogFile;
use Document::TocFile;
use Document::Toc;

package Document::Directory;
use vars qw{@ISA};
@ISA = qw( UNIVERSAL );

#=============================================================================
#                          CLASS METHODS                                    
#=============================================================================

sub open ($$$$) {
  my ($class,$path,$date,$title) = @_;
  my $self     = bless {}, $class;
  my $abspath  = File::Spec->rel2abs ($path);
  my $fs = File::Spec::PublicationPage->new ("$abspath/$date-$title");

  if (system ("mkdir", "-p", $fs->pathname) != 0) {
    Fault::ErrorHandler->warn 
	("Could not mkdir -p " . $fs->pathname . "\n");
  }
  my $tocpath = $fs->pathname . "/.toc";
  my $logpath = $fs->pathname . "/.log";
  my $log     = Document::LogFile->new ($fs->pathname);
  (-e $logpath) or return undef;
  
  # Open or create .toc file as necessary; create a toc object in memory.
  my $toc     = Document::Toc->new ();
  my $tocfile = Document::TocFile->open ( $fs->rootpath,
					  $fs->dates,
					  $fs->undated_filename );
  
  # If we created the .toc, log the fact and flush to instantiate it.
  if (! -e $tocpath) {
    $tocfile->flush                         or return undef;
    $log->log ("Created table of contents") or return undef;
  }

  @$self{'filespec','log','toc','tocfile'} = ($fs,$log,$toc,$tocfile);

  return $self;
}

#=============================================================================
#                          INSTANCE METHODS                                 
#=============================================================================

sub add ($$$) {
  my ($self,$pageid,$titles) = @_;
  my ($log,$tocfile,$toc) = @$self{'log','tocfile','toc'};

  (-e $self->pagepath($pageid)) or return undef;

  $log->log ("$pageid Scanned");

  $toc->addPageTitles ($pageid, ($titles) );
  
  # Merge new data so we can go back and add or rescan pages in an existing 
  # document.
  $tocfile->mergeFrom ($toc);
  $tocfile->flush;

  return $self;
}

#-----------------------------------------------------------------------------

sub pagename ($$) {
  my ($self,$pageid) = @_;
  my $fs = $self->{'filespec'};
  return $fs->dates . "-" . $fs->undated_filename . "-p" . $pageid;
}

#-----------------------------------------------------------------------------

sub pagepath ($$) {
  my ($self,$pageid) = @_;
  my $fs = $self->{'filespec'};
  return $fs->pathname . "/" . $self->pagename($pageid) . ".jpeg";
}

#-----------------------------------------------------------------------------

sub filespec ($) {shift->{'filespec'}};

#-----------------------------------------------------------------------------

sub info ($) {
  my $self = shift;
  my $fs   = $self->{'filespec'};

  printf  "[Document]\n" . 
	  "Document Location:         %s\n" .
	  "Document Name:             %s\n" .
	  "Date:                      %s\n" .
	  "Title:                     %s\n",
	  $fs->rootpath,
	  $fs->filename,
	  $fs->dates,
	  $fs->undated_filename;
  return $self;
}

#=============================================================================
#                          POD DOCUMENTATION                                
#=============================================================================
# You may extract and format the documention section with the 'perldoc' cmd.

=head1 NAME

 Document::Directory - Manage an archival Document directory.

=head1 SYNOPSIS

 use Document::Directory;
 $obj = Document::Directory->open($path,$date,$title);
 $obj = $obj->add ($pageid,$tiles);
 $str = $obj->pagename ($pageid);
 $str = $obj->pagepath ($pageid);
 $fs  = $obj->filespec;
 $obj = $obj->info;

=head1 Inheritance

 UNIVERSAL

=head1 Description

Manage a Document directory. A document directory contains images of document
pages along with a table of contents file (.toc) and a log of what has been
done to the document and pages in it. A Document is not a transient object
that will be edited or updated. It is an artifact that once created should
not be modified. 

There are of course some cases in which such changes might be needed. If a
page scan is badly done there might be a good reason to replace it. In such
cases the old page scan will be saved along with the new one.

While content should not be changed, the .toc file and the file naming can
be modified, but the fact of such changes will be logged.

=head1 Examples

 None.

=head1 Class Variables

 None.

=head1 Instance Variables

 filespec	A filespec object containing the document name and location
 logfile	A document log file object.
 tocfile        A document table of contents file object
 toc		In memory copy of the table of contents.

=head1 Class Methods

=over 4

=item B<$obj = Document::Directory-E<gt>open ($path,$date,$title)>

Create and initialize instances of Document::Directory for a document that
is located at $path and has a name of "$date-$title".

=head1 Instance Methods

=over 4

=item B<$obj = $obj-E<gt>add ($pageid,$titles)>

If a the file associated with $pageid exists, add the page id and titles to the .toc
file and log the date and time at which this was done.

Returns undef if any of these actions failed.

=item B<$str = $obj-E<gt>pagename ($pageid)>

Return the complete page name for $pageid. The name does not
include a file extension.

=item B<$str = $obj-E<gt>pagepath ($pageid)>

Return the absolute path name which should be used to access $pageid. The
file extension is assumed to be .jpeg.

=item B<$fs = $obj-E<gt>filespec)>

Return the filespec object which contains the document name and location.

=item B<$fs = $obj-E<gt>filespec)>

Print information about the document:

  [Document]
  Document Location:         /Archive/Publications/NuclearHobbiest/
  Document Name:             20080827-NuclearHobbiest
  Date:                      20080827
  Title:                     NuclearHobbiest

=back 4

=head1 Private Class Method

 None.

=head1 Private Instance Methods

 None.

=head1 KNOWN BUGS

 See TODO.

=head1 Errors and Warnings

 None.

=head1 SEE ALSO

 Document::Toc, Document::TocFile, Document::LogFile

=head1 AUTHOR

Dale Amon <amon@vnl.com>

=cut

#=============================================================================
#                                CVS HISTORY
#=============================================================================
# $Log: Directory.pm,v $
# Revision 1.2  2008-08-28 23:26:17  amon
# perldoc section regularization.
#
# Revision 1.1  2008-08-28 15:43:20  amon
# Added Directory class to handle document directory
#
# Revision 1.2  2008-08-07 19:52:48  amon
# Upgrade source format to current standard.
#
# Revision 1.1.1.1  2008-08-06 21:36:11  amon
# Classes for scanner use abstractions.
#
# 20070511   Dale Amon <amon@islandone.org>
#	     Created.
1;
