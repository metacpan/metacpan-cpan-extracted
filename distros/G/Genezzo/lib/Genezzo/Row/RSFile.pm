#!/usr/bin/perl
#
# $Header: /Users/claude/fuzz/lib/Genezzo/Row/RCS/RSFile.pm,v 7.21 2007/11/18 08:13:27 claude Exp claude $
#
# copyright (c) 2003-2007 Jeffrey I Cohen, all rights reserved, worldwide
#
#
use strict;
use warnings;

use Carp qw(cluck);
use Genezzo::Row::RSBlock;

package Genezzo::Row::RSFile;
use Genezzo::Util;
use Genezzo::BufCa::BCFile;
use Genezzo::SpaceMan::SMFile;
use Genezzo::SpaceMan::SMExtent;
use Genezzo::PushHash::HPHRowBlk;

use Carp;
use warnings::register;

our @ISA = qw(Genezzo::PushHash::HPHRowBlk) ;

our $GZERR = sub {
    my %args = (@_);

    return 
        unless (exists($args{msg}));

    if (exists($args{self}))
    {
        my $self = $args{self};
        if (defined($self) && exists($self->{GZERR}))
        {
            my $err_cb = $self->{GZERR};
            return &$err_cb(%args);
        }
    }

    my $warn = 0;
    if (exists($args{severity}))
    {
        my $sev = uc($args{severity});
        $sev = 'WARNING'
            if ($sev =~ m/warn/i);

        # don't print 'INFO' prefix
        if ($args{severity} !~ m/info/i)
        {
            printf ("%s: ", $sev);
            $warn = 1;
        }

    }
    # XXX XXX XXX
    print __PACKAGE__, ": ",  $args{msg};
#    print $args{msg};
#    carp $args{msg}
#      if (warnings::enabled() && $warn);
    
};

our $ROW_DIR_BLOCK_CLASS  = 'Genezzo::Row::RSBlock';

# private
sub _init
{
    #whoami;
    #greet @_;
    my $self = shift;
    my %required = (
                    tablename  => "no tablename !",
                    object_id  => "no object id !",
                    filename   => "no filename !",
                    numbytes   => "no bytes !",
                    numblocks  => "no blocks !",
                    bufcache   => "no bufcache !",
                    tso        => "no tso !",
                    object_type => "no object type"
                    );
    my %optional = (
                    RDBlock_Class  => "Genezzo::Block::RDBlock",
                    dbh_ctx        => {}
                    );
    
    my %args = (
                %optional,
                @_);

    return 0
        unless (Validate(\%args, \%required));

    # array of push hashes from make_new_chunk
    $self->{filename}  = $args{filename};
    $self->{filenumber}  = $args{filenumber};

    $self->{numbytes}  = $args{numbytes};
    $self->{numblocks} = $args{numblocks};
    $self->{tablename} = $args{tablename};
    $self->{realbc}    = $args{bufcache};
    $self->{object_id} = $args{object_id};
    $self->{tso}       = $args{tso};
    $self->{object_type} = $args{object_type};

#    $self->{initial_extent} = $args{initial_extent};
#    $self->{next_extent}    = $args{next_extent};

    my %nargs = (filename   => $args{filename},
                 numbytes   => $args{numbytes},
                 numblocks  => $args{numblocks},
                 bufcache   => $args{bufcache},
                 filenumber => $args{filenumber},
                 tablename  => $args{tablename},
                 object_id  => $args{object_id},
                 object_type  => $args{object_type}
                 );

    if ((exists($args{GZERR}))
        && (defined($args{GZERR}))
        && (length($args{GZERR})))
    {
        # NOTE: don't supply our GZERR here - will get
        # recursive failure...
        $nargs{GZERR} = $args{GZERR};
    }

    $self->{smf} = Genezzo::SpaceMan::SMExtent->new(%nargs);

    return 0
        unless (defined($self->{smf}));

    my $blockpkg = $args{RDBlock_Class};
    
    # NOTE: check if the rdblock class for RSBlock tie exists...
    unless (eval "require $blockpkg")
    {
        whisper "could not load class $blockpkg";
        return 0;
    }
    $self->{RDBlock_Class} = $blockpkg;

    # keep track of which block is currently buffered.
    $self->{bc} = {};

    my $bc = $self->{bc};

    $bc->{bufblockno} = ();  
    $bc->{bceref} = ();
    $bc->{realbcfileno} = 
        $self->{realbc}->FileReg(FileName   => $self->{filename},
                                 FileNumber => $self->{filenumber});

    # current insertion point - (not necessarily the current block)
    $self->{current_chunk_for_insert} = (); 

    # Contrib is the counterpart to the CPAN Genezzo::Contrib
    # namespace.  Add hash keys according to your package name, e.g.
    #   $self->{Contrib}->{Clustered} = 'foo' 
    $self->{Contrib} = {}; 

    return 1;
}

sub TIEHASH
{ #sub new 
#    greet @_;
    my $invocant = shift;
    my $class = ref($invocant) || $invocant ; 
    my $self = $class->SUPER::TIEHASH(@_);

    my %args = (@_);
    return undef
        unless (_init($self,%args));

    if ((exists($args{GZERR}))
        && (defined($args{GZERR}))
        && (length($args{GZERR})))
    {
        # NOTE: don't supply our GZERR here - will get
        # recursive failure...
        $self->{GZERR} = $args{GZERR};
    }

    return bless $self, $class;

} # end new

# private routines
sub _get_smf
{
    my $self = shift;
    return $self->{smf};
}

sub _buffered_blockno  # current buffered block, as distinct from currchunkno
{
#    whoami;
    local $Genezzo::Util::QUIETWHISPER = 1; # XXX: quiet the whispering

    my $self = shift;
#    greet $self->{tablename};

    my $bc        = $self->{bc};
    my $blockno   = $bc->{bufblockno};
    return $blockno if (defined($blockno));

    # load the first block if don't have it yet
    my $smf       = $self->{smf};
    my $tablename = $self->{tablename};
    my $object_id = $self->{object_id};

    # NOTE: some tricky stuff here -- first always define bufblockno.
    $bc->{bufblockno} = $self->_currchunkno();

    # NOTE: calling get_a_chunk will call currchunkno again, but since
    # bufblockno is defined it should exit at the first return.

    if (defined($bc->{bufblockno}))
    {
        whisper "try to load first chunk";
        my $chunk1 = $self->_get_a_chunk($bc->{bufblockno});
        unless (defined($chunk1))
        {
            whisper "could not load 1st chunk!";
            return undef;
        }
    }
    return ($bc->{bufblockno});

}

sub _currchunkno     # override the hph method
{
#    whoami;
    my $self = shift;
#    greet $self->{tablename};

    # load the first block if don't have it yet
    my $smf       = $self->{smf};
    my $tablename = $self->{tablename};
    my $object_id = $self->{object_id};

    unless (defined($self->{current_chunk_for_insert}))
    {
        $self->{current_chunk_for_insert} = 
            $smf->currblock(tablename => $tablename,
                            object_id => $object_id);
    }

    return ($self->{current_chunk_for_insert});
}

sub _get_current_chunk # override the hph method
{
#    whoami;
#    local $Genezzo::Util::QUIETWHISPER = 1; # XXX: quiet the whispering

    my $self = shift;
#    greet $self->{tablename};

    my $blockno = $self->_currchunkno();

    unless (defined($blockno))
    {
        return $self->_make_new_chunk();
    }

    # XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX
    #
    # Note: currchunkno is the current insertion point, not the
    # current _buffered_ block.  BE SURE TO CLEAR OUT THE BUFFERED BLOCK
    # so we can load the current insertion point.
    #
    # XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX
    my $bc = $self->{bc};
    
    if (defined($bc->{bufblockno})
        && ($bc->{bufblockno} != $blockno)) # no match!
    {
        $bc->{bufblockno} = ();  
        $bc->{bceref}     = ();

        # clear out the current tied block if it's not current
        # insertion point

        $self->_untie_block();
    } # buffered block didn't match

    unless (defined ($self->{rowd}))
    {
        whisper "try to load first chunk";
        my $chunk1 = $self->_get_a_chunk($blockno);
        unless (defined($chunk1))
        {
            whisper "could not load 1st chunk!";
            return undef;
        }
    }
    return ($self->{rowd})
}

sub _make_new_chunk # override the hph method
{
#    whoami;
    my $self = shift;

    my $smf  = $self->{smf};
    my $bc   = $self->{bc};
    my $tso  = $self->{tso};
    my $tablename = $self->{tablename};
    my $object_id = $self->{object_id};

    my $gotnewextent = 0; # true if get new extent

    # release tied blocks
    $self->_untie_block();

    my ($blockinfo, $blockno);
    for my $num_tries (1..2)
    {
        my %nargs = (tablename   => $tablename,
                     object_id   => $object_id,
                     all_info    => 1 # ask for all info
                     );

        # XXX XXX: get from TSO
        $nargs{pctincrease} = 50;

        $blockinfo =
            $smf->nextfreeblock(%nargs);

        $gotnewextent = 0; # true if get new extent

        if (defined($blockinfo))
        {
            $gotnewextent = $blockinfo->IsNewExtent();

            if ($gotnewextent)
            {
                greet "new extent", $blockinfo ;
            }

            $bc->{bufblockno} = $blockinfo->GetBlocknum();

            $blockno   = $bc->{bufblockno};
        }
        last if (defined ($blockno));

        # no space left?  See if can extend this file.
        # need to update numbytes, numblocks
        last unless ($tso->TSGrowFile(smf => $smf,
                                      tablename => $tablename,
                                      object_id => $object_id,
                                      pctincrease => 50 # extent size increase
                                      ));
    }
#    greet $blockno;

    unless (defined ($blockno))
    {
        whisper "out of free blocks!";
        return undef; 
    }

    $self->{current_chunk_for_insert} = $blockno;

    $bc->{bceref} = 
        $self->{realbc}->ReadBlock(filenum  => $bc->{realbcfileno},
                                   blocknum => $blockno);
    
    unless ($bc->{bceref})
    {
        whisper "failed to read block!";
        return (undef);
    }

    my $bce = ${$bc->{bceref}};
#    $smf->flush();
#    greet $bce;

    # tie the block -- set up the rowd and reftiebufa
    $self->_tie_block($blockno, $bce);

    if ($gotnewextent)
    {
        # size of extent is last entry in blockinfo
        my $extent_size = $blockinfo->GetExtentSize();

#        print "e:", $extent_size, "\n";

        # get meta data for the extent header
        my $row = $self->{rowd}->_get_meta_row("XHA");

#        if ($row && scalar(@{$row}) && ($row->[0] == $extent_size))
#        {
#            print "match for first extent\n";
#        }
#        else
#        {
#            print "no match for first extent - $extent_size\n";
#        }

        $self->{currextent}  = $blockno;
        $self->{extent_size} = $extent_size;
        $self->{extent_posn} = 0;
    }
    else
    {
        $self->{extent_posn} += 1;
        my $posn = $self->{extent_posn};
        # get meta data for the extent header
        my $row = $self->{rowd}->_get_meta_row("XHP");

#        if ($row && scalar(@{$row}) && ($row->[0] == $posn))
#        {
#            print "match for position\n";
#        }
#        else
#        {
#            print "no match for position - $posn \n";
#        }

    }
    
    return ($self->{rowd});
}

# NOTE: block routine for index operations
sub _make_new_block # override HPHRowBlk
{
    my $self = shift;

#    whoami;

    my $chunk = $self->_make_new_chunk();

    return undef
        unless (defined($chunk));
    my $blockno = $self->_currchunkno();
    # NOTE: add 0 as slotnumber
    return $self->_joinrid($blockno, '0');
}

# NOTE: block routine for index operations and row splitting
sub _get_current_block # override HPHRowBlk
{
    my $self = shift;

#    whoami;

    my $chunk = $self->_get_current_chunk();

    return undef
        unless (defined($chunk));

    my $blockno = $self->_currchunkno();
    # NOTE: add 0 as slotnumber
    return $self->_joinrid($blockno, '0');
}

# NOTE: block routine for index operations
sub _get_block_and_bce # override HPHRowBlk
{
    my ($self, $place) = @_;

    my ($chunk, $sliceno) = $self->_get_chunk_and_slice($place);

    return undef
        unless (defined($chunk));
 
    my $bc = $self->{bc};
    my $blockno = $self->_currchunkno();

    # XXX XXX : need method to get tie rdblock
    #   tiedblock , block number, bceref,  tied hash
    return ($chunk->{tie_rdblock}, 
            $blockno, 
            ($bc->{bceref}), 
            ($self->{reftiebufa}));
}

sub First_Blockno # override HPHRowBlk
{
    my $self = shift;

    return $self->_First_Chunkno();
} # end First_Blockno

sub Next_Blockno # override HPHRowBlk
{
    my $self = shift;

    return $self->_Next_Chunkno(@_);
} # end Next_Blockno

sub _get_a_chunk # override the hph method
{
    my ($self, $blocknum) = @_;
#    whoami @_;

    if ($blocknum !~ /\d+/)
    {
        carp "Non-numeric key: $blocknum "
            if warnings::enabled();
        return (undef); # protect us from non-numeric array offsets
    }

    my $buffered_blockno = $self->_buffered_blockno();
    #
    # XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX 
    #
    # NOTE: we might get called from within currchunkno for the very
    # first time.  In this case, the above call to to currchunkno
    # shouldn't recurse forever because the bufblockno is defined at
    # the beginning of the first call to currchunkno.  
    # 
    # However, in this routine, we need to check if self->rowd exists.
    # On the first pass currchunkno gets defined, but we haven't
    # loaded the first tie for the block, so rowd is undefined.  In
    # this case drop thru and read the block and tie it.  For
    # subsequent cases rowd will exists and we don't have to keep
    # going to read the block and retie.  May need to rethink this
    # strategy for more complicated locking model.
    #
    # In one case, might try to read the hash first, so call to
    # FIRSTKEY/NEXTKEY will call smf->firstblock (via _First_Chunkno),
    # and then this function.  In get_a_chunk we call currchunkno to
    # see if the chunkno = current.  currchunkno will set bufblockno
    # via smf->currblock, and then call this function *AGAIN* to load
    # the block.  Which calls currchunkno again, but bufblockno is
    # set, so it short-circuits.  Then this function finally loads the
    # block.
    #
    # In other case, might try to insert into the hash.  STORE can
    # call get_chunk_and_slice, which calls get_a_chunk, or HPush can
    # call get_current_chunk.  Either way currchunkno gets called
    # which loads the current block.  We need a smarter optimization
    # to avoid loading the current block for NEXTKEY, since we will
    # immediately discard it for the first block.
    #
    # XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX 
    #
    if (    (defined($buffered_blockno))
         && (defined($self->{rowd})))
    {
        return ($self->{rowd})
            if  ($buffered_blockno == $blocknum);
    }

    my $smf  = $self->{smf};
    my $bc   = $self->{bc};
    my $tablename = $self->{tablename};
    my $object_id = $self->{object_id};

    unless ($smf->hasblock(tablename => $tablename,
                           object_id => $object_id, 
                           blocknum  => $blocknum))
    {
        carp "key out of range: $blocknum "
            if warnings::enabled();
        return (undef);
    }

    $self->_untie_block();

#    print "RSFILE READ BLOCK: ", $blocknum, "\n";

    $bc->{bceref} = 
        $self->{realbc}->ReadBlock(filenum  => $bc->{realbcfileno},
                                   blocknum => $blocknum);
    
    unless ($bc->{bceref})
    {
        whisper "failed to read block!";
        return (undef);
    }

    my $bce = ${$bc->{bceref}};

    # tie the block -- set up the rowd and reftiebufa
    $self->_tie_block($blocknum, $bce);

    $bc->{bufblockno} = $blocknum;    
    
    return ($self->{rowd});

}

sub STORE # override the hph method and standard hash method
{
    my $self = shift;
    my $stat = $self->SUPER::STORE(@_);
    return $stat;
}

sub _First_Chunkno # override the hph method
{
#    whoami;
    my $self = shift;
    my $smf  = $self->{smf};
    my $tablename = $self->{tablename};
    my $object_id = $self->{object_id};

    my $chunkno = 
        $smf->firstblock(tablename => $tablename,
                         object_id => $object_id);

    return ($chunkno);
}

sub _Next_Chunkno # override the hph method
{
#    whoami;
    my ($self, $prevkey) = @_;
    my $smf  = $self->{smf};
    my $tablename = $self->{tablename};
    my $object_id = $self->{object_id};

    return (undef)
        unless (defined ($prevkey));

    my $chunkno = $smf->nextblock(tablename => $tablename,
                                  object_id => $object_id,
                                  prevblock => $prevkey);
    return $chunkno;
}

# count estimation
sub FirstCount
{
#    whoami;
    my $self = shift;
    my $smf  = $self->{smf};
    my $tablename = $self->{tablename};
    my $object_id = $self->{object_id};

    my ($sum, $sumsq) = (0,0);

    my $totchunk = 
        $smf->countblock(tablename => $tablename,
                         object_id => $object_id);

    my $chunkno = $self->_First_Chunkno();

    my $chunkcount = 0;

    while (defined($chunkno))
    {
#        greet $chunkno, $sum;
        my $chunk = $self->_get_a_chunk($chunkno);
        $chunkcount++;

        if (defined($chunk))
        {
            $sum += $chunk->HCount();
            $sumsq = $sum ** 2; # variance is (0-count) ^ 2
            last;
        }
        
        $chunkno = $self->_Next_Chunkno($chunkno);
    }

    my @outi;

    my $sliceno = 0;
    my $keyplace;
    $keyplace = $self->_joinrid($chunkno, $sliceno)
        if (defined($chunkno));

    my $esttot = 0;
    $esttot = $sum * ($totchunk/$chunkcount)
        if (($sum > 0) && ($chunkcount > 0) && ($totchunk > 0));

    push @outi, $keyplace, $esttot;
    push @outi, $sum, $sumsq, $chunkcount, $totchunk;

    return (@outi); 
} # FirstCount

# count estimation
sub NextCount
{
#    whoami;
    my ($self, $prevkey, $esttot, $sum, $sumsq, $chunkcount, $totchunk) = @_;

    return undef
        unless (defined($prevkey));
    my ($chunkno, $prevsliceno) = $self->_splitrid($prevkey);

    $chunkno = $self->_Next_Chunkno($chunkno);

    my $quitLoop = 1; # XXX XXX 
    my $loopCnt  = 0;
    my $lastone  = 0;

    while (1)
    {
        my $oldChunkno;

        $loopCnt++;

        unless (defined($chunkno))
        {
            $totchunk = $chunkcount; # NOTE: we are done - 
                                     # fix the total chunk count
            $chunkno = $oldChunkno;
            $lastone = 1;
            last;
        }
#        greet $chunkno, $sum;
        my $chunk = $self->_get_a_chunk($chunkno);
        $chunkcount++;
     
        # readjust the estimated total if chunkcount now exceeds it --
        # make it slightly larger so pct_complete < 100%...
        $totchunk = $chunkcount + 1
            if ($chunkcount >= $totchunk);

        if (defined($chunk))
        {
            my $hcnt  = $chunk->HCount();
            $sum     += $hcnt;

#            my $mean = 0;
#            $mean = $hcnt/$chunkcount
#                if ($chunkcount);

            # variance = 1/n-1 * Sum( (observed - mean)^2 )

#            $sumsq   += (($hcnt - $mean)**2);
            $sumsq   += (($hcnt)**2);

            last if $quitLoop;
        }

        $oldChunkno = $chunkno;
        $chunkno = $self->_Next_Chunkno($chunkno);

        # XXX XXX: add logic here
        $quitLoop = 1
            if $loopCnt > 10;
    }

    my @outi;

    my $sliceno = 0;
    my $keyplace;
    $keyplace = $self->_joinrid($chunkno, $sliceno)
        if (defined($chunkno));

    # current sum + (current avg * remaining chunks)
#    $esttot = $sum + (($sum/$chunkcount)*($totchunk-$chunkcount))
    if (($sum > 0) && ($chunkcount > 0) && ($totchunk > 0))
    {
        if ($lastone)
        {
            $esttot = $sum;
        }
        else
        {
            $esttot = $sum * ($totchunk/$chunkcount);
        }
    }
    push @outi, $keyplace, $esttot;
    push @outi, $sum, $sumsq, $chunkcount, $totchunk;

#    greet @outi;

    return (@outi); 
} # NextCount

sub CLEAR
{
#    whoami;
    my $self = shift;
    my $smf  = $self->{smf};
    my $tablename = $self->{tablename};
    my $object_id = $self->{object_id};

    $self->SUPER::CLEAR();

    $smf->freetable(tablename => $tablename,
                    object_id => $object_id);
}


END {

}

sub _tie_block
{
    my ($self, $blocknum, $bce) = @_;

    return undef
        unless (defined($blocknum) && defined($bce));

    # BCE to RDBlock - please respond
    my $mailbag = Genezzo::Util::AddMail(To => 'Genezzo::Block::RDBlock',
                                         From => $bce,
                                         Msg => 'RSVP');

    # RSFile to RDBlock - register in Contrib hash (for SMHook)
    $mailbag = Genezzo::Util::AddMail(To => 'Genezzo::Block::RDBlock',
                                      From => $self,
                                      Msg  => 'RegisterSender',
                                      MailBag => $mailbag);

    my %tiebufa;
    # tie array to buffer
    $self->{rowd} = 
        tie %tiebufa, $ROW_DIR_BLOCK_CLASS,
         (RDBlock_Class => $self->{RDBlock_Class},
          blocknum  => $blocknum,
          refbufstr => $bce->{bigbuf},
          blocksize => $bce->{blocksize}, # XXX XXX : get blocksize from bce!!
          MailBag   => $mailbag
          );

    $self->{reftiebufa} = \%tiebufa;

    if (defined(&tie_block_post_hook))
    {
        (tie_block_post_hook(self      => $self, 
                             rowd      => $self->{rowd},
                             blocknum  => $blocknum));
    }

    $self->{blocknum} = $blocknum;

    return $self->{rowd};

} # end tie_block

sub _untie_block
{
    my $self = shift;

    my $reftb     = $self->{reftiebufa};

    if (defined(&untie_block_pre_hook))
    {
        (untie_block_pre_hook(self     => $self, 
                              rowd     => $self->{rowd},
                              blocknum => $self->{blocknum},
                              filename   => $self->{filename},
                              filenumber => $self->{filenumber}
                              ));
    }

    $self->{rowd} = ();  # clear out to force reload

    if (defined($reftb))
    {
        untie $reftb;
    }

    if (defined(&untie_block_post_hook))
    {
        (untie_block_post_hook(self     => $self,
                               blocknum => $self->{blocknum}));
    }

}

1;

__END__

# Below is stub documentation for your module. You better edit it!

=head1 NAME

Genezzo::Row::RSFile - Row Source File tied hash class.

=head1 SYNOPSIS

 use Genezzo::Row::RSFile;

=head1 DESCRIPTION

RSFile is a hierarchical pushhash (see L<Genezzo::PushHash::hph>)
class that stores scalar data in a block (byte buffer) via
L<Genezzo::Block::RDBlock>.

=head1 ARGUMENTS

=over 4

=item tablename
(Required) - the name of the table

=item tso
(Required) - tablespace object from L<Genezzo::Tablespace>

=item bufcache
(Required) - buffer cache object from L<Genezzo::BufCa::BCFile>


=back


=head1 CONCEPTS

RSFile can persistently store scalar data in a single file.  It
doesn't know anything about rows -- that's all in
L<Genezzo::Row::RSTab>.  

RSFile has some extensions to directly manipulate the underlying
blocks.  These extensions are useful for building specialized index
mechanisms (see L<Genezzo::Index>) like B-trees, or for supporting
scalars that span multiple blocks.

=head2 Basic PushHash

You can use RSFile as a persistent hash of scalars if you like.
RSFile can only support strings that fit with a single database block.
Use L<Genezzo::Row::RSTab> if you need to split data over multiple
blocks.

=head2 HPHRowBlk - Row and Block operations

HPHRowBlk is a special pushhash subclass with certain direct block
manipulation methods.  One very useful function is HSuck, which
provides support for rows that span multiple blocks.  While the
standard HPush fails if a row exceeds the space in a single block, the
HSuck api lets the underlying blocks consume the rows in pieces --
each block "sucks up" as much of the row as it can.  However, RSFile
does not provide the HSuck api.  Instead, it provides some utility
functions so RSTab can get direct access to the low-level block
routines.  

=head2 Counting, Estimation, Approximation

RSFile has some support for count estimation, inspired by some of Peter
Haas' work (Sequential Sampling Procedures for Query Size Estimation,
ACM SIGMOD 1992, Online Aggregation (with J. Hellerstein and H. Wang),
ACM SIGMOD 1997 Ripple Joins for Online Aggregation (with
J. Hellerstein) ACM SIGMOD 1999).  

=head1 FUNCTIONS

RSFile support all standard hph hierarchical pushhash operations.

=head2 EXPORT

=head1 LIMITATIONS

various

=head1 TODO

=over 4

=item need error handlers vs "whisper"

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
