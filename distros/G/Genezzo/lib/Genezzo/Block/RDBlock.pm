#!/usr/bin/perl
#
# $Header: /Users/claude/fuzz/lib/Genezzo/Block/RCS/RDBlock.pm,v 7.10 2007/11/18 08:11:09 claude Exp claude $
#
# copyright (c) 2003-2007 Jeffrey I Cohen, all rights reserved, worldwide
#
#
use strict;
use warnings;

package Genezzo::Block::RDBlock;
use Genezzo::Util;
use Genezzo::Block::Std;
use Genezzo::Block::RowDir;

use Tie::Hash;
our @ISA = "Tie::Hash" ;

#use Genezzo::Util;
use Carp;
use warnings::register;

my $doRot13 = 0;

sub _mkrowdir
{
    my ($self, $numelts, $freespace) = @_;

    $self->{numelts}   = $numelts;
    $self->{freespace} = $freespace;

    my @rowdir = ();

    for (my $cnt = 0; $cnt < $self->{numelts}; $cnt++)
    {
        $rowdir[$cnt] = 
            [
              GetRDEntry($self, $cnt)
             ];
    }

    $self->{rowdir} = \@rowdir;

    return 1;
}

sub _init
{
#    whoami;
#    greet @_;
    my $self = shift;

    my %optional = (blocksize => $Genezzo::Block::Std::DEFBLOCKSIZE,
                    pctfree => 30,
                    pctused => 50);
    # should this be pctfree = 10, pctused = 40 ?

    my %args = (%optional,
                @_);

    return 0
        unless (exists($args{refbufstr}));

    $self->{bigbuf}  = $args{refbufstr};

    $self->{rowdir}  = []; # create an empty rowdir

    $self->{numelts} = 0; # total number of elements (valid data rows,
                          # deleted rows, and other non-data elements)
    $self->{freespace} = 0;
    $self->{blocksize} = $args{blocksize};

#    confess "bad blocksize"
#        unless ($self->{blocksize} =~ m/\d+/);

    # absfree: amount of space kept free for future updates.  Inserts
    # succeed as long as freespace > absfree.
    # absused - after block is full, amount of space that must be open
    # before can allow inserts.  Can insert again when freespace >
    # absused.

    # NOTE: make sure number between 0 and 100 
    # XXX : might want to round to integer with POSIX::floor
    # should this be 1..99 vs 0..100?

    if (
        1 
#        || ($args{pctfree} < 0)    # cheaper to test up front 
#        || ($args{pctfree} > 100)  # than call numval...
#        || ($args{pctused} < 0)   
#        || ($args{pctused} > 100)
        ) 
    {
        return 0
            unless (NumVal(
                           name => "pctfree",
                           val  => $args{pctfree},
                           MIN  => 0, MAX => 100));
        return 0
            unless (NumVal(
                           name => "pctused",
                           val  => $args{pctused},
                           MIN  => 0, MAX => 100));

        return 0
            if ($args{pctfree} + $args{pctused} > 100);

    }
    # might want to bottom out pctfree at 10% for table data, but can
    # go to 0% for index data.  
    
    # adjust the blocksize to reflect the header/footer space
    my $adjblocksize    = 
        $args{blocksize} - 
        ($Genezzo::Block::Std::LenHdrTemplate + 
         $Genezzo::Block::Std::LenFtrTemplate);

    $self->{adjblocksize} = $adjblocksize;

    $self->{absfree}    = $adjblocksize * ($args{pctfree} / 100);
    $self->{absused}    = $adjblocksize * ($args{pctused} / 100);
    $self->{can_insert} = 1;
    $self->{compacted}  = 0; # true if compacted out deleted rows

    if ($self->{absfree} < $Genezzo::Block::RowDir::LenRowDirTemplate)
    {
        # need enough free space to insert a zero len entry...
        $self->{absfree} = $Genezzo::Block::RowDir::LenRowDirTemplate;
    }

    my ($blocktype, $numelts, $freespace) = GetStdHdr($self);

#    whoami $blocktype, $numelts, $freespace;

    $self->{blocktype} = $Genezzo::Block::Std::BlockType{RandomBlock};
 
    if ($Genezzo::Block::Std::BlockType{EmptyBlock} == $blocktype)
    {
        $self->{freespace}  = $adjblocksize;
        $self->{can_insert} = ($self->{freespace} > $self->{absfree});
        return 1;
    }

    unless ($Genezzo::Block::Std::BlockType{RandomBlock} == $blocktype)
    {
        my $tstr = "UNKNOWN";

        carp "Invalid Block Type - $blocktype : $tstr - not RandomBlock "
            if warnings::enabled();
       return 0;
    }
    $self->{can_insert} = ($freespace > $self->{absfree});

    # Contrib is the counterpart to the CPAN Genezzo::Contrib
    # namespace.  Add hash keys according to your package name, e.g.
    #   $self->{Contrib}->{Clustered} = 'foo' 
    $self->{Contrib} = {}; 

#    return $self->_mkrowdir( $numelts, $freespace);
    return _mkrowdir($self, $numelts, $freespace);
}

# used by Genezzo::Havok::DebugUtils::blockdump()
sub BlockInfo
{
    my $self = shift;
    my $args = shift;

    my $outi = {};

    $outi->{blocktype} = $self->{blocktype};
    $outi->{blocktypestr} =
        ($self->{blocktype} == 0 ) ? "(Empty)" : 
        (($self->{blocktype} == 1 ) ? "(Append)" : 
         (($self->{blocktype} == 2 ) ? "(Random)" : "(Unknown!)"));

    $outi->{blocksize} = $self->{blocksize};
    # minus hdr/ftr
    $outi->{adjblocksize} = $self->{adjblocksize};
    $outi->{freespace} = $self->{freespace};

    $outi->{realfreepct} = ($self->{freespace}*100)/$self->{adjblocksize};

    # real used is adjblocksize - freespace
    # real pct used is 100 - real free pct

    $outi->{numelts}    = $self->{numelts};
    $outi->{can_insert} = $self->{can_insert};
    $outi->{compacted}  = $self->{compacted};
    $outi->{absfree}    = $self->{absfree};
    $outi->{pctfree}    = $self->{absfree}*100/$self->{adjblocksize};
    $outi->{absused}    = $self->{absused};
    $outi->{pctused}    = $self->{absused}*100/$self->{adjblocksize};

    return $outi
}

# used by Genezzo::Havok::DebugUtils::blockdump()
sub BlockInfoString
{
    my $self = shift;
    my $args = shift;

    my $outi = "";
    my $realfreepct;

    $outi .= "blocktype = " . $self->{blocktype} . " ";
    $outi .= ($self->{blocktype} == 0 ) ? "(Empty)" : 
        (($self->{blocktype} == 1 ) ? "(Append)" : 
         (($self->{blocktype} == 2 ) ? "(Random)" : "(Unknown!)"));
    $outi .= "\n";

    $outi .= "blocksize = " . $self->{blocksize} . "\n";
    $outi .= "minus hdr/ftr = " . $self->{adjblocksize} . "\n";
    $outi .= "freespace = " . $self->{freespace};

    $realfreepct = sprintf("%.2f", ($self->{freespace}*100)/$self->{adjblocksize});

    $outi .= " (" . $realfreepct . "%)\n";
    
    $outi .= "used      = " . ($self->{adjblocksize} - $self->{freespace});
    $outi .= " (" . sprintf("%.2f", (100.0 - $realfreepct)) . "%)\n";

    $outi .= "numelts   = " . $self->{numelts} . "\n";
    $outi .= "can_insert = " . $self->{can_insert} . "\n";
    $outi .= "compacted = " . $self->{compacted} . "\n";
    $outi .= "absfree   = " . $self->{absfree} . "\n";
    $outi .= "pctfree   = " . $self->{absfree}*100/$self->{adjblocksize} . "\%\n";
    $outi .= "absused   = " . $self->{absused} . "\n";
    $outi .= "pctused   = " . $self->{absused}*100/$self->{adjblocksize} . "\%\n";

    return $outi
        if ($args);

    my $lastelt = $self->{numelts};
    $lastelt--;

    my $refrowdir = $self->{rowdir};

    $outi .= "\n";

    for my $rplace (0..$lastelt)
    {
        my $place = $lastelt - $rplace;

        my ($rowstat, $rowposn, $rowlen) = @{ $refrowdir->[$place] };

        # X DELETED (vs not)
        # M Metadata (vs data)
        # L Locked (vs not)
        # H Head, T Tail (vs both)
        # ISNULL (vs not null)

        my $del  = _isdeletedrow($rowstat) ? "X" : " ";
        my $data = _isdatarow($rowstat) ? " " : "M";
        my $lck  = _islockedrow($rowstat) ? "L" : " ";
        my $hd   = _isheadrow($rowstat);
        my $tl   = _istailrow($rowstat);

        # "/" for a middle piece
        my $ht   = ($hd && $tl) ? " " : 
            (!($hd || $tl) ? "/" :
             ($hd ? "H" : "T"));

        my $isnull = _isnull($rowstat) ? "NULL" : "    ";
        
        $outi .= sprintf("% 5d: posn: % 5d, len: % 5d, %s %s %s %s %s\n", 
                         $place,
                         $rowposn,
                         $rowlen,
                         $del,
                         $data,
                         $lck,
                         $ht,
                         $isnull
                         );

        next
            if (_isnull($rowstat));

        my $rowval = $self->_realfetch ($rowposn, $rowlen );
        $rowval =~ s/([^a-zA-Z0-9])/uc(sprintf("%%%02lx",  ord $1))/eg;
        $outi .= "\t" . $rowval . "\n";

    }
    

    return $outi;
}

# originally, I thought this could be an array, but deleting from an
# array (via SHIFT or POP) never leaves a "hole", it just shifts the
# array entries around so they are always consecutively numbered from
# [0..n].  For a row directory block, each entry must keep its index,
# so deleted entries leave gaps.
sub TIEHASH
{ #sub new
#    greet @_;
    my $invocant = shift;
    my $class = ref($invocant) || $invocant ; 
    my $self = { };

    my %args = (@_);

    return undef
        # XXX: can't call self on unblessed reference here
        unless (_init($self, %args));

    unless ($self->{numelts})
    {
        my @foo;

        if (exists($args{blocknum}))
        {
            my $blockno = $args{blocknum};
            $self->{blocknum} = $blockno;

            # XXX XXX: add a comment in the metadata for testing...
            $foo[0] = "#:META blocknum $blockno";
        }

        # XXX XXX: Note - by default, row zero is metadata, unless
        # "nometazero" flag is set (for certain tests like Block1, Row1)
        unless (exists($args{nometazero}))
        {
            my $pstat = _push_one($self, 
                                  PackRow(\@foo), 0);
            return undef
                unless (defined($pstat));
        }
    }

    my $new_self = bless $self, $class;

    # check if we have any mail
    if (exists($args{MailBag}))
    {
        my $msglist = Genezzo::Util::CheckMail(MailBag => $args{MailBag},
                                               Address => __PACKAGE__);
        if (defined($msglist)
            && scalar(@{$msglist}))
        {
            for my $msg (@{$msglist}) # check all msgs
            {
                if (exists($msg->{Msg})
                    && exists($msg->{From})
                    && $msg->{Msg} eq 'RSVP')
                {
                    # RSVP to sender

                    my $sender = $msg->{From};
                    $sender->RSVP(name  => __PACKAGE__,
                                  value => $new_self);
                }
                if (exists($msg->{Msg})
                    && exists($msg->{From})
                    && $msg->{Msg} eq 'RegisterSender')
                {
                    # list the sender in the Contrib hash
                    my $r1 = ref($msg->{From});
                    
                    $self->{Contrib}->{mailbox}->{$r1}->{self} = $msg->{From};

                }
            } # end for
        }
    } # end if mailbag

    return $new_self

} # end new

our %RowStats = (
                deleted => 0x01, # set if row is deleted
                data    => 0x02, # set for data rows, unset for metadata
                lock    => 0x04, # row is locked, requires metadata
                                 # to identify locker
                head    => 0x08, # 1st piece of a (potentially) multipart row
                tail    => 0x10, # last piece of (potentially) multipart row
                isnull  => 0x20  # if packed value was just an UNDEF
                );

our $DATAROW    = $RowStats{data} | $RowStats{head} | $RowStats{tail}; 
# XXX: note - not a class or instance method
sub _isnull
{
    my $rowstat = shift @_;

    return ($rowstat & $RowStats{isnull})
}
sub _isvaldatarow
{
    my $rowstat = shift @_;

    return (_isdatarow($rowstat) && !_isdeletedrow($rowstat));
}
sub _isdatarow
{
    my $rowstat = shift @_;

    return ($rowstat & $RowStats{data});
}
sub _isdeletedrow
{
    my $rowstat = shift @_;

    return ($rowstat & $RowStats{deleted});
}
sub _islockedrow
{
    my $rowstat = shift @_;

    return ($rowstat & $RowStats{lock});
}
sub _isheadrow
{
    my $rowstat = shift @_;

    return (_isvaldatarow($rowstat) && ($rowstat & $RowStats{head}));
}
sub _istailrow
{
    my $rowstat = shift @_;

    return (_isvaldatarow($rowstat) && ($rowstat & $RowStats{tail}));
}

# XXX: note - not a class or instance method
sub _row_write
{
    my $value = shift;

    if ($doRot13)
    {
        $value =~ tr/A-Za-z/N-ZA-Mn-za-m/; # rot13 encryption
    }
    return $value;
#    my $packout = pack('n/a*', $value);
#    return $packout;
}

sub _row_read
{
    my ($rowposn, $rowlen, $refbufstr) = @_;

#    my @baz = unpack("x$rowposn n/a", $$refbufstr);
    my @baz = unpack("x$rowposn a$rowlen", $$refbufstr);

    return undef # XXX XXX: error!
        unless (scalar(@baz) > 0);

    my $value = $baz[0];

    if ($doRot13)
    {
        $value =~ tr/A-Za-z/N-ZA-Mn-za-m/; # rot13 encryption
    }
    return ($value);
}


sub _realfetch
{
    my ($self, $rowposn, $rowlen) = @_;

    my $refbufstr = $self->{bigbuf};

    # skip rowposn bytes then unpack rowlen bytes

    # XXX XXX: remember to fix packdeleted and RDBlock subclasses to
    # support rowlen
    return (_row_read($rowposn, $rowlen, $refbufstr));
}

# get and set metadata in a standard packed row format. value is a
# reference to an array
#
# Each row is identified by a unique id, not the standard 
# array offset (place).  Some example id's are "#" for comments, 
# "I" for indexes.
#
sub _get_meta_row
{
    my ($self, $id) = @_;

    my $place = $self->_fetchmeta($id);

    return undef
        unless (defined($place));
    
    my $fetched = $self->_fetchmeta(undef, $place);

    return undef
        unless (defined($fetched));

    my @row = UnPackRow($fetched, $Genezzo::Util::UNPACK_TEMPL_ARR);  

    return \@row;
}

sub _set_meta_row
{
    my ($self, $id, $value) = @_;

    my $place = $self->_fetchmeta($id);

    if (defined($place))
    {
        # store into the existing metadata row
        my $stat = $self->_realstore($place, 
                                     PackRow($value));   
        return undef
            unless (defined($stat));

        return $value;
    }
    else # no such row
    {
        # XXX XXX: slight hack -- "standard" blocks all have a
        # metadata row for row zero, but some test functions use
        # nonstandard blocks.  Create a row zero for this case if
        # necessary.
        my $numelts =  $self->{numelts};

#        my $stat = $self->_fetchmeta(undef, 0);
#        unless (defined($stat))
        unless ($numelts)
        {
            # no rows found
            greet "no meta zero!";

            # XXX XXX: should be able to use an empty row without
            # a comment...
            $place = $self->_push_one(PackRow(["#:empty"]), 0);

            unless (defined($place) && (!$place))
            {
                whisper "bad push";
                return undef;
            }
        }

        $place = $self->_push_one(PackRow($value), 0);
#        greet "new $place";
    }
    
    return undef 
        unless (defined($place));
    
    # use row zero to find the location of this metarow
    my $stat = $self->_update_meta_zero($id, $place);

    return undef
        unless (defined($stat));

    return $value;
} # end _set_meta_row

# delete a meta data row by id (as defined in meta zero)
sub _delete_meta_row
{
    my ($self, $id) = @_;
    my $value;
    
    my $place = $self->_fetchmeta($id);

    return undef
        unless (defined($place));

    # get the value
    $value = $self->_get_meta_row($id);

    # delete the meta row
    my $stat = $self->DELETE($place);

    # delete from meta zero
    my $mplace = $self->_delete_meta($id);

    return undef
        unless (defined($stat));

    return $value;
} # end delete_meta_row

# treat row zero as metadata row, an array of scalars identified by a
# unique id.  If the id does not exist, it is added.
#
# value is a scalar, not an array.
#
# NOTE: major assumption - that row zero exists and is a metadata row.
#
sub _update_meta_zero
{
    my ($self, $id, $value) = @_;
    my $oldvalue;
    my $place = 0;

    my $refrowdir = $self->{rowdir};

    my $numelts =  $self->{numelts};

    carp "no zero row for metadata!"
        unless ($numelts);

#  Carp::croak ("No such row")
    return (undef)
        unless ($place < $numelts);

    my ($rowstat, $rowposn, $rowlen) = @{ $refrowdir->[$place] };

    # XXX XXX: need to check if rowstat = metadata ...
    # return undef if rowstat?

    my @row;
    my $appendval = 1; # always append

  L_findcol:
    unless (_isnull($rowstat))
    {
        my $fetched = $self->_realfetch ($rowposn, $rowlen );

        last L_findcol
            unless (defined($fetched));

        @row = UnPackRow($fetched, $Genezzo::Util::UNPACK_TEMPL_ARR);

#        greet @row;

        my $regex = '^' . $id . ':(.*)';

        # XXX XXX: better to do a binary search of sorted array.
        for my $i (0..(scalar(@row)-1))
        {
            my $col = $row[$i];
            my @outi;
            if (@outi = ($col =~ m/$regex/))
            {
                $oldvalue = $outi[0];
                $appendval = 0;
                $row[$i] = $id . ':' . $value;
                last L_findcol;
            }
        }
    }  # end unless

    # XXX XXX: would be better to maintain a sorted array
    if ($appendval)
    {
        push @row, $id . ':' . $value;
    }

#    greet @row;

    my $stat = $self->_realstore($place, PackRow(\@row));

#    greet $stat;
    return undef
        unless (defined($stat));

    # return id and the oldvalue, since the oldvalue might be null...
    return [$id, $oldvalue];
} # end update_meta_zero

# fetch a metadata row either by id or place.  Fetch by id assumes
# valid metadata in row zero.
sub _fetchmeta
{
    my ($self, $id, $mplace) = @_;

    my $place = 0;

    if (!defined($id) && (defined($mplace)))
    {
        # metadata id not defined, so fetch a specific row by place
        # number
        $place = $mplace;
    }

    my $refrowdir = $self->{rowdir};

    my $numelts =  $self->{numelts};

#  Carp::croak ("No such row")
    return (undef)
        unless ($place < $numelts);

    my ($rowstat, $rowposn, $rowlen) = @{ $refrowdir->[$place] };

    return undef
        if (_isnull($rowstat));

    my $fetched = $self->_realfetch ($rowposn, $rowlen );

#    greet $fetched;

    return undef
        unless (defined($fetched));

    # if id is undefined, we have fetched the metadata for mplace

    return ($fetched)
        unless (defined($id)); # no metadata id

    # id was defined, so current row is row zero -- unpack it and find
    # the row associated with the id.

    my @row = UnPackRow($fetched, $Genezzo::Util::UNPACK_TEMPL_ARR);

#    greet @row;

    my $regex = '^' . $id . ':(.*)';

    # XXX XXX: better to do a binary search of sorted array.
    for my $col (@row)
    {
        my @outi;
        if (@outi = ($col =~ m/$regex/))
        {
#            greet @outi;
            return $outi[0];
        }
    }
    return undef;
} # end _fetchmeta

# remove the metadata row reference in row zero by id. 
# Note: called by delete_meta_row, which removes the actual row and
# calls this function to remove the reference
sub _delete_meta
{
    my ($self, $id) = @_;

    my $place = 0;

    my $refrowdir = $self->{rowdir};

    my $numelts =  $self->{numelts};

#  Carp::croak ("No such row")
    return (undef)
        unless ($place < $numelts);

    my ($rowstat, $rowposn, $rowlen) = @{ $refrowdir->[$place] };

    return undef
        if (_isnull($rowstat));

    my $fetched = $self->_realfetch ($rowposn, $rowlen );

#    greet $fetched;

    return undef
        unless (defined($fetched));

    # id was defined, so current row is row zero -- unpack it and find
    # the row associated with the id.

    my @row = UnPackRow($fetched, $Genezzo::Util::UNPACK_TEMPL_ARR);

#    greet @row;

    my $regex = '^' . $id . ':(.*)';
    my $oldvalue;

    # XXX XXX: better to do a binary search of sorted array.
    for my $i (0..(scalar(@row)-1))
    {
        my $col = $row[$i];
        my @outi;
        if (@outi = ($col =~ m/$regex/))
        {
            $oldvalue = $outi[0];

            # remove it
            splice(@row, $i, 1);

            last;
        }
    }

    my $stat = $self->_realstore($place, PackRow(\@row));

#    greet $stat;
    return undef
        unless (defined($stat));

    return $oldvalue;
} # end _delete_meta

# return rowstat
sub _fetch2
{
#    whoami ();
    my ($self, $place) = @_;

    return (undef)
        unless ($self->EXISTS($place));

    my $refrowdir = $self->{rowdir};
      
    my ($rowstat, $rowposn, $rowlen) = @{ $refrowdir->[$place] };

    return undef
        if (_isnull($rowstat));

    my @outi;
    my $f1 = $self->_realfetch ($rowposn, $rowlen );
    
    $outi[0] = $f1;
    $outi[1] = $rowstat;

    return @outi;
} # end fetch2

sub FETCH
{
#    whoami ();
    my ($self, $place) = @_;

    return (undef)
        unless ($self->EXISTS($place));

    my $refrowdir = $self->{rowdir};
      
    my ($rowstat, $rowposn, $rowlen) = @{ $refrowdir->[$place] };

    return undef
        if (_isnull($rowstat));

    return ($self->_realfetch ($rowposn, $rowlen ));
}

# XXX: note - not a class or instance method
sub _calctotalheader
{
    my $numelts = shift @_;

    return ($Genezzo::Block::Std::LenHdrTemplate + 
            ($numelts * $Genezzo::Block::RowDir::LenRowDirTemplate));
}

sub _spacecheck
{
    my ($self, $packlen) = @_;

    if (defined($packlen))
    {
        return ($self->{absfree} <
                ($self->{freespace} -
                 ($packlen + $Genezzo::Block::RowDir::LenRowDirTemplate)));
    }

    return ($self->{freespace} - 
            ($self->{absfree} +
             $Genezzo::Block::RowDir::LenRowDirTemplate));
}

# XXX: may want to reuse deleted slots at some point
# undef for failure, else return row index
sub _push_one 
{
#    whoami @_;
    my ($self, $value, $rowtype) = @_;

    my $refrowdir = $self->{rowdir};
    my $numelts   = $self->{numelts};

    # XXX XXX XXX
    # NOTE : need to define undef specially
    unless (defined($value))
    {
        $value = "";
        $rowtype |= $RowStats{isnull};
    }

    my $packout = _row_write($value);
    my $packlen = length($packout);

    my $refbufstr = $self->{bigbuf};

    my $nextpos = $self->{blocksize} - $packlen;

    $nextpos -= $Genezzo::Block::Std::LenFtrTemplate;

    if ($numelts)
    {
        # need cnt-1 for rowdir array -- get the final entry and
        # use it to calculate where the next row goes
        my ($rowstat, $rowposn, $rowlen) = @{ $refrowdir->[$numelts - 1] };
        
        $nextpos = $rowposn - $packlen;
    }
    else
    {
        # no holes for deleted rows if started at zero
        $self->{compacted} = 1; # cleaned up as much as possible
    }

#    Carp::croak ("no more room")
    return (undef)
        if ($nextpos <= _calctotalheader($numelts));

    my $sizediff = 
        ($packlen + $Genezzo::Block::RowDir::LenRowDirTemplate);
    # decrement the freespace
    $self->{freespace} -= $sizediff;

    $self->{can_insert} = ($self->{freespace} > $self->{absfree});    

#    whisper "$self->{freespace} bytes freespace remaining";
#    whisper "%free exceeded"
#        unless ($self->{can_insert});

    # add row to block
    substr($$refbufstr, $nextpos, $packlen) = $packout;
    
    # add row to row dir - note that array starts with zero, so we
    # use the unincremented rowcount to add the new row, i.e array
    # of size N={numelts} is [0..(N-1)]
    
    $refrowdir->[$numelts] = [$rowtype, $nextpos, $packlen ];
    $self->{numelts} += 1;

#       greet $refrowdir;

    # still use unincremented row count for new row

    SetRDEntry($self, $numelts,  @{ $refrowdir->[$numelts] } );
    
    # add new row count to main header
    SetStdHdr($self, $self->{blocktype}, $self->{numelts}, $self->{freespace});

    # push_post_hook
    if (defined(&push_post_hook))  
    {
#        return 0
#            unless 
            (push_post_hook(self => $self, sizediff => $sizediff));
    }


    return ($self->{numelts} - 1);

}

# SuckHash::Split::
# HSuck(array value)
#
# returns null if cannot consume the value, 
# else returns new key, offset
#
# XXX XXX: need to extend this api -- bytes consumed, bytes remaining,
# fwd ptr, fragmentation information, etc

sub HSuck
{
#    whoami;
    my $self = shift;
    my %args = (
                @_);

#    greet %args;
    return undef
        unless (defined($args{value}));

    my $val = $args{value};
    my $off = (defined($args{offset})) ? 
        $args{offset} : scalar(@{$val}); # offsets are 1 based, not 0

    my $next     = $args{next};
    my $oldplace = $args{place};
    my $headless = $args{headless}; # set if not a true row head piece

    my $maxsize = 0;
    my $oldrowstat;

    if (defined($oldplace))
    {
#    my ($rowstat, $rowposn, $rowlen) = @{ $refrowdir->[$place] };
        my @rstats = $self->_exists2($oldplace);        

        return undef # no such row
            unless (scalar(@rstats) > 1);
        $oldrowstat = $rstats[0];
        $maxsize    = $rstats[2];
    }
    else
    {
        return undef
            unless $self->{can_insert};
    }

    unless ($maxsize)
    {
        # set maxsize as minimum of freespace or absolute freespace if
        # inserting a new row, or if the oldplace was a zero length
        # row
        $maxsize = ($self->{freespace} < $self->{absfree}) ?
            $self->{freespace} : $self->{absfree}; # min

        unless (defined($oldplace))
        {
            return undef # need space for the new row directory entry
                unless ($maxsize > $Genezzo::Block::RowDir::LenRowDirTemplate);
            $maxsize -= $Genezzo::Block::RowDir::LenRowDirTemplate;
        }
    }

    my ($packstr, $off2, $frag) = PackRow2($val, $maxsize, $off, $next);

    return undef
        unless (defined($packstr));

    my $rowstat = $DATAROW;

    # clear the tail flag if next is defined
    $rowstat &= ~($RowStats{tail})
        if (defined($next));

    # clear the head flag if not fully consumed
    $rowstat &= ~($RowStats{head})
        if ((defined($off2)) || defined($headless));

    my $place;

    if (defined($oldplace))
    {
        if ($rowstat != $oldrowstat)
        {
            # XXX XXX : use exists2 to get persistent update of rowstat
            my @rstats = $self->_exists2($oldplace, $rowstat);        

#            my $refrowdir = $self->{rowdir};
            # reset the rowstat if changed 
#            @{ $refrowdir->[$oldplace] }[0] = $rowstat;
        }
        $place = $oldplace;
        my $stat = ($self->_realstore($place, $packstr));

        return undef # XXX XXX: Super Bad!  We just trashed a valid row!!
            unless (defined($stat));
    }
    else
    {
        $place  = $self->_push_one($packstr, $rowstat);
    }
    return undef
        unless (defined($place));

    my @outi;

    push @outi, $place;
    if (defined($off2))
    {
        push @outi, $off2;
    }
    if (defined($frag))
    {
        push @outi, $frag; # column was fragmented
    }

    # place, [offset, [frag]]
    return @outi;

} # end HSuck

sub HPush # pushhash style
{
#    whoami;
    my ($self, $value) = @_;

    return undef
        unless $self->{can_insert};

    my $place = $self->_push_one($value, $DATAROW);
    return $place;
}

# array style push
sub PUSH # XXX XXX: need to check pushcount - may fail if run out of space...
{
#    whoami;
    my $self = shift;

    my $pushcount = 0;

    # push gets list of values...
    foreach my $value  (  @_) 
    {
        last
            unless $self->{can_insert};

        my $pstat = $self->_push_one($value, $DATAROW);
        last
            unless (defined($pstat));
        $pushcount++;
    }
    return $pushcount;
}

sub STORE # return undef if out of space
{
#    whoami ();

    my ($self, $place, $value) = @_;

    return (undef)
        unless ($self->EXISTS($place));

    return ($self->_realstore($place, $value));
}

# this function stores a value into a pre-existing slot in the block,
# resizing (by moving around other elements) if necessary.  
# No EXISTance check: can be used to store values when element was not a
# data row (e.g., if row was already deleted)
sub _realstore # return undef if out of space
{
#    whoami ();

    my ($self, $place, $value) = @_;

    my $refrowdir = $self->{rowdir};
    my $numelts   = $self->{numelts};

#  Carp::croak ("No such row")
    return (undef)
        unless ($place < $numelts);
    
    # note: rowstat is preserved, not set to datarow
    my ($rowstat, $rowposn, $rowlen) = @{ $refrowdir->[$place] };

    # XXX XXX XXX
    # NOTE : need to define undef specially
    # Undef is problematic because STORE returns undef on failure, and
    # the value when it suceeds.  But if you store an undef you cannot
    # distinguish success from failure.
    if (defined($value))
    {
        # clear nullness
        if (_isnull($rowstat))
        {
            #  bitclear...
            $rowstat &= ~($RowStats{isnull});
        }

    }
    else
    {
#        whisper "null!";
        # set nullness
        $value = "";
        $rowstat |= $RowStats{isnull};
    }

    my $packout = _row_write($value);
    my $packlen = length($packout);

    my $refbufstr = $self->{bigbuf};

#    whisper "old rowlen : $rowlen\npacklen : $packlen";

    my $sizediff = $rowlen - $packlen;

#    whisper "sizediff : $sizediff";

    # perfect match!!
    if (0 == $sizediff)
    {
        # add row to block
        substr($$refbufstr, $rowposn, $packlen) = $packout;

        return ($value);
    }

    my ($lastrowstat, $lastrowposn, $lastrowlen) = 
        @{ $refrowdir->[$numelts - 1] };

    if ($sizediff < 0) # new row is larger
    {

        # as updated row size increases, offset to last row decreases.
        # When the start of the last row overwrites the end of the
        # header we are in trouble...

        if (($lastrowposn 
             + $sizediff) <= _calctotalheader($numelts))
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
    substr($$refbufstr, $rowposn + $sizediff, $packlen) = $packout;

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
        unless (0 == $sizediff);

    # realstore_post_hook
    # check sizediff
    if (defined(&realstore_post_hook))  
    {
#        return 0
#            unless 
            (realstore_post_hook(self => $self, sizediff => $sizediff));
    }


    return ($value);

}

sub _packdeleted
{
#    whoami ();

    my $self = shift;

    return 0 
        if ($self->{compacted}); # no further cleanup possible

    my $refrowdir    = $self->{rowdir};
    my $oldfreespace = $self->{freespace};
    my $minsize      = length(_row_write(''));

    my $numrows = 0;

#    whoami $self->{numelts};

#    for (my $cnt = $self->{numelts} - 1; $cnt > 0; $cnt--)

    for (my $cnt = 0; $cnt < $self->{numelts}; $cnt++)
    {
        my ($rowstat, $rowposn, $rowlen) = @{ $refrowdir->[$cnt] };
        
#        whoami $cnt, $rowstat, $rowlen, $minsize;
        # count undeleted rows...
        if (_isdeletedrow($rowstat) && ($rowlen > $minsize))
        {
            $self->_realstore($cnt, '');
            $numrows++;
        }
        
    }

    $self->{compacted} = 1; # cleaned up as much as possible


    # NOTE: don't need a packdel_post_hook because this function calls
    # _realstore...

    # packdel_post_hook
#    if (defined(&packdel_post_hook))  
#    {
#        return 0
#            unless 
#            (packdel_post_hook(self => $self, sizediff => $sizediff,
#                               numrows => $numrows));
#    }

    if ($numrows)
    {
        whisper "packed $numrows, saved ", 
        ($self->{freespace} - $oldfreespace), " bytes";
    }

    return $numrows;

}

# array style fetchsize
sub FETCHSIZE 
{
#    whoami ();

    my $self = shift;

    my $refrowdir = $self->{rowdir};
    
    my $numrows = 0;

    for (my $cnt = 0; $cnt < $self->{numelts}; $cnt++)
    {
        my ($rowstat, $rowposn, $rowlen) = @{ $refrowdir->[$cnt] };
        
        # count undeleted data rows...
        $numrows++
            if (_isheadrow($rowstat));
#            if (_isvaldatarow($rowstat)); XXX XXX: only head pieces
        
    }

    return $numrows;

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

    my $numrows = -1; # because first offset is zero

    for (my $cnt = 0; $cnt < $self->{numelts}; $cnt++)
    {
        my ($rowstat, $rowposn, $rowlen) = @{ $refrowdir->[$cnt] };

        # XXX XXX XXX XXX: how to handle this with row pieces?  should
        # this be only head rows?
        
        # count undeleted data rows...
        $numrows++
            if (_isvaldatarow($rowstat));

        return $cnt
            if ($numrows == $offset);
        
    }

    return undef;

}

sub _exists2   
{ 
    my ($self, $place, $newrowstat) = @_;

    # must be numeric for exists in array
    return undef
        unless (defined($place));
    return undef
        if ($place !~ /\d+/);

    my $refrowdir = $self->{rowdir};

    my $numelts =  $self->{numelts};

    my @outi;

    if ($place < $numelts)
    {
#    my ($rowstat, $rowposn, $rowlen) = @{ $refrowdir->[$place] };
        push @outi, @{ $refrowdir->[$place] };

        if (defined($newrowstat))
        {
            # update memory structs
            $refrowdir->[$place]->[0] = $newrowstat;
            $outi[0] = $newrowstat;
            # fix the rowdir entry in block header
            SetRDEntry($self, $place,  @{ $refrowdir->[$place] } );
        }
    }
    else
    {
#  Carp::croak ("No such row")
        push @outi, 0;
    }

    return @outi;
} # _exist2


sub EXISTS    
{ 
    my ($self, $place) = @_;

    # must be numeric for exists in array
    return undef
        unless (defined($place));
    return undef
        if ($place !~ /\d+/);

    my $refrowdir = $self->{rowdir};

    my $numelts =  $self->{numelts};

#  Carp::croak ("No such row")
    return (0)
        unless ($place < $numelts);

    my ($rowstat, $rowposn, $rowlen) = @{ $refrowdir->[$place] };

    # XXX XXX XXX XXX: how to handle this with row pieces?  should
    # this be only head rows?

    return (_isvaldatarow($rowstat));

}

sub DELETE    
{
#    whoami (); 
    my ($self, $place) = @_;

    return (undef)
        unless ($self->EXISTS($place));

    my $refrowdir = $self->{rowdir};
    my $numelts   = $self->{numelts};

    my ($rowstat, $rowposn, $rowlen) = @{ $refrowdir->[$place] };

    my $sizediff = 0;

    # normal case if not at end
    unless (($place + 1) == $numelts)
    {
        $self->{compacted} = 0; # not compacted - we now have a hole

        # clear nullness for deleted rows
        $rowstat &= ~($RowStats{isnull})
            if (_isnull($rowstat));

        # mark row as deleted
        @{$refrowdir->[$place]} = (($rowstat | $RowStats{deleted}),
                                   $rowposn, $rowlen );
        
        # fix the rowdir entry in block header
        SetRDEntry($self, $place,  @{ $refrowdir->[$place] } );
        # don't need to update main hdr - number of rowdir elements
        # and free space unchanged until we can really free up this
        # row or shuffle the space...

#        return ($self->_realfetch ($rowposn, $rowlen ));
        goto L_fin_delete;
    }

    # NOTE: trivial truncation if at end of row directory

    my $clrblock = 0;
    my ($istat, $iposn, $iln); # status, position, length
    
    $iln = $rowlen; # first pass use rowlen from specified row to
                    # fix freespace

  L_SCRUB:
    while (1)
    {
        $self->{numelts}   -= 1;
        
        my $deltadiff = ($iln + $Genezzo::Block::RowDir::LenRowDirTemplate);

        $self->{freespace} += $deltadiff;
        $sizediff += $deltadiff;

        # clear the block if rownum = 0
        $clrblock = ($self->{numelts} == 0);
            
#            whisper "delete $place";
        delete ($refrowdir->[$place]);
        
        # break if rownum = 0
        last L_SCRUB if ($clrblock);
        
        $place--;
        ($istat, $iposn, $iln) = @{ $refrowdir->[$place] };
        
        # if penultimate row was already deleted let's be a good
        # citizen and scrub him as well

        last L_SCRUB unless (_isdeletedrow($istat));
    } # end while scrub

    my $refbufstr = $self->{bigbuf};

    # add new row count to main header
    if ($clrblock)
    {
        ClearStdBlock($self);
    }
    else
    {
        SetStdHdr($self, 
                  $self->{blocktype}, $self->{numelts}, 
                  $self->{freespace});
    }

    unless ($self->{can_insert})
    {
        $self->{can_insert} = ($self->{freespace} > $self->{absused});
        whisper "%used met - inserts re-enabled"
            if ($self->{can_insert});
    }
 

L_fin_delete:

    # delete_post_hook
    if (defined(&delete_post_hook))  
    {
#        return 0
#            unless 
            (delete_post_hook(self => $self, sizediff => $sizediff));
    }

    # don't need to update rowdir elements in header -- numelts
    # specifies the length of the rowdir, and the trailing elemnts
    # will just get overwritten if new rows are added
    
    # return the deleted value
    return ($self->_realfetch ($rowposn, $rowlen ));
} # end DELETE

sub CLEAR
{
#    whoami (); 
    my $self = shift;

    my $refbufstr = $self->{bigbuf};

    # clear the main header
    ClearStdBlock($self);
    $self->_init(refbufstr => $refbufstr, blocksize => $self->{blocksize});

#    greet $self;
}

# reverse iterator...
sub _lastkey {
    return $_[0]->_prevkey($_[0]->{numelts} + 1);
}
sub _prevkey {
    my ($self, $nextkey) = @_;
    my $kk = $nextkey - 1;

    while ($kk > 0)
    {
        my @rstats = $_[0]->_exists2($kk);

        return $kk
            if ((scalar(@rstats) > 1) && _isheadrow($rstats[0]));
        $kk--;
    }
    return (undef);
}

sub NEXTKEY  { 

    my ($self, $prevkey) = @_;
    my $kk = $prevkey + 1;

    while ($kk < $self->{numelts})
    {
        my @rstats = $_[0]->_exists2($kk);

        return $kk
            if ((scalar(@rstats) > 1) && _isheadrow($rstats[0]));
        $kk++;
    }
    return (undef);
}

sub FIRSTKEY { 
    return $_[0]->NEXTKEY(-1);
}

sub GetContrib
{
    my $self = shift;
    return $self->{Contrib};
}

END {

}


1;

__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Genezzo::Block::RDBlock.pm - Row Directory Block tied hash class.  A
class that lets you treat the contents of a block (byte buffer) as a
hash.

Note: This implementation is almost, but not quite, a pushhash.  The
push hash implementation is B<Genezzo::Row::RSBlock>.  It also forms the
basis of a tied array in B<Genezzo::Block::RDBArray>.


=head1 SYNOPSIS

 use Genezzo::Block::RDBlock;
 use Genezzo::Block::Std;

 local $Genezzo::Block::Std::DEFBLOCKSIZE = 500;

 my $buff = "\0" x 500; # construct an empty byte buffer

 my %tied_hash = ();

 my $tie_val = 
     tie %tied_hash, 'Genezzo::Block::RDBlock', (refbufstr => \$buff);

 # pushhash style 
 # (note that the "PUSH" pseudo key is not supported)...
 my $newkey = $tie_val->HPush("this is a test");

 # or array style, your choice
 my $pushcount = $tie_val->PUSH(qw(push lots of data));

 $tied_hash{$newkey} = "update this entry";

 # a hash that supports array style FETCHSIZE
 my $getcount = $tie_val->FETCHSIZE(); # Note: not HCount

=head1 DESCRIPTION

RDBlock is the basis for persistent tied hashes, pushhashes, and tied
arrays.  After the hash is tied to the byte buffer, the buffer can be
written to persistent storage.  The storage is designed such that
inserts/appends/pushes are fairly efficient, and deletes are
inexpensive.  The pctfree/pctused parameters allow some tuning to
reserve space in the buffer for updates that "grow" existing values.
Updates that do not change the packed size of data are about as
efficient as insert/appends -- just the cost to copy your bytes into
the buffer -- but updates that do change the size of stored values can
require a large amount of byte shifting to open up storage space.
Also, the buffer does not grow to accomodate large values.  Wrapper
classes are necessary to specify mechanisms for packing complex data
structures and techniques to split objects across multiple buffers.

=head1 ARGUMENTS

=over 4

=item refbufstr
(Required) - a reference to the byte buffer used for storage.

=item blocksize
(Optional) - the size of the supplied byte buffer.
Default is $Genezzo::Block::Std::DEFBLOCKSIZE.
                    
=item pctfree
(Optional) - the percentage of space kept free for future updates.
Default is 30 (percent).
                    
=item pctused
(Optional) - after the block is full, the percentage of space that must
be open before inserts are re-enabled.  Default is 50 (percent).

=back


=head1 CONCEPTS

The structure and techniques for the Row Directory Block are described
in Chapter 14, "The Tuple-Oriented File System", of "Transaction
Processing: Concepts and Techniques" by Jim Gray and Andreas Reuter,
1993.

A tuple is a collection of values -- in the standard vernacular you
would call it a "row" in a database.  The I<refbufstr> argument to the
hash constructor is a "block", a fixed-size contiguous buffer of
bytes.  When you write (C<STORE>) a value into the RDBlock hash, it
writes an entry into the block as a byte string, and reads (C<FETCH>)
work in an analogous fashion.  

The RDBlock data structures refer to stored values as "rows", but the
basic C<STORE> and C<FETCH> only understand how to store and retrieve
individual byte strings.  Wrapper classes for RDBlock must
marshall/unmarshall (Freeze/Thaw) between simple strings and more
complex data structures.

The block has some header and footer information, plus a I<row
directory>, a data structure that records the offsets, extents, and
status information of the stored row data.  While the physical
location of row data in a block may change as other rows are added,
deleted or modified, the row keeps the same hash key.

Each row has an associated "status" bitfield, which is some
combination of the following values:

=over 4

=item  deleted

set if row is deleted.  Deleted rows are simply marked as deleted, but
the physical storaged is not immediately recouped.  

=item  data 

set for data rows, unset for metadata.  All information stored via the
standard public interfaces is data.  You can manipulate the private
interfaces to store "metadata", additional rows that describe, for
example, block contents, transaction information, or data
relationships, but are invisible to the public interfaces.  By
convention, row 0 is always a metadata row.  

=item  lock

set if row is locked.  Not used in this base class -- provided for
subclasses that must supply and maintain the appropriate metadata to
identify locker and transaction information.

=item  head

set if the stored value is the very first part of a row.

=item  tail

set if the stored value is the very last part of a row.  If C<STORE>
writes a complete value it sets both head and tail to true.  The base
class only writes rows that fit in a single block, so both head and
tail are always set.

These flags are useful if you wish to write subclasses with rows
that span multiple blocks.  Neither head nor tail is set if only the
middle section of a multi-part row is stored.

=item  isnull

If you supply C<STORE> with a value of undef, it writes a marker for a
zero-length string and sets this flag.  C<FETCH> will correctly return
an undef.  

Note: When packing more complex data structures, make sure to use an
encoding that distinguishes between undefs and zero-length strings.  A
simple scheme for packing an array of strings is to prefix the packed
array with a bitstring that specifies which entries are null.

=back


=head1 FUNCTIONS

RDBlock support all standard hash operations, with the exception
that you cannot create or insert a user key -- you must push new
entries and use the generated key or basic iteration to retrieve your
data.  

It also supports three additional public methods: an array style
C<PUSH> and C<FETCHSIZE>, plus a PushHash style HPush.  Note that
these methods are associated with the tie value (i.e. the blessed ref
for the RDBlock class), not the tied hash.  Finally, it has five
"private" methods that may be of use in constructing subclasses:
push_one, packdeleted, offset2hkey, lastkey, prevkey

=over 4

=item PUSH this, LIST

PUSH appends the list to the end of the hash and returns the number of
items it pushed.

=item FETCHSIZE

Returns the total number of valid, undeleted data items in the hash.

=item HPush

HPush returns the new key for each pushed value.  It only accepts a
single argument, not a list.

my $newkey = $tie_val->HPush("this is a test");

Note that there is not a corresponding "pop" operation.

=back

=head2 EXPORT

DATAROW, RowStat

=head1 LIMITATIONS

The storage mechanism uses network longs (32 bits?) to describe the
lengths of rows and offsets within the block.  (That seems pretty
large -- maybe it should use shorts to restrict blocksize and row
piece length to 64K?  Or init should take an optional module name for
block type that lets us vary the row directory, header and footer
sizing).

=head1 TODO

=over 4

=item use row directory rowlen vs len/value for row storage

=item meta row - should binary search for meta id

=item unicode support

=back

=head1 AUTHOR

Jeffrey I. Cohen, jcohen@genezzo.com

=head1 SEE ALSO

L<perl(1)>.

Copyright (c) 2003-2007 Jeffrey I Cohen.  All rights reserved.

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
