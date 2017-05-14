#================================== Toc.pm ===================================
# Filename:            Toc.pm
# Description:         Manage a Table of contents file.
# Original Author:     Dale Amon
# Revised by:          $Author: amon $ 
# Date:                $Date: 2008-08-28 23:26:17 $ 
# Version:             $Revision: 1.5 $
# License:	       LGPL 2.1, Perl Artistic or BSD
#
#=============================================================================
use strict;
use Document::Members;
use Fault::DebugPrinter;

package Document::Toc;
use vars qw{@ISA};
@ISA = qw( Document::Members );

#=============================================================================
#			Object Methods
#=============================================================================
#			Predicate operators
#-----------------------------------------------------------------------------

sub havePage {
  my ($self)    = shift;
  my ($pagenum) = @_;
  defined $pagenum || (return 0);
  return ($self->_havepage (@_));
}

#-----------------------------------------------------------------------------

sub havePageTitle {
  my ($self)           = shift;
  my ($pagenum,$title) = @_;

  defined $pagenum         || (return 0);
  defined $title           || (return 0);

  ($self->_havepage  (@_)) || (return 0);
  return ($self->_havetitle (@_));
}

#-----------------------------------------------------------------------------

sub havePageTitleCategory {
  my ($self)                     = shift;
  my ($pagenum,$title,$category) = @_;

  defined $pagenum         || (return 0);
  defined $title           || (return 0);
  defined $category        || (return 0);

  ($self->_havepage  (@_)) || (return 0);
  ($self->_havetitle (@_)) || (return 0);
  return ($self->_havecategory (@_));
}

#-----------------------------------------------------------------------------
#			Key listing operators
#-----------------------------------------------------------------------------

sub pages {return (shift->_listpages)}

#-----------------------------------------------------------------------------

sub pageTitles {
  my $self      = shift;
  my ($pagenum) = @_;

  defined $pagenum        || (return undef);
  ($self->_havepage (@_)) || (return undef);
  return ($self->_listtitles (@_));
}

#-----------------------------------------------------------------------------

sub pageTitleCategories {
  my $self             = shift;
  my ($pagenum,$title) = @_;

  defined $pagenum         || (return undef);
  defined $title           || (return undef);
  ($self->_havetitle (@_)) || (return undef);
  return ($self->_listcats (@_));
}

#-----------------------------------------------------------------------------
#			Add operators
#-----------------------------------------------------------------------------

sub addPages {
  my ($self)  = shift;
  foreach my $p (@_) {($self->_havepage ($p)) || ($self->_initpage ($p));}
  $self->_l8r;
  return 1;
}

#-----------------------------------------------------------------------------

sub addPageTitles{
  my ($self) = shift;
  my ($p)    = shift;

  defined $p             || (return 0);
 ($self->_havepage ($p)) || ($self->_initpage ($p));

  foreach my $t (@_) {
    ($self->_havetitle ($p,$t)) || ($self->_inittitle ($p,$t));
  }
  $self->_l8r;
  return 1;
}

#-----------------------------------------------------------------------------

sub addPageTitleCategories {
  my ($self)           = shift;
  my ($pagenum,$title, @categories) = @_;

  defined $pagenum || (return 0);
  defined $title   || ($title="");

  Fault::DebugPrinter->dbg
      (2,"Toc->addPageTitleCategories [$pagenum], [$title], [@categories]");
  
  ($self->_havepage    (@_)) || ($self->_initpage  (@_));
  ($self->_havetitle   (@_)) || ($self->_inittitle (@_));
  $self->_mergecatlist (@_);
  $self->_l8r;
  return 1;
}

#-----------------------------------------------------------------------------
#			Remove operators
#-----------------------------------------------------------------------------

sub removePages {
  my $self      = shift;
  foreach my $p (@_) {($self->_havepage ($p)) && ($self->_killpage ($p));}
  $self->_l8r;
  return 1;
}

#-----------------------------------------------------------------------------

sub removePageTitles {
  my ($self,$p) = (shift,shift);

  defined $p || (return 0);

  foreach my $t (@_) {
    ($self->_havetitle ($p,$t)) && ($self->_killtitle ($p,$t));
  }
  $self->_l8r;
  return 1;
}

#-----------------------------------------------------------------------------

sub removePageTitleCategories {
  my ($self,$p,$t) = (shift,shift,shift);

  defined $p || (return 0);
  defined $t || (return 0);

  # NOTE: It is probably possible to do this all in 1 line like _mergecatlist
  #
  foreach my $c (@_) {
    ($self->_havecategory ($p,$t,$c)) && ($self->_killcategory ($p,$t,$c));
  }

  $self->_l8r;
  return 1;
}

#-----------------------------------------------------------------------------
#			Replace operators
#-----------------------------------------------------------------------------

sub replacePageTitle {
  my ($self,$p,$o,$n) = @_;
  defined $p                   || (return 0);
  defined $o                   || (return 0);
  defined $n                   || (return 0);
  (!$self->_havetitle ($p,$n)) || (return 0);
  ($self->_havetitle ($p,$o))  || (return 0);

  $self->_duptitle ($p,$o,$n);
  $self->_killtitle ($p,$o);
  $self->_l8r;
  return 1;
}

#-----------------------------------------------------------------------------
#	       Current selection or "bookmark" methods
#-----------------------------------------------------------------------------

sub setpage       {my $s=shift; return (@{$s->{'mark'}}=($s->_selpage (@_)));}
sub settitle      {my $s=shift; return (@{$s->{'mark'}}=($s->_seltitle(@_)));}
sub setcategories {my $s=shift; return (@{$s->{'mark'}}=($s->_selcats     ));}
sub setmark       {my $s=shift; return (@{$s->{'mark'}}=($s->_selall  (@_)));}

sub setfirstpage  {my $s=shift; 
		   return (@{$s->{'mark'}}=($s->_selpage ($s->_1stpage )));}
sub setfirsttitle {my $s=shift; 
		   return (@{$s->{'mark'}}=($s->_seltitle($s->_1sttitle)));}

#-----------------------------------------------------------------------------

sub curpage       {my $s=shift; 
		   my ($page, $title, @categories) = @{$s->{'mark'}}; 
		   return $page;}

sub curtitle      {my $s=shift; 
		   my ($page, $title, @categories) = @{$s->{'mark'}}; 
		   return $title;}

sub curpages      {return shift->pages;}

sub curtitles     {my $s=shift; 
		   return ($s->pageTitles          (@{$s->{'mark'}}));}

sub curcategories {my $s=shift; 
		   return ($s->pageTitleCategories (@{$s->{'mark'}}));}

#-----------------------------------------------------------------------------
#	           Override most parent methods
#-----------------------------------------------------------------------------

sub isMember      {return shift->havePage    (@_);}
sub addMembers    {return shift->addPages    (@_);}
sub members       {return (shift->pages      (@_));}
sub removeMembers {return shift->removePages (@_);}

#=============================================================================
#			Internal Methods
#=============================================================================

sub _lazy {
  my $self = shift;
  $self->SUPER::_lazy || return 0;

  my ($p,$t,@c) = @{$self->{'first'}};
  $t = (defined $p) ? $self->_1sttitle($p)    : undef;
  @c = (defined $t) ? $self->_listcats($p,$t) : undef;
  @{$self->{'first'}} = ($p, $t, @c);
  return 1;
}

#=============================================================================
# The following are a set of internal primitive operations on the toc data
# structure. They are used by external methods which also do arg checking.
#=============================================================================
# Args:		self
# Returns:	_listpages returns list of pages in toc
#		_cntpages  returns the number of keys in the hash
#		_1stpage   returns the first element of the sorted keys,
#			    undef if there are none.

sub _listpages  {return (keys %{shift->{'toc'}});}
sub _cntpages   {return shift->_cntmembers;}
sub _1stpage    {return shift->_1stmember;}

#-----------------------------------------------------------------------------
# Args:		self
#		pagenum
# Returns:	_havepage returns true or false
#		_listtitles returns list of titles on page
#		_1sttitle returns 1st element of sorted title hash keys
#		others return nothing.

sub _initpage   {               shift->{'toc'}->{+shift} = {};}
sub _killpage   {        delete shift->{'toc'}->{+shift};}
sub _havepage   {return  exists shift->{'toc'}->{+shift};}
sub _listtitles {return (sort keys %{shift->{'toc'}->{+shift}});}
sub _1sttitle   {my ($s,$p)=(shift,shift);
		 return ($s->_cnttitles($p) > 0) ? 
		   ($s->_listtitles($p))[0] : undef;}

#-----------------------------------------------------------------------------
# Args:		self
#		pagenum
#		title
# Returns:	_havetitle returns true or false
#		_listcats returns list of categories for title
#		_cnttitles returns the number of title hash keys 
#		others return nothing.

sub _inittitle  {               shift->{'toc'}->{+shift}->{+shift} = {};}
sub _killtitle  {        delete shift->{'toc'}->{+shift}->{+shift};}
sub _havetitle  {return  exists shift->{'toc'}->{+shift}->{+shift};}
sub _cnttitles  {return ($#{ [keys %{shift->{'toc'}->{+shift}}] } + 1);}
sub _listcats   {return (sort keys %{shift->{'toc'}->{+shift}->{+shift}});}

#-----------------------------------------------------------------------------
# _mergecatlist: Take the title's hash address; set all elements (if any) 
#                named in categories to undef. This will merge the new list 
#		 with the existing list.
#
# Args:		self
#		pagenum
#		title
#		category, except _addcategory for which it is @categories
# Returns:	_havecategory returns true or false
#		_cntcats returns the number of category hash keys
#		others return nothing.

sub _initcategory {              shift->{'toc'}->{+shift}->{+shift}->{+shift}={};}
sub _killcategory {       delete shift->{'toc'}->{+shift}->{+shift}->{+shift};}
sub _havecategory {return exists shift->{'toc'}->{+shift}->{+shift}->{+shift};}
sub _mergecatlist {my $a =       shift->{'toc'}->{+shift}->{+shift}; 
		   @$a{@_} = ();}

sub _cntcats {return ($#{ [keys %{shift->{'toc'}->{+shift}->{+shift}}] } + 1);}

#-----------------------------------------------------------------------------
# _duptitle: Set the contents of new title to the same hash as old title.
#	     (This is used before deleting the old title.)
#
# Args:		self
#		pagenum
#		old title
#		new title
# Returns:	return nothing.

sub _duptitle {my ($s,$p,$o,$n) = @_; 
	       $s->{'toc'}->{$p}->{$n} = $s->{'toc'}->{$p}->{$o};}

#-----------------------------------------------------------------------------
#	       Current selection or "bookmark" methods
#-----------------------------------------------------------------------------
# Build a selection based on the specified page.
#
# Args:		self
#		page or undef
# Returns:	(undef, undef,    emptyarray) or
#		(page,  undef,    emptyarray) or
#		(page,  1sttitle, emptyarray) or
#		(page,  1sttitle, emptyarray) or
#		(page,  1sttitle, category list) 

sub _selpage {
  my ($self,$page)  = @_;
  if (!defined $page)                {return (undef,undef);}
  if (!$self->_havepage($page))      {return (undef,undef);}
  if ($self->_cnttitles($page) < 1)  {return ($page,undef);}

  my $title       = ($self->_listtitles($page))[0];
  my @categories  = ($self->_listcats ($page,$title));

				      return ($page,$title,@categories);
}

#-----------------------------------------------------------------------------
# After selecting a page, build a selection based on the specified title.
#
# Args:		self
#		title or undef
# Returns:	(undef, undef, emptyarray) or
#		(page,  undef, emptyarray) or
#		(page,  title, emptyarray) or
#		(page,  title, category list) 

sub _seltitle {
  my ($self,$title) = @_;
  my ($p,$t)        = (@{$self->{'mark'}});

  if (!defined $p)                   {return (undef,undef)};
  if (!defined $title)               {return ($p,   undef);}
  if (!$self->_havetitle($p,$title)) {return ($p,   undef);}

  my @categories  = ($self->_listcats ($p,$title));

				      return ($p,   $title, @categories);
}

#-----------------------------------------------------------------------------
# After selecting a page and title, add the categories, if any. 
#
# NOTE: Rather redundant actually... Keep it around for now.
#
# Args:		self
#		title or undef
# Returns:	(undef, undef, emptyarray) or
#		(page,  undef, emptyarray) or
#		(page,  title, emptyarray) or
#		(page,  title, category list)

sub _selcats {
  my ($self)        = @_;
  my ($p,$t,@c)     = (@{$self->{'mark'}});

  if (!defined $p)                   {return (undef,undef)};
  if (!defined $t)                   {return ($p,   undef)};
                                      return ($p,$t,$self->_listcats ($p,$t));
}

#-----------------------------------------------------------------------------
# After selecting a page, build a selection based on the specified title.
#
# Args:		self
#		page  or undef
#		title or undef
# Returns:	(undef, undef, emptyarray) or
#		(page,  undef, emptyarray) or
#		(page,  title, emptyarray) or
#		(page,  title, category list)

sub _selall {
  my ($self,$p,$t) = @_;

  if (!defined $p)               {return (undef,undef)};
  if (!$self->_havepage($p,$t))  {return (undef,undef);}
  if (!defined $t)               {return ($p,   undef);}
  if (!$self->_havetitle($p,$t)) {return ($p,   undef);}
                                  return ($p,$t,$self->_listcats ($p,$t));
}

#=============================================================================
#                       Pod Documentation
#=============================================================================
# You may extract and format the documention section with the 'perldoc' cmd.

=head1 NAME

 Document::Toc - Manage a Table of contents file.

=head1 SYNOPSIS

 use Document::Toc;

 @pagelist     = $obj->pages;
 @titles       = $obj->pageTitles              ($pageid);
 @categories   = $obj->pageTitleCategories     ($pageid, $title);

 $flg          = $obj->havePage                ($pageid);
 $flg          = $obj->havePageTitle           ($pageid, $title);
 $flg          = $obj->havePageTitleCategory   ($pageid, $title, $category);

 $flg          = $obj->addPages                (@pageids);
 $flg          = $obj->addPageTitles           ($pageid, @titles);
 $flg          = $obj->addPageTitleCategories  ($pageid, $title, @categories);

 $flg          = $obj->removePages             (@pageid);
 $flg          = $obj->removePageTitles        ($pageid, @titles);
 $flg          = $obj->removePageTitleCategories ($pageid,$title,@categories);

 $flg          = $obj->replacePageTitle        ($pageid, $oldtitle, $newtitle);
 @curselection = $obj->setpage                 ($page);
 @curselection = $obj->settitle                ($title);
 @curselection = $obj->setcategories;
 @curselection = $obj->setmark                 ($page, $title);
 @curselection = $obj->setfirstpage;
 @curselection = $obj->setfirsttitle;

 $page         = $obj->curpage;
 $title        = $obj->curtitle;
 @pages        = $obj->curpages;
 @titles       = $obj->curtitles;
 @categories   = $obj->curcategories;

 @members      = $obj->members;
 $flg          = $obj->isMember                ($member);
 $flg          = $obj->addMembers              (@members);
 $flg          = $obj->removeMembers           (@members);

=head1 Inheritance

 UNIVERSAL
   Document::Members
     Document::Toc

=head1 Description

This Class manages a table of contents object. A table of contents is
keyed by pageids; each pageid may have zero or more titles; each title
may belong to zero or more categories. It encodes the semantics of a
.toc file.

 001 cover
 002 contents
 003 --
 005 ArticleTitleOne    Space, Aeronautics
 005 ArticleTitleTwo    Biology, Genetics
 006 backcover

into an easily modifiable and searchable form.

=head1 Examples

 use Document::Toc;
 my $toc = Document::Toc->new;

 my $f = $toc->addPages               ("001","002","003","005","006");
    $f = $toc->addPageTitles          ("002","TitleOne","TitleTwo");
    $f = $toc->addPageTitleCategories ("002","TitleTwo","Biology","Genetics");
    $f = $toc->addPageTitles          ("003","TitleOne","TitleTwo");
    $f = $toc->addPageTitleCategories ("003","TitleTwo","Biology","Genetics");
    $f = $toc->addPageTitles          ("005","TitleOne","TitleTwo");
    $f = $toc->addPageTitleCategories ("005","TitleTwo","Biology","Genetics");

 my @pages      = $toc->pages;
 my @titles     = $toc->pageTitles          ("005");
 my @categories = $toc->pageTitleCategories ("005", "TitleTwo");

    $f = $toc->havePage                     ("001");
    $f = $toc->havePageTitle                ("005","TitleTwo");
    $f = $toc->havePageTitleCategory        ("005","TitleTwo","Biology");

    $f = $toc->removePages                  ("002","006");
    $f = $toc->removePageTitles             ("003","TitleOne");
    $f = $toc->removePageTitleCategories    ("005","TitleTwo","Genetics");

    $f = $toc->replacePageTitle             ("005","TitleTwo","NewTitle");
 my @cursel = $toc->setpage                 ("005");
    @cursel = $toc->settitle                ("TitleTwo");
    @cursel = $toc->setcategories;
    @cursel = $toc->setmark                 ("003","TitleTwo");
    @cursel = $toc->setfirstpage;
    @cursel = $toc->setfirsttitle;

 my $page       = $toc->curpage;
 my $title      = $toc->curtitle;
    @pages      = $toc->curpages;
    @titles     = $toc->curtitles;
    @categories = $toc->curcategories;

    @pages      = $toc->members;
    $f          = $toc->isMember            ("001");
    $f          = $toc->addMembers          ("004");
    $f          = $toc->removeMembers       ("003");

=head1 Class Variables

 None.

=head1 Instance Variables

 None.

=head1 Class Methods

 None. 

=head1 Instance Methods

=over 4

=item B<$flg = $obj-E<gt>addMembers (@members)>

Overrides parent and calls addPages.

=item B<$flg = $obj-E<gt>addPages (@pageids)>

Add new pageids to the toc with a blank title and no categories. True if
it succeeds. Existing pages are unaffected.

=item B<$flg = $obj-E<gt>addPageTitleCategories ($pageid, $title, @categories)>

Merge new categories into the list of categories associated with title on
the specified page. True if it succeeds. Existing categories are unaffected.

=item B<$flg = $obj-E<gt>addPageTitles ($pageid, @titles)>

Add new titles to an existing pageid. True if it succeeds. Existing titles
are unaffected. Note that a blank title really is "" and not represented
by "--" as in a TocFile!

=item B<@categories =  $obj-E<gt>curcategories>

Return a list of all categories in the current page and table selection
or an empty array.

=item B<$page = $obj-E<gt>curpage>

Return the current page name or undef if there is none.

=item B<@pages = $obj-E<gt>curpages>

Return a list of all pages in this Toc or undef if empty.

=item B<$title = $obj-E<gt>curtitle>

Return the current title or undef if there is none.

=item B<@titles = $obj-E<gt>curtitles>

Return a list of all titles on the current page or undef if there are none.

=item B<$flg = $obj-E<gt>havePage ($pageid)>

True if $pageid exists. 

=item B<$flg = $obj-E<gt>havePageTitle ($pageid, $title)>

True if $title exists on $pageid.

=item B<$flg = $obj-E<gt>havePageTitleCategory ($pageid, $title, $category)>

True if $category  is in use  for $title on $pageid.

=item B<$flg = $obj-E<gt>isMember ($member)>

Overrides parent and calls havePage.

=item B<@members = $obj-E<gt>members>

Overrides parent and calls pages.

=item B<@pagelist = $obj-E<gt>pages>

Return a list of the pageids in the toc. List may be empty.

=item B<@categories = $obj-E<gt>pageTitleCategories ($pageid, $title)>

Return a list of all the categories associated with a specific page title.
List can be empty if there is no assignment of the title to a category or
categories yet.

=item B<@titles = $obj-E<gt>pageTitles ($pageid)>

Return a list of the page titles associated with a specific pageid found
in the .toc. List can be empty as there will always be one untitled entry
for each page in the Archivist::Publication's directory.

=item B<$flg = $obj-E<gt>replacePageTitle ($pageid, $oldtitle, $newtitle)>

Change the a title name without disturbing its' associated categories.
Success means a new title was created, given the category hash of the old
title, and the old title was deleted.

=item B<I might want some bulk operators to do complete replacement of a
page title category list record.>

=item B<$flg = $obj-E<gt>removeMembers (@members)>

Overrides parent and calls removePages.

=item B<$flg = $obj-E<gt>removePages (@pageid)>

Remove pageids from the hash. Will remove all titles and their
associated categories that are part of the specified pages. Ignores pages
that don't exist. Returns true if the operation succeeds.

=item B<$flg = $obj-E<gt>removePageTitles ($pageid, @title)>

Remove titles and their associated categories from a pageid. Ignores
titles that don't exist. Returns true on success.

=item B<$flg = $obj-E<gt>removePageTitleCategories ($pageid, $title, @category)>

Remove categories from the specified title on the specified pageids.
Ignores categories which don't exist. Returns true on success.

=item B<@curselection = $obj-E<gt>setcategories>

Set the selection mark to start with the categories associated with the
current title. Return the modified current selection.

=item B<@curselection = $obj-E<gt>setfirstpage>

Set the selection mark to the firstpage. Return the modified current 
selection.

=item B<@curselection = $obj-E<gt>setfirsttitle>

Set the selection mark to the first title on the current page. Return the 
modified current selection.

=item B<@curselection = $obj-E<gt>setmark ($page, $title)>

Set the selection mark to start with the specified page and title. Return 
the modified current selection.

=item B<@curselection = $obj-E<gt>setpage ($page)>

Set the selection mark to start with the specified page. Return the modified
current selection.

=item B<@curselection = $obj-E<gt>settitle ($title)>

Set the selection mark to start with the specified title on the current
page. Return the modified current selection.

=back 4

=head1 Private Class Methods

 None.

=head1 Private Instance Methods

=over 4

=item B<$dideval = $obj-E<gt>_lazy>

SUBCLASS MAY CHAIN. Chains to parent class method. If the lazy evaluation
bit is set, do evaluations and  then clear it. Returns true if subclass
should carry out it's own lazy evaluation.

This is an internal primitive operation on the members data. It assumes
you know what you are doing because if you screw up the lazy evaluation
you could create some really subtle bugs.

=back 4

=head1 KNOWN BUGS

 See TODO.

=head1 SEE ALSO

Document::Members, Fault::DebugPrinter

=head1 AUTHOR

Dale Amon <amon@vnl.com>

=cut

#=============================================================================
#                                CVS HISTORY
#=============================================================================
# $Log: Toc.pm,v $
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
# Revision 1.1.1.1  2004-09-12 12:39:26  amon
# Manages a Document directory
#
# 20040813      Dale Amon <amon@islandone.org>
#               Moved to Document:: from Archivist::
#               to make it easier to enforce layers.
#
# 20030110	Dale Amon <amon@vnl.com>
#		Added selection mark support
#
# 20021219	Dale Amon <amon@vnl.com>
#		Created.
#
1;
