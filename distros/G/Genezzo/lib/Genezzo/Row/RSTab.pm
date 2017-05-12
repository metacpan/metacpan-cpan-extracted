#!/usr/bin/perl
#
# $Header: /Users/claude/fuzz/lib/Genezzo/Row/RCS/RSTab.pm,v 7.5 2006/10/19 09:04:13 claude Exp claude $
#
# copyright (c) 2003,2004,2005 Jeffrey I Cohen, all rights reserved, worldwide
#
#
package Genezzo::Row::RSTab;
use strict;
use warnings;
use Carp;
use Genezzo::Util;
use Genezzo::PushHash::HPHRowBlk;
use Genezzo::PushHash::PushHash;
use Genezzo::PushHash::PHFixed;
use Data::Dumper;
use Genezzo::BufCa::BCFile;
use Genezzo::SpaceMan::SMFile;
use Genezzo::Row::RSFile;
use warnings::register;

our @ISA = qw(Genezzo::PushHash::HPHRowBlk);

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

sub make_fac1 {
    my $tclass = shift;
    my %args = (
                @_);

    if (exists($args{hashref}))
    {    
        carp "cannot supply hashref to factory method - deleting !\n"
            if warnings::enabled();

        delete $args{hashref};
    }

    my %td_hash1 = ();

    my $newfunc          = 
        sub {
#            whoami @_;
            my $tiehash1 = 
                tie %td_hash1, $tclass, %args;

            return $tiehash1;
        };
    return $newfunc;
}

# private
sub _init
{
    #whoami;
    #greet @_;
    my $self      =  shift;
    my %required  =  (
                      tablename => "no tablename !",
                      object_id => "no object id !",
                      tso       => "no tso",
                      bufcache  => "no buffer cache",
                      object_type => "no object type"
                      );
    my %optional  =  (
                      dbh_ctx  => {} # XXX XXX XXX: is this used?
                      );
    
    my %args = (@_);

    return 0
        unless (Validate(\%args, \%required));

    $self->{tablename} = $args{tablename};
    $self->{tso}       = $args{tso};
    $self->{bc}        = $args{bufcache};
    $self->{object_id} = $args{object_id};
    $self->{object_type} = $args{object_type};

    $self->{fac1} = make_fac1('Genezzo::PushHash::PushHash');

    $self->{get_filenum}      = {}; # get the filenum based upon chunkno
    $self->{get_chunkno}      = {}; # get the chunkno based upon filenum
    # preload so 0/0 works for nextkey
    $self->{get_filenum}->{0} = 0; 
    $self->{get_chunkno}->{0} = 0;

    # XXX XXX XXX : self->splitrow - if no split rows then simplify store/fetch


    # get the href info from TSTableAFU...
    my $s2 = $self->{tso}->TSTableAFU (tablename => $args{tablename},
                                       object_id => $args{object_id});

    if (defined($s2))
    {
        my $sth = shift @{$s2};
        if (defined($sth))
        {
            # XXX XXX XXX XXX 
#            greet $sth->SQLFetch();
#            greet $s2;
        }
        else
        {
            greet "no afu for $args{tablename}";
#            greet $s2;
#            greet $href;
        }
    }

    my $href = shift @{$s2};

    foreach my $i (@{ $href->{filesused} })
    {
        # XXX: use magic loadme flag
        return 0
            unless (defined(_make_new_chunk($self, $i)));
    }

    # the "small row" threshold is only a small fraction of the
    # default block size in order to avoid wasting space.  For
    # example, if the current block has 500 bytes of freespace, and
    # the packed row is 1000 bytes, it would be more efficient to
    # split the row over two blocks versus leaving 500 bytes free and
    # allocating a new block.  
    $self->{small_row} = 200; # use HSuck on rows > small_row bytes

    return 1;
}

sub TIEHASH
{ #sub new 
#    greet @_;
    my $invocant = shift;
    my $class    = ref($invocant) || $invocant ; 
    my $self     = $class->SUPER::TIEHASH(@_);

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

sub _make_new_chunk # override the hph method
{
#    whoami @_;

    my $self = shift;

    # XXX: rstab specific
    my $loadme = shift;

    my $harr   = $self->{ "Genezzo::PushHash::hph" . ":H_ARRAY"  };
    my $hcount = scalar(@{$harr});

    my $tso  = $self->{tso};

    my $fileinfo;
    if (defined ($loadme))
    {
        $fileinfo = $tso->TSFileInfo (fileno => $loadme);
    }
    else
    {
        # if we have a current file number then get the next one, else
        # don't advance
        my $neednext   = ($hcount > 0);
        my $currfileno = $tso->TS_get_fileno (nextfile => $neednext);
        
        $fileinfo = $tso->TSFileInfo (fileno => $currfileno);
    }
    return (undef)
        unless (defined($fileinfo));

    my ($filename, $filesize, $fileblks, $filenumber) = @{$fileinfo};

    my %realhash = ();

    my %args = (
                hashref   => \%realhash ,
                factory   => $self->{fac1}, 
                tablename => $self->{tablename},
                object_id => $self->{object_id},
                object_type => $self->{object_type},
                filename  => $filename,
                numbytes  => $filesize,
                numblocks => $fileblks,
                filenumber => $filenumber,
                bufcache  => $self->{bc},
                tso       => $self->{tso}
                );

    if (exists($self->{GZERR}) &&
        defined($self->{GZERR}))
    {
        $args{GZERR} = $self->{GZERR};
    }

#    if ($MAXCOUNT > 1)
 #   {
  #      return undef
   #         unless ($hcount < $MAXCOUNT);
    #}
    my $tiehash = 
        $self->{ "Genezzo::PushHash::hph" . ":PushHash_Factory"  }->(%args);

    unless (defined ($tiehash))
    {
        carp "factory could not allocate pushhash"
            if warnings::enabled();
        return undef; # factory out of hashes
    }

    # can only work with pushhash - else die
    croak "not a pushhash"
        unless ($tiehash->isa("Genezzo::PushHash::PushHash"));

    return undef # push failed
        unless( (push @{$harr}, $tiehash) > $hcount);

    # get file number as defined by initial bc file registration
    my $absolute_fileno = 
        $self->{bc}->FileReg(FileName => $filename, 
                             FileNumber => $filenumber);

    $self->{get_filenum}->{($hcount+1)}      = $absolute_fileno;
    $self->{get_chunkno}->{$absolute_fileno} = ($hcount + 1);

    {
        return undef
            unless
                $tso->TSTableUseFile (
                                      tablename  => $self->{tablename},
                                      object_id  => $self->{object_id},
                                      filenumber => $absolute_fileno,
#                                      href => $href
                                      );
        
#            push (@{$href->{filesused}}, $absolute_fileno);
    }
    
    # NOTE: treat array as 1-based (versus 0 based)
    return $harr->[$hcount];
}

sub _splitrid # override the hph method
{
    my $self = $_[0]; # no shift

    # split into 2 parts - chunkno and sliceno
    unless ($_[1] =~ m/$Genezzo::PushHash::hph::RIDSEPRX/)
    {
        my $msg = "could not split key: $_[1] \n";
        my %earg = (self => $self, msg => $msg,
                    severity => 'warn');
        
        &$GZERR(%earg)
            if (defined($GZERR));

        return undef; # no rid separator
    }
    my @splitval = split(/$Genezzo::PushHash::hph::RIDSEPRX/,($_[1]), 2);

    # given an input rid based upon the absolute file number, convert
    # to chunk number
    my $absfileno = $splitval[0];
#    whisper "chunkno  $_[0]->{get_chunkno}->{$absfileno}";

    $splitval[0] = $_[0]->{get_chunkno}->{$absfileno};

    return @splitval;
}

sub _joinrid # override the hph method
{
    my $self = shift;

    my @args = @_;

    my $chunkno = $args[0];

#    whisper "fileno $self->{get_filenum}->{$chunkno}";

    # convert the internal chunknumber to the absolute file number
    $args[0] = $self->{get_filenum}->{$chunkno};

    return (join ($Genezzo::PushHash::hph::RIDSEP, @args));
}

# Constraint Methods

# get/set the constraint list
sub _constraint_check
{
#    whoami;
    my $self = shift;

#    greet $self->{tablename};

    $self->{constraint_list} = shift if @_ ;

    return $self->{constraint_list};
}

# check constraint when inserting new row
sub check_insert
{
    my $self = shift;

    return 0
        unless (exists($self->{constraint_list}));

    my $cons_list = $self->{constraint_list};

    return 0
        unless (defined($cons_list) &&
                exists($cons_list->{check_insert}));

    my $cci_check = $cons_list->{check_insert};
    
    my $val;
    # be very paranoid - filter might be invalid perl
    eval {$val = &$cci_check(@_) };

    # XXX XXX: figure out name of defective constraint
    if ($@)
    {
        whisper "check constraint blew up: $@";
        greet  $cci_check;
        my $msg = "bad check constraint: $@\n";
        my %earg = (self => $self, msg => $msg,
                    severity => 'warn');
        
        &$GZERR(%earg)
            if (defined($GZERR));

        return 1; #### undef;
    }

    return ($val);
} # end check insert

# insert new values into index when inserting new row
sub index_insert
{
    my $self = shift;

    return 0
        unless (exists($self->{constraint_list}));

    my $cons_list = $self->{constraint_list};

    return 0
        unless (defined($cons_list) &&
                exists($cons_list->{index_insert}));

    my $cci = $cons_list->{index_insert};

    return (&$cci(@_));
} # end index insert

sub HSuck
{
#    whoami;
    my $self = shift;
    my %args = (
                @_);

    # CONSTRAINT

#    greet %args;
    return undef
        unless (defined($args{value}));

    my $val = $args{value};
    my $off = (defined($args{offset})) ? 
        $args{offset} : scalar(@{$val}); # offsets are 1 based, not 0
    my $next = $args{next};
    my $headless = $args{headless}; # set if not a true row head piece

    $next = ':' . $next
        if (defined($next));

    my ($place, $frag, $blk_place, $newoff);

    my $firsttry = 1;

  L_whileoff:
    while (defined($off))
    {
        if ($firsttry)
        { # try to fit row piece in current block
            $blk_place = $self->_get_current_block();
        }
        else
        {
            $blk_place = $self->_make_new_block();
        }

        last
            unless (defined($blk_place));

        my ($blktie, $blocknum, $bceref, $href_tie) = 
            $self->_get_block_and_bce($blk_place);

        # Note: we don't pack the value here like 
        # HPush/STORE -- packing is performed at the block level.
        # XXX XXX: need a way to specify a packing method for the
        # underlying HSuck
        ($place, $newoff, $frag) = $blktie->HSuck (
                                                   value  => $val,
                                                   next   => $next,
                                                   offset => $off,
                                                   headless => $headless
                                                   );

        unless (defined($place))
        {
            # allow failure on first try - current block might be too
            # small to hold any part of split row, but new block
            # should always be able to take a piece.

            if ($firsttry)
            { 
                $firsttry = 0;
                next  L_whileoff; # try again in new block
            }

            # XXX XXX: should store list of inserts so can delete
            # pieces if run out of space
            return undef;
        }
        $firsttry = 0;

        if (defined($frag))
        {
            $next = $frag . ":";
        }
        else
        {
            $next = ":";
        }
        # build next pointer as fully qualified rid -- set block_place
        # final sliceno to $place
        my $sloty = '(0$)';         # XXX : replace trailing zero
        $next .=  $blk_place;
        $next =~ s/$sloty/$place/;

        # offset is now new offset
        $off = $newoff;

    } # end while

    my @outi;

    if (defined($blk_place) && defined($place))
    {
        my $slotyy = '(0$)';            # XXX : replace trailing zero
        $next =  $blk_place;
        $next =~ s/$slotyy/$place/;
    }
    else
    {
        # XXX XXX: is this bad?  Probably not.  
        greet "bad:", $firsttry, $blk_place, $place, $off, $next;
    }

    push @outi, $next;
    if (defined($off))
    {
        push @outi, $off;
    }
    if (defined($frag))
    {
        push @outi, $frag; # column was fragmented
    }

    return @outi;
} # end HSuck

# HPush public method (not part of standard hash)
sub HPush
{
    my ($self, $value) = @_;

    my $toobig  = 0;
    my $maxsize = 2 * $self->{small_row}; 

    # XXX XXX: need a "mutating" constraint to support default values
    # for null columns, numeric precision, column uppercasing, etc.

    # CONSTRAINT - "check constraints" first

    if ($self->check_insert($value, undef, $self->{tablename}))
    {
        # Note: $place is undefined, because we haven't pushed
        # yet.  But might need it for check constraints that
        # require the rid (very very improbable - should probably
        # be illegal)

        {
            # Check constraint FAILED
            return undef;
        }
    }

    my $packstr = PackRowCheck($value, $maxsize);

    if (defined($packstr))
    {
        # fit maybe
    }
    else
    {
        $toobig = 1;
    }
    my $place = $self->_localHPush($packstr, $value, $toobig);

    return undef
        unless (defined($place));

    # CONSTRAINT - index_inserts, like primary/unique key.  Need to do
    # after the push because need a rid for the index.  maybe
    # restructure so don't have to push huge rows that would violate
    # constraint.  bt->insert_maybe with localhpush callback to
    # generate rid
    #
    # val TBD callback needs a place_ref so subsequent cons_lists can
    # get correct place, and so HPush can return place to caller
    #
    # cons_list ($value, null, val_TBD_cb, place_ref)

    if ($self->index_insert($value, $place))
    {
        {
            whisper "undo insert!!";
            # and don't specify the constraint check.  Why?
            # Because if the insert failed with a duplicate key,
            # then delete will remove it from the index.
            $self->_localDELETE($place);
            return undef;
        }
    }

    return $place;
}

# count estimation
sub FirstCount 
{
#    whoami;
    my $self = shift;

    my $key = $self->FIRSTKEY();

    my @outi;
    push @outi, $key;

    return $self->NextCount(@outi); 

} # FirstCount

# count estimation
sub NextCount
{
#    whoami;
    my ($self, $prevkey, $esttot, $sum, $sumsq, $chunkcount, $totchunk) = @_;

    return undef
        unless (defined($prevkey));

    my ($chunkno, $prevsliceno) = $self->_splitrid($prevkey);
    my $chunk;

    unless (defined($esttot))
    {
#        greet "first first";

        $prevsliceno = ();
        ($esttot, $sum, $sumsq, $chunkcount, $totchunk) = (0,0,0,0,0);
        $chunkno = $self->_First_Chunkno();

        while (defined($chunkno))
        {
            $chunk = $self->_get_a_chunk($chunkno);
            my @foo = $chunk->FirstCount();

#            greet @foo;
            #                        XXX XXX: why not defined?
            if ((scalar(@foo) > 4) && defined($foo[-1]))
            {
                $totchunk += $foo[-1];
            }
            $chunkno = $self->_Next_Chunkno($chunkno);
        }
        $chunkno = $self->_First_Chunkno();
    }

    my @outi;
#    push @outi, $prevkey, $esttot, $sum, $sumsq, $chunkcnt, $totchunk;

    my $quitLoop = 1; # XXX XXX 
    my $loopCnt  = 0;

    while (defined($chunkno))
    {
        $chunk = $self->_get_a_chunk($chunkno);
        $loopCnt++;

        if (defined ($prevsliceno))
        {
            @outi = $chunk->NextCount($prevsliceno, 
                                      $esttot, $sum, $sumsq,
                                      $chunkcount, $totchunk);
        }
        else
        {
            my @oldouti = @outi;

            @outi = $chunk->FirstCount();
            if (scalar(@outi))
            {
                $outi[2]  += $sum;
                $outi[3]  += $sumsq;
                $outi[4]  += $chunkcount;
                $outi[5]  = $totchunk;

#    $esttot = $sum * ($totchunk/$chunkcount)
#        if (($sum > 0) && ($chunkcount > 0) && ($totchunk > 0));
                
                $outi[1]  = $outi[2] * ($totchunk/$outi[4])
                    if (($outi[2] > 0) && ($outi[4] > 0) 
                        && ($totchunk > 0));

    # current sum + (current avg * remaining chunks)
#           $outi[1] = $outi[2] + (($outi[2]/$outi[4])*($outi[5]-$outi[4]))


            }
            else
            {
                @outi = @oldouti;
            }
        }

        last
            if ($quitLoop && scalar(@outi) && defined($outi[0]));

        $prevsliceno = ();
        $chunkno = $self->_Next_Chunkno($chunkno);

        # XXX XXX: add logic here
        $quitLoop = 1
            if $loopCnt > 10;
    } # end while chunkno

    return @outi
        unless (scalar(@outi) && defined($chunkno) && defined($outi[0]));

    my $sliceno = shift @outi;
    unshift @outi, $self->_joinrid($chunkno, $sliceno);

    return @outi;
} # nextcount


sub _localHPush
{
    my ($self, $packstr, $value, $toobig) = @_;

    # NOTE: space management busted here -- pushing a huge row 
    # (packstr >= blocksize) bounces off the new block, which then
    # allocates a new file.  Avoid the issue by only pushing small
    # strings
    if (!($toobig) && 
        (length($packstr) < $self->{small_row}))
    {
        my $place = $self->SUPER::HPush($packstr);

        return $place
            if (defined($place));
    }

    # if string was too big, or push failed, try HSuck
    my @stat = $self->HSuck (value => $value);

    # null stat for failure, or extra cols indicates partial pack --
    # should see a single column for complete pack.
    return undef
        unless (scalar(@stat) == 1);

    return $stat[0]; # rid for first rowpiece
}

sub STORE
{
    my ($self, $place, $value) = @_;

    # CONSTRAINT
    my $cons_list = $self->{constraint_list};
    my ($cci_index, $ccu, $ccd);
    my @cc_op_list; # delete/insert operations

    if (defined($cons_list))
    {
        $ccu = $cons_list->{update};
        $ccd = $cons_list->{delete};
        $cci_index = $cons_list->{index_insert};
    }

    # CONSTRAINT - do "check constraints" before update
    if ($self->check_insert($value, $place, $self->{tablename}))
    {
        # Check constraint FAILED
        return undef;
    }

    my $oldvalue;

    if ($place !~ m/^PUSH$/)
    {
        if (defined($cci_index))
        {
            # clear out the insert callback -- ccu will generate an
            # op_list of delete/inserts if necessary.
            $cci_index = (); 
        }

        if (defined($ccu))
        {
            $oldvalue = $self->FETCH($place);

            if (&$ccu($value, $oldvalue, $place, \@cc_op_list))
            {
                whisper "updated key - delete from index";
                greet @cc_op_list;
                greet $place, $value, $oldvalue;
#                greet &$ccd($oldvalue, $place);
            }
            else
            {
                whisper "keys match - index not updated";
                $oldvalue  = (); # keys match - don't keep old value 
            } 
        }
    } # end !push

    # 2 cases: 
    # either PUSHing a new key *or* 
    # the old keys didn't match so we deleted them from the index.
    #
    # NOTE that we do the "index_insert" before the update, because the
    # rid exists already.  

    my $maxj;

    if (defined($cci_index))
    {
        return undef
            if (&$cci_index($value, $place));
    }
    elsif (scalar(@cc_op_list))
    {
        my $maxi = scalar(@cc_op_list);
     
        for my $i (0..($maxi - 1))
        {
            my $opv = $cc_op_list[$i];

            greet $opv;
            my $cnam = $opv->[0];
            my $del1 = $opv->[1];
            my $ins1 = $opv->[2];

            if (defined($del1) && defined($oldvalue))
            {
                greet &$del1($oldvalue, $place);
            }

            if (defined($ins1))
            {
                if (&$ins1($value, $place))
                {
                    # Index insert FAILED - revert indexes to old state
                    $maxj = $i;
                    if (defined($oldvalue)) # had an old key
                    {
                        whisper " attempt to restore old value";
                        &$ins1($oldvalue, $place);
                    }
                    return undef 
                        unless ($i); # we're done if only a single index
                    last;
                }

            }

        }
    }

    if (defined($maxj))
    {
        for my $j (0..($maxj - 1))
        {
            my $opv = $cc_op_list[$j];

            greet $opv;
            my $cnam = $opv->[0];
            my $del1 = $opv->[1];
            my $ins1 = $opv->[2];

            if (defined($del1))
            {
                # delete the new value
                greet &$del1($value, $place);
            }

            if (defined($ins1)  && defined($oldvalue))
            {
                # restore the old value if possible
                if (&$ins1($oldvalue, $place))
                {
                    greet "really screwed up, sorry!";
                    my $msg = "Serious error during update!!\n";
                    my %earg = (self => $self, msg => $msg,
                                severity => 'warn');
        
                    &$GZERR(%earg)
                        if (defined($GZERR));

                    return undef;
                }
            }
        } # end for
        return undef;
    } # end if maxj
            

    my $stat = $self->_localStore($place, $value);
    
    if (!defined($stat))
    {
        if (defined($cci_index))
        {
            # localStore FAILED - revert indexes to old state

            whisper "delete new key from index";
            &$ccd($value, $place);
            if (defined($oldvalue))
            {
                whisper " attempt to restore old value";
                &$cci_index($oldvalue, $place);
            }
        }
        elsif (scalar(@cc_op_list))
        {
            my $maxi = scalar(@cc_op_list);
     
            for my $i (0..($maxi - 1))
            {
                my $opv = $cc_op_list[$i];

                greet $opv;
                my $cnam = $opv->[0];
                my $del1 = $opv->[1];
                my $ins1 = $opv->[2];

                if (defined($del1))
                {
                    greet &$del1($value, $place);
                }

                if (defined($ins1) && defined($oldvalue))
                {
                    if (&$ins1($oldvalue, $place))
                    {
                        whisper "oh gosh!";
                        my $msg = "Really serious error during update!!\n";
                        my %earg = (self => $self, msg => $msg,
                                    severity => 'warn');
                        
                        &$GZERR(%earg)
                            if (defined($GZERR));
                    }
                }
            } # end for
        }
    } # end if not defined stat

    return ($stat);
}

# if setfwdptr (set Forwarding pointer), then only storing an empty
# header with pointer to the first rowpiece.
sub _localStore
{
#    whoami;
    my ($self, $place, $value) = @_;

    my $toobig  = 0;
    my $oldsize = 0;
    my @estat   = $self->_exists2($place); # HPHRowBlk method

    if (   (scalar(@estat) > 2) 
        && Genezzo::Block::RDBlock::_isheadrow($estat[0])
        && Genezzo::Block::RDBlock::_istailrow($estat[0])
           )
    {
        # if the row already exists as a single, contiguous buffer,
        # set maxsize for PackRowCheck to determine if can update in
        # place.
        $oldsize = $estat[2];
    }
    my $maxsize = 2 * $self->{small_row}; 

#    greet "max: $maxsize, old: $oldsize";

    $maxsize = $oldsize
        if ($oldsize > $maxsize);

    my $packstr = PackRowCheck($value, $maxsize);

#    greet "packstr: ", length($packstr) if (defined($packstr));

    unless ($oldsize)
    {
        # keep maxsize a bit small unless space is already allocated
        $maxsize = $self->{small_row}; 
    }

    if (defined($packstr))
    {
#        greet "fit maybe";
    }
    else
    {
#        greet "toobig";
        $toobig = 1;
    }

    if ($place =~ m/^PUSH$/)
    {
        $place = $self->_localHPush($packstr, $value, $toobig);
        return undef 
            unless (defined($place));
        return $value;
    }

    # XXX XXX: race condition here -- would need to lock row to ensure
    # that rowstat doesn't change.  Probably need a new STORE with the
    # specification to only update if both head and tail, and the
    # _exists2 is merely a hint.

    # estat = ($rowstat, $rowposn, $rowlen)
    @estat = $self->_exists2($place); # HPHRowBlk method

    if (   (scalar(@estat) < 3) # no such row or bad rid (so fail on STORE)
        # or the row fits in a block   
        ||
           (   (scalar(@estat) > 2) 
            && Genezzo::Block::RDBlock::_isheadrow($estat[0])
            && Genezzo::Block::RDBlock::_istailrow($estat[0])
            && !($toobig)                    # toobig check
            && $estat[2] >= length($packstr) # see if still fits   
           )
        )
    {
        if (!($toobig)
            && (length($packstr) <= $maxsize)) # avoid long rows
        {
#            greet "should fit";
            my $stat = $self->SUPER::STORE($place, $packstr);
            return $value
                if (defined($stat));
            return undef;
        }
    }

    # set up arguments for HSuck.  HSuck new value as "headless",
    # since it gets stored as a continuation of the first piece of the
    # old row
    my %nargs = (value    => $value,
                 headless => 1); 

    # XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX 
    # if the original row is split over multiple blocks, then push the
    # new value and replace the first piece of the original row with a
    # forwarding pointer to the new value
    #
    # It's not an optimal or efficient replacement strategy, but it is
    # straightforward.  Need to figure out how to:
    #   1. re-use freed space from old row
    #   2. figure out how to update individual columns more
    #      efficiently.  One possible variation is do current replacement
    #      strategy starting at column N, i.e., if updating column N,
    #      truncate the row from column N onward and stick the forwarding
    #      pointer at col N.
    #
    # XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX 

    my $split_row = !(Genezzo::Block::RDBlock::_istailrow($estat[0]));

    # suck new value first, so we still have the old row if it fails...
    
    # sukk = (newplace, offset, frag flag)
    my @sukk = $self->HSuck (%nargs);
    # XXX XXX: HSuck could fail here - that would be bad...
    greet "sukk:", @sukk;

    return undef # XXX XXX: need to test this...
        unless (scalar(@sukk) && (defined($sukk[0])));

    # if the old value is split over multiple blocks
    if ($split_row)
    {
        whisper "long row";

        # use localFetchDelete to delete the existing row pieces, but
        # keep the first piece and mark it as complete (both head and
        # tail bits get set).  Note: First piece *must* be large
        # enough to hold the forwarding pointer.

        my $val = $self->_localFetchDelete($place, 1, 1); # delete trailing 
                                                          # pieces, 
                                                          # but keep head 
        # now only the first piece is left, 
#        greet "oldval: ", $val;
    }

    {
        # create a forwarding pointer to the row.  It needs to an
        # empty col1 fragment that points to col1 in the new row.
        my @fakerow;
        push @fakerow, ""; # blank col1
        push @fakerow, "F:".$sukk[0];

        my $packfake = PackRow(\@fakerow);
        my $sstat = $self->SUPER::STORE($place, $packfake);

        # XXX XXX: STORE could fail here too - that would be bad

        # XXX: don't call localstore recursively...

####     my $sstat = $self->_localStore($place, \@fakerow, 1);
#        greet "stat:", $sstat;
#        greet $self->_exists2($sukk[0]); # HPHRowBlk method
#        greet "e1:", @estat;

        # clear the tail flag of the first piece, since it now points to
        # the new value
        $estat[0] &= ~($Genezzo::Block::RDBlock::RowStats{tail});
        @estat = $self->_exists2($place, $estat[0]); # HPHRowBlk method
#        greet "e2:", @estat;
    }
    return $value;
}

#sub FETCH    
#{ 
#    my ($self, $place) = @_;
#    
#    my $value = ($self->SUPER::FETCH($place));
#
#    return (undef)
#        unless (defined($value));
#
#    my @outarr = UnPackRow($value);
#    
#    return (\@outarr);
#
#}
sub FETCH    
{ 
    my ($self, $place) = @_;

    # CONSTRAINT
    
    return $self->_localFetchDelete($place);
}

# if doDelete is set then perform recursive delete on chained rows
sub _localFetchDelete
{ 
    my ($self, $place, $doDelete, $keepHead) = @_;

    # XXX : should be able to do FETCH directly if know have
    # information that no split rows...
    # XXX XXX: maybe ok to piggy-back fetch2 into normal FETCH?

    # fetcha = (value, rowstat)
    my @fetcha = $self->_fetch2($place); # HPHRowBlk method

    # XXX: check status?
    my $deleteStatus;
    if (defined($doDelete))
    {    
#        greet "a", $keepHead, $place, @fetcha;
        unless (defined($keepHead))
        {
            $deleteStatus = $self->SUPER::DELETE($place);
        }
    }

    return undef
        unless (   (scalar(@fetcha) > 1)
                && defined($fetcha[0]) # value
                && defined($fetcha[1]) # rowstat
                && Genezzo::Block::RDBlock::_isheadrow($fetcha[1]));
    
    my @rowpiece = 
        UnPackRow($fetcha[0], 
                  $Genezzo::Util::UNPACK_TEMPL_ARR); # first row piece 
    
    # Note: just return if row was not split.  Avoid the extra push in
    # the while loop
    return (\@rowpiece)
        if (Genezzo::Block::RDBlock::_istailrow($fetcha[1]));

    if (defined($doDelete) && defined($keepHead))
    {
        # keep the head, but define it as a completed piece
#        greet "del, keephead", @fetcha;
        my @estat = $self->_exists2($place, 
                                    (
                                     $fetcha[1] |
                                     ($Genezzo::Block::RDBlock::RowStats{tail})
                                     )
                                    ); # HPHRowBlk method
        # Note: fetcha[1] ("rowstat") is checked to terminate while loop, 
        # so don't update it here!
#        greet @estat;
    }

    my $gotFrag = 0;
    my @outarr; # current rowpiece loaded into outarr in while loop

    # Fetch the remaining row pieces, and re-assemble the row.  If the
    # piece isn't the tail (end) of the row, the last column is a
    # "next pointer", a pointer to the next piece, with a flag which
    # indicates whether the last column (the real last column, not the
    # aforementioned next pointer) was split.

    my $piececount = 0;

  L_rowpiece:
    while (1)
    {
        if ($gotFrag)
        { # column was fragmented - merge the next column piece 
            my $h1 = shift @rowpiece;
            $outarr[-1] .= $h1; # append remainder to end of last column
        }
        
        # append next set of columns to existing row
        push @outarr, @rowpiece;

#        greet "count:", $piececount, @outarr;

        last L_rowpiece # done when last piece of row is fetched
            if (Genezzo::Block::RDBlock::_istailrow($fetcha[1]));

        my $nextp = pop @outarr; # last column was pointer to next piece,
                                 # so remove it from output

        # check next pointer to see if column was fragmented (split)
        my ($frag, $pieceplace) = split(':', $nextp);

        # XXX XXX: clean this up - centralize knowledge of frag flag somewhere
        $gotFrag = (defined($frag)) && ($frag =~ m/F/);

        # get the next piece
        @fetcha   = $self->_fetch2($pieceplace);

        $piececount++;

        unless (   (scalar(@fetcha) > 1)
                && defined($fetcha[0]) 
                && defined($fetcha[1]) 
               )
        { # ERROR: remainder of row not found
            if  (scalar(@outarr))
            {
 #               greet "b", $pieceplace, @fetcha;
 #               greet @outarr;
                my $tname = $self->{tablename};
                whisper "table $tname: malformed row $place at $pieceplace";

                my $msg = "table $tname: malformed row $place at " .
                    "$pieceplace\n";
                my %earg = (self => $self, msg => $msg,
                            severity => 'warn');
        
                &$GZERR(%earg)
                    if (defined($GZERR));
            }
            return undef;
        }
        if (defined($doDelete))
        {
            # XXX: should check delete status here
#            greet "c", $pieceplace, @fetcha;
            whisper "delete piece $pieceplace";
            $deleteStatus = $self->SUPER::DELETE($pieceplace);
#            greet $deleteStatus;
        }

        @rowpiece = UnPackRow($fetcha[0], $Genezzo::Util::UNPACK_TEMPL_ARR); 
    } # end while l_rowpiece

    return (\@outarr);
} # end localFetchDelete  

sub DELETE
{
#    whoami;
    my ($self, $place) = @_;

    # CONSTRAINT
    my $cons_list = $self->{constraint_list};

    return $self->_localDELETE($place, $cons_list);
}
sub _localDELETE
{
#    whoami;
    my ($self, $place, $cons_list) = @_;

    # CONSTRAINT

    # XXX XXX XXX XXX: need to support foreign key constraint, also
    # DELETE CASCADE

    my $ccd;

    if (defined($cons_list))
    {
        $ccd = $cons_list->{delete};
    }

    my @estat = $self->_exists2($place); # HPHRowBlk method

    if (   (scalar(@estat) < 3) # no such row or bad rid
        # or the row fits in a block   
        || (   (scalar(@estat) > 2) 
            && Genezzo::Block::RDBlock::_isheadrow($estat[0])
            && Genezzo::Block::RDBlock::_istailrow($estat[0])
           )
        )
    {
        my $val = $self->SUPER::DELETE($place);

        return undef
            unless (defined($val));

        if (defined($ccd))
        {
            my @outarr = UnPackRow($val, $Genezzo::Util::UNPACK_TEMPL_ARR);
            &$ccd(\@outarr, $place); # delete from index
            return (\@outarr);
        }
        else
        {
            return (UnPackRow($val, $Genezzo::Util::UNPACK_TEMPL_ARR));
        }
    }

    # fetch the pieces and delete them
    if (defined($ccd))
    {
        my @outarr =  $self->_localFetchDelete($place, 1);
        &$ccd(\@outarr, $place);
        return (\@outarr);
    }
    else
    {
        return $self->_localFetchDelete($place, 1);
    }

} # end DELETE

sub SQLPrepare # get a DBI-style statement handle
{
    my $self = shift;
    my %args = @_;
    $args{pushhash} = $self;
    $args{tablename} = $self->{tablename};

    if ((exists($self->{GZERR}))
        && (defined($self->{GZERR})))
    {
        $args{GZERR} = $self->{GZERR};
    }

    my $sth = Genezzo::Row::SQL_RSTab->new(%args);

    return $sth;
}

package Genezzo::Row::SQL_RSTab;
use strict;
use warnings;
use Genezzo::Util;

sub _init
{
    my $self = shift;
    my %args = (@_);

    return 0
        unless (defined($args{pushhash}));
    $self->{pushhash} = $args{pushhash};
    $self->{tablename} = $args{tablename};
    if (defined($args{alias}))
    {
        $self->{tablename} = $args{alias};
    }

    if (defined($args{filter}))
    {
        $self->{SQLFilter} = $args{filter}; 
        my $ff = $args{filter}; 
#        greet $ff;

        my $cons_list = $self->{pushhash}->_constraint_check();

        if (defined($cons_list))
        {
            my @both_keys = Genezzo::Util::GetIndexKeys($ff);
            
            if ((scalar(@both_keys) > 1) 
                && (exists($cons_list->{SQLPrepare})))
            {
#                greet @both_keys; # keys in table colidx order

                my $get_search = $cons_list->{SQLPrepare};

                # prepare an index search if have startkey/stopkey

                my $searchhandle = &$get_search(@both_keys);

                $self->{IndexSth} = $searchhandle
                    if (defined($searchhandle));
            }
        }
    }
    $self->{rownum} = 0;

    return 1;
}

sub new
{
 #   whoami;
    my $invocant = shift;
    my $class = ref($invocant) || $invocant ; 
    my $self = { };

    my %args = (@_);

    if ((exists($args{GZERR}))
        && (defined($args{GZERR}))
        && (length($args{GZERR})))
    {
        # NOTE: don't supply our GZERR here - will get
        # recursive failure...
        $self->{GZERR} = $args{GZERR};
    }

    return undef
        unless (_init($self,%args));

    return bless $self, $class;

} # end new


# SQL-style execute and fetch functions
sub SQLExecute
{
    my ($self, $filter) = @_;

#    $self->{SQLFilter} = $filter; # check this
    if (exists($self->{IndexSth}))
    {
        greet "index execute";

        $self->{SQLFetchKey} = 1;
        return $self->{IndexSth}->SQLExecute();
    }

    $self->{SQLFetchKey} = $self->FIRSTKEY();

    # XXX: define filters and fetchcols
    return (1);
}

# XXX XXX XXX XXX:  create a separate dynamic package to
# hold the fetch state, vs keeping the fetch state in the base
# pushhash.  Then can maintain multiple independent SQLFetches open
# on same RSTab object.

# combine NEXTKEY and FETCH in a single operation
sub SQLFetch
{
    my ($self, $key) = @_;
    my $fullfilter = $self->{SQLFilter};
    my $filter = (defined($fullfilter)) ? $fullfilter->{filter} : undef;

    # use explicit key if necessary
#    $self->{SQLFetchKey} = $key
#        if (defined($key));

    while (defined($self->{SQLFetchKey}))
    {
        my $currkey;

        if (exists($self->{IndexSth}))
        {
#            greet "index fetch";

            my @idx_row = $self->{IndexSth}->SQLFetch();

#            greet @idx_row;

            unless (scalar(@idx_row) > 1)
            {
                $self->{SQLFetchKey} = undef;
                return undef;
            }

            pop @idx_row; # remove extra search cols
            pop @idx_row;
            
            $currkey = pop @idx_row; # val is rowid for table
        }
        else
        {
            $currkey = $self->{SQLFetchKey};
        }

        my $outarr  = $self->FETCH($currkey);
        my $tablename = $self->{tablename};
        my $get_col_alias = {$tablename => $outarr};

        # save the value of the key because we pre-advance to the next one
        $self->{SQLFetchKey} = $self->NEXTKEY($currkey)
            unless (exists($self->{IndexSth}));        

        # Note: always return the rid
        return ($currkey, $outarr)
            unless (defined($filter));

        # filter is defined
        my $val;

        my $rownum = $self->{rownum} + 1;
        # be very paranoid - filter might be invalid perl
        eval {$val = &$filter($self, $currkey, $outarr, 
                              $get_col_alias, $rownum) };
        if ($@)
        {
            whisper "filter blew up: $@";
            greet   $fullfilter;

            my $msg = "bad filter: $@\n" ;
#            $msg .= Dumper($fullfilter)
#               if (defined($fullfilter));
            my %earg = (self => $self, msg => $msg,
                        severity => 'warn');
            
            &$GZERR(%earg)
                if (defined($GZERR));

            return undef;
        }
        unless (!$val)
        {
            $self->{rownum} += 1;
            return ($currkey, $outarr);
        }

    }

    return undef;
}

sub AUTOLOAD 
{
    my $self = shift;
    my $ph = $self->{pushhash};

    our $AUTOLOAD;
    my $newfunc = $AUTOLOAD;
    $newfunc =~ s/.*:://;
    return if $newfunc eq 'DESTROY';

#    greet $newfunc;
    return ($ph->$newfunc(@_));
}

END {

}

1;

__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Genezzo::Row::RSTab.pm - Row Source TABle tied hash class. 

=head1 SYNOPSIS

 use Genezzo::Row::RSTab;

 # see Tablespace.pm -- implementation and usage is tightly tied
 # to genezzo engine...

 # make a factory for rsfile
 my $fac2 = make_fac2('Genezzo::Row::RSFile');
        
 my %args = (
             factory   => $fac2,
             # need tablename, bufcache, etc...
             tablename => ...
             tso       => ...
             bufcache  => ...
                    );

  my %td_hash;
  $tie_val = 
    tie %td_hash, 'Genezzo::Row::RSTab', %args;

 # pushhash style 
 my @rowarr = ("this is a test", "and this is too");
 my $newkey = $tie_val->HPush(\@rowarr);

 @rowarr = ("update this entry", "and this is too");
 $tied_hash{$newkey} = \@rowarr;

 my $getcount = $tie_val->HCount();

=head1 DESCRIPTION

RSTab is a hierarchical pushhash (see L<Genezzo::PushHash::hph>) class
that stores perl arrays as rows in a table, writing them into a block
(byte buffer) via B<Genezzo::Row::RSFile> and B<Genezzo::Block::RDBlock>.

=head1 ARGUMENTS

=over 4

=item tablename
(Required) - the name of the table

=item tso
(Required) - tablespace object from B<Genezzo::Tablespace>

=item bufcache
(Required) - buffer cache object from B<Genezzo::BufCa::BCFile>


=back


=head1 CONCEPTS

Logically, a table is made of rows, and rows are vectors of columns.
Physically (at least from an OS implementation viewpoint), a table is
made up of blocks stored in files.  The RSTab hierarchical pushhash
(hph) uses an RSFile factory, though it could be constructed as an hph
of arbitrary depth.  The basic HPush mechanism takes an array,
flattens it into a string, and pushes the string into one of the
underlying blocks.

While the RSTab api is primarily intended as a row-based interface, it
has some extensions to directly manipulate the underlying blocks.
These extensions are useful for building specialized index mechanisms
(see L<Genezzo::Index>) like B-trees, or for supporting rows that span
multiple blocks.

=head2 Basic PushHash

You can use RSTab as a persistent hash of arrays of scalars if you
like.  The arrays and scalars can be of arbitrary length (as long as
they fit in your datafiles).  

=head2 SQL DBI-style interface

RSTab is designed to efficiently support prepare/execute/fetch
operations against tables.  What distinguishes this API from a
standard hash is that the "prepare" operation generates a custom,
stateful iterator that understands filters and range selection.  A
filter is simply a predicate which is applied to every row -- rows
which pass are returned to the caller, and rows which fail are
"filtered out".  Range selection is somewhat similar, with the notion
of start and stop keys -- the iterator only returns the rows which are
restricted to a certain range of values.  In general, range selection
is driven off a separate indexing mechanism that positions the fetch
to specifically retrieve the range in an efficient manner, versus
fetching all rows and filtering rows outside the range.

=head2 HPHRowBlk - Row and Block operations

HPHRowBlk is a special pushhash subclass with certain direct block
manipulation methods.  One very useful function is HSuck, which
provides support for rows that span multiple blocks.  While the
standard HPush fails if a row exceeds the space in a single block, the
HSuck api lets the underlying blocks consume the rows in pieces --
each block "sucks up" as much of the row as it can.  The RSTab HPush
is re-implemented on top of HSuck to support large rows.

=head2 Counting, Estimation, Approximation

RSTab has some support for count estimation, inspired by some of Peter
Haas' work (Sequential Sampling Procedures for Query Size Estimation,
ACM SIGMOD 1992, Online Aggregation (with J. Hellerstein and H. Wang),
ACM SIGMOD 1997 Ripple Joins for Online Aggregation (with
J. Hellerstein) ACM SIGMOD 1999).  It could use support for confidence
intervals, so drop me a line if you understand Central Limit Theorem,
Hoeffding and Chebyshev inequalites.  Knowledge of change-points and
time-series is also a plus.

=head1 FUNCTIONS

RSTab support all standard hph hierarchical pushhash operations, with
the extension that it manipulates arrays of scalars, not individual
scalars.

=head2 EXPORT

=head1 LIMITATIONS

various

=head1 TODO

=over 4

=item rownum filter support to move to separate package

=item $href: remove - need a dict function to return allfileused via tso

=item HSuck: need a way to specify packing method 

=item HSuck: fix trailing zero replacement

=item NextCount: fix quitloop

=item localPush/Store: qualify length packstr as percentage of blocksize (1/3?)

=item localStore: race condition on rowstat 

=item localFetchDelete: frag flag info, delete status.  Could express
this function as a generalized "RowSplice" (as distinct from
RDBlkA::HSplice, which is a block splice operator).  Would need be
able to splice based upon column number/array offset, as well as
substring byte offset -- the inverse functionality of PackRow2/HSuck

=item DBI - support Bind and projection (returning only certain
specified columns, versus all columns)

=item _init: change to use TSTableAFU support versus href->{filesused}

=item need support for constraints that "mutate" supplied values,
      e.g. manipulate numeric precision or supply default values for 
      columns.  Also need support for foreign keys in delete.

=back

=head1 AUTHOR

Jeffrey I. Cohen, jcohen@genezzo.com

=head1 SEE ALSO

L<Genezzo::PushHash::HPHRowBlk>,
L<Genezzo::PushHash::hph>,
L<Genezzo::PushHash::PushHash>,
L<Genezzo::Tablespace>,
L<Genezzo::Row::RSFile>,
L<Genezzo::Row::RSBlock>,
L<Genezzo::Block::RDBlock>,
L<Genezzo::BufCa::BCFile>,
L<Genezzo::BufCa::BufCaElt>,
L<perl(1)>.

Copyright (c) 2003, 2004, 2005 Jeffrey I Cohen.  All rights reserved.

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
