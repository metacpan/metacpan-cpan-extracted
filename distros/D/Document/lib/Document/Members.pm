#================================ Members.pm =================================
# Filename:            Members.pm
# Description:         Manage a Members file.
# Original Author:     Dale Amon
# Revised by:          $Author: amon $ 
# Date:                $Date: 2008-08-28 23:26:17 $ 
# Version:             $Revision: 1.5 $
# License:	       LGPL 2.1, Perl Artistic or BSD
#
#=============================================================================
use strict;

package Document::Members;
use vars qw{@ISA};
@ISA = qw( UNIVERSAL );

#=============================================================================
#				Class Methods
#=============================================================================

sub new {
  my ($class) = @_;
  my $self = bless {}, $class;
  @$self{'toc','lazy','cnt','mark','first'} = ({},1,0,[],[]);
  return $self;
}

#=============================================================================
#			Object Methods
#=============================================================================
#			Predicate operators
#-----------------------------------------------------------------------------

sub isMember {
  my ($self)    = shift;
  my ($member) = @_;
  defined $member || (return 0);
  return ($self->_havemember (@_));
}

#-----------------------------------------------------------------------------
#			Key listing operators
#-----------------------------------------------------------------------------

sub members {return (shift->_listmembers);}

#-----------------------------------------------------------------------------
#			Add operators
#-----------------------------------------------------------------------------

sub addMembers {my $s=shift; 
		my $a=$s->{'toc'};  @$a{@_}=(); $s->_l8r; return 1;}

#-----------------------------------------------------------------------------
#			Remove operators
#-----------------------------------------------------------------------------

sub removeMembers {
  my $self      = shift;
  foreach my $m (@_) {($self->_havemember ($m)) && ($self->_killmember ($m));}
  $self->_l8r;
  return 1;
}

#-----------------------------------------------------------------------------

sub initmark {
  my $self = shift;
  $self->_lazy;
  @{$self->{'mark'}} = @{$self->{'first'}};
  return (@{$self->{'mark'}});
}

#-----------------------------------------------------------------------------

sub mark {return (@{+shift->{'mark'}});}

#-----------------------------------------------------------------------------

sub _selmember {
  my ($self,$item) = @_;

  if (!defined $item)                {return (undef);}
  if (!$self->_havemember($item))    {return ($item);}
                                      return (undef);      
}

#=============================================================================
#			Internal Methods
#=============================================================================

sub _l8r {shift->{'lazy'}=1;}

#-----------------------------------------------------------------------------

sub _lazy {
  my $self = shift;
  $self->{'lazy'} || return 0;

  $self->{'cnt'}      = $self->_cntmembers;
  $self->{'first'}[0] = $self->_1stmember;
  $self->{'lazy'}     = 0;
  return 1;
}

#=============================================================================
# The following are a set of internal primitive operations on the toc data
# structure. They are used by external methods which also do arg checking.
#=============================================================================

sub _listmembers {return (sort keys %{shift->{'toc'}});}
sub _cntmembers  {return ($#{ [keys %{shift->{'toc'}}] } + 1);}
sub _1stmember   {my $s=shift; 
		  return ($s->{'cnt'} > 0) ? ($s->_listmembers)[0] : undef;}

#-----------------------------------------------------------------------------

sub _initmember {               shift->{'toc'}->{+shift} = undef;}
sub _killmember {        delete shift->{'toc'}->{+shift};}
sub _havemember {return  exists shift->{'toc'}->{+shift};}

#=============================================================================
#                       Pod Documentation
#=============================================================================
# You may extract and format the documention section with the 'perldoc' cmd.

=head1 NAME

 Document::Members - Manage a Members file.

=head1 SYNOPSIS

 use Document::Members;
 $obj = Document::Members->new

 @members      = $obj->members
 $flg          = $obj->isMember      ($member)
 $flg          = $obj->addMembers    (@members)
 $flg          = $obj->removeMembers (@members)
 @curselection = $obj->initmark
 @listmark     = $obj->mark

=head1 Inheritance

 UNIVERSAL

=head1 Description

This Class manages a sorted hierarchical hash of  set members. It manages
addition and subtraction of members; tests for set membership and does the
book-keeping so that 'foreach' operations may be done on the set or subsets
of the members. The sorting required for stepping through elements in
alphabetic order is only done when necessary (an internal flag has been set
to indicate the changes have been made) and at the last possible moment
(lazy evaluation).

For the most part this class will be used as an Abstract Superclass. It is
structured so that elements are defined not by a single lookup key, but by a
path list of keys which lead from the root members hash to a terminal element.
This allows a foreach operation to traverse the entire structure via depth
first recursive search.  In this class there is only the first level. But the
structure is all here for subclasses to chain, override and extend. 

For example, a subclass implementing a three level hierarchy might have
address marks something like this:

      (Book1, Page1, Paragraph5)

where Book1 is the top level hash key. The hash attached to Book1 is
accessed with the Page1 second level hash key; the hash attached to Page1
can then finally be accessed with Paragraph5 to return the data stored at
the leaf (terminal) node. 

=head1 Examples

 use Document::Members;
 my $foo          = Document::Members->new ();
 my $flg          = $obj->addMembers    ("one","two","three","four");
    $flg          = $obj->removeMembers ("two","three");
    $flg          = $obj->isMember      ("two");
    $flg          = $obj->isMember      ("one");
 my @members      = $obj->members;
 my @curselection = $obj->initmark;
 my @listmark     = $obj->mark;

=head1 Class Variables

 None.

=head1 Instance Variables

 toc         Pointer to the member hash.
 mark        Array containing the current 'address mark'.
 first       Array containing the 'address mark' of the first member
             as of the last key sort.
 cnt         Number of elements in the member hash.

=head1 Class Methods

=over 4

=item B<$obj = Document::Members-E<gt>new>

Create a blank members object and return true.

=head1 Instance Methods

=item B<$flg = $obj-E<gt>addMembers (@members)>

Add a new member name to the hash, with an undef value. Members is a list 
of member names and may be empty. True if it succeeds.

Override if you have to use the value. Sets lazy eval bit.

=item B<@curselection = $obj-E<gt>initmark>

Copy the contents of the first selection (a list) to the current selection   
(also a list). It is done this way so that subclasses may have arbitrarily
long selection marks; the length can even vary from one selection to the next.
(eg, [page, title, (category list)] in a Toc subclass)

=item B<$flg = $obj-E<gt>isMember ($member)>

True if $member exists. 

=item B<@listmark = $obj-E<gt>mark>

Return the current selection mark array. The list mark contains only one
element in this class, but this could be extended in child classes.

=item B<@members = $obj-E<gt>members>

Return a list of the members in the hash. List may be empty.

=item B<$flg = $obj-E<gt>removeMembers (@members)>

Remove a member name from the hash. Returns true if the operation succeeds.

=back 4

=head1 Private Class Methods

 None. 

=head1 Private Instance Methods

=over 4

=item B<$membername = $obj-E<gt>_1stmember >

Returns the first element of the current sorted key list or undef if there
the list is empty.

This is an internal primitive operation on the members data.. It is used by
child  methods which also do the argument checking.  It assumes you know what
you are doing. 

=item B<$cnt = $obj-E<gt>_cntmembers>

Returns a current count of the number of keys that are in the members hash.

This is an internal primitive operation on the members data.. It is used by
child  methods which also do the argument checking.  It assumes you know what
you are doing. 

=item B<$obj-E<gt>_l8r>

Set the lazy evaluation bit so we'll do things l8r. Mananna.

This is an internal primitive operation on the members data. It assumes you
know what you are doing. You probably can't do much damage with this one
other than to cause the lazy evaluation to happen more often than it should.

=item B<$dideval = $obj-E<gt>_lazy>

SUBCLASS MAY CHAIN. If the lazy evaluation bit is set, do evaluations and
then clear it. Returns true if subclass should carry out it's own lazy
evaluation.

This is an internal primitive operation on the members data. It assumes you
know what you are doing because if you screw up the lazy evaluation you could
create some really subtle bugs.

=item B<$exists = $obj-E<gt>_havemember ($membername)>

It returns true if the specified member exists in the top level set.

This is an internal primitive operation on the members data.. It is used by
child  methods which also do the argument checking.  It assumes you know what
you are doing. 

=item B<$obj-E<gt>_initmember ($membername)>

Set the value of the specified set member to undef.

This is an internal primitive operation on the members data.. It is used by
child  methods which also do the argument checking.  It assumes you know what
you are doing. 

=item B<$obj-E<gt>_killmember ($membername)>

Remove the member from the set if it exists.

This is an internal primitive operation on the members data.. It is used by
child  methods which also do the argument checking.  It assumes you know what
you are doing. 

=item B<@keys = $obj-E<gt>_listmembers>

Returns a current sorted list of keys that are in the members hash.

This is an internal primitive operation on the members data.. It is used by
child  methods which also do the argument checking.  It assumes you know what
you are doing. 

=item B<$membername = $obj-E<gt>_selmember ($membername) >

If $membername exists in the set, return it as is. If it does not exist,
return undef instead. This routine does argument checking, but is primarily
here for the convenience of subclasses.

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
# $Log: Members.pm,v $
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
# Revision 1.1.1.1  2004-08-30 13:28:42  amon
# Manages a Document directory
#
# 20040813      Dale Amon <amon@islandone.org>
#               Moved to Document:: from Archivist::
#               to make it easier to enforce layers.
#
# 20030110	Dale Amon <amon@vnl.com>
#		Added selection mark support
#
# 20021222	Dale Amon <amon@vnl.com>
#		Created as a superclass to Toc.pm
#
1;
