#============================== DatedPage.pm =================================
# Filename:            DatedPage.pm
# Description:         Object to parse dated filenames with page numbers.
# Programmed by:       Dale Amon <amon@islandone.org> 
# Revised by:          $Author: amon $ 
# Date:                $Date: 2008-08-31 23:41:58 $ 
# Version:             $Revision: 1.4 $
# License:	       LGPL 2.1, Perl Artistic or BSD
#
#==============================================================================
use strict;
use Fault::DebugPrinter;
use DMA::FSM;
use Document::PageId;
use File::Spec::Dated;

package File::Spec::DatedPage;
use vars qw{@ISA};
@ISA = qw( File::Spec::Dated );

#==============================================================================
#                       Object Methods
#==============================================================================
# Local Lexical Analyzers for splitpath method.

sub _getDocTitleAndStartPage {
  my ($lexeme, $bb) = @_;
  my $lpar;

  # Is it a page number? Flag is true to require leading p.
  ($lpar,$lexeme) = Document::PageId->parse($lexeme,1);

  if ($lpar) {
    @$bb{'startpage','del','tail'} = ($lpar,"","startpage");
    return (1,$lexeme);
  }

  # Swallow title lexemes
  $bb->{'document_title_section'} .= $bb->{'del'} . $lexeme;
  @$bb{'del','tail'} = ("-","document_title_section");
  return (0,undef);
}

sub _getSecondPage {
  my ($lexeme, $bb) = @_;
  my $lpar;

  # Check for ending page. Flag is false to require NO leading p.
  ($lpar,$lexeme) = Document::PageId->parse($lexeme, 0);
  if ($lpar) {
    @$bb{'endpage','tail'} = ($lpar,"endpage");
    return (1,$lexeme);
  }
  return (0,$lexeme);
}

sub _getPageTitle {
  my ($lexeme, $bb) = @_;
  $bb->{'page_title_section'} .= $bb->{'del'} . $lexeme;
  @$bb{'del','tail'} = ("-","page_title_section");
  return (1,undef);
}

sub _noop {my ($lexeme, $bb) = @_; return (1,$lexeme);}

#------------------------------------------------------------------------------

sub splitpath {
  my ($self,$file) = (shift, shift);

  my $fst = 
    {
     'S0' => ["D0","SAME", \&_getDocTitleAndStartPage,"S1","TSTL","S0","NEXT"],
     'S1' => ["D0","SAME", \&_getSecondPage,          "S2","NEXT","S2","SAME"],
     'S2' => ["D0","SAME", \&_getPageTitle,           "S2","NEXT","",""],
     'D0' => ["D0","DONE", \&_noop,                   "","","",""],
    };  

  $self->SUPER::splitpath ($file);
  Fault::DebugPrinter->dbg (4, "Beginning parse for File::Spec::DatedPage");

  $self->{'del'} = "";
  $self->{'name_body'} =  $self->_append_extensions_to_tail;

  # There really should be nothing remaining; I only capture this so I'll 
  # remember it exists in case I do find a future need to look at it.
  #
  my @remaining = DMA::FSM::FSM ( $fst, $self, 
				  split (/-/, $self->{'name_body'}));
  delete $self->{'del'};
  delete $self->{'state'};

  # If page or document_title sections were the tailpart, see if it has 
  # trailing extensions. If the tailpart were pages, there could not have 
  # been anything leftover.
  #
  {$_ = $self->{'tail'};
   if (/page_title_section/ ||
       /document_title_section/) {
     my $lpar    = $self->_parse_extensions_from_tail;
     $self->{$_} = ($lpar) ? $lpar : undef;
     $self->reset_name_body;
     $self->reset_name;
   }
 }

  return (@$self{'volume','basepath','directory',
		 'startdate','enddate',
		 'document_title_section',
		 'startpage','endpage',
		 'page_title_section'},
	  @{$self->{'extensions'}});
}

#------------------------------------------------------------------------------
# Set parts of a name_body

sub set_startpage   {my $s=shift; @$s{'startpage',  '_dirty'}=(shift,1); 
		     return $s;}

sub set_endpage     {my $s=shift; @$s{'endpage',    '_dirty'}=(shift,1); 
		     return $s;}

sub set_document_title_section
  		    {my $s=shift; @$s{'document_title_section',
				                    '_dirty'}=(shift,1); 
		     return $s;}
sub set_page_title_section
                    {my $s=shift; @$s{'page_title_section',
				                    '_dirty'}=(shift,1); 
		     return $s;}

#------------------------------------------------------------------------------

sub reset_name_body {
  my $self = shift;
  my ($namebody,$del) = ("","");
  my (@list) = (@$self{'document_title_section',
		       'startpage','endpage',
		       'page_title_section'});
  $list[1] = (defined $list[1]) ? "p$list[1]" : undef;

  foreach (@list) {
    $_ || next;
    $namebody .= "$del$_"; $del = "-";
  }
  return $self->{'name_body'} = ($namebody) ? $namebody : undef;
}

#------------------------------------------------------------------------------

sub startpage              {return shift->{'startpage'};}
sub endpage                {return shift->{'endpage'};}
sub document_title_section {return shift->{'document_title_section'};}
sub page_title_section     {return shift->{'page_title_section'};}
sub ambiguous              {return shift->{'ambiguous'};}

#------------------------------------------------------------------------------

sub pages {
  my $self = shift;
  my ($beg,$end) = ($self->{'startpage'}, $self->{'endpage'});
  defined $beg || (return undef);
  defined $end || (return $beg);
                   return $beg . "-" . $end;
}

#==============================================================================
#                       INTERNAL: Object Methods
#==============================================================================

sub _init {
  my $self = shift;
  $self->SUPER::_init;
  @$self{'document_title_section',
	 'startpage','endpage',
	 'page_title_section',
	 'ambiguous'} = 
	   (undef,undef,undef,undef,0 );
}

#==============================================================================
#                       Pod Documentation
#==============================================================================
# You may extract and format the documention section with the 'perldoc' cmd.

=head1 NAME

 File::Spec::DatedPage - Parse a dated and page numbered file name in a system independant way.

=head1 SYNOPSIS

  use File::Spec::DatedPage;

 ($volume, $basepath, $directory, 
  $startdate, $enddate, $document_title_section,
  $startpage, $endpage, $page_title_section,
  @extensions)           = $obj->splitpath ($filepath);

 $document_title_section = $obj->document_title_section;

 $startpage = $obj->startpage;
 $endpage   = $obj->endpage;
 $pages     = $obj->pages;

 $page_title_section = $obj->page_title_section;

 $flag      = $obj->ambiguous;
 $obj      = $obj->set_document_title_section ($document_title_section);
 $obj      = $obj->set_startpage              ($startpage);
 $obj      = $obj->set_endpage                ($endpage);
 $obj      = $obj->set_page_title_section     ($page_title_section);

 $name_body = $obj->reset_name_body;

=head1 Inheritance

 UNIVERSAL
   File::Spec::Unix
     File::Spec::BaseParse
       File::Spec::Dated
         File::Spec::DatedPage

=head1 Description

Further splits a pathname string from what it's parent classes have already
done. Using the example name_body string, XMAS-Title-Subtitle-note, it will
be broken down further as:

 document_title_section:    XMAS-Title-Subtitle-note
 startpage:
 endpage
 page_title_section:

The 'ambiguous' flag is not implemented yet: it is only talked about.. It
should mark cases where a file extension might really be part of a filename
as shown in File::Spec::Dated. This is the first semantic level at which it
seems to matter. I have  now made sure it does not exist outside this module
so as to make it easy to purge if I decide it is an unworkable idea.

=head1 Examples

 use File::Spec::DatedPage;
 my $baz        = File::Spec::DatedPage->new;
 my @list       = $baz->splitpath
                  ("/my/base/Cards/19901225-XMAS-Title-Subtitle-note.tar.gz");

 my $foo        = File::Spec::DatedPage->new
                  ("/my/base/Cards/19901225-XMAS-Title-Subtitle-note.tar.gz");

 my $startpage  = $foo->startpage;
 my $endpage    = $foo->endpage;
 my $pages      = $foo->pages;
 my $dtitle     = $foo->document_title_section;
 my $ptitle     = $foo->page_title_section;

 $foo->set_startpage  ("100");
 $foo->set_endpage    ("101");
 $foo->set_document_title_section 
                      ("JournalOfIrreproduceableResults-QuantumBubbling" );
 $foo->set_page_title_section ("ThePintEffect-allTheTimeInTheworldInAGuinness");
 my $name_body  = $foo->reset_name_body;
 my $name       = $foo->reset_name;
 my $filename   = $foo->reset_filename;
 my $filepath   = $foo->reset_pathname;
 my @parts      = $foo->reparse;

=head1 Class Variables

 None.

=head1 Instance Variables

 document_title_section   Title of the whole document.
 startpage                Starting page string.
 endpage                  Ending page string.
 page_title_section       Title specifically associated with the page.
 ambiguous                Set if it is ambiguous whether  the leftmost file
                          extension really is a file extension.

=head1 Class Methods

 None.

=head1 Instance Methods

=over 4

=item B<$flag = $obj-E<gt>ambiguous>

Return true if it is ambiguous whether the rightmost file extension is really
a file extension.

=item B<$document_title_section = $obj-E<gt>document_title_section>

Return the document title section string.

=item B<$endpage = $obj-E<gt>endpage>

Return the ending pageid object or undef if there is none.

=item B<$pages = $obj-E<gt>pages>

Return a $pages string suitable for use in an index or table of contents, 
eg "100", "100-101" or "42.1-42.2".

Return undef if there is no page information associated with this filespec.

=item B<$page_title_section = $obj-E<gt>page_title_section>

Return the title string.

=item B<$obj = $obj-E<gt>set_endpage  ($endpage)>

Unconditionally set the end page.

=item B<$obj = $obj-E<gt>set_document_title_section ($document_title_section)>

Unconditionally set the document_title_section string.

=item B<$obj = $obj-E<gt>set_startpage ($startpage)>

Unconditionally set the start page.

=item B<$obj = $obj-E<gt>set_page_title_section ($page_title_section)>

Unconditionally set the page_title_section.

=item B<($volume, $basepath, $directory, $startdate, $enddate, $document_title_section, $startpage, $endpage, $page_title_section, @extensions) = $obj-E<gt>splitpath ($filepath)>

Parses the filename into:

 {firstdate{-lastdate}}{-title}{-startpage{-endpage}}{-subtitle}{.extensions}

and returns all the elements of the pathname and filename as a list. 
Completely reinitializes the object for the name $filepath.

=item B<$startpage = $obj-E<gt>startpage>

Return the starting pageid object.

=item B<$name_body = $obj-E<gt>reset_name_body >

Rebuild the name_body ivar from parts:

 document_title_section + startpage + endpage + page_title_section -> name_body

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

Fault::DebugPrinter, DMA::FSM, Document::PageId, File::Spec::Dated

=head1 AUTHOR

Dale Amon <amon@vnl.com>

=cut

#=============================================================================
#                                CVS HISTORY
#=============================================================================
# $Log: DatedPage.pm,v $
# Revision 1.4  2008-08-31 23:41:58  amon
# Fixed doc title problem, one colon where two were needed by CPAN.
#
# Revision 1.3  2008-08-28 23:32:45  amon
# perldoc section regularization.
#
# Revision 1.2  2008-08-16 17:49:06  amon
# Update source format, documentation; switch to Fault package
#
# Revision 1.1.1.1  2004-09-02 12:37:47  amon
# File Spec extensions for doc name formats.
#
# 20040821      Dale Amon <amon@islandone.org>
#		Switched to Finite State Machine for parsing.
#
# 20040820      Dale Amon <amon@islandone.org>
#		Split it up. Much has gone to File::Spece:PublicationPage.
#		This class now just parses out:
#			<dates>-<title>-<pages>-<subtitle>
#		Where title and subtitle now have a different meaning
#		than they used to: before I used 'title' to mean the
#		first dash delimited text item after a publication name;
#		the rest of the set were the subtitles. I was not really
#		dealing with a set of article titles after the pageid's.
#		Now I have dubbed all of the first set of -text- items
#		as title and the second set as subtitle. So I need new
#		names for the 'first and rest' for both sets now.
#
# 20040815      Dale Amon <amon@islandone.org>
#		Changed from Archivist::PublicationSpec to 
#		File::Spec::DatedPage
#
# 20021208      Dale Amon <amon@vnl.com>
#		Hacked it apart into a Class hierarchy.
#
# 20021121      Dale Amon <amon@vnl.com>
#               Created.
#
1;
