#=========================== PublicationPage.pm ==============================
# Filename:            PublicationPage.pm
# Description:         Object to parse publication filenames.
# Original Author:     Dale Amon
# Revised by:          $Author: amon $ 
# Date:                $Date: 2008-08-31 23:41:58 $ 
# Version:             $Revision: 1.4 $
# License:	       LGPL 2.1, Perl Artistic or BSD
#
#=============================================================================
use strict;
use DMA::FSM;
use Fault::DebugPrinter;
use File::Spec::DatedPage;

package File::Spec::PublicationPage;
use vars qw{@ISA};
@ISA = qw( File::Spec::DatedPage );

#=============================================================================
#                       Object Methods
#=============================================================================
# Local Lexical Analyzers for splitpath method.

sub _noPublication
 {my ($lexeme, $bb) = @_; $bb->_err("No publication name found"); 
  $bb->{'tail'} = "publication";
  return (1,undef);}

sub _getPublication
 {my ($lexeme, $bb) = @_; @$bb{'publication','tail'} 
    = ($lexeme,"publication"); 
  return (1,undef);}

sub _getPubTitleHead
 {my ($lexeme, $bb) = @_; 
  @$bb{'publication_title_head','tail'} = ($lexeme,"publication_title_head");
  return (1,undef);}

# Annotations start with a lowercase char
sub _getPubSubtitles {
  my ($lexeme, $bb) = @_;
  if ($lexeme =~ /^[^A-Z]/) {return (1,$lexeme);}

  $bb->{'publication_subtitles'} .= 
    ((defined $bb->{'publication_subtitles'}) ? "-" : "") . $lexeme;
  $bb->{'tail'} = "publication_subtitles";
  return (0,undef);
}

sub _getPubNoteHead
  {my ($lexeme, $bb) = @_; 
   @$bb{'publication_annotations','tail'} 
     = ($lexeme,"publication_annotations"); 
   return (1,undef);}

sub _getPubSubnotes
  {my ($lexeme, $bb) = @_; 
   $bb->{'publication_annotations'} .= "-" . $lexeme; return (1,undef);}

sub _getPageTitleHead
 {my ($lexeme, $bb) = @_; 
  @$bb{'page_title_head','tail'} = ($lexeme,"page_title_head"); 
  return (1,undef);}

# Annotations start with a lowercase char
sub _getPageSubtitles {
  my ($lexeme, $bb) = @_;
  if ($lexeme =~ /^[^A-Z]/) {return (1,$lexeme);}

  $bb->{'page_subtitles'} .= 
    ((defined $bb->{'page_subtitles'}) ? "-" : "") . $lexeme;
  $bb->{'tail'} = "page_subtitles";
  return (0,undef);
}

sub _getPageNoteHead
 {my ($lexeme, $bb) = @_; 
  @$bb{'page_annotations','tail'} = ($lexeme,"page_annotations"); 
  return (1,undef);}

sub _getPageSubnotes
 {my ($lexeme, $bb) = @_; 
  $bb->{'page_annotations'} .= "-" . $lexeme; 
  $bb->{'tail'} = "page_annotations";
  return (1,undef);}

sub _noop {my ($lexeme, $bb) = @_; return (1,$lexeme);}

#-----------------------------------------------------------------------------

sub splitpath {
  my ($self,$file) = (shift, shift);

  $self->SUPER::splitpath ($file);
  Fault::DebugPrinter->dbg 
      (4,"Beginning parse for File::Spec::PublicationPage");
  
  my $doctitle_fst = 
    {
     'S0' => ["E0","SAME", \&_getPublication,  "S1", "NEXT", "", ""],
     'S1' => ["D0","SAME", \&_getPubTitleHead, "S2", "NEXT", "", ""],
     'S2' => ["D0","SAME", \&_getPubSubtitles, "S3", "SAME", "S2", "NEXT"],
     'S3' => ["D0","SAME", \&_getPubNoteHead,  "S4", "NEXT", "", ""],
     'S4' => ["D0","SAME", \&_getPubSubnotes,  "S4", "NEXT", "", ""],
     'E0' => ["E0","FAIL", \&_noPublication,   "",   "",     "", ""],
     'D0' => ["D0","DONE", \&_noop,            "",   "",     "", ""],
    };

  my $pagetitle_fst = 
    {
     'S0' => ["D0","SAME", \&_getPageTitleHead,"S1", "NEXT", "S1", "NEXT"],
     'S1' => ["D0","SAME", \&_getPageSubtitles,"S2", "SAME", "S1", "NEXT"],
     'S2' => ["D0","SAME", \&_getPageNoteHead, "S3", "NEXT", "S3", "NEXT"],
     'S3' => ["D0","SAME", \&_getPageSubnotes, "S3", "NEXT", "S3", "NEXT"],
     'E0' => ["E0","FAIL", \&_noop,            "",   "",     "",   ""],
     'D0' => ["D0","DONE", \&_noop,            "",   "",     "",   ""],
    };

  # Append the extensions onto the end of the last entity
  LEXANAL: while ($_=$self->{'tail'}) {
      if (/document_title_section/) {
	$self->{'document_title_section'} = $self->_append_extensions_to_tail;
	last;
      }
      if (/page_title_section/) {
	$self->{'page_title_section'} = $self->_append_extensions_to_tail;
	last;
      }
    }

  my @doctitle_remaining  = 
    DMA::FSM::FSM ($doctitle_fst, $self,
		   split (/-/, $self->{'document_title_section'}));

  my @pagetitle_remaining 
    = DMA::FSM::FSM ($pagetitle_fst, $self,
		     split (/-/, $self->{'page_title_section'}))
      if (defined $self->{'page_title_section'});
  delete $self->{'state'};

  # If page or document_title sections were the tailpart, see if it has 
  # trailing extensions. If the tailpart were pages, there could not have 
  # been anything leftover.
  #
  LEXANAL: {
      $_=$self->{'tail'};
      if (/publication/            ||
	  /publication_title_head/ ||
	  /publication_subtitles/  ||
	  /publication_annotations/) {
	my $lpar = $self->_parse_extensions_from_tail;
	$self->{$_} = ($lpar) ? $lpar : undef;
	$self->reset_document_title_section;
	$self->reset_name_body;
	$self->reset_name;
	last;
      }
      if (/page_title_head/ ||
	  /page_subtitles/  ||
	  /page_annotations/) {
	my $lpar = $self->_parse_extensions_from_tail;
	$self->{$_} = ($lpar) ? $lpar : undef;
	$self->reset_page_title_section;
	$self->reset_name_body;
	$self->reset_name;
	last;
      }
    }

  return (@$self{'volume','basepath','directory',
		 'startdate','enddate',
		 'publication',
                 'publication_title_head','publication_subtitles',
		 'publication_annotations',
		 'startpage','endpage',
		 'page_title_head','page_subtitles','page_annotations'},
	  @{$self->{'extensions'}});
}

#-----------------------------------------------------------------------------
# Set parts of document_title_section.

sub set_publication {my $s=shift; @$s{'publication','_dirty'}=(shift,1); 
		     return $s;}

sub set_publication_title_head
                    {my $s=shift; @$s{'publication_title_head',
				                    '_dirty'}=(shift,1); 
		     return $s;}

sub set_publication_subtitles
                    {my $s=shift; @$s{'publication_subtitles',
				                    '_dirty'}=(shift,1); 
		     return $s;}

sub set_publication_annotations
                    {my $s=shift; @$s{'publication_annotations',
				                    '_dirty'}=(shift,1); 
		     return $s;}

#-----------------------------------------------------------------------------
# Set parts of page_title_section

sub set_page_title_head
                    {my $s=shift; @$s{'page_title_head',
				                    '_dirty'}=(shift,1); 
		     return $s;}

sub set_page_subtitles
                    {my $s=shift; @$s{'page_subtitles',
				                    '_dirty'}=(shift,1); 
		     return $s;}

sub set_page_annotations
                    {my $s=shift; @$s{'page_annotations',
				                    '_dirty'}=(shift,1); 
		     return $s;}

#-----------------------------------------------------------------------------

sub reset_document_title_section {
  my $self = shift;
  my ($title,$del) = ("","");
  my (@list) = (@$self{'publication','publication_title_head',
		       'publication_subtitles','publication_annotations'});
  foreach (@list) {
    $_ || next;
    $title .= "$del$_"; $del = "-";
  }
  return $self->{'document_title_section'} = ($title) ? $title : undef;
}

#-----------------------------------------------------------------------------

sub reset_page_title_section {
  my $self = shift;
  my ($pagesection,$del) = ("","");
  my (@list) = (@$self{'page_title_head',
		       'page_subtitles','page_annotations'});
  foreach (@list) {
    $_ || next;
    $pagesection .= "$del$_"; $del = "-";
  }
  return $self->{'page_title_section'} 
    = ($pagesection) ? $pagesection : undef;
}

#-----------------------------------------------------------------------------

sub publication             {return shift->{'publication'};}
sub publication_title_head  {return shift->{'publication_title_head'};}
sub publication_subtitles   {return shift->{'publication_subtitles'};}
sub publication_annotations {return shift->{'publication_annotations'};}
sub page_title_head         {return shift->{'page_titles_head'};}
sub page_subtitles          {return shift->{'page_subtitles'};}
sub page_annotations        {return shift->{'page_annotations'};}
sub fulltitle               {return shift->{'page_title_section'};}

#-----------------------------------------------------------------------------

sub publication_title_section {
  my $self = shift;
  my ($title,$subtitle,$notes) = 
    (@$self{'publication_title_head',
	    'publication_subtitles',
	    'publication_annotations'});
  defined $title || (return undef);

  my $full = $title;
  defined $subtitle && ($full .= "-$subtitle");
  defined $notes    && ($full .= "-$notes");
  return $full;
}

#-----------------------------------------------------------------------------

sub issuename {
  my $self = shift;
  my ($dates,$publication) = ($self->dates, $self->{'publication'});
  ((defined $dates) && (defined $publication)) || (return undef);

  return "$dates-$publication";
}

#-----------------------------------------------------------------------------

sub pagename {
  my $self = shift;
  my ($issue,$pages) = ($self->issuename, $self->pages);
  ((defined $issue) && (defined $pages)) ||
    (return undef);

  return "$issue-p$pages";
}

#=============================================================================
#                       INTERNAL: Object Methods
#=============================================================================

sub _init {
  my $self = shift;
  $self->SUPER::_init;
  @$self{'publication',
	 'publication_title_head','publication_subtitles',
	 'publication_annotations',
	 'page_title_head','page_subtitles','page_annotations'} = 
	   (undef,
	    undef,undef,
	    undef,
	    undef,undef,undef);
}

#=============================================================================
#                       Pod Documentation
#=============================================================================
# You may extract and format the documention section with the 'perldoc' cmd.

=head1 NAME

 File::Spec::PublicationPage - Parse a dated and page numbered archive file name in a system independant way.

=head1 SYNOPSIS

 use File::Spec::PublicationPage;

 ($volume, $basepath, $directory, 
  $startdate, $enddate, $publication, 
  $publication_title_head, $publication_subtitles, $publication_annotations,
  $startpage, $endpage, 
  $page_title_head, $page_subtitles, $page_annotations, 
  @extensions)               = $obj->splitpath ($filepath);

 $publication_title_section  = $obj->publication_title_section;
 $publication                = $obj->publication;
 $publication_title_head     = $obj->publication_title_head;
 $publication_subtitles      = $obj->publication_subtitles;
 $publication_annotations    = $obj->publication_annotations;
 $page_title_head            = $obj->page_title_head;
 $page_subtitles             = $obj->page_subtitles;
 $page_annotations           = $obj->page_annotations;
 $page_title_section         = $obj->fulltitle;
 $pagename                   = $obj->pagename;
 $issuename                  = $obj->issuename;

 $obj = $obj->set_publication             ($publication);
 $obj = $obj->set_publication_title_head  ($publication_title_head);
 $obj = $obj->set_publication_subtitles   ($publication_subtitles);
 $obj = $obj->set_publication_annotations ($publication_annotations);
 $obj = $obj->set_page_title_head         ($page_title_head);
 $obj = $obj->set_page_subtitles          ($page_subtitles);
 $obj = $obj->set_page_annotations        ($page_annotations);

 $publication_title_sections = $obj->reset_document_title_section;
 $page_title_sections        = $obj->reset_page_title_section;

=head1 Inheritance

 UNIVERSAL
   File::Spec::Unix
     File::Spec::BaseParse
       File::Spec::Dated
         File::Spec::DatedPage
           File::Spec::PublicationPage

=head1 Description

Further splits a pathname string from what it's parent classes have already
done. Using the example publication_title_section string,
XMAS-Title-Subtitle-note, it will be broken down further as:

 publication:               XMAS
 publication_title_head:    Title
 publication_subtitles:     Subtitle
 publication_annotations:   note
 page_title_head:           undef
 page_subtitles:            undef
 page_annotations:          undef

Ordering is used in this parsing. The first "-" delimited element in the
name_body is the publication name; the second is the main title of the
article; the third and remaining items are subtitles of the article unless
the first character is lower case, in which case it is taken to be a local
annotation. 

Such annotations are useful for adding key words to the file name so that
Unix locate and find will be more useful. One might have added 
"-iranStudentRebellion" if the publication or page title did not mention
Iran and one wished to be able to locate all files with information about
Iran.

=head1 Examples

 use File::Spec::PublicationPage;

 my $baz         = File::Spec::PublicationPage->new;
 my @list        = $baz->splitpath
                   ("/my/base/Cards/19901225-XMAS-Title-Subtitle-note.tar.gz");

 my $foo         = File::Spec::PublicationPage->new
                   ("/my/base/Cards/19901225-XMAS-Title-Subtitle-note.tar.gz");

 my $startpage   = $foo->startpage;
 my $endpage     = $foo->endpage;
 my $pages       = $foo->pages;
 my $pagename    = $foo->pagename;
 my $publication = $foo->publication;
 my $pubsection  = $foo->publication_title_section;
 my $dtitle_head = $foo->publication_title_head;
 my $dsubtitle   = $foo->publication_subtitles;
 my $dnotes      = $foo->publication_annotations;
 my $pgsection   = $foo->fulltitle;
 my $ptitle_head = $foo->page_title_head;
 my $psubtitle   = $foo->page_subtitles;
 my $pnotes      = $foo->page_annotations;

 $foo->set_publication             ("JournalOfIrreproduceableResults");
 $foo->set_publication_title_head  ("QuantumBubbling" );
 $foo->set_publication_subtitles   ("ThePintEffect");
 $foo->set_publication_annotations ("allTheTimeInTheworldInAGuinness");

 $foo->set_page_title_head         ("TheCat );
 $foo->set_page_subtitles          ("DeadOrAlive");
 $foo->set_page_annotations        ("whatWillPetaSay");

 my $docsection  = $foo->reset_document_title_section;
 my $pgsection   = $foo->reset_page_title_section;
 my $name_body   = $foo->reset_name_body;
 my $name        = $foo->reset_name;
 my $filename    = $foo->reset_filename;
 my $filepath    = $foo->reset_pathname;
 my @parts       = $foo->reparse;

=head1 Class Variables

 None.

=head1 Instance Variables

 publication               Name of the publication
 publication_title_head    The primary title of the whole document.
 publication_subtitles     Subtitles of the whole document.
 publication_annotations   Annotations on the whole document.
 page_title_head           The primary title of the page.
 page_subtitles            Subtitles of the page.
 page_annotations          Annotations on the page.

=head1 Class Methods

 None.

=head1 Instance Methods

=over 4

=item B<$page_title_section = $obj-E<gt>fulltitle>

Return a $page_full_title string , eg "MainTitle",
"MainTitle-SubtitleOne-SubtitleTwo". "MainTitle-OnlySubtitle-firstNote" or
perhaps "MainTitle-firstNote-secondNote".

undef if there is no page title information associated with this filespec.

=item B<$issuename = $obj-E<gt>issuename>

Return a $issuename string , eg "20021225-NewScientist".

undef if there the date string or publication name is unavailable. Both are 
required.

=item B<$page_annotations = $obj-E<gt>page_annotations>

Return the page annotations string.

=item B<$page_subtitles = $obj-E<gt>page_subtitles>

Return the page subtitles string.

=item B<$page_title_head = $obj-E<gt>page_title_head>

Return the page main title string.

=item B<$pagename = $obj-E<gt>pagename>

Return the page name string, eg "20021225-NewScientist-p010" or undef if the
date string, publication name or pageid string is unavailable. All are 
required.

=item B<$publication = $obj-E<gt>publication>

Return the publication name string.

=item B<$publication_annotations = $obj-E<gt>publication_annotations>

Return the publication annotations string.

=item B<$publication_subtitles = $obj-E<gt>publication_subtitles>

Return the publication subtitles string.

=item B<$publication_title_head = $obj-E<gt>publication_title_head>

Return the publication main title string.

=item B<$publication_title_section = $obj-E<gt>publication_title_section>

Return the publication_title_section string: 

    "publication-title-head publication-subtitles publications-annotations"

or whatever portion is available. Return undef if there is none. 

=item B<$publication_title_sections = $obj-E<gt>reset_document_title_section >

Regenerate the document_title_section from pieces:

     publication + publication_title_head + publication_subtitles + 
     publication_annotations -> document_title_section

=item B<$page_title_sections = $obj-E<gt>reset_page_title_section >

Regenerate the page_title_section from pieces:

  page_title_head + page_subtitles + page_annotations -> page_title_section

=item B<$obj = $obj-E<gt>set_publication ($publication)>

Unconditionally set the publication name.

=item B<$obj = $obj-E<gt>set_publication_annotations ($publication_annotations)>

Unconditionally set the publication annotations.

=item B<$obj = $obj-E<gt>set_publication_subtitles ($publication_subtitles)>

Unconditionally set the publication subtitles.

=item B<$obj = $obj-E<gt>set_publication_title_head ($publication_title_head)>

Unconditionally set the publication_title_head.

=item B<$obj = $obj-E<gt>set_page_annotations ($page_annotations)>

Unconditionally set the page annotations.

=item B<$obj = $obj-E<gt>set_page_subtitles ($page_subtitles)>

Unconditionally set the page subtitles.

=item B<$obj = $obj-E<gt>set_page_title_head ($page_title_head)>

Unconditionally set the page_title_head.

=item B<($volume, $basepath, $directory, $startdate, $enddate, $publication, $publication_title_head, $publication_subtitles, $publication_annotations, $startpage, $endpage, $page_title_head, $page_subtitles, $page_annotations, @extensions) = $obj-E<gt>splitpath ($filepath)>

Override and chain the parent method. Parses the filename into:

  {firstdate{-lastdate}}{-publication
  {-publication_title_head}{-publication_subtitles}{-publication_annotations}}
  {-startpage{-endpage}}
  {-page_title_head}{-page_subtitles}{-page_annotations}}{.extensions}

Returns all the elements of the pathname as a list. Completely reinitializes
the object for the name $filepath.

=back 4

=head1 Private Class Methods

 None.

=head1 Private Instance Methods

=over 4

=item B<$obj = $obj-E<gt>_init>

Internal initializer.

This method is for the subclass initializer chaining and should not be used
otherwise.

=back 4

=head1 KNOWN BUGS

 See TODO.

=head1 SEE ALSO

DMA::FSM, Fault::DebugPrinter, File::Spec::DatedPage

=head1 AUTHOR

Dale Amon <amon@vnl.com>

=cut

#=============================================================================
#                                CVS HISTORY
#=============================================================================
# $Log: PublicationPage.pm,v $
# Revision 1.4  2008-08-31 23:41:58  amon
# Fixed doc title problem, one colon where two were needed by CPAN.
#
# Revision 1.3  2008-08-28 23:32:45  amon
# perldoc section regularization.
#
# Revision 1.2  2008-08-16 17:49:06  amon
# Update source format, documentation; switch to Fault package
#
# Revision 1.1.1.1  2004-08-30 23:43:26  amon
# File Spec extensions for doc name formats.
#
# 20040821      Dale Amon <amon@islandone.org>
#		Switched to Finite State Machine for parsing.
#
# 20040820      Dale Amon <amon@islandone.org>
#		Split Archivist specific portions out of 
#		File::Spec::DatedPage to form 
#		File::Spec::PublicationPage
#
# 20040815      Dale Amon <amon@islandone.org>
#		Changed from Archivist::PublicationSpec to 
#		File::Spec::PublicationPage
#
# 20021208      Dale Amon <amon@vnl.com>
#		Hacked it apart into a Class hierarchy.
#
# 20021121      Dale Amon <amon@vnl.com>
#               Created.
#
1;
