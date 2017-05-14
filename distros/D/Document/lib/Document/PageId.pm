#================================ PageId.pm ==================================
# Filename:            PageId.pm
# Description:         Page Identifier Class.
# Original Author:     Dale Amon
# Revised by:          $Author: amon $ 
# Date:                $Date: 2008-08-28 23:26:17 $ 
# Version:             $Revision: 1.5 $
# License:	       LGPL 2.1, Perl Artistic or BSD
#
# NOTE		* Order matters in the switch statements as a format
#		  will hide those after it if they are subsumed by it.
#
#=============================================================================
use strict;

package Document::PageId;
use vars qw{@ISA};
@ISA = qw( UNIVERSAL );

#=============================================================================
#				Class Methods
#=============================================================================

sub new {
  my ($class, $pageid) = @_;
  my $self = bless {}, $class;

  return $self->_init ($pageid);
}

#-----------------------------------------------------------------------------

sub parse {
  my ($class, $lexeme, $flg) = @_;
  my (@vals) = ("", $lexeme,);
  defined $flg || ($flg = 0);

  my $delim        = ($flg) ? "p" : "";
  my ($lpar,$rpar) =  ($lexeme =~ /^($delim)(.*)/);
  defined $lpar   || ($lpar = "");
  $lpar eq $delim || (return @vals);
  
 SWITCH: {$_ = $rpar;
    # Example:	001.04b
    if (/^(\d+\.\d+[a-z])(.*)/) { @vals = ($1,$2); last SWITCH;}

    # Example:	001.04
    if (/^(\d+\.\d+)(.*)/)	 { @vals = ($1,$2); last SWITCH;}

    # Example:	000.spine
    if (/^(0+.spine)(.*)/)	 { @vals = ($1,$2); last SWITCH;}

    # Example:	000a
    if (/^(\d+[a-z])(.*)/)	 { @vals = ($1,$2); last SWITCH;}

    # Example:	001
    if (/^(\d+)(.*)/)		 { @vals = ($1,$2); last SWITCH;}
  }
  return @vals;
}

#=============================================================================
#			Object Methods
#=============================================================================

sub get       {my ($self) = @_; $self->_update; return $self->{'pageid'};}
sub canonical {my ($self) = @_; $self->_update; return $self->{'pageid'};}

#-----------------------------------------------------------------------------

sub pagenumber       {return shift->{'pagenum'};}
sub subpagenumber    {return shift->{'subpagenum'};}
sub side             {return shift->{'side'};}
sub pagealpha        {return shift->{'side'};}
sub ispairable       {return shift->{'pairable'};}

sub haspagenumber    {return defined shift->{'pagenum'};}
sub hassubpagenumber {return defined shift->{'subpagenum'};}
sub haspagealpha     {return defined shift->{'side'};}

#=============================================================================
#			Internal Methods
#=============================================================================

sub _init {
  my ($self, $pageid) = @_;
  my @vals;

 SWITCH: foreach ($pageid) {
    # Example:	001
    if (/^(\d+)$/)               {@vals = ($1, $1, undef, undef, 
					   length $1, 0, 1, 1); 
				  last SWITCH;}

    # Example:	000a
    if (/^(\d+)([a-z])$/)        {@vals = ($1 . $2, $1, $2, undef,
					   length $1, 0, 1, 2); 
				  last SWITCH;}

    # Example:	000.spine
    if (/^(0+)\.(spine)$/)       {@vals = ("000.spine", $1, $2, undef,
					   length $1, 0, 0, 3);
				  last SWITCH;}

    # Example:	001.04
    if (/^(\d+)\.(\d+)$/)        {@vals = ($1 . "." . $2 , $1, undef, $2,
					   length $1, length $2, 1, 4);
				  last SWITCH;}
    # Example:	001.04b
    if (/^(\d+)\.(\d+)([a-z])$/) {@vals = ($1 . "." . $2 . $3, $1, $3, $2,
					   length $1, length $2, 1, 5);
				  last SWITCH;}
    return undef;
  }

  @$self{'pageid','pagenum','side','subpagenum',
	 'pn_digits','spn_digits','pairable', 'type'} = @vals;

  $self->{'_dirty'} = 0;
  return $self;
}

#-----------------------------------------------------------------------------

sub _update {
  my $self = shift;
  return $self if (!$self->{'_dirty'});

  my $pageid;
  my ($p, $s) = @$self{'pn_digits','spn_digits'};
 SW: {
    $_ = $self->{'type'};
    if (/1/)  {$pageid = sprintf ("%0${p}d",   $self->{'pagenum'});
	       last SW;}
    if (/2/)  {$pageid = sprintf ("%0${p}d%1s", @$self{'pagenum','side'});
	       last SW;}
    if (/3/)  {$pageid = "000.spine"; 
	       last SW;}
    if (/4/)  {$pageid = sprintf ("%0${p}d.%0${s}d", 
				  @$self{'pagenum','subpagenum'});
	       last SW;}
    if (/5/)  {$pageid = sprintf ("%0${p}d.%0${s}d%1s", 
				  @$self{'pagenum','subpagenum','side'});
	       last SW;}
  }
  @$self{'pageid','_dirty'} = ($pageid,0);
  return $self;
}

#=============================================================================
#                       Pod Documentation
#=============================================================================
# You may extract and format the documention section with the 'perldoc' cmd.

=head1 NAME

 Document::PageId - Page Identifier Class.

=head1 SYNOPSIS

 use Document::PageId;

 $obj            = Document::PageId->new   ($string);
 ($pageid,$rest) = Document::PageId->parse ($lexeme,$pflag);

 $string         = $obj->get;
 $string         = $obj->canonical;
 $pagenum        = $obj->pagenumber;
 $subpagenum     = $obj->subpagenumber;
 $side           = $obj->side;
 $side           = $obj->pagealpha;
 $flg            = $obj->ispairable;
 $flg            = $obj->haspagenumber;
 $flg            = $obj->hassubpagenumber;
 $flg            = $obj->haspagealpha;

=head1 Inheritance

 UNIVERSAL

=head1 Description

Page identifiers will usually be a simple format like "001", but over the
years I've found need for variants such as "010.01" and  "000a". Not yet
even thought about are the many locational descriptions for pageid's which
should be moved out of the basic filename: foo-a-toprt, foo-b-botleft, and
all sorts of naming conventions I've used for cases where a single document
page has been scanned as multiple sub-pages. It will probably be a major 
effort to sort this out.

Just as a warning... do not get in the habit of directly accessing the 
pageid ivar. This class and subclasses do lazy evaluation, so if you do
not retrieve the value through the approved methods, you may not get what 
you expect.

=head1 Examples

 None.

=head1 Class Variables

 None.

=head1 Instance Variables

 pageid            Page identification string, eg 050,  000a , 10.1, 100.01b. 
                   Default is undef.
 pagenum           Integer page number part of page id, eg 100.01b
 subpagenum        Integer subpage number, eg 100.01b
 side              Page side, , eg 100.01b
 pn_digits         Number of digits in the page number. Not accessible at
                   present.
 spn_digits        Number of digits in the subpage number. Not accessible at
                   present.
 type              Type of format of this pageid. Internal use.

=head1 Class Methods

=over 4

=item B<$obj = Document::PageId-E<gt>new ($string)>

Create a new pageid object around $string. It returns undef and does not
create an object if $string cannot be parsed as a pageid.

Will I need a last page Class as well? Perhaps subclass first and last? I
might either detect the p here and set a switch or outside and not worry
about it. That might be the cleanest option. I will need a way to autodetect
the field widths of pagenum and subpagenum. I still have not started to deal
with segmented pages, top/mid/bot/left/right nomenclature. Sometimes a and b
are front and back; sometimes they are a fill in for publications with page 1
many pages inside: so I have 00a...00g,01 as page numbers in the front.

=item B<($pageid,$rest) = Document::PageId-E<gt>parse ($lexeme,$pflag)>

Parse the string contained in $lexeme.. If $pflag is set, page number formats
assume a leading 'p', eg. 'p001'. The default is to not require the leading
'p'. 

If $lexeme contains a right justified pageid string, that is returned as 
$pageid and any remaining chars are placed in $rest. If no pageid is found, 
$pageid is and all of $lexeme is return in $rest; if $lexeme is empty or 
undef to start with, both values are .

=back 4

=head1 Instance Methods

=over 4

=item B<$string = $obj-E<gt>canonical>

Return the pageid in a canonical format. Currently the same as verbatim. This
will be useful when I start constructing new pageid's on the fly and want to
generate the "perfect" string according to current rules. 

[Also useful if I someday want to update all files to use a standard format.
Use get for the original page and canonical for the way it should be.]

=item B<$string = $obj-E<gt>get>

Return the original pageid.

=item B<$flg = $obj-E<gt>haspagealpha>

True if there is an alpha part to the pageid.

=item B<$flg = $obj-E<gt>haspagenumber>

True if there is a page number part to the pageid.

=item B<$flg = $obj-E<gt>hassubpagenumber>

True if there is a subpage number part to the pageid..

=item B<$side = $obj-E<gt>ispairable>

Returns true if the pageid contained in this object may be part of a
sequential pair like p001-002. At present the only non-pairable pageid
is 000.spine.

=item B<$side = $obj-E<gt>pagealpha>

Return the page side or alphabetic used for otherwise unnumbered pages within
a page numbered document. In most cases a single sheet of paper or a flyer has
a side a and a side b; however I also use this as a way of handling publications
whose page 1 is 10 pages from the front cover. So I just have a lot of page
000's: 000a,000b,000c....001.

=item B<$pagenum = $obj-E<gt>pagenumber>

Return the page number. 

=item B<$side = $obj-E<gt>side>

A synonym for the pagealpha method.

=item B<$subpagenum = $obj-E<gt>subpagenumber >

Return the sub-page number. This is often used for inserted booklets in
magazines, or updates in manuals.

=back 4

=head1 Private Instance Methods

None.

=head1 Private Instance Methods

=over 4

=item B<$obj  =  $obj-E<gt>_init ($pageid)>

Subclass use only. This method does the bulk of the work for the new class
method. Parses $pageid into components and sets up all the associated ivars.
Returns undef if the pageid is not parseable.

=item B<$obj = $obj-E<gt>_update>

Subclass use only. Using the format information recorded by _init, recreate
the pageid from its parts. This is a way to rebuild the pageid after a
subclass modifies one of its components.

=back 4

=head1 KNOWN BUGS

 See TODO.

=head1 SEE ALSO

 None.

=head1 AUTHOR

Dale Amon <amon@vnl.com>

=cut

#=============================================================================
#                                CVS HISTORY
#=============================================================================
# $Log: PageId.pm,v $
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
# Revision 1.1.1.1  2006-07-05 12:11:24  amon
# Manages a Document directory
#
# 20060705      Dale Amon <amon@islandone.org>
#		A page of (001,01,a) was printing as 00101a because
#		the dot was misplaced in the format statement.
# 20040816      Dale Amon <amon@islandone.org>
#		Added support for a page named 000.spine which cannot
#		exist as part of a pageid pair like 'p001-002'. Added
#		the ispairable method to support this restriction.
#
# 20040813      Dale Amon <amon@islandone.org>
#               Moved to Document:: from Archivist::
#               to make it easier to enforce layers.
#
# 20021211	Dale Amon <amon@vnl.com>
#		Created.
1;
