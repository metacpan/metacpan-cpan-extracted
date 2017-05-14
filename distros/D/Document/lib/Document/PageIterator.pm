#============================== PageIterator.pm ==============================
# Filename:            PageIterator.pm
# Description:         Page Iterator Class.
# Original Author:     Dale Amon
# Revised by:          $Author: amon $ 
# Date:                $Date: 2008-08-28 23:26:17 $ 
# Version:             $Revision: 1.5 $
# License:	       LGPL 2.1, Perl Artistic or BSD
#
#=============================================================================
use strict;
use Document::PageId;

package Document::PageIterator;
use vars qw{@ISA};
@ISA = qw( Document::PageId );

#=============================================================================
#			Instance Methods
#=============================================================================
# Return undef if the page was not changed.
#
sub setpageid
  {my ($self,$pageid) = @_; return $self->_init($pageid);}

#-----------------------------------------------------------------------------

sub setfirstpage {
  my ($self,$first) = @_;

  ($first =~ /^\d*$/)                       || return undef;
  ((length $first) <= $self->{'pn_digits'}) || return undef;

  $self->{'firstpage'} = $first;
  return $self;
}

#=============================================================================
# These return undef on page overflow.

sub advancepage {
  my ($self,$n) = @_;
  (defined $n)    || ($n=1); 
  ($n =~ /^\d*$/) || return undef;
 SW: {
    $_ = $self->{'type'};
    if (/1/)  { $self->_incpage($n)
			|| return undef;
		last SW;}			# 001
    if (/2/)  { $self->_incpage($n)
			|| return undef;
		$self->_firstalphapage;
		last SW;}			# 001a
    if (/3/)  { last SW;}			# 000.spine
    if (/4/)  { $self->_incpage($n)
			|| return undef;
		$self->_firstsubpage;
		last SW;}			# 001.01
    if (/5/)  { $self->_incpage($n)
			|| return undef;
		$self->_firstsubpage;
                $self->_firstalphapage;
		last SW;}			# 001.01a
  }
  return $self->get;
}

#-----------------------------------------------------------------------------

sub advancesubpage {
  my ($self,$n) = @_;
  (defined $n)    || ($n=1); 
  ($n =~ /^\d*$/) || return undef;
 SW: {
    $_ = $self->{'type'};
    if (/1/)  { last SW;}			# 001
    if (/2/)  { last SW;}			# 001a
    if (/3/)  { last SW;}			# 000.spine
    if (/4/)  { $self->_incsubpage($n)
			|| return undef;
		last SW;}			# 001.01
    if (/5/)  { $self->_incsubpage($n)
			|| return undef;
                $self->_firstalphapage;
		last SW;}			# 001.01a
  }
  return $self->get;
}

#-----------------------------------------------------------------------------

sub nextid {
  my ($self,$n) = @_;
  (defined $n) || ($n=1); 
  ($n =~ /^\d*$/)             || return undef;

  if ($self->{'mode'} eq "page") 
    {$self->_incpage($n)      || return undef;}

  elsif ($self->{'mode'} eq "subpage")
    {$self->_incsubpage($n)   || return undef;}

  elsif ($self->{'mode'} eq "alphapage")
    {$self->_incalphapage($n) || return undef;}

  else                          {return undef;}

  return $self->get;
}

#=============================================================================

sub setPagenumber {
  my ($self,$n) = @_;
  (defined $self->{'pagenum'})           || return undef;
  ($n =~ /^\d*$/)                        || return undef;
  ((length $n) <= $self->{'pn_digits'})  || return undef;

  @$self{'pagenum','_dirty'} = ($n,1);
  return $self;
}

#-----------------------------------------------------------------------------

sub setSubpagenumber {
  my ($self,$n) = @_;
  (defined $self->{'subpagenum'})        || return undef;
  ($n =~ /^\d*$/)                        || return undef;
  ((length $n) <= $self->{'spn_digits'}) || return undef;

  @$self{'subpagenum','_dirty'} = ($n,1);
  return $self;
}

#-----------------------------------------------------------------------------

sub setAlphapage {
  my ($self,$c) = @_;
  (defined $self->{'side'})              || return undef;
  ($c =~ /^[a-z]$/)                      || return undef;

  @$self{'side','_dirty'} = ($c,1);
  return $self;
}

#=============================================================================
#			Internal Methods
#=============================================================================
# Increment the various possible elements of a pageid. All return false on 
# page number field overflow.

sub _incpage      {my ($self,$n) = @_;
		   (defined $n) || ($n=1); 
		   $self->{'_dirty'}      = 1;
		   $self->{'pagenum'}    += $n;
		   return
		     ((length $self->{'pagenum'}) <= $self->{'pn_digits'});}

#-----------------------------------------------------------------------------

sub _incsubpage   {my ($self,$n) = @_;
		   (defined $n) || ($n=1); 
		   $self->{'_dirty'}      = 1;
		   $self->{'subpagenum'} += $n;
		   return 
		     ((length $self->{'subpagenum'}) <= $self->{'spn_digits'});}

#-----------------------------------------------------------------------------

sub _incalphapage {my ($self,$n) = @_;
		   (defined $n) || ($n=1); 
		   return 0 if ($self->{'side'} eq "z");
		   $self->{'_dirty'}      = 1;
		   $self->{'side'}        = chr (ord ($self->{'side'}) + $n);
		   return 1;}

#=============================================================================

sub _firstpage     {my $self = shift; 
		    $self->{'_dirty'}      = 1;
		    $self->{'pagenum'}     = $self->{'firstpage'};}

sub _firstsubpage  {my $self = shift; 
		    $self->{'_dirty'}      = 1;
		    $self->{'subpagenum'}  = 1;}

sub _firstalphapage{my $self = shift; 
		    $self->{'_dirty'}      = 1;
		    $self->{'side'}        = "a";}

#=============================================================================
# Mode identifies the rightmost element, the one which will be incremented by 
# a nextid method. Elements to the left of it require specifically being 
# 'advanced'.

sub _init {
  my $self = shift;
  $self->SUPER::_init (@_) || return undef;

  my $mode;
 SW: {
    $_ = $self->{'type'};
    if (/1/)  {$mode = "page";      last SW;}  # 001
    if (/2/)  {$mode = "alphapage"; last SW;}  # 001a
    if (/3/)  {$mode = "notpage";   last SW;}  # 000.spine
    if (/4/)  {$mode = "subpage";   last SW;}  # 001.01
    if (/5/)  {$mode = "alphapage"; last SW;}  # 001.01a
               $mode = "notpage";
  }
  $self->{'mode'} = $mode;
  return $self;
}

#=============================================================================
#                       Pod Documentation
#=============================================================================
# You may extract and format the documention section with the 'perldoc' cmd.

=head1 NAME

 Document::PageIterator - Page Iterator Class.

#head1 SYNOPSIS

  use Document::PageIterator;
  $bool   = $pg->setpageid        ($pageid);
  $pageid = $pg->nextid;
  $bool   = $pg->setfirstpage     ($n);

  $bool   = $pg->advancepage      ($inc);
  $bool   = $pg->advancesubpage   ($inc);
  $bool   = $pg->SetPagenumber    ($n);
  $bool   = $pg->SetSubpagenumber ($n);
  $bool   = $pg->SetAlphapage     ($c);

=head1 Inheritance

 UNIVERSAL
   Document::Page
    Document::PageIterator

=head1 Description

This subclass of Document::Page adds the ability to increment any of the
pageid formats. Only the last element of a pageid is incremented. Increments
may continue until an invalid character (anything past "z") for an alphapage 
or a number exceeding the available field size is produced.

=head1 Examples

  $pg = Document::PageIterator->new ("001") || die ("Invalid page id");
  $pg->setpageid ("001.01a")                || die ("Invalid page id");
  $pg->setfirstpage (1)                     || die ("Invalid 1st page num");
  $pageid = $pg->nextid;
  defined $pageid                           || die ("Page id overflow");

=head1 Class Variables

 None.

=head1 Instance Variables

 firstpage	The first page number in the document. This
		is used when resetting. Usually this is 1 
		or 0 for the cover page of most publications;
		But it could be any number for publications
		that use page numbering based on volumes rather
		than issues.

=head1 Class Methods

 None.

=head1 Instance Methods

=over 4

=item B<$bool = $pg-E<gt>advancepage ($inc);>

If a page number exists in the current pageid, increment it by
the specified $inc value. If $inc is not numeric or the result would
exceed the field size of the subpage, it returns false.

This is not a commonly used operator.

=item B<$bool = $pg-E<gt>advancesubpage ($inc);>

If a subpage number exists in the current pageid, increment it by
the specified $inc value. If $inc is not numeric or the result would
exceed the field size of the subpage, it returns false.

This is not a commonly used operator.

=item B<$pageid = $pg-E<gt>nextid>

Increment the pageid. Returns undef if this would cause an overflow.
Overflows can occur if any field size would be exceeded or an illegal
value generated. For example, increments of the following would fail:

	100z
	001.01z
	001.99
	999

=item B<$bool = $pg-E<gt>SetAlphapage ($c);>

If a page alpha character exists in the current pageid, set it to the 
specified alphabetic character. If $c is not a single alphabetic 
character, it returns false.

This is not a commonly used operator.

=item B<$bool= $pg-E<gt>setfirstpage ($n);>

Set the first page number in the document. This is used when resetting. 
Usually it is 1 or 0 for the cover page of most publications; but it 
could be any number for publications which use page numbering based on 
volumes rather than issues.

=item B<$bool= $pg-E<gt>setpageid ($pageid)>

Set the page id string and fully reinitialize the object for the implied
field sizes of that id. Returns undef if the pageid is invalid.

For example, "009.10a" would set the pagenumber to 9, with a field size
of 3; the subpage number to 10 with a field size of 2; and the page alpha
to "a". Since increments only happen at the end, this page id would be
incrementable from "009.10a" to "009.10z" before an overflow would occur.

Typically such complex page numbers are only used for inserts and such; 
more typical is a plain "009" which would be incrementable to "999" before
overflow occurred.

=item B<$bool = $pg-E<gt>SetPagenumber ($n);>

If a page number exists in the current pageid, set it to the 
specified number $n. If $n is not numeric or is too large for
the page number field, it returns false.

This is not a commonly used operator.

=item B<$bool = $pg-E<gt>SetSubpagenumber ($n);>

If a subpage number exists in the current pageid, set it to the 
specified number $n. If $n is not numeric or is too large for
the subpage number field, it returns false.

This is not a commonly used operator.

=back 4

=head1 Private Class Method

 None.

=head1 Private Instance Methods

 None.

=head1 Errors and Warnings

 None.

=head1 KNOWN BUGS

 See TODO.

=head1 SEE ALSO

Document::PageId

=head1 AUTHOR

Dale Amon <amon@vnl.com>

=cut

#=============================================================================
#                                CVS HISTORY
#=============================================================================
# $Log: PageIterator.pm,v $
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
# Revision 1.1.1.1  2006-07-05 12:14:23  amon
# Manages a Document directory
#
# 20050323	Dale Amon <amon@islandone.org>
#		Added support for generalized increment to nextid.
#
# 20040904	Dale Amon <amon@islandone.org>
#		Created.
#
1;
