#!/usr/bin/perl
#
# $Header: /Users/claude/fuzz/lib/Genezzo/SpaceMan/RCS/SMExtent.pm,v 1.42 2007/07/28 07:48:40 claude Exp claude $
#
# copyright (c) 2006, 2007 Jeffrey I Cohen, all rights reserved, worldwide
#
#
package Genezzo::SpaceMan::SMExtent;

use strict;
use warnings;

use Carp;
use Genezzo::Util;
use Genezzo::Row::RSBlock;
use Genezzo::SpaceMan::SMFile;

BEGIN {
    use Exporter   ();
    our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

    # set the version for version checking
#    $VERSION     = 1.00;
    # if using RCS/CVS, this may be preferred
    $VERSION = do { my @r = (q$Revision: 1.42 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r }; # must be all one line, for MakeMaker

    @ISA         = qw(Exporter);
    @EXPORT      = ( ); # qw(&NumVal);
    %EXPORT_TAGS = ( );     # eg: TAG => [ qw!name1 name2! ],

    # your exported package globals go here,
    # as well as any optionally exported functions
#    @EXPORT_OK   = qw($Var1 %Hashit &func3 &func5);
    @EXPORT_OK   = (); 

}

our $GZERR = sub {
    my %args = (@_);

    return 
        unless (exists($args{msg}));

    if (exists($args{severity}))
    {
        my $sev = uc($args{severity});
        return if ($sev eq 'IGNORE');
    }

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


our $SMX_SEV = 'IGNORE';
#our $SMX_SEV = 'WARN';

sub _init
{
    #whoami;
    #greet @_;
    my $self      =  shift;
    my %required  =  (
                      filename   => "no filename !",
                      numbytes   => "no numbytes !",
                      numblocks  => "no numblocks !",
                      bufcache   => "no bufcache !",
                      filenumber => "no filenumber !",
                      tablename  => "no tablename !",
                      object_id  => "no object id !",
                      object_type => "no object type"
                      );
    
    my %args = (@_);

    return undef
        unless (Validate(\%args, \%required));

    $self->{filename} = $args{filename}; # save for error reporting
    $self->{object_type} = $args{object_type}; # use type to determine
                                               # storage allocation

    my $smf = Genezzo::SpaceMan::SMFile->new($args{filename},
                                             $args{numbytes},
                                             $args{numblocks},
                                             $args{bufcache},
                                             $args{filenumber});

    return undef
        unless (defined($smf));

    $self->{smf} = $smf;

    my %nargs   = (tablename  => $args{tablename},
                   object_id  => $args{object_id}
                   );
    
    my $blockno = $self->{smf}->firstblock(%nargs);

    if (defined($blockno))
    {
        $self->{first_seghdr}   = $blockno;
        $self->{current_seghdr} = $blockno;

        # need to call this way because SELF isn't BLESSed yet...
        my $rowd = _get_rowd($self, $blockno);
        unless (defined($rowd))
        {
            return (undef);
        }

        # get meta data for the segment header
        my $row  = $rowd->_get_meta_row("X1A");

        # if the current hdr is full...
        while (defined($row) && (scalar(@{$row}) > 0)
               && ($row->[0] =~ m/F/))
        {
            # overflow header is listed in x1b
            my $row2 = $rowd->_get_meta_row("X1B");

            # XXX XXX: need some error checking here...
            last
                unless (defined($row2) && (scalar(@{$row2} > 2)));

            my $nexthdr = $row2->[-1]; # check the end of the array

            my @ggg = $self->_split_extent_descriptor($nexthdr);

            last 
                unless (scalar(@ggg) > 1);

            # advance to the next header...
            $blockno = $ggg[0];
            $self->{current_seghdr} = $blockno;

# XXX XXX            print "advance to next header, block $blockno\n";

            $rowd = _get_rowd($self, $blockno);
            unless (defined($rowd))
            {
                return (undef);
            }

            # get meta data for the segment header
            $row  = $rowd->_get_meta_row("X1A");

        } # end while
        

##        print Data::Dumper->Dump([$row]), "\n";
 
        # need to call this way because SELF isn't BLESSed yet...       
        $rowd = _get_rowd($self, 0);
        unless (defined($rowd))
        {
            return (undef);
        }
    }

    return 1;

}

sub new 
{
    my $invocant = shift;
    my $class = ref($invocant) || $invocant ; 
    my $self = { };
    
#    whoami @_;
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

    my $blessref = bless $self, $class;

    return $blessref;

} # end new

sub _get_rowd # private
{
    my ($self, $blockno) = @_;

    $blockno = 0
        unless (defined($blockno));

    my $bc = $self->{smf}->{bc};

    unless ($self->{smf}->_tiefh($bc, $blockno))
    {
        whisper "bad fh tie";
        my $fn = $self->{filename};
        my $msg = "bad fh tie for block $blockno, file $fn\n";
        my %earg = (self => $self, msg => $msg,
                    severity => 'warn');
        
        &$GZERR(%earg)
            if (defined($GZERR));

        return (undef);
    }
    my $fileheader = $bc->{fileheader};
    
    my $rowd = $fileheader->{RealTie};

    unless (defined($rowd))
    {
        whisper "bad fh real tie";
        my $msg = "bad fh real tie\n";
        my %earg = (self => $self, msg => $msg,
                    severity => 'warn');
        
        &$GZERR(%earg)
            if (defined($GZERR));

    }
    return $rowd;
}

# for Tablespace::TSGrowFile
sub _file_info
{
    my $self = shift;
    return $self->{smf}->_file_info(@_);
}

# for Tablespace::TSGrowFile
sub SMGrowFile
{
    my $self = shift;
    return $self->{smf}->SMGrowFile(@_);
}

# truncate a number to a certain length, or pad with leading zeros
# Assumes $num is non-negative
sub _trunc_or_pad
{
    use POSIX ; #  need some rounding

    my ($num, $padlen) = @_;

    # Note: outi must be an integer -- round down
    my $outi = POSIX::floor($num);

    if ($padlen == 2)
    {
        # common case
        $outi = 99
            if ($outi > 99);
    }
    else
    {
        # XXX XXX: need to test this...
        $outi = (("9"x$padlen) + 0)
            if ($outi > (10**$padlen));
    }
    $outi = 0
        if ($outi < 1);

    # kind of redundant...
    $outi = substr($num, 0, $padlen)
        if (length($num) > $padlen);

    if (length($outi) < $padlen)
    {
        if ($padlen == 2)
        {
            # common case
            $outi = "0".$outi;
        }
        else
        {
            # XXX XXX: need to test this...
            my $plen = $padlen - length($outi);
            $outi = ("0"x$plen).$outi
        }
    }
    return $outi;
}

sub _make_extent_descriptor
{
    my ($self, $blockno, $extent_size, $total_pctused, 
        $alloc_pctused, $num_free) = @_;

    $total_pctused = 0 unless (defined($total_pctused));

    $total_pctused = _trunc_or_pad($total_pctused, 2);

    $alloc_pctused = $total_pctused unless (defined($alloc_pctused));
    $alloc_pctused = _trunc_or_pad($alloc_pctused, 2);

    $num_free = $extent_size unless (defined($num_free));
    my $free_len = 0; # set to zero for zero free
    $free_len = length($num_free)  # number of digits
        if ($num_free > 0);
    $free_len = 9 if ($free_len > 9);

    return join(':', $blockno, $extent_size, $total_pctused,
                $alloc_pctused, $free_len
                );
}

sub _split_extent_descriptor
{
    my ($self, $extent_desc_str) = @_;

    return split(':', $extent_desc_str);
}

sub _dump_extent_descriptor
{
    my $xdsc = shift @_;
    my $outi;

    my @ggg = _split_extent_descriptor("fakeself", $xdsc);

    unless (scalar(@ggg) > 4)
    {
        $outi = 'invalid descriptor: $xdsc\n';
        return $outi;
    }

    my ($ext_hdr_block, $extent_size, $total_pctused,
        $alloc_pctused, $free_len) = @ggg;

    $outi .= "starts: block number $ext_hdr_block, length: $extent_size\n";
    $outi .= "$total_pctused % of total used, $alloc_pctused % of allocated blocks used\n";
    if (0 == $free_len)
    {
        $outi .= "0 free blocks \n";
    }
    else 
    {
        my $freeb = "0" x $free_len;

        $outi .= "less than 1" . $freeb . " free blocks\n";
    }
    return $outi;
}
sub _meta_row_dump_X1A
{
    my ($self, $v1) =  @_;

    my @val = @{$v1};
    my $vfflag = shift @val;

    my $outi;
    $outi .= "X1A (eXtent FIRST _A_):\nExtent Header: ";
    $outi .= (($vfflag =~ m/v/i) ? '[V]acant ' : '[F]ull ');

    $outi .= "\n";
 
    for my $xd (@val)
    {
        $outi .= _dump_extent_descriptor($xd);
    }

    $outi .= "\n";

    return $outi;

}
sub _meta_row_dump_X1B
{
    my ($self, $v1) =  @_;

    my @val = @{$v1};

    my $first_seghdr = shift @val;
    my $prev         = shift @val;

    my $outi;
    $outi .= "X1B (eXtent FIRST _B_):\n";
    $outi .= "First seghdr at $first_seghdr, previous header at block $prev\n";

    if (scalar(@val))
    {
        $outi .= "Next at:\n";
    }


    for my $xd (@val)
    {
        $outi .= _dump_extent_descriptor($xd);
    }

    return $outi;
}
sub _meta_row_dump_XHA
{
    my ($self, $v1) =  @_;

    my @val = @{$v1};

    my $seghdr = shift @val;
    my $extsiz = shift @val;
    my $bvec   = shift @val;

    my $outi = "XHA (eXtent Header _A_):\n";
    $outi .=
     "Segment header at block $seghdr,\n current extent size $extsiz blocks\n";
    my $bvstr = unpack("b*",$bvec);
    $outi .= "bitvec: $bvstr\n";

    my @pct = $self->_xhdr_bv_to_pct($bvec, $extsiz);
    my $extent_stats  = shift @pct;

    $outi .= "block usage:\n";
    $outi .= join('% ', @pct) . "% \n";
    return $outi;

}
sub _meta_row_dump_XHP
{
    my ($self, $v1) =  @_;

    my @val = @{$v1};

    my $offset = shift @val;
    my $pctused = shift @val;

    $pctused = $pctused * 10;

    my $outi = "XHP (eXtent Header Position):\n" .
        "basic block info - offset: $offset, $pctused" . "% used\n";

    return $outi;
}


sub _create_segment_hdr
{
    my ($self, $rowd, $blockno, $extent_size, $parent, $first_seghdr) = @_;

    return undef
        unless (defined($rowd));

    # X1A (eXtent FIRST _A_):
    #   1 at start of segment (segment header/first extent), and 1 for
    #   each overflow block of the segment header.  The segment header
    #   starts as the first block of the first extent, and each
    #   overflow block is a "subheader".
    #
    #   contains vacant/full flag, which indicates whether this piece
    #   of the segment header has the maximum number of extent listings,
    #   followed by a list of extent descriptors.

    $rowd->_set_meta_row("X1A", 
                         [
                          "V", # [V]acant, vs [F]ull
                          $self->_make_extent_descriptor(
                                                         $blockno, 
                                                         $extent_size, 
                                                         '0.0')
                          ]
                         );

    unless (defined($parent))
    {
        # should only be for very first allocated extent
        $self->{first_seghdr}   = $blockno;
        $self->{current_seghdr} = $blockno;
        $parent                 = $blockno;
        $first_seghdr           = $blockno;
    }

    # X1B (eXtent FIRST _B_):
    #   1 at start of segment (segment header/first extent), and 1 for
    #   each overflow block of the segment header.
    #
    #   Initially, just has the block number for the first segment
    #   header and the previous segment header (which is just the
    #   current blockno if this block is the very first).  However,
    #   once the first extent is allocated for this piece of the
    #   segment header, then this extent is designated as the segment
    #   header overflow block, and the extent descriptor is appended
    #   to the X1B row.
    #
    #   Note that the extent descriptor should describe the overall
    #   status of all the extents managed beneath the overflow block,
    #   not just the first extent in that block.

    # no "next" segment header, just list parent piece of seg hdr
    $rowd->_set_meta_row("X1B", [
                                 $first_seghdr,
                                 $parent]);

    return $rowd;
} # end _create_segment_hdr

sub _add_extent_to_segment_hdr
{
    my ($self, $blockno, $extent_size) = @_;

#    whisper "update seg hdr\n";

    my ($row, $row2, $rowd, $val);

  L_bigW:
    while (1)
    {
        $rowd = $self->_get_rowd($self->{current_seghdr});
        unless (defined($rowd))
        {
            return (undef);
        }
        # get meta data for the segment header
        $row2 = $rowd->_get_meta_row("X1B");

        # if current segment header does not have a child for overflow,
        # then the new extent is allocated for that purpose
        if (defined($row2) && (scalar(@{$row2}) < 3)) 
        {
            # X1B (eXtent FIRST _B_):
            #
            # add the extent descriptor for the overflow block.
            #
            # Note that the "extent_size" in this descriptor can vary,
            # since it's an approximation of the total space allocated
            # under the subheader.  However, we can keep the length of
            # the extent_size approximation a constant 4 characters
            # using standard space suffixes, eg: 100K, 1.2M, .99G
            push @{$row2}, $self->_make_extent_descriptor($blockno, 
                                                          $extent_size, 
                                                          '0.0');

            $rowd->_set_meta_row("X1B", $row2);

            $rowd = $self->_get_rowd($blockno);
            unless (defined($rowd))
            {
                return (undef);
            }
            
            my $parent       = $self->{current_seghdr};
            my $first_seghdr = $self->{first_seghdr};

            # create the new segment subheader in the new extent
            $self->_create_segment_hdr($rowd, 
                                       $blockno, $extent_size, 
                                       $parent,
                                       $first_seghdr);

            $rowd = $self->_get_rowd($self->{current_seghdr});
            unless (defined($rowd))
            {
                return (undef);
            }
        } # end if make overflow

        $row = $rowd->_get_meta_row("X1A");

        unless (defined($row))
        {
            croak "serious error 4!";
            exit;
        }

        my $new_ext = $self->_make_extent_descriptor($blockno,
                                                     $extent_size, 
                                                     '0.0');

        push @{$row}, $new_ext;


# XXX XXX XXX: overflow test? but how to check?
        if (0 && scalar(@{$row}) > 4)
        {
#            print "overflow to next header\n";
            $val = undef;
        }
        else
        {

            $val = $rowd->_set_meta_row("X1A", $row);
        }
        
        ########################################
        #  end here if set meta row correctly  #
        ########################################
        last L_bigW
            if (defined($val));

        # else we set the current header as full, and use the next
        pop @{$row};
        $row->[0] = 'F' ; # row is full
        $val = $rowd->_set_meta_row("X1A", $row);
        unless (defined($val))
        {
            # should have been able to just update status flag
            croak "serious error 1!";
            exit;
        }
        
        # find the overflow header
        $row2 = $rowd->_get_meta_row("X1B");
        unless (defined($row2) && (scalar(@{$row2} > 2)))
        {
            croak "serious error 2!";
            exit;
        }

        my $nexthdr = $row2->[-1]; # check the end of the array

        my @ggg = $self->_split_extent_descriptor($nexthdr);

        unless (scalar(@ggg) > 1)
        {
            croak "serious error 3!";
            exit;
        }
        
        # find the blockno of the overflow header, and make it current
##        $parent = $self->{current_seghdr};
        $self->{current_seghdr} = $ggg[0];
        # try again...
    } # end while
    
    return $rowd;
} # end _add_extent_to_segment_hdr

sub _update_extent_in_segment_hdr
{
    my ($self, $rowd, $ext_hdr_block, $extent_desc) = @_;

    my $row = $rowd->_get_meta_row("X1A");

    unless (defined($row))
    {
        croak "serious error 4!";
        exit;
    }

    my $maxi = scalar(@{$row});

    return undef
        unless ($maxi);
    # zero based
    $maxi--;

    for my $ii (0..$maxi)
    {
        my $xdsc = $row->[$ii];
#        print $xdsc, "\n";
        my @ggg = $self->_split_extent_descriptor($xdsc);
        next
            unless (scalar(@ggg) > 4);
        my ($curr_ext_hdr_block, $extent_size, $total_pctused,
            $alloc_pctused, $free_len) = @ggg;

        # update if they are different
        if ($ext_hdr_block == $curr_ext_hdr_block)
        {
            if ($xdsc eq $extent_desc)
            {
#                print "xdsc match - no update: $xdsc\n";
            }
            else
            {
                $row->[$ii] = $extent_desc;
                return $rowd->_set_meta_row("X1A", $row); 
            }
            last;
        }
    }
    return undef;
} # end _update_extent_in_segment_hdr

sub _create_extent_hdr
{
    my ($self, $rowd, $extent_size, $seghdr) = @_;

    return undef
        unless (defined($rowd));

    # XXX XXX: need enforcement of max extent size

    my $numbits = Genezzo::Util::PackBits(2 * $extent_size);
    my $nullstr = pack("B*", "0"x$numbits);

    # XHA (eXtent Header _A_): 
    #   1 per extent.
    #   contains the segment header, extent size and usage bitvec.
    #
    # XHP (eXtent Header Position): 
    #   1 per block (including 0th block of extent).
    #   contains the offset of the block in the extent,
    #   and the percent used in 10% increments (eg 1 is 10%, 9 is 90%)

    $rowd->_set_meta_row("XHA", [$seghdr, $extent_size, $nullstr]);
    # extent position is zero (1st block in extent), initial %used is zero 
    $rowd->_set_meta_row("XHP", [0, 0]);

    return $rowd;
} # end _create_extent_hdr

sub _update_extent_hdr
{
    my ($self, $rowd, $posn, $pct_used) = @_;

    return undef
        unless (defined($rowd));

    # get meta data for the segment header
    my $row = $rowd->_get_meta_row("XHA");

    if (! (defined($row) && scalar(@{$row})))
    {
        my $msg = "bad extent header\n";
        my %earg = (self => $self, msg => $msg,
                    severity => 'warn');
        
        &$GZERR(%earg)
            if (defined($GZERR));

        return undef;
    }

    my ($seghdr, $extent_size, $bvec) = @{$row};

#    whisper "size, bv: $extent_size," , unpack("b*",$bvec), "\n";

    my ($bit1, $bit2) = (0, 0 ); # empty

    if ($pct_used >= 90)
    {
        ($bit1, $bit2) = (1,1 ); # full
    }
    elsif ($pct_used >= 60)
    {
        ($bit1, $bit2) = (1,0 );
    }
    elsif ($pct_used >= 30)
    {
        ($bit1, $bit2) = (0,1 );
    }

    my @pct = $self->_xhdr_bv_to_pct($bvec, $extent_size);
    my $extent_stats  = shift @pct;
    my $avgpct        = $extent_stats->{avgpct};
    my $prev_numempty = $extent_stats->{numempty};
    my $allocpct      = $extent_stats->{allocpct};

    # use 2 bits per posn -- 00 is empty , 11 is full
    vec($bvec, (2*$posn),   1) = $bit1;
    vec($bvec, (2*$posn)+1, 1) = $bit2;
    whisper "size, bv: $extent_size," , unpack("b*",$bvec), "\n";

    @pct = $self->_xhdr_bv_to_pct($bvec, $extent_size);
    $extent_stats     = shift @pct;
    $avgpct           = $extent_stats->{avgpct};
    my $curr_numempty = $extent_stats->{numempty};

    # update
    $rowd->_set_meta_row("XHA", [$seghdr, $extent_size, $bvec]);

    # if this update causes the extent to transition from full to
    # partially-empty, need to return a status so we can update the
    # segment header

    my @outi;

    push @outi, $rowd;

    if ((0 == $prev_numempty) && (0 != $curr_numempty))
    {
# XXX XXX XXX XXX
#        print "Emptied a block!!\n";
        @outi = ($rowd, $seghdr, $extent_size, $bvec);
#        return @outi;
    }
    return @outi;
    
} # end _update_extent_hdr

# convert a bitvec to an array of percentages
sub _xhdr_bv_to_pct
{
    my ($self, $bvec, $extent_size) = @_;

    my $bvstr = unpack("b*",$bvec);

    my @bvfull = split(/ */, $bvstr);

    my $bit1;
    my @pct;
    my $totpct   = 0;
    my $numempty = 0;

    # construct an array of percent usage for each block in the extent
    for my $bitty (@bvfull)
    {
        if (!defined($bit1))
        {
            $bit1 = $bitty;
            next;
        }

        my $bit2 = $bitty;
        
        my $blockpct;

        if (0 == $bit1)
        {
            # b01 = d30, b00 = d0
            $blockpct = ($bit2 ? 30: 0);
        }
        else
        {
            # b11 = d90, b10 = d60
            $blockpct = ($bit2 ? 90: 60);
        }
        $numempty++ unless ($blockpct);
        $totpct += $blockpct;
        push @pct, $blockpct;

        $bit1 = undef;
        $extent_size--;
        last unless ($extent_size);

    } # end for
    
    # prefix the array of pct usage with avg usage and number of empty blocks
    if (scalar(@pct))
    {
        $extent_size = scalar(@pct);
        my %extent_stats;

        # prefix array of percentages with avg pct used
        my $avgpct   = $totpct/$extent_size;
        my $allocpct = $avgpct;

        if ($numempty && ($numempty < $extent_size))
        {
            $allocpct = 
                $totpct/($extent_size-$numempty);
            $allocpct = 90 
                if ($allocpct > 90);
        }

        $extent_stats{allocpct} = $allocpct;
        $extent_stats{avgpct}   = $avgpct;
        # track the number of empty blocks in an extent
        $extent_stats{numempty} = $numempty;
        unshift @pct, \%extent_stats;
    }

    return @pct;
} # end  _xhdr_bv_to_pct


sub _find_extent_hdr
{
    whoami;

#    print "find extent header \n";
    
    my ($self, $blockno) = @_;

#    whisper "update seg hdr\n";

    my $rowd = $self->_get_rowd($blockno);
    unless (defined($rowd))
    {
        return (undef);
    }
    # get meta data for the position
    my $row = $rowd->_get_meta_row("XHP");

    unless (defined($row))
    {
        my $msg = "no position!\n";
        my %earg = (self => $self, msg => $msg,
                    severity => 'warn');
        
        &$GZERR(%earg)
            if (defined($GZERR));

        return undef;
    }
    my $posn        = $row->[0];
    my $curr_extent = $blockno - $posn;

    whisper "curr ext: $curr_extent, pos: $posn \n";

    return ($curr_extent, $posn);
}

sub _extent_get_free_block
{
    my $self = shift;

    my %required = (
                    start_of_extent => "no start for extent",
                    extent_size => "no extent size",
                    current_position => "no extent position"
                    );

    # ignore blocks less than some percentage free
    my %optional = (
                    pctfree => 10
                    );
    my %args = (
                %optional,
		@_);

#    greet (%args);

    return undef
        unless (Validate(\%args, \%required));

    # curr_extent is the block number of the start of the current extent
    my $current_extent  = $args{start_of_extent};
    my $extent_size     = $args{extent_size};
    my $extent_position = $args{current_position};
    my $pctfree = $args{pctfree};

    my $blockinfo;

    # XHA
    my $rowd = $self->_get_rowd($current_extent);        
    unless (defined($rowd))
    {
        return (undef); # XXX XXX: should be one...
    }
     
    my $row = $rowd->_get_meta_row("XHA");

    unless (defined($row) && (scalar(@{$row}) > 1))
    {
#        print "bad XHA row for $blockno \n";
        return (undef);
    }

    my ($seghdr, $extsz, $bvec) = @{$row};

    my @pct = $self->_xhdr_bv_to_pct($bvec, $extent_size);
    my $extent_stats     = shift @pct;
    my $avgpct           = $extent_stats->{avgpct};
    my $curr_numempty    = $extent_stats->{numempty};

    for my $posn (0..(scalar(@pct)-1))
    {
        next
            if ($posn == $extent_position);
            
        # less than 50% used...
        next
            if ($pct[$posn] >= $pctfree);

        my $blockno = $current_extent+$posn;
#        print "try block $blockno\n";
#        print "only ",$pct[$posn],"\% used\n";

        $rowd = $self->_get_rowd($blockno);        

        unless (defined($rowd))
        {
            return (undef); # XXX XXX: should be one...
        }

        $row = $rowd->_get_meta_row("XHP");
            
        unless (defined($row) && (scalar(@{$row}) > 1))
        {
#        print "bad XHP row for $blockno \n";

            # set meta data for the extent header (position,
            # initial %used is zero)

            $rowd->_set_meta_row("XHP", [$posn, 0]);

            $row = [$posn, 0];
#                return (undef);
        }

        my ($posn2, $pctused) = @{$row};

        unless ($pctused < $pctfree)
        {
            # make sure enough space is free
            next;
        }

        my %nargs = (
                     blocknum        => $blockno,
#                  firstextent     => $firstextent,
                     current_extent  => $self->{curr_extent},
                     extent_size     => $self->{extent_size},
                     extent_position => $posn
                     );

        $blockinfo =
            Genezzo::SpaceMan::SMFreeBlock->new(%nargs);

# XXX XXX XXX        print "extent:\n",Data::Dumper->Dump([$blockinfo]), "\n";

# XXX XXX $self->{extent_posn} = $posn;
        last;
    } # end for
    
    return $blockinfo;

} # end _extent_get_free_block

sub nextfreeblock
{
    # this routine for finding free blocks in allocated extents

    # First, check curr_extent -- if have space there use it.
    # If current extent is full, pop back to segment header.
    # Check for free extents in segment header.  If have one, set it
    # as current and use it.
    # If no space available in the segment header, call SMFile and ask
    # for more space.

    my $self = shift;

    my %freeblockargs = @_;

    # XXX XXX: should maintain space information for all objects, but
    # only re-use space for standard tables.
   if (!exists($self->{object_type})
       || ($self->{object_type} ne 'TABLE'))
    {
        goto  L_nospacefound;
    }

    if (defined(&smextent_usehooks))
    {
        my $msg = "smx: use hooks\n";
        my %earg = (self => $self, msg => $msg,
                    severity => $SMX_SEV);
        
        &$GZERR(%earg)
            if (defined($GZERR));

        # if we are using smextent and need a new extent from smfile,
        # then mark it as full.
        $freeblockargs{mark_as_full} = 1;
    }
    else
    {
        my $msg = "smx: no hooks\n";
        my %earg = (self => $self, msg => $msg,
                    severity => $SMX_SEV);
        
        &$GZERR(%earg)
            if (defined($GZERR));

        goto  L_nospacefound;
    }

    # if no space in current extent, then perform housekeeping on the
    # segment subheader, and check it for free space.

    # XXX XXX: check current extent first, then current seghdr...

    if (exists($self->{curr_extent}) &&
        exists($self->{extent_size}) &&
        exists($self->{extent_posn}))
    {
        my $blockinfo = 
            $self->_extent_get_free_block(
                                          start_of_extent => 
                                          $self->{curr_extent},
                                          extent_size => $self->{extent_size},
                                          current_position => 
                                          $self->{extent_posn});

        # use the free block from this extent if it exists...
        if (defined($blockinfo))
        {
            # the extent doesn't change -- just the current position
            $self->{extent_posn} = $blockinfo->GetExtentPosition();

            return $blockinfo;
        }
        else
        {
            # need a new extent
            #
            # NOTE: Always mark the extent as full to prevent problems
            # if revert back to SMFile space management.  If not
            # marked full, SMFile will assume it is empty, which will
            # cause problems when it bounces off full blocks in the
            # extent.
            $freeblockargs{neednewextent} = 1;
            $freeblockargs{mark_as_full} = 1;

# XXX XXX XXX            print "SMExtent->nextfreeblock: need a new extent!!\n";

        }
                                                      
    } # end check for current extent


    my $seghdr = $self->{current_seghdr};

    # XXX XXX XXX: find extents in current seghdr
    if (defined($seghdr))
    {
        my $rowd = $self->_get_rowd($seghdr);
        unless (defined($rowd))
        {
            goto  L_no_curr;
#        return (undef);
        }


        # no current?
      L_no_curr:
    }

    # XXX XXX XXX: back to first seghdr
    $seghdr = $self->{first_seghdr};

    unless (defined($seghdr))
    {
        goto  L_nospacefound;
    }

    my $rowd = $self->_get_rowd($seghdr);
    unless (defined($rowd))
    {
        goto  L_nospacefound;
#        return (undef);
    }
    my $row = $rowd->_get_meta_row("X1A");

    unless (defined($row) && (scalar(@{$row}) > 1))
    {
        goto  L_nospacefound;
#        print "bad X1A row for $blockno \n";
#        return (undef);
    }

    my (@checklist, %revised);
    for my $xdesc (@{$row})
    {
        my @ggg = $self->_split_extent_descriptor($xdesc);
        next
            unless (scalar(@ggg) > 4);
        my ($blockno, $extent_size, $total_pctused,
            $alloc_pctused, $free_len) = @ggg;

        next
            unless ($free_len > 0);

        my $checkitem = [$blockno, $extent_size, $total_pctused,
                         $alloc_pctused, $free_len];

        push @checklist, $checkitem;
    } # end for all xdesc in X1A row

    # update the extents in the checklist if necessary
    for my $item (@checklist)
    {
        my ($blockno, $extent_size, $total_pctused,
            $alloc_pctused, $free_len) = @{$item};

        $rowd = $self->_get_rowd($blockno);
        unless (defined($rowd))
        {
            print "bad rowd for $blockno!!\n";
            return (undef);
        }
        $row = $rowd->_get_meta_row("XHA");
        unless (defined($row) && (scalar(@{$row}) > 1))
        {
            my $cnt = $rowd->HCount();

            print "rowcount: $cnt\n";

            print "bad XHA row for $blockno \n";
            return (undef);
        }
        my $seghdr = $row->[0];
        my $extsiz = $row->[1];
        my $bvec   = $row->[2];
        my @pct = $self->_xhdr_bv_to_pct($bvec, $row->[1]);

        my $extent_stats = shift @pct;
        my $avgpct   = $extent_stats->{avgpct};
        my $numempty = $extent_stats->{numempty};
        my $allocpct = $extent_stats->{allocpct};

# XXX XXX XXX XXX        
#        print "block $blockno: ",  join(" ",
#                                        ( $total_pctused,
#                                         $alloc_pctused, $free_len)), "\n";

        # get magnitude of number of empty blocks (0-9, where 0 is 0
        # free, and 9 is 10^9)
        my $new_free_len = $numempty ? length($numempty) : 0;
        $new_free_len = 9 
            if ($new_free_len > 9 );

        $avgpct   =  _trunc_or_pad($avgpct, 2);
        $allocpct =  _trunc_or_pad($allocpct, 2);

# XXX XXX XXX XXX
#        print "now: ", join(" ", ($avgpct, $allocpct, $new_free_len)),"\n";

        if (($total_pctused != $avgpct) ||
            ($alloc_pctused != $allocpct) ||
            ($free_len != $new_free_len))
        {
            # use numempty, not free_len, because make_extent_desc
            # will do calculation
            my $revitem = [$blockno, $extent_size, $avgpct,
                           $allocpct, $numempty];

            $revised{$blockno} =  $revitem;
        }

    } # end for checklist

    $rowd = $self->_get_rowd($seghdr);
    unless (defined($rowd))
    {
        return (undef);
    }
    $row = $rowd->_get_meta_row("X1A");
        
    unless (defined($row) && (scalar(@{$row}) > 1))
    {
        goto  L_nospacefound;
#        print "bad X1A row for $blockno \n";
#        return (undef);
    }

    if (scalar(keys(%revised)))
    {

        for my $ii (0..(scalar(@{$row})-1))
        {
            my $xdesc = $row->[$ii];

            my @ggg = $self->_split_extent_descriptor($xdesc);
            next
                unless (scalar(@ggg) > 4);
            my ($blockno, $extent_size, $total_pctused,
                $alloc_pctused, $free_len) = @ggg;

            next 
                unless (exists($revised{$blockno}));

            my $new_xd = $revised{$blockno};
            $row->[$ii] = $self->_make_extent_descriptor(@{$new_xd});

        } # end for all xdesc in X1A row
        $rowd->_set_meta_row("X1A", $row);
    }

    for my $ii (0..(scalar(@{$row})-1))
    {
        my $xdesc = $row->[$ii];

        my @ggg = $self->_split_extent_descriptor($xdesc);
        next
            unless (scalar(@ggg) > 4);
        my ($blockno, $extent_size, $total_pctused,
            $alloc_pctused, $free_len) = @ggg;

        next 
            unless (exists($revised{$blockno}));

        my $new_xd = $revised{$blockno};
        $row->[$ii] = $self->_make_extent_descriptor(@{$new_xd});

    } # end for all xdesc in X1A row

    if (1)
    {
        # XXX XXX: fixup SMFile and SMExtent

        my $currBlocknum;

        my %nargs = (
                  blocknum        => $currBlocknum,
#                  firstextent     => $firstextent,
                  current_extent  => $self->{curr_extent},
                  extent_size     => $self->{extent_size},
                  extent_position => $self->{extent_posn}
                  );

        my $h2 = 
            Genezzo::SpaceMan::SMFreeBlock->new(%nargs);

    }
    

  L_nospacefound:
    # if no space available, get space from SMFile
    return $self->_file_nextfreeblock(%freeblockargs);
}

sub _file_nextfreeblock
{
    my $self = shift;
    my $gotnewextent = 0; # true if get new extent
    my $blockinfo;
    my %freeblockargs = @_;

    # XXX XXX XXX: did this do anything?
    for my $try (1..2)
    {

        if (0)
        {
            local $Genezzo::Util::QUIETWHISPER = 0;
            local $Genezzo::Util::WHISPERDEPTH = 10;
            
            whoami("nfi");

        }


#        print "_file_nextfreeblock args:\n", Data::Dumper->Dump([%freeblockargs]), "\n";
        $blockinfo = $self->{smf}->nextfreeblock(%freeblockargs);

# XXX XXX XXX    print "_file_nextfreeblock:\n", Data::Dumper->Dump([$blockinfo]), "\n";
#        print "_file_nextfreeblock:\n", Data::Dumper->Dump([$blockinfo]), "\n";

        # check if block is truly "free"...
        # XXX XXX XXX XXX:




        last
            if (defined($blockinfo));

        # get a new extent (no re-use)
        $freeblockargs{neednewextent} = 1;
    }

    return undef
        unless (defined($blockinfo));

    {
        $gotnewextent = $blockinfo->IsNewExtent();

        if ($gotnewextent)
        {
            greet "new extent", $blockinfo ;
        }
    }

    my $blockno = $blockinfo->GetBlocknum();

    my $rowd = $self->_get_rowd($blockno);
    unless (defined($rowd))
    {
        return (undef);
    }

    my @new_extent_info;
    if (!$gotnewextent)
    {
        # check if already have extent position
        my $row = undef;

        # if the current extent isn't new, then curr_extent should
        # have been set when the extent was created.  However, if the
        # extent was created in a previous session, we need to track
        # down the header to determine the current position

        unless (exists($self->{curr_extent}) &&
                exists($self->{extent_posn}))
        { # no position info
            $row = $rowd->_get_meta_row("XHP");
            if (defined($row))
            {
                # if the "new" block has a position, then we are done

                whisper "found position!!\n";
                my $posn = $row->[0];
                $self->{curr_extent} = $blockno - $posn;
                $self->{extent_posn} = $posn;

                goto L_setposition;                
            }

            # if we don't know the start of the current extent, check
            # the previous block
            
            $rowd = undef;

            my @ggg = $self->_find_extent_hdr($blockno - 1);

            unless (scalar(@ggg) > 1)
            {
                my $msg = "could not find extent header!\n";
                my %earg = (self => $self, msg => $msg,
                            severity => 'warn');
        
                &$GZERR(%earg)
                    if (defined($GZERR));

                return undef;
            }
            # set info for previous block
            $self->{curr_extent} = shift @ggg;
            $self->{extent_posn} = shift @ggg;
            
            # reload the current block
            $rowd = $self->_get_rowd($blockno);
            unless (defined($rowd))
            {
                return (undef);
            }
 
        } # end no position info

        # if we know the blockno of the current extent, just
        # increment the extent position
        $self->{extent_posn} += 1;

      L_setposition:
        my $posn = $self->{extent_posn};
        # set meta data for the extent header (position, initial %used is zero)
        $rowd->_set_meta_row("XHP", [$posn, 0]);

    }
    else # got new extent
    {
        # size of extent is last entry in blockinfo
        my $extent_size = $blockinfo->GetExtentSize();

        $self->{extent_size}  = $extent_size;

        # curr_extent is the block number of the start of the current extent
        $self->{curr_extent}  = $blockno;

        # each block in the extent has a "position" -- an offset from
        # the 1st block.  The 1st block is position zero, 
        # the 2nd is position 1, etc.
        $self->{extent_posn}  = 0;

        if ($blockinfo->IsFirstExtent())
        {
            # set meta data for the segment header in this file
            unless ($self->_create_segment_hdr($rowd, $blockno, $extent_size))
            {
                my $msg = "could not create segment header\n";
                my %earg = (self => $self, msg => $msg,
                            severity => 'warn');
        
                &$GZERR(%earg)
                    if (defined($GZERR));

                return undef;
            }
        }
        else
        {
            # get info for segment header
            push @new_extent_info, $blockno, $extent_size;
        }
        # set meta data for the extent header
        unless ($self->_create_extent_hdr($rowd, $extent_size,
                                          $self->{current_seghdr}))
        {
            my $msg = "could not create extent header\n";
            my %earg = (self => $self, msg => $msg,
                        severity => 'warn');
        
            &$GZERR(%earg)
                if (defined($GZERR));

            return undef;
        }

    }

    my $curr_seghdr = $self->{current_seghdr};

    if (scalar(@new_extent_info))
    {
        $self->_add_extent_to_segment_hdr(@new_extent_info);
    }
        
    $rowd = $self->_get_rowd(0);
    unless (defined($rowd))
    {
        return (undef);
    }

    return $blockinfo;
} # end nextfreeblock

sub currblock
{
    my $self = shift;
    return $self->{smf}->currblock(@_);
}

sub firstblock
{
    my $self = shift;
    return $self->{smf}->firstblock(@_);
}

sub nextblock
{
    my $self = shift;
    return $self->{smf}->nextblock(@_);
}

sub countblock
{
    my $self = shift;
    return $self->{smf}->countblock(@_);
}

sub hasblock
{
    my $self = shift;
    return $self->{smf}->hasblock(@_);
}

sub freetable
{
    my $self = shift;
    return $self->{smf}->freetable(@_);
}

sub flush
{
    my $self = shift;
    return $self->{smf}->flush(@_);
}

END {

}


1;  # don't forget to return a true value from the file

__END__

=head1 NAME

Genezzo::SpaceMan::SMExtent.pm - Extent Space Management

=head1 SYNOPSIS

 use Genezzo::SpaceMan::SMExtent;

=head1 DESCRIPTION

Maintain segment headers and extent headers for objects stored in
a file with information on space usage.  The set of space allocations
for an object in a file is called a *segment*.  Each segment is
composed of *extents*, groups of contiguous blocks.

allocate a new extent:

if have first extent (segment header)
  create X1A with current blockno, size.
else 
  update X1A with new extent info.

in first block of extent:
  create XHA with empty space usage bitvec
  create XHP, marked as position zero 

if allocate a new block:
  if 1st block of an extent, 
    goto allocate new extent
  else
    could mark prior block as used in XHA...

if free a block:
  clear bitvec in XHA

if freed all blocks in XHA
  update X1A

if X1A is too small:
need 2 rows.  pump out with free space at end.

seghd_allextents: status_flag extent:size:pct_used, 
                  extent:size:pct_used, extent:size:pct_used...
seghd_next: parent_seghead next_seghead:tot_size:pct_used

tot_size in human_num, eg 10K, 100G, 2P...

leapfrog:

seghd in extent 1, create a seghd in extent 2 when
you allocate it.  
when seghd in extent 1 fills, overflow to seghd in 
extent 2.  When allocate next new extent, update the
2nd seghead, and create a new seghd in the new extent.

x1a: extent:size:pct_used, extent:size:pct_used, ...
x1b: parent [child]

parent = self for 1st extent
fill in child when allocate 2nd extent...
child info tracks additional space usage in segment subhead, and
if use "human readable" numbers, can restrict to 4 char fixed size
0-999B, 1K-999K, 1M-999M 
marker for "subhead full" vs vacancy...
x1a: full_flag extent:size:pct_used, extent:size:pct_used, ...


if XHA bitvec is too long:
break out over multiple rows, over multiple blocks.    

xhd1: parent_xhd bitvec
xhd[N]: next_xhd
  
or maybe -- recursive split 

bitvec of blocks or subextents.
for extent of < 128 blocks, simple bitvec for each block.

for extent of 256 blocks
top bitvec of 2 subextents
each subextent has bitvec of 128 blocks

actually, could top out extent size at 1M, use 256 4K blocks per extent

xhd needs to track seghd/subhead info

xhp tracks extent position [0 to N-1] and
%used in extent header (ie 0 is 0%, 3 is 30%, 6 is 60%, and 9 is 90+%).

Note that block zero is a very similar to a segment header, though it
tracks the lists of extents associated with each object, and it
doesn't track percent usage.  However, if we have the case of a file
which is solely for one object, we could merge a good portion of block
zero and the segment header into a combined set of data structures.


=head1 FUNCTIONS

=over 4

=item currblock

return the current active block (insert high water mark) for an object.

Advanced: allow multiple active blocks for concurrent usage.

=item nextfreeblock

return the next unused block for an object, which would be one beyond
the current block in the current extent if possible, or else it
allocates a new extent.

Advanced: allow multiple "next blocks" for concurrent users.  Maintain
multiple freelists.  Use this call as an opportunity to probe extent
headers to update the segment header.

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

=item  need to coalesce adjacent free extents

=item  maintain multiple free lists for performance

=item  better indexing scheme - maybe a btree

=back



=head1 AUTHOR

Jeffrey I. Cohen, jcohen@genezzo.com

=head1 SEE ALSO

perl(1).

Copyright (c) 2006, 2007 Jeffrey I Cohen.  All rights reserved.

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
