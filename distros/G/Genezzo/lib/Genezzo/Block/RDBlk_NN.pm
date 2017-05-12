#!/usr/bin/perl
#
# $Header: /Users/claude/fuzz/lib/Genezzo/Block/RCS/RDBlk_NN.pm,v 7.1 2005/07/19 07:49:03 claude Exp claude $
#
# copyright (c) 2004 Jeffrey I Cohen, all rights reserved, worldwide
#
#
use strict;
use warnings;

package Genezzo::Block::RDBlk_NN;
use Genezzo::Util;
use Genezzo::Block::RDBlkA;
use Genezzo::Block::RDBlock;
use Genezzo::Block::Std;
use Genezzo::Block::RowDir;

our @ISA = "Genezzo::Block::RDBlkA" ;

use Carp;
use warnings::register;

sub TIEHASH
{ #sub new
#    greet @_;
#    whoami;
    my $invocant = shift;
    my $class = ref($invocant) || $invocant ; 
    my $self = $class->SUPER::TIEHASH(@_);

    my %args = (@_);

    return bless $self, $class;

} # end new


sub _packdeleted
{
    whoami ();

    my $self = shift;

    return 0 
        if ($self->{compacted}); # no further cleanup possible

    return 0
        unless ($self->SUPER::_packdeleted());

    my $refrowdir    = $self->{rowdir};
    my $numelts      = $self->{numelts};
    my $cnt = 0;

    while ($cnt < $numelts)
    {
        $refrowdir = $self->{rowdir};
        my ($rowstat, $rowposn, $rowlen) = @{ $refrowdir->[$cnt] };
        
        if (Genezzo::Block::RDBlock::_isdeletedrow($rowstat))
        {
            # splice out deleted rows and reduce the total number of
            # elements left

#            $self->HeSplice(\$err_str, $cnt, 1);

            greet $cnt;

            $self->_splice_out($cnt);

            $numelts--;
            # don't advance the counter - we just deleted current position
        }
        else
        {
            # skip over rows which are not deleted
            $cnt++;
        }
    }

    return 1;

}

# convert an array-like offset to a true hash key
sub _offset2hkey
{
#    whoami ();

    my ($self, $offset) = @_;

    my $refrowdir = $self->{rowdir};

    # Note: only positive offsets for now
    return undef
        unless ($offset > -1);
    return undef
        if ($offset > $self->{numelts});

    my $cnt = 0;

    for (; $cnt < $self->{numelts}; $cnt++)
    {
        my ($rowstat, $rowposn, $rowlen) = @{ $refrowdir->[$cnt] };

        # XXX XXX XXX XXX: how to handle this with row pieces?  should
        # this be only head rows?
        
        # find first undeleted data row - skip leading metadata if necessary
        last
            if (Genezzo::Block::RDBlock::_isheadrow($rowstat));
#            if (_isvaldatarow($rowstat));
    }

    # $cnt is offset 0 - add $cnt to offset and return the resulting hkey

    $offset += $cnt;
    return undef
        if ($offset > $self->{numelts});

    # NOTE: the offset isn't necessarily a "valid" data entry.
    # Gimmick the FETCH to return NULLs for invalid data...
    return $offset;
}

sub FETCH
{
#    whoami ();
    my ($self, $place) = @_;

    return (undef)
        unless ($self->EXISTS($place));

    my $refrowdir = $self->{rowdir};
      
    my ($rowstat, $rowposn, $rowlen) = @{ $refrowdir->[$place] };

    unless (Genezzo::Block::RDBlock::_isheadrow($rowstat))
    {
        whisper "FETCH: return undef for invalid row";
        return undef;
    }

#        unless (_isvaldatarow($rowstat));

    return ($self->SUPER::FETCH($place));
}

sub DELETE
{
    whoami ();
    my ($self, $place) = @_;
    greet $place;
    my $stat = ($self->SUPER::DELETE($place));

##    $self->_packdeleted(); # workaround

    return $stat;
}



1;

__END__

# Below is stub documentation for your module. You better edit it!

=head1 NAME

Genezzo::Block::RDBlk_NN.pm - Row Directory Block Not Null (array) tied
hash class.

This class converts the B<Genezzo::Block::RDBlkA> operations from a
conventional array to a "Not Null" array.  B<Genezzo::Block::RDBArray>
uses this class as the basis of a tied array.

Note: Like its parent RDBlock, this class is almost, but not quite, a
pushhash.  

=head1 SYNOPSIS

 use Genezzo::Block::RDBlk_NN;
 use Genezzo::Block::Std;

 local $Genezzo::Block::Std::DEFBLOCKSIZE = 500;

 my $buff = "\0" x 500; # construct an empty byte buffer

 my %tied_hash = ();

 my $tie_val = 
    tie %tied_hash, 'Genezzo::Block::RDBlk_NN', (refbufstr => \$buff);

 # pushhash style 
 # (note that the "PUSH" pseudo key is not supported)...
 my $newkey = $tie_val->HPush("this is a test");

 # or array style, your choice
 my $pushcount = $tie_val->PUSH(qw(push lots of data));

 $tied_hash{$newkey} = "update this entry";

 # a hash that supports array style FETCHSIZE
 my $getcount = $tie_val->FETCHSIZE(); # Note: not HCount

 # splice it
 my $err_str;

 my @a1 = $tie_val->HeSplice(\$err_str, 5, 3, qw(more stuff to splice));


=head1 DESCRIPTION

While RDBlkA adds array-like splice capabilities to RDBlock, violating
the standard hash abstraction, RDBlk_NN violates the array
abstraction, creating an array subclass called a "Not Null" array, a
sort of priority queue.

=head2 "Not Null" arrays

Not Null arrays are designed to store non-null entries.  Entries in
the array which correspond to deleted values or metadata (see
B<Genezzo::Block::RDBlock>) may sometimes get returned as null entries,
so various array manipulation algorithms should be adjusted to reflect
this quirk.  RDBlkA performs a good approximation of a well-behaved
array, but the requirement to map a strictly ascending series of array
offsets onto the normal data in RDBlock, which may be interspersed
with deleted values and metadata, performs at O(n), versus O(1) for
the "Not Null" version.

=over 4

=item DELETE

Delete can have two outcomes: a deleted entry can disappear (standard
outcome), or it can leave a null entry as a "hole".

=back



=head1 FUNCTIONS

RDBlk_NN support all standard hash operations, with the exception
that you cannot create or insert a user key -- you must push new
entries and use the generated key or basic iteration to retrieve your
data.  

In addition to the RDBlock standard public methods, RDBlk_NN
adds HSplice and HeSplice.

=over 4

=item HSplice this, offset, length, LIST

Perform the equivalent of C<splice> on the array. 

I<offset> is optional and defaults to zero, negative values count back 
from the end of the array. 

I<length> is optional and defaults to rest of the array.

I<LIST> may be empty.

Returns a list of the original I<length> elements at I<offset>.

=item HeSplice this, error_ref, offset, length, LIST

I<error_ref> is a string ref.  Normally set to undef, set to error
string on failure.


=back

=head2 EXPORT

none

=head1 TODO

=over 4

=item  build simple test cases

=item  build complex test cases

=item  test thoroughly

=item  packdeleted: make this work.  It's broken!

=item  integration with bt2 - need to packdelete in bsplit, do null checks in 
       leaf blocks (branch blocks should be ok)

=item  need a validation function to ensure that block maintains
       invariant: small number of leading metadata rows starting at
       row zero, followed by data rows (deletes ok).  Easier to
       support non-split rows initially, but should be able to support
       head rows (need mods to splice functions to preserve rowstats
       for this case).


=item  need to modify metadata methods so all metadata created in first n
       rows.

=item  could simply have delete really delete the rows, so no changes
       necessary for rdblock clients (i.e., no "null rows" generated).

=back

=head1 AUTHOR

Jeffrey I. Cohen, jcohen@genezzo.com

=head1 SEE ALSO

perl(1).

Copyright (c) 2004 Jeffrey I Cohen.  All rights reserved.

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA

Address bug reports and comments to: jcohen@genezzo.com

For more information, please visit the Genezzo homepage 
at L<http://www.genezzo.com>

=cut
