#!/usr/bin/perl
#
# $Header: /Users/claude/fuzz/lib/Genezzo/SpaceMan/RCS/SMFile.pm,v 7.16 2007/07/28 07:45:29 claude Exp claude $
#
# copyright (c) 2003-2007 Jeffrey I Cohen, all rights reserved, worldwide
#
#
package Genezzo::SpaceMan::SMFile;  # assumes Some/Module.pm

use strict;
use warnings;

use Carp;
use Genezzo::Util;
use Genezzo::Row::RSBlock;
use Genezzo::SpaceMan::SMFreeBlock;

BEGIN {
    use Exporter   ();
    our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

    # set the version for version checking
#    $VERSION     = 1.00;
    # if using RCS/CVS, this may be preferred
    $VERSION = do { my @r = (q$Revision: 7.16 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r }; # must be all one line, for MakeMaker

    @ISA         = qw(Exporter);
    @EXPORT      = ( ); # qw(&NumVal);
    %EXPORT_TAGS = ( );     # eg: TAG => [ qw!name1 name2! ],

    # your exported package globals go here,
    # as well as any optionally exported functions
#    @EXPORT_OK   = qw($Var1 %Hashit &func3 &func5);
    @EXPORT_OK   = (); 

}

sub new 
{
    my $invocant = shift;
    my $class = ref($invocant) || $invocant ; 
    my $self = { };
    
#    whoami @_;

    $self->{filename}  = shift;
    $self->{numbytes}  = shift;
    $self->{numblocks} = shift;

    # buffer cache
    $self->{realbc} = shift;

    $self->{filenumber} = shift;

    $self->{read_only} = 0; # TODO: set for read-only database
    
    $self->{bc} = {};
    my $bc = $self->{bc};
    $bc->{realbcfileno} = 
        $self->{realbc}->FileReg(FileName => $self->{filename},
                                 FileNumber => $self->{filenumber});

    unless (defined($bc->{realbcfileno}))
    {
        whoami;
        my $fn = $self->{filename};
        whisper "failed to register $fn!!";
        print   "\nfailed to register $fn!!\n";
        return undef;
    }


    # read the fileheader
    $bc->{fileheader} = {};

    my $blessref = bless $self, $class;

    unless (_tiefh($self, $bc, 0))
    {
        whisper "bad tie for file header";
        return undef;
    }
    my $fileheader = $bc->{fileheader};

    # get the index for the freelist row
    my $flidx = $fileheader->{RealTie}->_fetchmeta("FL");

    {
        # currently have a free extent starting at block _1_
        # of _numblocks_ [i.e. all] blocks

        # block 0 for file header

        unless (defined($flidx))
        {

            # fileheader - last col indicates that a single extent
            # (block 0, length 1 block) is used for the header 
            # XXX XXX: extend to support additional blocks of file header
            # information

            my $packstr = 
                PackRow(
                        [
                         'HEADER',
                         $self->{filename},
                         $self->{numbytes},
                         $self->{numblocks},
                         '0:1'
                         ]
                        );

            $fileheader->{RealTie}->HPush($packstr);

            # block 0 is in use for fileheader
            my $freelist = '1:' . ($self->{numblocks}-1);
            
            $packstr = 
                PackRow(
                        [
                         'FreeExtents',
                         $freelist
                         ]
                        );

            # set the metadata for the free list index
            $flidx = $fileheader->{RealTie}->HPush($packstr);

            return undef
                unless (defined($flidx));

            my $stat = 
                $fileheader->{RealTie}->_update_meta_zero("FL", $flidx);

            return undef
                unless (defined($stat));

            # flush not necessary unless update block 

            return undef
                unless ($self->flush());
        }
        $self->{freelist_idx} = $flidx;

    }

    return $blessref;

} # end new

sub _file_info
{
    my $self = shift;
    my %args = @_;

    my @outarr;

    my $bc = $self->{bc};

    push @outarr, $bc->{realbcfileno};
    push @outarr, $self->{filename};
    push @outarr, $self->{numbytes};
    push @outarr, $self->{numblocks};

    if (exists($args{tablename})
        && exists($args{object_id}))
    { # add the latest extent information for the specified object
        my $tablename = $args{tablename};
        my $object_id = $args{object_id};

        my $spacelist = $self->UnPackSpaceList($tablename);
        if (_is_valid_spacelist($spacelist))
        {
            my ($currBlocknum, @currExtent) = _get_current_info($spacelist);  
            
            push @outarr, @currExtent
                if (scalar(@currExtent > 1));
        }
    }
    return @outarr;
}

sub PackSpaceList
{
    my ($self, $tablename, $object_id, $desc) = @_;

#    whoami;
#        local $Genezzo::Util::QUIETWHISPER = 0; # XXX: unquiet the whispering

    unless (defined($object_id))
    {
        use Carp; # XXX XXX XXX XXX

        croak "no object id for $tablename";

    }

    my $bc = $self->{bc};
    unless ($self->_tiefh($bc, 0))
    {
        whisper "bad fh tie";
        return (0);
    }
    my $fileheader = $bc->{fileheader};

    my $reftb = $fileheader->{RefTie};

    my @outarr;    

    my ($kk, $vv);

#    my $cnt = scalar(keys(%{$reftb}));
    while (($kk, $vv) = each (%{$reftb}))
#    while ($icount < scalar (@{$reftb}))
    {

        @outarr = UnPackRow($vv);

#        greet $kk, @outarr;
        my $rtyp = shift @outarr;
        unless ($rtyp =~ m/TABLE/)
        {
            @outarr = ();
            next;
        }
        last if ($outarr[0] eq $tablename); 
        
        @outarr = ();
    }

    if ((defined($object_id))
        && (scalar(@{$desc}))
        && ($desc->[0] =~ /TABLE/))
    {
        $desc->[0] = 'TABLE_' . $object_id;
    }

    my $packstr = 
        PackRow($desc);

    unless (scalar(@outarr))
#    if ($icount >= scalar (@{$reftb}))
    {
        
#        whisper "no match! push new row";
        
        my $stat = $fileheader->{RealTie}->HPush($packstr);

        unless ($stat)
        {
            whisper "out of space in block header!";
            return 0;
        }
#        push (@{$reftb}, $packstr);
        
        return 1;
    }

#    whisper "match!";

    $reftb->{$kk} = $packstr;

    return 1;

}

sub UnPackSpaceList
{
    # XXX: setting pluskey prepends hash key for table to outarr
    my ($self, $tablename, $pluskey) = @_;

#    whoami;

    my $bc = $self->{bc};
    unless ($self->_tiefh($bc, 0))
    {
        whisper "bad fh tie";
        return (0);
    }
    my $fileheader = $bc->{fileheader};
#    greet $bc;

    my $reftb = $fileheader->{RefTie};

    my @outarr;    

#    my $cnt = scalar(keys(%{$reftb}));
    my ($kk, $vv);
    while (($kk, $vv) = each (%{$reftb}))
#    while ($icount < scalar (@{$reftb}))
    {
        @outarr = UnPackRow($vv);
#        greet $kk, @outarr;
        my $rtyp = shift @outarr;
        unless ($rtyp =~ m/TABLE/)
        {
            @outarr = ();
            next;
        }
        if ($outarr[0] eq $tablename)
        {
            # prepend the key value if requested
            unshift (@outarr, $kk)
                if ($pluskey);
                    
            last ;
        }

        @outarr = ();
    }

    return undef unless (scalar(@outarr));
    return undef if (scalar(@outarr) < 2);

#    whisper "match!";

#    greet @outarr; 

    return \@outarr;
}

sub _tiefh
{
    my ($self, $bc, $blocknum) = @_;

#    whoami;

    my $fileheader = $bc->{fileheader};

    # XXX XXX:
    # NOTE: always in block zero for now 
#    my $blocknum = 0;

    $fileheader->{bceref} = 
        $self->{realbc}->ReadBlock(filenum  => $bc->{realbcfileno},
                                   blocknum => $blocknum);

    unless ( $fileheader->{bceref} )
    {
        whisper "failed to read block!";
        return (0);
    }

    my $bce = ${$fileheader->{bceref}};
#    greet $bce;

    # BCE to RDBlock - please respond
    my $mailbag = Genezzo::Util::AddMail(To => 'Genezzo::Block::RDBlock',
                                         From => $bce,
                                         Msg => 'RSVP');

    # build a separate tie for the file header
    my %filetiebufa;
    
    # tie array to buffer
    $fileheader->{RealTie} = 
        tie %filetiebufa, 'Genezzo::Row::RSBlock', 
        (refbufstr => $bce->{bigbuf}, 
         blocksize => $bce->{blocksize},
         blocknum  => $blocknum,
         MailBag   => $mailbag
         );
    
    $fileheader->{RefTie} = \%filetiebufa;

    return 1;
}

# XXX: note - not a class or instance method
sub _is_valid_spacelist
{
    my $spacelist = shift;

    return 0
        unless (defined($spacelist)
                && (scalar(@{$spacelist}) > 3));

    return 1;
}
# XXX: note - not a class or instance method
sub _get_current_info
{
    my $spacelist = shift;

    # NOTE: assume valid spacelist

    my ($currBlocknum, $freeBlocknum);

    if ($spacelist->[1] =~ m/\d+/)
    {
        # no free list
        $currBlocknum = $spacelist->[1];
    }
#    else
#    {
#        # have free list
#        my @foo =  split('F', $spacelist->[1]);
#        $currBlocknum = shift @foo;
#        $freeBlocknum = shift @foo;
#    }
        
    my @currExtent = split(':', $spacelist->[2]);

    return $currBlocknum, @currExtent;
}


sub SMGrowFile
{
    whoami;

    my $self = shift;
    my %required = (
                    filenumber => "no filenumber!",
                    blocksize  => "no blocksize!",
                    );

    my %optional = (
                    numblocks   => 0,
#                    pctincrease => 50
                    );

    my %args = (%optional,
                @_);

    my @newinfo;

    return undef
        unless (Validate(\%args, \%required));

    # get free extent info from fileheader
    my $bc = $self->{bc};
    my $freelist_idx = $self->{freelist_idx};

    unless ($self->_tiefh($bc, 0))
    {
        whisper "bad fh tie";
        return (undef);
    }
    my $fileheader = $bc->{fileheader};
    
    my $reftb = $fileheader->{RefTie};
    
#    greet $reftb;

    my @freelist = UnPackRow($reftb->{$freelist_idx});
            
    greet @freelist;
            
    shift @freelist;

    if ($args{numblocks})
    {
        # last blockno is current block total
        my $lastblockno = $self->{numblocks}; 
        my $numblocks   = $args{numblocks};

        # divide max file size/blocksize to get max block number
        my $maxblockno = $Genezzo::Util::MAXDBSIZE/$args{blocksize};

        # XXX: off by 1?
        if (($lastblockno + $numblocks) > $maxblockno)
        {
            $numblocks = $maxblockno - $lastblockno;
            return @newinfo
                unless ($numblocks > 0);
        }

        my ($startblockno, $new_numblocks) = 
            $self->{realbc}->BCGrowFile($args{filenumber}, $lastblockno,
                                        $numblocks);

        # Note: issue of multiple clients trying to grow same file in parallel

        greet "match!" if (($startblockno == $lastblockno)
                           && (defined($new_numblocks))
                           && ($new_numblocks == $numblocks));

        return @newinfo # make sure got something...
            unless (defined($new_numblocks) && ($new_numblocks > 0));

        $self->{numblocks} += $new_numblocks;
        $self->{numbytes}  += ($new_numblocks * $args{blocksize});

        my $free_ext = $startblockno . ':' . $new_numblocks;
        greet $free_ext;

        push @freelist, $free_ext;
        unshift (@freelist, 'FreeExtents');

        # XXX: fragile - need a STORE with a check to see if succeeds
        $reftb->{$freelist_idx} =
            PackRow(\@freelist);

        @newinfo = ($startblockno, $new_numblocks);
    }


    return @newinfo;
} # end SMGrowFile


sub make_new_extent
{
    return 0;
}

sub make_new_block
{
    my $self = shift;
    return $self->nextfreeblock(@_);
}

# get next free block from current extent, else allocate new extent...
sub nextfreeblock
{
#    whoami;
    my $self = shift;
    
    my %optional = (
                    extentsize  => 2, # 2 blocks
                    pctincrease => 0, # make next extent 0% larger, i.e
                                      # the same size as previous
                    all_info    => 0, # only return basic info

                    neednewextent => 0, # force new extent creation

                    mark_as_full => 0   # set current location to the end 
                                        # of the new extent (see SMExtent)
                    );

    my %required = (
                    tablename  => "no tablename !",
                    );

    my %args = (%optional,
		@_);

    return undef
        unless (Validate(\%args, \%required));

#    local $Genezzo::Util::QUIETWHISPER = 1; # XXX: quiet the whispering
    
    my $gotnewextent = 0; # true if get new extent
    my $firstextent  = 0; # true if first extent for object

    # get free extent info from fileheader
    my $bc = $self->{bc};
    my $freelist_idx = $self->{freelist_idx};

    unless ($self->_tiefh($bc, 0))
    {
        whisper "bad fh tie";
        return (undef);
    }
    my $fileheader = $bc->{fileheader};
    
    my $reftb = $fileheader->{RefTie};
    
#    greet $reftb;

    my $extsize = $args{extentsize};
    my $tablename = $args{tablename};
    my $object_id = $args{object_id};

    my ($currBlocknum, @currExtent, $endNewExtent );

    my $spacelist = $self->UnPackSpaceList($tablename);
#    greet "spacelist:", $spacelist;

    if (!(_is_valid_spacelist($spacelist)))
    {
        $firstextent = 1; # true if first extent for object
        $spacelist = [ $tablename ];
    }
    else
    {
        
        ($currBlocknum, @currExtent) = _get_current_info($spacelist);  

        if (scalar(@currExtent) < 2)
        {
            whisper "bad curr extent";
            return (undef);
        }

#        for my $i (3..(scalar(@{$spacelist})-1))
#        {
#            whisper "used extent $i : $spacelist->[$i]";
#        }

        if ($args{pctincrease})
        {
            use POSIX ; #  need some rounding

            # convert the pctincrease to a real multiplication factor,
            # e.g. pct=50 -> 1.5 to get 50% larger (which is really
            # 150% of the previous size)
            my $pctincrease = ($args{pctincrease}/100) + 1;

            # XXX XXX: this won't work if add freelist at end of extent list...
            my @LastExtent = split(':', $spacelist->[-1]);
            greet @LastExtent;
            my $lastsize = pop @LastExtent;

            # reset extent size to the calculated increased of the
            # last extent size
            $extsize = POSIX::floor($lastsize * $pctincrease);
            greet $extsize;
        }        

    }

    # don't exceed maximum extent
    $extsize = $Genezzo::Util::MAXEXTENTSIZE
        if ($extsize > $Genezzo::Util::MAXEXTENTSIZE);

    # XXX XXX XXX XXX: can just clear @currExtent to force new extent
    # allocation.  Maybe extend this to create multiple extents
    # simultaneously? Or never update the table entry in block zero,
    # which would treat each call to nextfreeblock as the first extent
    # creation (though this would break pctincrease, since no last
    # extent...)

    if ($args{neednewextent} > 0)
    {
        @currExtent = ();
    }

  L_bigloop:
    while (1)
    {
        # allocate an extent if necessary
        unless (scalar(@currExtent))
        {

            # current algorithm works if start with one large extent and
            # always allocate fixed size extents of same size [even
            # divisors of numblocks, though could add a round-up to fix
            # that].

            # pop off a free extent -- if has enough space subdivide it
            # and use $extsize for the currextent and return the rest.

            # if free extent is exact extsize don't have to return anything.

            # $$$ $$$ variable extsize requires a mechanism to search the
            # free extents for best fit.

            # $$$ note locking issues for multithreaded allocations --
            # contention over free extent

            my @freelist = UnPackRow($reftb->{$freelist_idx});
            
###         greet @freelist;
            
            shift @freelist;

            unless (scalar (@freelist))
            {
                whisper "failed to allocate extent - none left!! ";
                return undef;           
            }
            
            # $$$ $$$ make this work for list of free extents -- do
            # "best fit", etc
            
            my %bysize; # hash by size
            for (my $flidx = 0; $flidx < scalar(@freelist); $flidx++)
            {
                my @splitextent = ($freelist[$flidx] =~ m/(\w.*)\:(\w.*)/);

                unless (2 == scalar (@splitextent))
                {
                  Carp::croak("badly formed extent - $flidx!! ");
                    return undef;
                }
                
                # hash by size of indexes of freelist entries
                push (@{$bysize{$splitextent[1]}}, $flidx);
            }
            
            my $free_ext = ();
            if (exists($bysize{$extsize}))
            {
                whisper "exact match for extent of size $extsize";

                my $flidx = pop(@{$bysize{$extsize}});
                my @splitextent = ($freelist[$flidx] =~ m/(\w.*)\:(\w.*)/);
                $free_ext = \@splitextent;
                # remove this entry from free list
                splice(@freelist, $flidx, 1);
            }
            else # inexact match - look for best fit
            {
                # foreach key of free list extentsize...
              L_flx:
                foreach my $flxsize (sort {$a <=> $b}(keys(%bysize)))
                {
                    next if ($extsize > $flxsize);

                    my $flidx = pop(@{$bysize{$flxsize}});
                    my @splitextent = ($freelist[$flidx] =~ m/(\w.*)\:(\w.*)/);

                    # splitextent should always have 2 entries - we
                    # checked when bysize was loaded...
                    $free_ext = \@splitextent;
                    # return remainder (if any) of free extent to free list 
                    my $startblock = ($free_ext->[0] + $extsize);
                    my $sizeleft   = ($free_ext->[1] - $extsize);

                    # sizeleft is always nonzero
                    $freelist[$flidx] = 
                        ( $startblock . ':' . $sizeleft) ;

                    $free_ext->[1] = $extsize;
                    last L_flx;
                }
                unless (defined($free_ext)
                        && (scalar(@{$free_ext})))
                {
                    whisper "failed to allocate extent - insufficient space!! ";
                    return undef;
                }
            } # end look for best fit

            unless (defined($free_ext)
                    && (scalar (@{$free_ext})))
            {
                whisper "failed to allocate extent - none left!! ";
                return undef;
            }
            
            if ($free_ext->[1] < $extsize)
            {
                whisper "failed to allocate extent - insufficient space!! ";
                return undef;
            }

            # set the current block number to the first block of the
            # new extent
            $currBlocknum  = $currExtent[0] = $free_ext->[0];
            $currExtent[1] = $free_ext->[1];
            $endNewExtent  = $currBlocknum + $free_ext->[1] - 1;

            $gotnewextent = 1;

            unshift (@freelist, 'FreeExtents');

            # XXX: fragile - need a STORE with a check to see if succeeds
            $reftb->{$freelist_idx} =
                PackRow(\@freelist);

            return undef 
                unless ($self->flush());

            # we are done
            last L_bigloop;
        } # end allocate extent

        whisper "current block : $currBlocknum";

        if (($currExtent[1] + $currExtent[0]) > $currBlocknum + 1)
        {
            # still room in this extent
            $currBlocknum += 1;
            last L_bigloop;
        }
        else
        {

            whisper "need new extent";

            @currExtent = ();
            next L_bigloop;

        }
    } # end L_bigloop while(1)

    $spacelist->[1] = $currBlocknum;
    $spacelist->[2] = join (':', @currExtent);

    if ($gotnewextent && ($args{mark_as_full}))
    {
        # SMExtent: allocate a new extent, but mark it as full.
        # SMExtent does its own space-management, so it doesn't care,
        # and SMFile must not attempt to allocate blocks in
        # SMExtent-managed extents.
        $spacelist->[1] = $endNewExtent;
    }

    # extend the used extent list if got a new one
    push @{$spacelist}, $spacelist->[2]
        if ($gotnewextent);

    # XXX XXX: why not 'TABLE_' . $object_id ??  Because packspacelist
    # fixes this up for us...
    unshift @{$spacelist}, 'TABLE'; 

    return undef
        unless ($self->PackSpaceList($tablename, $object_id, $spacelist));

    my @outi;
    push @outi, $currBlocknum;
    push @outi, @currExtent  # new extent info
        if ($gotnewextent);
    
    if ($args{all_info})
    {
        # NOTE: for RSFile
        # return as hash vs simple array

        my %nargs = (
                     newextent       => $gotnewextent,
                     blocknum        => $currBlocknum,
                     firstextent     => $firstextent,
                     current_extent  => $currExtent[0],
                     extent_size     => $currExtent[1],
                     extent_position => ($currBlocknum - $currExtent[0])
                     );

        my $baz = 
            Genezzo::SpaceMan::SMFreeBlock->new(%nargs);

        return $baz;
    }

    return @outi;
}

sub get_current_block
{
    my $self = shift;
    return $self->currblock(@_);
}

sub currblock
{
    my $self = shift;

    my %required = (
                    tablename  => "no tablename !",
                    );

    my %args = (
		@_);

    return undef
        unless (Validate(\%args, \%required));

    my $tablename = $args{tablename};
    my $spacelist = $self->UnPackSpaceList($tablename);
#    greet $tablename, $spacelist;

    return (undef)
        unless (_is_valid_spacelist($spacelist));
 
    my ($currBlocknum, @currExtent) = _get_current_info($spacelist);       

    if (scalar(@currExtent) < 2)
    {
        whisper "bad curr extent";
        return (undef);
    }

    return ($currBlocknum);
}

sub firstblock
{
    my $self = shift;

    my %required = (
                    tablename  => "no tablename !",
                    );

    my %args = (
		@_);

    return undef
        unless (Validate(\%args, \%required));

    my $tablename = $args{tablename};
    my $spacelist = $self->UnPackSpaceList($tablename);
#    greet $spacelist;

    return (undef)
        unless (_is_valid_spacelist($spacelist));
        
    my ($currBlocknum, @currExtent) = _get_current_info($spacelist);       
        
    my @firstExtent = split(':', $spacelist->[3]);

    if (scalar(@firstExtent) < 2)
    {
        whisper "bad first extent";
        return (undef);
    }

    return ($firstExtent[0]);

}

sub nextblock
{
    my $self = shift;

    my %required = (
                    tablename  => "no tablename !", 
                    prevblock  => "no previous block !",
                   );

    my %args = (
		@_);

    return undef
        unless (Validate(\%args, \%required));

    my $tablename = $args{tablename};
    my $prevblock = $args{prevblock};
    my $spacelist = $self->UnPackSpaceList($tablename);
#    greet $spacelist;

    unless (defined($prevblock))
    {
        whisper "no previous block";
        return (undef);
    }

    return (undef)
        unless (_is_valid_spacelist($spacelist));

    my $currBlocknum = $spacelist->[1];        

    # XXX XXX XXX XXX XXX XXX XXX 
    # stop if we reached the current block (insertion point)
#    return undef
#        if ($prevblock == $currBlocknum);

    # shift off the current block info
    splice (@{$spacelist}, 0, 3);

#    greet @{$spacelist};

    my $getnext = 0; # true if next block is in next extent

    foreach my $xt (@{$spacelist})
    {
        my @nextExtent = split(':', $xt);

#        greet @nextExtent;

        if (scalar(@nextExtent) < 2)
        {
            return (undef);
        }

        return ($nextExtent[0])  # first block of this extent is next block
            if $getnext;         # if getnext was set

        # last block of this extent
        my $lastblock = ($nextExtent[0] + ($nextExtent[1] - 1)) ;
        # return the nextblock if it would still be in current extent
        if (($prevblock >= $nextExtent[0]) &&
            ($prevblock < $lastblock))
        {
            $prevblock++;
            return ($prevblock);
        }

        # if prevblock = last block of this extent, then next block is
        # first block of next extent, so set $getnext.  Works
        # correctly (returns undef) if no next extent

        $getnext = 1
            if ($prevblock == $lastblock)
    }
    return (undef);

}

# count of all blocks allocated for a table.  
# NOTE: Allocated block count is possibly greater than the current
# number of blocks in use -- it doesn't take into account deleted
# blocks.
sub countblock
{
#    whoami;
    my $self = shift;

    my %required = (
                    tablename  => "no tablename !", 
                   );

    my %args = (
		@_);

    return undef
        unless (Validate(\%args, \%required));

    my $tablename = $args{tablename};
    my $spacelist = $self->UnPackSpaceList($tablename);
#    greet $spacelist;

    return (undef)
        unless (_is_valid_spacelist($spacelist));

    my ($currBlocknum, @currExtent) = _get_current_info($spacelist);       

    # shift off the current block info
    splice (@{$spacelist}, 0, 3);

    my $total = 0;

    foreach my $xt (@{$spacelist})
    {
        my @nextExtent = split(':', $xt);

#        greet $xt, @nextExtent;

        if (scalar(@nextExtent) < 2)
        {
            return $total; # XXX XXX : ? what is this case? no extents?
        }

        if ($currExtent[0] == $nextExtent[0])
        {
            # get an accurate count of the number of blocks in use in
            # the current extent to try to give decent estimates if
            # have a single enormous extent
            $total += 1 + ($currBlocknum - $currExtent[0]);
        }
        else
        {
            # assume entire extent is in use.  
            # XXX XXX: Could have metadata in the extent header to
            # provide more accurate usage statistics
            $total += $nextExtent[1] ;
        }
    }

    return $total;
} # countblock

sub hasblock
{
    my $self = shift;

    my %required = (
                    tablename  => "no tablename !", 
                    blocknum   => "no block number !",
                   );

    my %args = (
		@_);

    return undef
        unless (Validate(\%args, \%required));

    my $tablename = $args{tablename};
    my $blocknum  = $args{blocknum};
    my $spacelist = $self->UnPackSpaceList($tablename);
#    greet $spacelist;

    return 0
        unless (_is_valid_spacelist($spacelist));

    # shift off the current block info
    splice (@{$spacelist}, 0, 3);

    foreach my $xt (@{$spacelist})
    {
        my @nextExtent = split(':', $xt);

#        greet @nextExtent;

        if (scalar(@nextExtent) < 2)
        {
            return (0);
        }
        # last block of this extent
        my $lastblock = ($nextExtent[0] + ($nextExtent[1] - 1)) ;

        # return 1 if block in current extent
        if (($blocknum >= $nextExtent[0]) &&
            ($blocknum <= $lastblock))
        {
            return (1);
        }
    }
    return 0;
}

sub freetable # drop table/drop index/destroy any object
{
    my $self = shift;

    my %required = (
                    tablename  => "no tablename !",
                    );

    my %args = (
		@_);

    return undef
        unless (Validate(\%args, \%required));

    my $tablename = $args{tablename};
    # XXX: unpack the space list with the key prepended
    my $spacelist = $self->UnPackSpaceList($tablename, 1);
#    greet $spacelist;

    unless (defined($spacelist))
    {
        return (undef);
    }

    my $tablekey = shift @{$spacelist};
    my $bc = $self->{bc};
    my $freelist_idx = $self->{freelist_idx};

    unless ($self->_tiefh($bc, 0))
    {
        whisper "bad fh tie";
        return (undef);
    }
    my $fileheader = $bc->{fileheader};
    
    my $reftb = $fileheader->{RefTie};

    # blow the table out of the main list
    delete $reftb->{$tablekey};

    return (0) 
        unless $self->flush();

    # check for valid table data
    return 1
        unless (_is_valid_spacelist($spacelist));
        
    # shift off the current block info
    splice (@{$spacelist}, 0, 3);

#    greet @{$spacelist};

    my @freelist = UnPackRow($reftb->{$freelist_idx});
            
    unless (scalar (@freelist))
    {
        return (0);
    }

    # return the space used
    push @freelist, @{$spacelist};

    # XXX: fragile - need a STORE with a check to see if succeeds
    $reftb->{$freelist_idx} =
        PackRow(\@freelist);
    
    return ($self->flush());
}

sub flush
{
    my $self = shift;

    return 1
        if ($self->{read_only});

    my $bc = $self->{bc};

    # XXX XXX: need to support flush of all blocks associated with
    # space management if stored in more places than block zero.

    # NOTE: always in block zero for now
    my $blocknum = 0;

    unless (
            $self->{realbc}->WriteBlock(filenum  => $bc->{realbcfileno},
                                        blocknum => $blocknum))
    {
        whisper "failed to write block!";
        return (0);
    }
    return 1;
}

sub dump
{
    my $self = shift;
    my $bc = $self->{bc};
    unless ($self->_tiefh($bc, 0))
    {
        whisper "bad fh tie";
        return (undef);
    }
    my $fileheader = $bc->{fileheader};
    
    my $reftb = $fileheader->{RefTie};

    my ($kk, $vv);

#    my $cnt = scalar(keys(%{$reftb}));
    while (($kk, $vv) = each (%{$reftb}))
    {
        my @outarr = UnPackRow($vv);

        print join(" ",@outarr), "\n";
    }
}

# if switching from SMFile to SMExtent, mark all current extents for
# all tables as full.  This fixup prevents problems with SMFile if we
# switch back.
sub _extent_fixup_mark_full
{
    my $self = shift;

#    whoami;

    my $bc = $self->{bc};
    unless ($self->_tiefh($bc, 0))
    {
        whisper "bad fh tie";
        return (0);
    }
    my $fileheader = $bc->{fileheader};
#    greet $bc;

    my $reftb = $fileheader->{RefTie};

    my @keylist = keys (%{$reftb});

    for my $kk (@keylist)
    {
        my $vv = $reftb->{$kk};

        my @outarr = UnPackRow($vv);
#        greet $kk, @outarr;
        my $rtyp = $outarr[0];

        unless ($rtyp =~ m/TABLE/)
        {
            @outarr = ();
            next;
        }
        
        # 0 - object type
        # 1 - object name
        # 2 - current blockno
        # 3 - start of current extent, extent size

        my $currblockno = $outarr[2];

        my @foo = split(':', $outarr[3]);

        my $endextent = $foo[0] + $foo[1] - 1;

        if ($endextent != $currblockno)
        {
            $outarr[2] = $endextent;

            $reftb->{$kk} = PackRow(\@outarr);
        }

        @outarr = ();
    }

    return 0
        unless ($self->flush());

    return 1;
}



END {

}


1;  # don't forget to return a true value from the file

__END__

=head1 NAME

Genezzo::SpaceMan::SMFile.pm - File Space Management

=head1 SYNOPSIS


=head1 DESCRIPTION

Maintain a block header for each file with information on space usage.
Each file is composed of *extents*, groups of contiguous blocks.  The
free extent list is composed of a number of blocknumber/extent length
pairs, e.g. the row:

  FreeExtents 39:12 19:2  

indicates that the current file has free space starting at block 39 of
12 contiguous blocks, plus space of 2 contiguous block starting at
block 19.

When an object requests space, SMFile tries to find an exact match in
the free list.  If it cannot, it carves the requested size from a
larger free extent.

=head1 FUNCTIONS

=over 4

=item currblock

return the current active block (insert high water mark) for an object

=item firstblock, nextblock

iterate over the set of *used* blocks for an object.  Ignores unused
blocks in last extent

=item countblock

count of all blocks associated with the object.  Includes allocated,
*unused* blocks, plus empty blocks (i.e. blocks with no rows).

=item hasblock 

check if block is associated with an object

=item freetable 

return all of an object's blocks to the freelist

=item flush 

write the contents of block zero to disk.  Need to handle case of
extent lists spread over multiple blocks.


=back


=head2 EXPORT

=head1 TODO

=over 4

=item  read_only database support

=item  support for non-table objects like indexes - done? 

=item  freetable: when last object is freed, need to update _tsfiles as
       UNUSED

=item  need to coalesce adjacent free extents

=item  maintain multiple free lists for performance

=item  better indexing scheme - maybe a btree

=item  chain the block header if necessary -- allocate a new block to
       hold additional free list information, append extent allocation
       to HEADER row (after 0:1)

=item  check status everywhere where update rows 

=item  maintain free extents list for each object, so can re-use
       extents (especially important for updates of large multi-block rows)

=back



=head1 AUTHOR

Jeffrey I. Cohen, jcohen@genezzo.com

=head1 SEE ALSO

perl(1).

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
