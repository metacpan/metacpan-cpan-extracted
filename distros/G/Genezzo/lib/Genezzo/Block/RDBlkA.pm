#!/usr/bin/perl
#
# $Header: /Users/claude/fuzz/lib/Genezzo/Block/RCS/RDBlkA.pm,v 7.1 2005/07/19 07:49:03 claude Exp claude $
#
# copyright (c) 2003, 2004 Jeffrey I Cohen, all rights reserved, worldwide
#
#
use strict;
use warnings;

package Genezzo::Block::RDBlkA;
use Genezzo::Util;
use Genezzo::Block::RDBlock;
use Genezzo::Block::Std;
use Genezzo::Block::RowDir;

our @ISA = "Genezzo::Block::RDBlock" ;

use Carp;
use warnings::register;

sub TIEHASH
{ #sub new
#    greet @_;
    my $invocant = shift;
    my $class = ref($invocant) || $invocant ; 
    my $self = $class->SUPER::TIEHASH(@_);

    my %args = (@_);

    return bless $self, $class;

} # end new

sub _splice_in # XXX XXX : need to test this...
{
    my ($self, $place, $value) = @_;

    my $refrowdir = $self->{rowdir};
    my $numelts   = $self->{numelts};
    my $bSpliceIn  = 1;

#  Carp::croak ("No such row")
    return (undef)
        unless ($place < $numelts);

    # XXX XXX : need place - 1
    # Note: rowstat is NOT preserved, and IS set to datarow
    my ($rowstat, $rowposn, $rowlen);
    if ($place)
    {
        ($rowstat, $rowposn, $rowlen) = @{ $refrowdir->[$place - 1] };
        $rowstat = $Genezzo::Block::RDBlock::DATAROW;
    }
    else
    {
        my $nextpos = $self->{blocksize};

        $nextpos -= $Genezzo::Block::Std::LenFtrTemplate;

        ($rowstat, $rowposn, $rowlen) = ($Genezzo::Block::RDBlock::DATAROW,
                                         $nextpos, 0);
    }

    # XXX XXX XXX
    # NOTE : need to define undef specially
    if (defined($value))
    {
        # clear nullness
        if (Genezzo::Block::RDBlock::_isnull($rowstat))
        {
            $rowstat &= ~($Genezzo::Block::RDBlock::RowStats{isnull});
        }

    }
    else
    {
        whisper "null!";
        # set nullness
        $value = "";
        $rowstat |=  $Genezzo::Block::RDBlock::RowStats{isnull};
    }
        
    my $packout = Genezzo::Block::RDBlock::_row_write($value);
    my $packlen = length($packout);

    my $refbufstr = $self->{bigbuf};

#    whisper "old rowlen : $rowlen\npacklen : $packlen";

    if ($bSpliceIn)
    {
        $rowlen = 0;
    }

    my $sizediff = $rowlen - $packlen;

#    whisper "sizediff : $sizediff";

    # perfect match!!
    if (!$bSpliceIn && (0 == $sizediff))
    {
        # add row to block
        substr($$refbufstr, $rowposn, $packlen) = $packout;

        return ($value);
    }

    my ($lastrowstat, $lastrowposn, $lastrowlen) = 
        @{ $refrowdir->[$numelts - 1] };

    if ($bSpliceIn || ($sizediff < 0)) # new row is larger
    {
        # as updated row size increases, offset to last row decreases.
        # When the start of the last row overwrites the end of the
        # header we are in trouble...


        # XXX XXX XXX: need to add in length rowdir template????

        if (($lastrowposn 
             + $sizediff) <= 
            Genezzo::Block::RDBlock::_calctotalheader($numelts + $bSpliceIn))
        {

            whisper "Ran out of space in block!! \n";

            return (undef);
        }

    }

    if ($bSpliceIn)
    {
        $numelts++;
        $self->{numelts} += 1;

        my $newelt = [$rowstat, $rowposn, $rowlen];
        
        splice(@{$refrowdir}, $place, 0, $newelt);
        $self->{freespace} -= 
            $Genezzo::Block::RowDir::LenRowDirTemplate;

    }

    if ($place < ($numelts - 1))
    { # not the last row in the block, so have to move them around

#        whisper "shift the rows:";
        
        my $endchunk   = $rowposn;
        my $startchunk = $lastrowposn ;

#        whisper "endchunk : $endchunk\nlastrowposn : $lastrowposn";
#        whisper "lastrowlen : $lastrowlen";

        # startchunk (the position of the last row) is a smaller
        # offset than endchunk because we insert the rows at the end
        # of the block and work back toward the header
        #
        #     +------------+ <-- start of block
        #     | header     |
        #     +------------+
        #     |  .   free  |
        #     |  .   space |
        #     |  .         |
        #  -  +------------+ <-- startchunk = lastrowposn
        #  ^  | lastrow    |
        #  |  +------------+
        #  |  |  .         |
        #  s  |  .         |
        #  h  |  .         |
        #  i  |  .         |
        #  f  |  .         |
        #  t  |  .         |
        #  |  |  .         |
        #  |  +------------+ 
        #  v  | place+1    |
        #  -  +------------+ <-- endchunk = rowposn 
        #     | place      | <======= *update here*
        #     +------------+
        #     |  .         |
        #     |  .         |
        #     |  .         |
        #     +------------+
        #     | row 0      |
        #     +------------+ <-- end of block

        # XXX: would be nice to optimize this shift using something
        # like memmove

        my $bufchunk = substr($$refbufstr, $startchunk, 
                              $endchunk - $startchunk);

        substr($$refbufstr, $startchunk + $sizediff, $endchunk - $startchunk)
            = $bufchunk;
    }

    # add row to block
    substr($$refbufstr, $rowposn + $sizediff, $packlen) = $packout
        if ($packlen);

    # adjust freespace
    $self->{freespace} += $sizediff ;

    if ($self->{can_insert})
    {
        $self->{can_insert} = ($self->{freespace} > $self->{absfree});
        whisper "%free exceeded - inserts disabled"
            unless ($self->{can_insert});
    }
    else
    {
        $self->{can_insert} = ($self->{freespace} > $self->{absused});
        whisper "%used met - inserts re-enabled"
            if ($self->{can_insert});
    }

    # fix the rowlen for refrowdir[place] here - offsets are fixed in
    # loop below
    $rowlen = $packlen;

    # fix offsets for all rows
    for my $ii ($place..($numelts - 1))
    {
        # rowstat, rowposn, rowlen set for first pass already
        if ($ii == $place)
        {
            # reset the rowlen for the updated row
            @{ $refrowdir->[$ii] }[2] = $rowlen;
            # reset the rowstat if changed from null
            @{ $refrowdir->[$ii] }[0] = $rowstat;
        }
        else
        {
            ($rowstat, $rowposn, $rowlen) = @{ $refrowdir->[$ii] };
        }

#        whisper "$ii: ",$rowposn + $sizediff;
        @{ $refrowdir->[$ii] }[1] = $rowposn + $sizediff;
#        $refrowdir->[$ii] = [$rowstat, $rowposn + $sizediff, $rowlen];

        SetRDEntry($self, $ii,  @{ $refrowdir->[$ii] } );
    }
    # update main header freespace
    SetStdHdr($self, $self->{blocktype}, $self->{numelts}, $self->{freespace})
        if ($bSpliceIn || (0 != $sizediff));

    return ($value);


}

# XXX XXX : Need to modify hesplice to use splice_out vs delete
sub _splice_out
{
#    whoami ();

    my ($self, $place) = @_;

    my $refrowdir = $self->{rowdir};
    my $numelts   = $self->{numelts};

#  Carp::croak ("No such row")
    return (undef)
        unless ($place < $numelts);
    
    # note: rowstat is preserved, not set to datarow
    my ($rowstat, $rowposn, $rowlen) = @{ $refrowdir->[$place] };

    my $out_value = $self->_realfetch ($rowposn, $rowlen );

    my $packout ; # = Genezzo::Block::RDBlock::_row_write($value);
    my $packlen = 0;

    my $refbufstr = $self->{bigbuf};

#    whisper "old rowlen : $rowlen\npacklen : $packlen";

    my $sizediff = $rowlen - $packlen;

#    whisper "sizediff : $sizediff";


    my ($lastrowstat, $lastrowposn, $lastrowlen) = 
        @{ $refrowdir->[$numelts - 1] };

    if ($sizediff < 0) # new row is larger
    {

        # as updated row size increases, offset to last row decreases.
        # When the start of the last row overwrites the end of the
        # header we are in trouble...

        if (($lastrowposn 
             + $sizediff) <= 
            Genezzo::Block::RDBlock::_calctotalheader($numelts))
        {

            whisper "Ran out of space in block!! \n";

            return (undef);
        }

    }

    if ($place < ($numelts - 1))
    { # not the last row in the block, so have to move them around

#        whisper "shift the rows:";
        
        my $endchunk   = $rowposn;
        my $startchunk = $lastrowposn ;

#        whisper "endchunk : $endchunk\nlastrowposn : $lastrowposn";
#        whisper "lastrowlen : $lastrowlen";

        # startchunk (the position of the last row) is a smaller
        # offset than endchunk because we insert the rows at the end
        # of the block and work back toward the header
        #
        #     +------------+ <-- start of block
        #     | header     |
        #     +------------+
        #     |  .   free  |
        #     |  .   space |
        #     |  .         |
        #  -  +------------+ <-- startchunk = lastrowposn
        #  ^  | lastrow    |
        #  |  +------------+
        #  |  |  .         |
        #  s  |  .         |
        #  h  |  .         |
        #  i  |  .         |
        #  f  |  .         |
        #  t  |  .         |
        #  |  |  .         |
        #  |  +------------+ 
        #  v  | place+1    |
        #  -  +------------+ <-- endchunk = rowposn 
        #     | place      | <======= *update here*
        #     +------------+
        #     |  .         |
        #     |  .         |
        #     |  .         |
        #     +------------+
        #     | row 0      |
        #     +------------+ <-- end of block

        # XXX: would be nice to optimize this shift using something
        # like memmove

        my $bufchunk = substr($$refbufstr, $startchunk, 
                              $endchunk - $startchunk);

        substr($$refbufstr, $startchunk + $sizediff, $endchunk - $startchunk)
            = $bufchunk;
    }

    # add row to block
    substr($$refbufstr, $rowposn + $sizediff, $packlen) = $packout
        if ($packlen);


    # fix the rowlen for refrowdir[place] here - offsets are fixed in
    # loop below
    $rowlen = $packlen;

    # fix offsets for all rows
    for my $ii ($place..($numelts - 1))
    {
        # rowstat, rowposn, rowlen set for first pass already
        if ($ii == $place)
        {
            # reset the rowlen for the updated row
            @{ $refrowdir->[$ii] }[2] = $rowlen;
            # reset the rowstat if changed from null
            @{ $refrowdir->[$ii] }[0] = $rowstat;
        }
        else
        {
            ($rowstat, $rowposn, $rowlen) = @{ $refrowdir->[$ii] };
        }

#        whisper "$ii: ",$rowposn + $sizediff;
        @{ $refrowdir->[$ii] }[1] = $rowposn + $sizediff;
#        $refrowdir->[$ii] = [$rowstat, $rowposn + $sizediff, $rowlen];

        SetRDEntry($self, $ii,  @{ $refrowdir->[$ii] } );
    }

    unless ($packlen)
    {
        $self->{numelts} -= 1;
        splice(@{$refrowdir}, $place, 1);
        $self->{freespace} += 
            $Genezzo::Block::RowDir::LenRowDirTemplate;
    }
    # adjust freespace
    $self->{freespace} += $sizediff ;

    if ($self->{can_insert})
    {
        $self->{can_insert} = ($self->{freespace} > $self->{absfree});
        whisper "%free exceeded - inserts disabled"
            unless ($self->{can_insert});
    }
    else
    {
        $self->{can_insert} = ($self->{freespace} > $self->{absused});
        whisper "%used met - inserts re-enabled"
            if ($self->{can_insert});
    }

    # update main header freespace
    SetStdHdr($self, $self->{blocktype}, $self->{numelts}, $self->{freespace})
        unless (0 == $sizediff);

    return ($out_value);

}


# NOTE: splice for array-like operations on offsets of datarows, not
# hash key ids for all rows.
sub HSplice
{
    my $self = shift @_;
#    whoami @_;

    return $self->HeSplice(undef, @_);

}

sub HeSplice
{

    local $Genezzo::Util::QUIETWHISPER = 1; # XXX: quiet the whispering

    my $self = shift @_;
#    whoami @_;

    my $err = shift @_;

    my $errstr;
    my $puterr = (ref($err)) ? 1 : 0;

    my @undo_all;

#    my $refrowdir = $self->{rowdir};
    my $numelts   = $self->{numelts};
#    my $sz        = $self->FETCHSIZE;

    # treat offset as location of EXISTing rows, not an absolute "place"
    my $off = (@_) ? shift : 0;

    if ($off !~ /\d+/)
    {
        $errstr = "non numeric offset";
        $$err = $errstr
            if ($puterr);
        whisper $errstr;
        return undef;
    }

    # key at this offset
    my $offkey = $self->FIRSTKEY();

    if ($off >= 0)
    {
        for (my $keynum = 0; $keynum < $numelts; $keynum++)
        {
            last 
                if ($keynum >= $off);
            $offkey = $self->NEXTKEY($offkey);
            unless (defined($offkey))
            {
                $errstr = "offset too large";
                $$err = $errstr
                    if ($puterr);
                whisper $errstr;
                return undef;
            }
        }
    }
    else # negative offset from the end
    {   
        $offkey = $self->_lastkey();
        my $revoff = $off * -1;

        for (my $keynum = 0; $keynum < $numelts; $keynum++)
        {
            $revoff--;
            last 
                unless ($revoff);
            $offkey = $self->_prevkey($offkey);
            unless (defined($offkey))
            {
                $errstr = "negative offset too large";
                $$err = $errstr
                    if ($puterr);
                whisper $errstr;
                return undef;
            }
        }
    }

    my $hadlen = (@_);
    my $len = $hadlen ? shift : $numelts;
    my $truelen = 0;
    my $stopkey = undef;

    if ($off !~ /\d+/)
    {
        $errstr = "non numeric length";
        $$err = $errstr
            if ($puterr);
        whisper $errstr;
        return undef;
    }

    # NOTE: special case for length == 0 and single value
    if (0 == $len)
    {
        if (1 == scalar(@_))
        {
            my $outi = $self->_splice_in($offkey, $_[0]);

            unless (defined($outi))
            {
                $errstr = "splice in: out of space";
                $$err = $errstr
                    if ($puterr);
                whisper $errstr;
                return undef;
            }
            my @fff; # return an empty array
            return @fff;
        }
    }

    # for negative length, splice from start of offset to (end - length)
    if ($len < 0)
    { 
        my $revoff = $len * -1;
        $len = $numelts;
        $hadlen = 0; # reset hadlen so we obtain "truelen"

        $stopkey = $self->_lastkey();

        # decrement the reverse offset to obtain a stopkey
        for (my $keynum = 0; $keynum < $numelts; $keynum++)
        {
            $revoff--;
            last 
                unless ($revoff);
            $stopkey = $self->_prevkey($stopkey);
            unless (defined($stopkey))
            {
                $errstr = "negative length too large";
                $$err = $errstr
                    if ($puterr);
                whisper $errstr;
#                return undef;
                # XXX XXX: is this correct behavior?
                $len = 0;
                $offkey = $self->_lastkey();
                last;
            }
        }
    } # end negative length

    my @result;  # values to return at end
    my @keylist;

    my $the_key = $offkey;
    for (; $truelen < $len; $truelen++)
    {
        my $val = $self->FETCH($the_key);
        push(@keylist, $the_key);
        push(@result, $val);  # save these -- return them at the end

        whisper "fetch $the_key : \n"; # val might be undef # $val \n";

        $the_key = $self->NEXTKEY($the_key);
        unless (defined($the_key))
        {
            # reset len to true number of elements after offset if it
            # was not specified
            $errstr = "no more keys $len $truelen";
            $$err = $errstr
                if ($puterr);
            whisper $errstr;
            $len = $truelen
                unless ($hadlen);
            last;
        }

        if (defined($stopkey)) # for negative length
        {
            if ($the_key == $stopkey)
            {
                # reset len to true length from offset to stopkey
                $len = $truelen;
                last;
            }
        }
    }

    # what to do if list was supplied
    if (@_ < $len)
    {
        # delete existing items and shove in new ones

        my $listlen = scalar(@_);
        my $j = 0;
        foreach my $i (@keylist)
        {
            my $oldval = $self->FETCH($i);
            push (@undo_all, [ 's', $i, $oldval ]);

            if ($j < $listlen)
            {
                # replace the existing items
                my $val = $_[$j];
                my $stat = $self->_realstore($i, $val);
                unless(defined($stat))
                {
                    $errstr = "replace 1 out of space";
                    $$err = $errstr
                        if ($puterr);
                    whisper $errstr;
                    goto L_RESTORE;
                }
            }
            else
            {
                # delete trailing items
                whisper "delete $i \n";
                $self->DELETE($i);
            }
            $j++;
        }
    }
    elsif (@_ >= $len)
    {
        # set nextk to offset for case of null keylist -- 
        # else reset it using keylist
        my $nextk = $offkey; 
        foreach my $i (@keylist)
        {
            # delete fetched items (starting at offset for length $len)
            my $oldval = $self->FETCH($i);
            push (@undo_all, [ 's', $i, $oldval ]);

            whisper "delete $i \n";
            $nextk = $self->NEXTKEY($i);
            $self->DELETE($i);
        }
        my @trail;
        # save all the trailing items, leave only items 0..offset
        while (defined($nextk))
        {
            my $the_key = $nextk;
            whisper "delete and save $the_key \n";
            my $val = $self->FETCH($the_key);
            push(@trail, $val);
            push (@undo_all, [ 's', $the_key, $val ]);

            $nextk = $self->NEXTKEY($the_key);
            $self->DELETE($the_key);
        }

        # push in the new items from @_, and then the old trailing items

        foreach my $i (@_)
        {
            my $kk = $self->HPush($i);
            
            unless (defined($kk))
            {
                $errstr = "push 1 out of space";
                $$err = $errstr
                    if ($puterr);
                whisper $errstr;
                goto L_RESTORE;
            }
            unshift (@undo_all, [ 'd', $kk ]);
        }

        foreach my $i (@trail)
        {
            my $kk = $self->HPush($i);

            unless (defined($kk))
            {
                $errstr = "push 2 out of space";
                $$err = $errstr
                    if ($puterr);
                whisper $errstr;
                goto L_RESTORE;
            }
            unshift (@undo_all, [ 'd', $kk ]);
        }
    }

    return @result;

  L_RESTORE:

    $self->_packdeleted(); # try for space

    my $packdel = 0;
    foreach my $uval (@undo_all)
    {
        if ($uval->[0] =~ m/d/)
        {
            whisper "delete ", $uval->[1],"\n";
            $self->DELETE($uval->[1]);
        }
        if ($uval->[0] =~ m/s/)
        {
            unless ($packdel)
            {
                $self->_packdeleted(); # try for space
                $packdel = 1;
            }
            whisper "store ", $uval->[1]," :  ",$uval->[2],"\n";
            my $stat;
            if ($uval->[1] < $self->{numelts})
            {
                $stat = $self->_realstore($uval->[1], $uval->[2]);
            }
            else
            {
                $stat = $self->HPush($uval->[2]);
            }
            unless(defined($stat))
            {
                $errstr = "more damage during recovery from " . $errstr;
                $$err = $errstr
                    if ($puterr);
                whisper $errstr;
                return undef;
            }
        }

    }

    $errstr = "recovered from " . $errstr;
    $$err = $errstr
        if ($puterr);
    whisper $errstr;

    return undef;

} # end hesplice


1;

__END__

# Below is stub documentation for your module. You better edit it!

=head1 NAME

Genezzo::Block::RDBlkA.pm - Row Directory Block Adjunct tied hash class.
This class adds array-like splice capabilities to
B<Genezzo::Block::RDBlock>.  B<Genezzo::Block::RDBArray> uses this class as
the basis of a tied array.

Note: Like its parent RDBlock, this class is almost, but not quite, a
pushhash.  

=head1 SYNOPSIS

 use Genezzo::Block::RDBlkA;
 use Genezzo::Block::Std;

 local $Genezzo::Block::Std::DEFBLOCKSIZE = 500;

 my $buff = "\0" x 500; # construct an empty byte buffer

 my %tied_hash = ();

 my $tie_val = 
    tie %tied_hash, 'Genezzo::Block::RDBlkA', (refbufstr => \$buff);

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

RDBlkA adds array-like splice capabilities to RDBlock, violating the
standard hash abstraction.  Splicing values resets hash keys, treating
them more like array offsets.  If you want to use a hash, use RDBlock
or C<Genezzo::Row::RSBlock>.  If you want to use an array, use
C<Genezzo::Block::RDBArray>.

=head1 FUNCTIONS

RDBlkA support all standard hash operations, with the exception
that you cannot create or insert a user key -- you must push new
entries and use the generated key or basic iteration to retrieve your
data.  

In addition to the RDBlock standard public methods, RDBlkA 
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

=head1 LIMITATIONS

The effort to convert a set of potentially sparse hash keys to array
indexes is O(n), which ain't cheap.  See B<Genezzo::Block::RDBlk_NN> as
an alternative -- imposing certain restrictions on the array contents
and usage makes it possible to perform this conversion at O(1).

=head2 EXPORT

none

=head1 TODO

=over 4

=item  HSplice: offset calculation must match offset2hkey in RDBlock.
       Special handling needed if inherited by RDBlk_NN?

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
