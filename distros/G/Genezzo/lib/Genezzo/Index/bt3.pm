#!/usr/bin/perl
#
# $Header: /Users/claude/fuzz/lib/Genezzo/Index/RCS/bt3.pm,v 7.2 2006/10/19 08:43:18 claude Exp claude $
#
# copyright (c) 2003, 2004 Jeffrey I Cohen, all rights reserved, worldwide
#
#
use strict;
use warnings;

package Genezzo::Index::bt3;

use Genezzo::PushHash::PushHash;
use Genezzo::Row::RSFile;
use Genezzo::Index::bt2;
use Genezzo::Util;
use Genezzo::Block::Std;
use Genezzo::Block::RowDir;
use Genezzo::Block::RDBlkA;
use Genezzo::Block::RDBArray;
use Genezzo::BufCa::BufCa;
use Carp;
#use warnings::register;

our @ISA = qw(Genezzo::Index::bt2) ;


sub make_fac2 {
    my $tclass = shift;
    my %args1 = (
                @_);

    if (exists($args1{hashref}))
    {    
        carp "cannot supply hashref to factory method - deleting !\n"
            if warnings::enabled();

        delete $args1{hashref};
    }

    my %td_hash1  = ();

    # NOTE: args1 contains original @_ from closure creation, but is
    # overridable when caller invokes at later time
    my $newfunc = 
        sub {
#            whoami @_;
            my %args2 = (
                         %args1,
                         @_);

            my $tiehash1 = 
                tie %td_hash1, $tclass, %args2;

            return $tiehash1;
        };
    return $newfunc;
}

sub new
{ #sub new 
#    greet @_;
#    whoami;
    my $invocant = shift;
    my $class = ref($invocant) || $invocant ; 

    # Note: turn off size limits and private buffer cache in bt2
    my %optional = (maxsize => 0, numblocks => 0); 

    my %args = (%optional,
                @_);

    my $self = $class->SUPER::new(%args);

    return undef
        unless (defined($self) && _more_init($self, %args));

    return bless $self, $class;

} # end new

sub _more_init
{
    my $self = shift;
#    whoami;

    my %required = (
                    tablename => "no tablename !",
                    object_id => "no object id !",
                    tso       => "no tso",
                    bufcache  => "no buffer cache"
                    );
    my %optional = (
                    );
    
    my %args = (@_);

    return 0
        unless (Validate(\%args, \%required));

#    greet $self->{fac1};
    $self->{tablename} = $args{tablename};
    $self->{tso}       = $args{tso};
    $self->{bc}        = $args{bufcache};
    $self->{object_id} = $args{object_id};

    $self->{maxnodeid} = 0;
    $self->{blocknum}  = 0;
    $self->{spacecache} = [];

    my %realhash = ();

    # NOTE: the underlying rdblock package is RDBlkA, not RDBlock, to
    # get array functions
    my %hzero = 
        (
         RDBlock_Class => 'Genezzo::Block::RDBlkA'
         );

    $self->{fac1} = make_fac2('Genezzo::Row::RSFile', %hzero); 

    my %hargs = (
                 hashref   => \%realhash ,
                 factory   => $self->{fac1}, 
                 tablename => $self->{tablename},
                 object_id => $self->{object_id},
                 bufcache  => $self->{bc},

                 tso  => $self->{tso},
                 object_type => 'INDEX'
                 );

    my $tiehash = tie %realhash, 'Genezzo::Row::RSTab', %hargs;
    
    unless (defined ($tiehash))
    {
        carp "factory could not allocate pushhash"
            if warnings::enabled();
        return undef; # factory out of hashes
    }

    $self->{fi_hashref} = \%realhash;
    $self->{fi_tieval}  = $tiehash;

#    $self->{maxblockno} = -1;

    # XXX XXX XXX: need to fix this 
    my $fk = $tiehash->FIRSTKEY();
    if (defined($fk))
    {
#        greet $fk;
        $self->_getMainMeta($fk);
    }

    return 1;
}

sub _make_new_block
{
    my $self = shift;

#    whoami;

    $self->{maxnodeid} += 1;

    # XXX: check for undef
    my $blocknum;

    if (scalar(@{$self->{spacecache}}))
    {
        $blocknum = pop @{$self->{spacecache}};
        whisper "use cached block $blocknum";
    }
    else
    {
        $blocknum = $self->{fi_tieval}->_make_new_block();
    }
    $self->{blocknum} = $blocknum;

#    greet $self->{blocknum};
    
    return $self->{blocknum};
}

sub _getarr
{
    my ($self, $place) = @_;

#    greet $place;

    my @outi;

    # XXX: check for undef
    my ($blktie, $blocknum, $bceref, $href) = 
        $self->{fi_tieval}->_get_block_and_bce($place);

#    greet $bceref;
 
    push @outi, $bceref; # block stays pinned as long as bceref is in scope

    # obtain the actual Buffer Cache Element
    my $bce = $$bceref;
    
    my @a1;

    # tie an array using the rdblka tied hash
    my $t2 = tie @a1, "Genezzo::Block::RDBArray", (RDBlockHash => $blktie);

    push @outi, $blktie;
    push @outi, $href;

    # return the tied array first, then the bceref, then the tied hash
    unshift @outi, \@a1;

    return @outi;
}


sub _spacecheck
{
    my ($self, $height) = @_;

    # degenerate case: splitting root (height zero) requires two
    # additional blocks -- new head plus new sibling

    my $maxsp    = $height + 2;
    
    # make sure we have enough space to accomodate splits
    my $cachecnt = scalar(@{$self->{spacecache}});

    whisper "cached $cachecnt blocks, need $maxsp";

    return 1; # XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX 

    # preallocate some space if necessary XXX XXX ignored for now
    while ($cachecnt < $maxsp)
    {
        my $blocknum = $self->{fi_tieval}->_make_new_block();
        return 0
            unless (defined($blocknum));
        push @{$self->{spacecache}}, $blocknum;
        $cachecnt++;
    }

    # XXX XXX XXX XXX: need to make cache persistent, else lose maxsp
    # allocated blocks

    return 1;
#    my $spaceleft = $self->{maxblockno} - $self->{maxnodeid};
#    whisper "_spacecheck: need $maxsp blocks, $spaceleft left";

#    return ($spaceleft > $maxsp);
}


END {

}

# insert code here

1;


__END__
    
# Below is stub documentation for your module. You better edit it!
    
=head1 NAME
    
Genezzo::Index::bt3 - persistent btree

A btree built of row directory blocks.  

=head1 SYNOPSIS

 use Genezzo::Index::bt?;

 my $tt = Genezzo::Index::btree->new();

 $tt->insert(1, "hi");
 $tt->insert(7, "there");

=head1 DESCRIPTION

This btree algorithm is a bottom-up implementation based upon ideas
from Chapter 16 of "Algorithms in C++ (third edition)", by Robert
Sedgewick, 1998 and Chapter 15, "Access Paths", of "Transaction
Processing: Concepts and Techniques" by Jim Gray and Andreas Reuter,
1993.  The pedagogical examples use a fixed number of entries per
node, or fixed-size keys in each block, but this implementation has
significant extensions to support variable numbers of variably-sized
keys in fixed-size disk blocks, with the associated error handling,
plus support for reverse scans.

=head1 FUNCTIONS

functions 

=over 4

=item insert

=item delete

=back

=head2 EXPORT

none

=head1 TODO

=over 4

=item new: maybe a way to get blocksize from rstab/rsfile and pass to bt2, 
      versus passing it to each layer separately

=item getMainMeta from first block of tied hash, but no guarantee that 
      space management is nice enough to return blocks in allocation order.
      Should store block address of leftmost leaf in index table.

=item spacecheck: space cache should simply be free extents allocated to
      the index.  Need to extend smfile to have multiple free extents in
      spacelist, vs just used extents.  Note still an issue for simultaneous
      inserts -- need lots of space for pathological case where each parallel
      insert splits a separate subtree.  That's why transactions were invented.

=back

=head1 AUTHOR

Jeffrey I. Cohen, jcohen@genezzo.com

=head1 SEE ALSO

perl(1).

Copyright (c) 2003, 2004 Jeffrey I Cohen.  All rights reserved.

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
