#!/usr/bin/perl
#
# $Header: /Users/claude/fuzz/lib/Genezzo/SpaceMan/RCS/SMHook.pm,v 1.30 2007/11/20 07:43:07 claude Exp claude $
#
# copyright (c) 2006, 2007 Jeffrey I Cohen, all rights reserved, worldwide
#
#
package Genezzo::SpaceMan::SMHook;

use Genezzo::Util;

use strict;
use warnings;
use warnings::register;

use Carp;

our $VERSION;
our $MAKEDEPS;

BEGIN {
    $VERSION = do { my @r = (q$Revision: 1.30 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r }; # must be all one line, for MakeMaker

    my $pak1  = __PACKAGE__;
    $MAKEDEPS = {
        'NAME'     => $pak1,
        'ABSTRACT' => ' ',
        'AUTHOR'   => 'Jeffrey I Cohen (jcohen@cpan.org)',
        'LICENSE'  => 'gpl',
        'VERSION'  =>  $VERSION,
#        'UPDATED'  => Genezzo::Dict::time_iso8601()
        }; # end makedeps

    $MAKEDEPS->{'PREREQ_HAVOK'} = {
        'Genezzo::Havok' => '0.0',
        'Genezzo::Havok::SysHook' => '0.0',
    };

    # DML is an array, not a hash

#    my $now = Genezzo::Dict::time_iso8601()
    my $now = 
    do { my @r = (q$Date: 2007/11/20 07:43:07 $ =~ m|Date:(\s+)(\d+)/(\d+)/(\d+)(\s+)(\d+):(\d+):(\d+)|); sprintf ("%04d-%02d-%02dT%02d:%02d:%02d", $r[1],$r[2],$r[3],$r[5],$r[6],$r[7]); };


    my $dml =
        [
         "select add_sys_hook(\'pkg=Genezzo::Block::RDBlock\', \'hook=push_post_hook\', \'replace=Push_Hook\', \'module=$pak1\', \'function=block_push_hook\', \'version=$VERSION\') from dual",
         "select add_sys_hook(\'pkg=Genezzo::Block::RDBlock\', \'hook=delete_post_hook\', \'replace=Delete_Hook\', \'module=$pak1\', \'function=block_delete_hook\', \'version=$VERSION\') from dual",
         "select add_sys_hook(\'pkg=Genezzo::Block::RDBlock\', \'hook=realstore_post_hook\', \'replace=Store_Hook\', \'module=$pak1\', \'function=block_store_hook\', \'version=$VERSION\') from dual",
         "select add_sys_hook(\'pkg=Genezzo::Row::RSFile\', \'hook=untie_block_pre_hook\', \'replace=PreUntie_Hook\', \'module=$pak1\', \'function=block_pre_untie_hook\', \'version=$VERSION\') from dual",
         "select add_sys_hook(\'pkg=Genezzo::Row::RSFile\', \'hook=untie_block_post_hook\', \'replace=PostUntie_Hook\', \'module=$pak1\', \'function=block_post_untie_hook\', \'version=$VERSION\') from dual",
         "select add_sys_hook(\'pkg=Genezzo::Row::RSFile\', \'hook=tie_block_post_hook\', \'replace=PostTie_Hook\', \'module=$pak1\', \'function=block_post_tie_hook\', \'version=$VERSION\') from dual",
         "select add_sys_hook(\'pkg=Genezzo::SpaceMan::SMExtent\', \'hook=smextent_usehooks\', \'replace=SMX_Use_Hook\', \'module=$pak1\', \'function=spaceman_smx_use_hook\', \'version=$VERSION\') from dual",
         ];

    for my $pfunc ('spacefixup', 'extent_fixup')
    {
        my %attr = (module => $pak1, 
                    function => "sql_func_" . $pfunc,
                    creationdate => $now,
                    argstyle => 'HASH',
                    sqlname => $pfunc);

        my @attr_list;
        while ( my ($kk, $vv) = each (%attr))
        {
            push @attr_list, '\'' . $kk . '=' . $vv . '\'';
        }

        my $bigstr = "select add_user_function(" . join(", ", @attr_list) .
            ") from dual";
        push @{$dml}, $bigstr;

    }

    # NOTE: run extent fixup once, then remove it from the function table

    my $bigstr = "select extent_fixup() from dual";
    push @{$dml}, $bigstr;
    $bigstr = "select drop_user_function(\'extent_fixup'\) from dual";
    push @{$dml}, $bigstr;
    $bigstr = "select spacefixup() from dual";
    push @{$dml}, $bigstr;


    $MAKEDEPS->{'DML'} = [
                          { check => ["select * from sys_hook where xname=\'$pak1\'"],
                            install => $dml }
                          ];

#    print Data::Dumper->Dump([$MAKEDEPS]);
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

    carp $args{msg}
        if warnings::enabled();
    
};

#our $SMH_SEV = 'info';
our $SMH_SEV = 'IGNORE';

sub MakeYML
{
    use Genezzo::Havok;

    my $makedp = $MAKEDEPS;

#    $makedp->{'UPDATED'}  = Genezzo::Dict::time_iso8601();

    return Genezzo::Havok::MakeYML($makedp);
}


# Genezzo::Block::RDBlock hook
our $Push_Hook;
sub block_push_hook
{
    my %args = @_;

    if (exists($args{self}))
    {
        my $sizediff = $args{sizediff} || 0;

        my $self = $args{self};

        # self might not be "blessed"...
        my $spaceleft = "?";
        if (ref($self) ne "HASH")
        {
            $spaceleft = (($self->_spacecheck()*100)/$self->{freespace});


            _track_usage($self, $sizediff);

        }

#        print "push $sizediff -- $spaceleft!!\n";

        my $smf = _get_rsfile_smf_from_mailbox($self);

    }

   # call the callback
    {
        if (defined($Push_Hook))
        {
            my $foo = $Push_Hook;
            return 0
                unless (&$foo(self => $args{self}));
        }
    }

    return 1;
    
}

# Genezzo::Block::RDBlock hook
our $Store_Hook;
sub block_store_hook
{
    my %args = @_;

    if (exists($args{self}))
    {
        my $sizediff = $args{sizediff} || 0;

        my $self = $args{self};

        # self might not be "blessed"...
        my $spaceleft = "?";
        if (ref($self) ne "HASH")
        {
            $spaceleft = (($self->_spacecheck()*100)/$self->{freespace});

            _track_usage($self, $sizediff);

        }

#        print "store $sizediff -- $spaceleft!!!!\n";

    }

   # call the callback
    {
        if (defined($Store_Hook))
        {
            my $foo = $Store_Hook;
            return 0
                unless (&$foo(self => $args{self}));
        }
    }

    return 1;

} # end block_store_hook

# Genezzo::Block::RDBlock hook
our $Delete_Hook;
sub block_delete_hook
{
    my %args = @_;

    if (exists($args{self}))
    {
        my $sizediff = $args{sizediff} || 0;

        my $self = $args{self};

        # self might not be "blessed"...
        my $spaceleft = "?";

        if (ref($self) ne "HASH")
        {
            $spaceleft = (($self->_spacecheck()*100)/$self->{freespace});

            _track_usage($self, $sizediff);
        }

#        print "delete $sizediff -- $spaceleft!!\n";

        if (0 && defined($self) && exists($self->{GZERR}))
        {
            my $err_cb = $self->{GZERR};
            &$err_cb(self => $self, severity => 'info',
                     msg => "delete!!");
        }
    }

   # call the callback
    {
        if (defined($Delete_Hook))
        {
            my $foo = $Delete_Hook;
            return 0
                unless (&$foo(self => $args{self}));
        }
    }

    return 1;

} # end block_delete_hook

sub _maybe_update_segment_header
{
    my %optional = (
                    filename => ""
                    );
    my %required = (
                    stat_list   => "no update extent header stat_list!",
                    hookee_self => "no hookee_self!",
                    blocknum    => "no blocknum!",
                    ext_hdr_block => "no extent header block!",
                    smf         => "no smf!",
                    rowd        => "no rowd!",
                    package_name => "no package name!"
                    );

    my %args = (%optional,
                @_);

    my $stat_list = $args{stat_list};
    my @stat;
    push @stat, @{$stat_list};

    my $hookee_self = $args{hookee_self};
    my $blocknum    = $args{blocknum};
    my $ext_hdr_block = $args{ext_hdr_block};
    my $smf         = $args{smf};
    my $rowd        = $args{rowd};
    my $pak1        = $args{package_name};

    my @outi;

    # check the status list from update_extent_header.  If it has
    # greater than three elements then the extent header update must
    # have freed a block, so we need to update the segment header

    unless (scalar(@stat) > 3) 
    {
        push @outi, "no_update";
        return @outi;
    }
    # need to update the segment header

    my ($orig_rowd, $seghdr, $extent_size, $bvec) = @stat;

    my $fnam = $args{filename};

    my @pct = $smf->_xhdr_bv_to_pct($bvec, $extent_size);

    my $extent_stats = shift @pct;
    my $avgpct   = $extent_stats->{avgpct};
    my $numempty = $extent_stats->{numempty};
    my $allocpct = $extent_stats->{allocpct};

    if ($seghdr == $blocknum)
    {
        # the current block is the segment header,
        # so update it now, before the untie

        my $msg =  "update seghdr - file $fnam, current block $blocknum\n";
        
        $msg .=  Data::Dumper->Dump([$extent_stats])  . "\n";
        
        my %earg = (self => $hookee_self, msg => $msg,
                    severity => $SMH_SEV);
        
        &$GZERR(%earg)
            if (defined($GZERR));

        my $xdsc = $smf->_make_extent_descriptor(
                                                 $ext_hdr_block,
                                                 $extent_size,
                                                 $avgpct,
                                                 $allocpct,
                                                 $numempty);
        my $update_stat = 
            $smf->_update_extent_in_segment_hdr(
                                                $rowd,
                                                $ext_hdr_block,
                                                $xdsc);
        push @outi, "updated", $update_stat;
    }
    else
    {
        # save the info needed to update the
        # segment header and use it post_untie

        my $msg = "update seghdr - file $fnam, need seghdr block $seghdr for extent $blocknum\n";
        
        my %earg = (self => $hookee_self, msg => $msg,
                    severity => $SMH_SEV);
        
        &$GZERR(%earg)
            if (defined($GZERR));
            
        $hookee_self->{Contrib}->{$pak1}->{blk_update_seg_hdr} =
        {
            seg_hdr_block => $seghdr,
            ext_hdr_block => $ext_hdr_block,
            extent_stats  => $extent_stats,
            extent_size   => $extent_size,
            bvec          => $bvec
        };

        push @outi, "deferred";
        
    }

    return @outi;

} # end maybe_update_segment_header

# Genezzo::Row::RSFile hook
our $PreUntie_Hook;
sub block_pre_untie_hook
{
    my %args = @_;

    if (exists($args{self}))
    {
        my $self = $args{self};

        # self might not be "blessed"...
        if (ref($self) ne "HASH")
        {
            goto L_nogood
                unless (exists($args{rowd}) && defined($args{rowd}));
            goto L_nogood
                unless (exists($args{blocknum}) && defined($args{blocknum}));

            my $rowd     = $args{rowd};
            my $blocknum = $args{blocknum};

            my $row = $rowd->_get_meta_row("XHP");

            goto L_nogood            
                unless (defined($row) && (scalar(@{$row}) > 1));

            my $posn    = $row->[0];
            my $pctused = $row->[1];

            my $pak1 = __PACKAGE__;        
            
            my $doUpdateExtentHeader = 0;

            if (exists($self->{Contrib}) &&
                exists($self->{Contrib}->{$pak1}) &&
                exists($self->{Contrib}->{$pak1}->{blk_pctused}))
            {
                # post_tie should have save the original block
                # pctusage in the Contrib hash.  If pctused has
                # changed, then we need to update the extent header.

                if ($self->{Contrib}->{$pak1}->{blk_pctused} != 
                    $pctused)
                {
#                    print "pctused updated to $pctused\n";
                    $doUpdateExtentHeader = 1;
                }
            }
            else
            {
#                print "no Contrib hash info for this package?\n";
                $doUpdateExtentHeader = 1;
            }

            # clean this out -- set it based upon status of extent
            # header update
            delete $self->{Contrib}->{$pak1}->{blk_update_seg_hdr};

            $pctused *= 10; # normalize to 100%

#            print "pre untie hook - $posn, $pctused\n";

            if (!$doUpdateExtentHeader)
            {
                # no change -- do nothing.  Delete the percent usage
                # and extent position info, since we don't need to
                # update the extent header in post_untie

                delete $self->{Contrib}->{$pak1}->{blk_pctused};
                delete $self->{Contrib}->{$pak1}->{blk_extent_position};
            }
            else
            {
                if ($posn != 0)
                {
                    # the current block is not the extent header, so
                    # we need to save percent usage and extent
                    # position info in order to update the extent
                    # header in post_untie
                    $self->{Contrib}->{$pak1}->{blk_pctused} =
                        $pctused;
                    $self->{Contrib}->{$pak1}->{blk_extent_position} = 
                        $posn;
                }
                else
                {
                    # the current block is at position zero in the
                    # extent, so it contains the header.  Update the
                    # extent header now, before the block gets untied

                    my $smf  = $self->_get_smf();
                    unless (defined($smf))
                    {
                        my $msg = "bad smf\n";
                        my %earg = (self => $self, msg => $msg,
                                    severity => 'warn');
        
                        &$GZERR(%earg)
                            if (defined($GZERR));

                        goto  L_nogood;
                    }

                    my @stat =
                        $smf->_update_extent_hdr(
                                                 $rowd,
                                                 $posn,
                                                 $pctused
                                                 );

                    # Since we just updated the extent header, clear
                    # the percent usage and extent position info -- we
                    # don't need to update the extent header again in
                    # post_untie

                    delete $self->{Contrib}->{$pak1}->{blk_pctused};
                    delete $self->{Contrib}->{$pak1}->{blk_extent_position};

                    # Now check if we need to update the segment
                    # header

                    my $fnam = "";
                    $fnam = $args{filename}
                    if (exists($args{filename}) && 
                        defined($args{filename}));

                    my @maybe_stat = 
                        _maybe_update_segment_header(
                                                     filename     => $fnam,
                                                     stat_list    => \@stat,
                                                     hookee_self  => $self,
                                                     blocknum     => $blocknum,
                                                    ext_hdr_block => $blocknum,
                                                     smf          => $smf,
                                                     rowd         => $rowd,
                                                     package_name => $pak1
                                                     );
                    if (scalar(@maybe_stat))
                    {
#                        if ($maybe_stat[0] !~ m/no_update/)
                        {
                            my $msg = 
                                "update segment header [pre]" . 
                                " ($fnam, $blocknum): " . 
                                $maybe_stat[0] . "\n";
                            my %earg = (self => $self, msg => $msg,
                                        severity => $SMH_SEV);
        
                            &$GZERR(%earg)
                                if (defined($GZERR));

                        }
                    }
                    else
                    {
                        my $msg = 
                        "update segment header [pre]" . 
                        " ($fnam, $blocknum) failed!\n";

                        # XXX XXX: warn? 
                        my %earg = (self => $self, msg => $msg,
                                    severity => $SMH_SEV);
        
                        &$GZERR(%earg)
                            if (defined($GZERR));

                    }
                    
                } # end if posn = 0
            }
          L_nogood:
        }

        if (0 && defined($self) && exists($self->{GZERR}))
        {
            my $err_cb = $self->{GZERR};
            &$err_cb(self => $self, severity => 'info',
                     msg => "pre_untie!!");
        }
    } # end if exists arg self

   # call the callback
    {
        if (defined($PreUntie_Hook))
        {
            my $foo = $PreUntie_Hook;
            return 0
                unless (&$foo(self => $args{self}));
        }
    }
    return 1;

} # end block_pre_untie_hook

# Genezzo::Row::RSFile hook
our $PostUntie_Hook;
sub block_post_untie_hook
{
    my %args = @_;

    if (exists($args{self}))
    {
        my $self = $args{self};

        # self might not be "blessed"...
        if (ref($self) ne "HASH")
        {
            my $pak1 = __PACKAGE__;        

            my ($posn, $pctused, $blocknum, $smf);

            my ($seg_hdr_block, $ext_hdr_block, $extent_stats, 
                $extent_size, $bvec);

            my $doUpdateExtentHeader = 0;

            if (exists($self->{Contrib}) &&
                exists($self->{Contrib}->{$pak1}))
            {
                if (
                    exists($self->{Contrib}->{$pak1}->{blk_pctused}) &&
                    exists($self->{Contrib}->{$pak1}->{blk_extent_position}))
                {
                    $pctused = $self->{Contrib}->{$pak1}->{blk_pctused};
                    $posn    = $self->{Contrib}->{$pak1}->{blk_extent_position};

                    $blocknum = $args{blocknum};
                
#                print "pctused updated to $pctused\n";
                    $doUpdateExtentHeader = 1;

                }

            }
#            $pctused *= 10; # normalize to 100%


            if ($doUpdateExtentHeader) 
            {
#                print "post untie hook - block $blocknum, $posn, $pctused\n";

                delete $self->{Contrib}->{$pak1}->{blk_pctused};
                delete $self->{Contrib}->{$pak1}->{blk_extent_position};

                my $smf  = $self->_get_smf();
                unless (defined($smf))
                {
                    my $msg = "bad smf\n";
                    my %earg = (self => $self, msg => $msg,
                                severity => 'warn');
                    
                    &$GZERR(%earg)
                        if (defined($GZERR));

                    goto  L_nogood;
                }

                my $rowd = $smf->_get_rowd($blocknum - $posn);
                unless (defined($rowd))
                {
                    my $msg = "bad rowd\n";
                    my %earg = (self => $self, msg => $msg,
                                severity => 'warn');
        
                    &$GZERR(%earg)
                        if (defined($GZERR));

                    goto  L_nogood;
                }

                my $row = $rowd->_get_meta_row("XHA"); 
                unless (defined($row) && (scalar(@{$row}) > 1))
                {
                    my $cnt = $rowd->HCount();

                    # NOTE: don't bother trying to update the XHA in
                    # an empty block -- this situation could arise
                    # when we clear the blocks for "DROP TABLE"

                    # XXX XXX: maybe should dump BlockInfoString? 
                    goto  L_nogood
                        unless ($cnt);

                    my $msg = "rowcount: $cnt\n";

                    my $bk = $blocknum - $posn;

                    $msg .= "bad XHA row for block $bk\n";

                    my %earg = (self => $self, msg => $msg,
                                severity => 'warn');
        
                    &$GZERR(%earg)
                        if (defined($GZERR));

                    goto  L_nogood;
                }

                my $seghdr = $row->[0];
                $bvec   = $row->[2];

                my $msg2 = "extent size: " .  $row->[1];
                $msg2 .=  ", bv: " .  unpack("b*",$bvec) . "\n";
                my @pct = $smf->_xhdr_bv_to_pct($bvec, $row->[1]);
                $extent_stats = shift @pct;
                my $avgpct   = $extent_stats->{avgpct};
                my $numempty = $extent_stats->{numempty};
                my $allocpct = $extent_stats->{allocpct};

                $msg2 .= join(", ", @pct) . " avg: $avgpct, empty: $numempty\n";
                my %earg = (self => $self, msg => $msg2,
                            severity => $SMH_SEV);
        
                &$GZERR(%earg)
                    if (defined($GZERR));

                my @stat;

                if ($posn != 0)
                {
                    @stat =
                        $smf->_update_extent_hdr(
                                                 $rowd,
                                                 $posn,
                                                 $pctused
                                                 );
                }
                $row = $rowd->_get_meta_row("XHA"); 
                unless (defined($row) && (scalar(@{$row}) > 1))
                {
                    my $msg = "bad row 2\n";
                    my %earg = (self => $self, msg => $msg,
                                severity => 'warn');
        
                    &$GZERR(%earg)
                        if (defined($GZERR));

                    goto  L_nogood;
                }
                $bvec = $row->[2];

                $msg2 = "extent size: " .  $row->[1];
                $msg2 .=  ", bv: " .  unpack("b*",$bvec) . "\n";

                @pct = $smf->_xhdr_bv_to_pct($bvec, $row->[1]);
                $extent_stats = shift @pct;
                my $new_avgpct   = $extent_stats->{avgpct};
                my $new_numempty = $extent_stats->{numempty};

                $msg2 .= join(", ", @pct) . " avg: $avgpct, empty: $numempty\n";
                %earg = (self => $self, msg => $msg2,
                         severity => $SMH_SEV);
        
                &$GZERR(%earg)
                    if (defined($GZERR));

                    
                # Now check if we need to update the segment
                # header

                my $fnam = "";
                $fnam = $args{filename}
                  if (exists($args{filename}) && 
                      defined($args{filename}));

                my @maybe_stat = 
                    _maybe_update_segment_header(
                                                 filename     => $fnam,
                                                 stat_list    => \@stat,
                                                 hookee_self  => $self,
                                                 blocknum     => $blocknum,
                                                 ext_hdr_block => $blocknum,
                                                 smf          => $smf,
                                                 rowd         => $rowd,
                                                 package_name => $pak1
                                                 );
                if (scalar(@maybe_stat))
                {
#                        if ($maybe_stat[0] !~ m/no_update/)
                    {
                        my $msg = 
                            "update segment header [post]" .
                            " ($fnam, $blocknum): " . 
                            $maybe_stat[0] . "\n";

                        my %earg = (self => $self, msg => $msg,
                                    severity => $SMH_SEV);
        
                        &$GZERR(%earg)
                            if (defined($GZERR));
                    }
                    if ($maybe_stat[0] !~ m/updated/)
                    {
                        delete $self->{Contrib}->{$pak1}->{blk_update_seg_hdr};
                    }
                }
                else
                {
                    my $msg = 
                        "update segment header [post]" .
                        " ($fnam, $blocknum) failed!\n";

                    # XXX XXX: warn? 
                    my %earg = (self => $self, msg => $msg,
                                severity => $SMH_SEV);
        
                    &$GZERR(%earg)
                        if (defined($GZERR));
                }

          L_nogood:
            } # end if doupdateextentheader

            # update extent header if necessary
            if (exists($self->{Contrib}) &&
                exists($self->{Contrib}->{$pak1}))
            {

                if (exists($self->{Contrib}->{$pak1}->{blk_update_seg_hdr}))
                {
                    my $up_seg_hsh = $self->{Contrib}->{$pak1}->{blk_update_seg_hdr};
                    $seg_hdr_block = $up_seg_hsh->{seg_hdr_block};
                    $ext_hdr_block = $up_seg_hsh->{ext_hdr_block};
                    $extent_stats  = $up_seg_hsh->{extent_stats};
                    $extent_size   = $up_seg_hsh->{extent_size};
                    $bvec          = $up_seg_hsh->{bvec};
                }
                else
                {
                    goto L_no_update_seghdr;
                }

                my $smf  = $self->_get_smf();
                unless (defined($smf))
                {
                    my $msg = "bad smf\n";
                    my %earg = (self => $self, msg => $msg,
                                severity => 'warn');
        
                    &$GZERR(%earg)
                        if (defined($GZERR));

                    goto L_no_update_seghdr;
                }

                my $rowd = $smf->_get_rowd($seg_hdr_block);
                unless (defined($rowd))
                {
                    my $msg = "bad rowd\n";
                    my %earg = (self => $self, msg => $msg,
                                severity => 'warn');
        
                    &$GZERR(%earg)
                        if (defined($GZERR));


                    goto L_no_update_seghdr;
                }

                my $msg2 = "last try to update seg hdr!!\n";

                my %earg = (self => $self, msg => $msg2,
                            severity => $SMH_SEV);
        
                &$GZERR(%earg)
                    if (defined($GZERR));

                # XXX XXX: build a fake stat structure like
                # update_extend_header
                my @stat_list = ($rowd, $seg_hdr_block, $extent_size, $bvec);

                my @maybe_stat = 
                    _maybe_update_segment_header(
                                                 filename     => "",
                                                 stat_list    => \@stat_list,
                                                 hookee_self  => $self,
                                                 blocknum     => $seg_hdr_block,
                                                 ext_hdr_block => $ext_hdr_block,
                                                 smf          => $smf,
                                                 rowd         => $rowd,
                                                 package_name => $pak1
                                                 );
                if (scalar(@maybe_stat))
                {
#                        if ($maybe_stat[0] !~ m/no_update/)
                    {
                        my $msg = 
                            "update segment header [post2]" .
                            " (?, $seg_hdr_block): " . 
                            $maybe_stat[0] . "\n";

                        my %earg = (self => $self, msg => $msg,
                                    severity => $SMH_SEV);
        
                        &$GZERR(%earg)
                            if (defined($GZERR));
                    }
                    if ($maybe_stat[0] !~ m/updated/)
                    {
                        delete $self->{Contrib}->{$pak1}->{blk_update_seg_hdr};
                    }
                }
                else
                {
                    my $msg = 
                        "update segment header [post2]" .
                        " (?, $seg_hdr_block) failed!\n";

                    # XXX XXX: warn? 
                    my %earg = (self => $self, msg => $msg,
                                severity => $SMH_SEV);
        
                    &$GZERR(%earg)
                        if (defined($GZERR));
                }
                
          L_no_update_seghdr:
            } # end if exists contrib


            my $rowd = $smf->_get_rowd(0)
                if (defined($smf));
        } # end if self ne hash...

        if (0 && defined($self) && exists($self->{GZERR}))
        {
            my $err_cb = $self->{GZERR};
            &$err_cb(self => $self, severity => 'info',
                     msg => "post_untie!!");
        }
    }


   # call the callback
    {
        if (defined($PostUntie_Hook))
        {
            my $foo = $PostUntie_Hook;
            return 0
                unless (&$foo(self => $args{self}));
        }
    }

    return 1;

} # end block_post_untie_hook


# Genezzo::Row::RSFile hook
our $PostTie_Hook;
sub block_post_tie_hook
{
    my %args = @_;

    if (exists($args{self}))
    {
        my $self = $args{self};

        if (exists($args{rowd}) && defined($args{rowd}))
        {
            my $rowd = $args{rowd};
            my $row = $rowd->_get_meta_row("XHP");        

            # some assumptions: the RSFile post tie hook gives us a
            # valid RSFile "self" and RDBlock rowd.  The block
            # contains the XHP (eXtent Header Position) metadata,
            # which is the offset in the extent (position 0 to N-1)
            # and the percent used.  
            #
            # Only a single block is tied for the current RSFile object.

            if ($row && (scalar(@{$row}) > 1))
            {
                my $pak1 = __PACKAGE__;        

                # immediately after we tie this block, save its
                # current extent position and percent usage
                # information.  If the pct used changes by the time we
                # are ready to untie this block (pre_untie), we may
                # need to update the extent header (in pre or post untie).

                $self->{Contrib}->{$pak1}->{blk_extent_position} = $row->[0];
                $self->{Contrib}->{$pak1}->{blk_pctused}         = $row->[1];
            }
        

        }
        if (0 && defined($self) && exists($self->{GZERR}))
        {
            my $err_cb = $self->{GZERR};
            &$err_cb(self => $self, severity => 'info',
                     msg => "post_tie!!");
        }
    }

   # call the callback
    {
        if (defined($PostTie_Hook))
        {
            my $foo = $PostTie_Hook;
            return 0
                unless (&$foo(self => $args{self}));
        }
    }

    return 1;

} # end block_post_tie_hook

# Genezzo::SpaceMan::SMExtent hook
our $SMX_Use_Hook;
sub spaceman_smx_use_hook
{
    my %args = @_;

    return 1;
}

sub _track_usage
{
    my ($rdblock, $sizediff) = @_;

    return -1
        if ($sizediff == 0);

    my $spaceleft = (($rdblock->_spacecheck()*100)/$rdblock->{freespace});

    my $row = $rdblock->_get_meta_row("XHP");

    return undef
        unless (defined($row) && (scalar($row) > 1));
            
    my $pctused = 0;
    $pctused = $row->[1];
            
    my $new_pctused = -1;

    if ($sizediff)
    {
        if ($spaceleft < 10)
        {
            if ($pctused != 9)
            {
                $new_pctused = 9;
            }
        }
        elsif (($spaceleft >= 10) && ($spaceleft < 30))
        {
            if ($pctused != 6)
            {
                $new_pctused = 6;                    
            }

        }
        elsif (($spaceleft >= 30) && ($spaceleft < 60))
        {
            if ($pctused != 3)
            {
                $new_pctused = 3;                    
            }

        }
        else
        {
            if ($pctused != 0) ### ?
            {
                $new_pctused = 0;
            }
        }
    }
    if ($new_pctused != -1)
    {
        my $msg = "update pctused -- was $pctused" .
            "0, now $new_pctused" . "0\n";

        # XXX XXX: NOTE: no $self !!!
#        my %earg = (self => $rdblock, msg => $msg,
        my %earg = ( msg => $msg,
                    severity => $SMH_SEV);
        
        &$GZERR(%earg)
            if (defined($GZERR));


        $row->[1] = $new_pctused;

        $rdblock->_set_meta_row("XHP", $row);
    }

    return $new_pctused;
}

sub _get_rsfile_smf_from_mailbox
{
    my $rdblock_self = shift;

    return undef
        unless (defined($rdblock_self));

    # check for a mailbox
    if (exists($rdblock_self->{Contrib})
        && exists($rdblock_self->{Contrib}->{mailbox}))
    {
        my $rdblock_mailbox = $rdblock_self->{Contrib}->{mailbox};

        # check for listing for RSFile
        if (exists($rdblock_mailbox->{'Genezzo::Row::RSFile'})
            && exists($rdblock_mailbox->{'Genezzo::Row::RSFile'}->{self}))
        {
            my $rsfile_self = 
                $rdblock_mailbox->{'Genezzo::Row::RSFile'}->{self};
     
            # get the space management object
            return $rsfile_self->_get_smf();
   
        }
    }
    return undef;

}

# In block zero of the file, SMFile tracks the current block in the
# current extent, but SMExtent always marks its extents as full, which
# serves several purposes: 
#  1.  Since SMExtent manages the contents of its own extents, SMFile
#      shouldn't ever try to manage them.  If the extent is "full"
#      SMFile will just get a new one.
#  2.  If we fallback to SMFile space management from SMExtent,
#      everything will work correctly.  We may waste some space
#      because the extent could have free blocks, but SMFile cannot
#      correctly manage non-sequential free blocks anyway.
sub sql_func_extent_fixup
{
    my %args= @_;

    my $dict = $args{dict};
    my $dbh  = $args{dbh};
    my $fn_args = $args{function_args};

    if (1)
    {
        my $tsf   =  $dict->_get_table(tname => "_tsfiles");

        return 0
            unless  (defined($tsf));

        return 0
            unless (exists($dict->{tablespaces}->{SYSTEM}));

        my $ts1 = $dict->{tablespaces}->{SYSTEM};

        return 0
            unless (exists($ts1->{tsref})
                    && exists($ts1->{tsref}->{the_ts})
                    && exists($ts1->{tsref}->{the_ts}->{bc}));

        my $bc1 = $ts1->{tsref}->{the_ts}->{bc};

        while (my ($kk, $vv) = each (%{$tsf}))
        {
            my $getcol  = $dict->_get_col_hash("_tsfiles");
            my $fsize   = $vv->[$getcol->{filesize}];
            my $blksize = $vv->[$getcol->{blocksize}];
            my $filenum = $vv->[$getcol->{fileidx}];
            my $numblks = $vv->[$getcol->{numblocks}];

            my $fhts;     # gnz_home table space

	    if(getUseRaw()){
		$fhts = $dict->{gnz_home};
	    }else{
                $fhts = File::Spec->catdir($dict->{gnz_home}, "ts");
	    }

            my $fnam1   = $vv->[$getcol->{filename}];

            my $fname   = 
                File::Spec->file_name_is_absolute($fnam1) ?
                $fnam1 : 
                File::Spec->rel2abs(
                                    File::Spec->catfile(
                                                        $fhts,
                                                        $fnam1
                                                        ));

#            print "\n$fname\n";

            my $smf = Genezzo::SpaceMan::SMFile->new($fname,
                                                     $fsize,
                                                     $numblks,
                                                     $bc1,
                                                     $filenum);

            if (defined($smf))
            {
#                $smf->dump();

                # call SMFile method to iterate over all objects for
                # the datafile and mark current extent as full.
                $smf->_extent_fixup_mark_full();
#                $smf->dump();
            }

        } # end while

        return 1;
    }
    return 0;
} # end extent_fixup

sub _spacefixup_table
{
    my ($dict, $tname) = @_;

    my $hashi  = $dict->DictTableGetTable (tname => $tname);

    return 0
        unless (defined($hashi));

    my $tv = tied(%{$hashi});
        
    my $blockno = $tv->First_Blockno();

    while ($blockno)
    {
        my %earg = ( msg => "$blockno",
                    severity => $SMH_SEV);
        
        &$GZERR(%earg)
            if (defined($GZERR));

        # XXX XXX: cannot use joinrid because is redefined for RSTab
#            my $blk_place = $tv->_joinrid($blockno, 0);
        my $blk_place = join ($Genezzo::PushHash::hph::RIDSEP, 
                              $blockno, 0);
            
        {
            my ($blktie, $block_num, $bceref, $href_tie) = 
                $tv->_get_block_and_bce($blk_place);

            $blktie->_set_meta_row('FIX',['UP']);
            $blktie->_delete_meta_row('FIX');
        }

        $blockno = $tv->Next_Blockno($blockno);
    }
    
    return 1;
}

sub sql_func_spacefixup
{
    my %args= @_;

    my $dict = $args{dict};
    my $dbh  = $args{dbh};
    my $fn_args = $args{function_args};

    if (scalar(@{$fn_args}) > 0)
    {
        my $tname = $fn_args->[0];

        return _spacefixup_table($dict, $tname);
    }
    else
    {
        # spacefixup all tables

        my $sth;
        $sth = $dbh->prepare(
                    "select tname from _tab1 where object_type = \'TABLE\'");

        return 0
            unless ($sth->execute());

        my @ggg = $sth->fetchrow_array();
    
        while (scalar(@ggg))
        {
             my $tname = ($ggg[0]);
             my %earg = ( msg => "$tname",
                          severity => $SMH_SEV);
             
             &$GZERR(%earg)
                 if (defined($GZERR));

             _spacefixup_table($dict, $tname);
             @ggg = $sth->fetchrow_array();
        }
    }

    return 1;

} # end spacefixup


1;  # don't forget to return a true value from the file

__END__

=head1 NAME

Genezzo::SpaceMan::SMExtent.pm - Extent Space Management

=head1 SYNOPSIS


=head1 DESCRIPTION

This module contains the space management hooks for
L<Genezzo::Block::RDBlock> basic block operations.  Any
insert/update/delete operation which modifies a block might change the
space usage.  All minor changes are reflected in the local block
XHP (eXtent Header Position) record.  Any changes greater than ~30%
are reflected in the extent header XHA (eXtent Header _A_), which has
a bitvec to track every block in the extent.  Larger changes must
propagate to the segment header (or subheader) X1A (eXtent FIRST _A_),
which tracks space usage for every extent in the segment.

Space management must balance efficient space usage against update
costs/concurrency issues.  Frequently updating the extent headers and
segment headers provides more accurate information on actual block
usage, but these blocks become a point of contention when multiple
updates are running simultaneously.  If the extent and segment headers
are updated infrequently, space managment might allocate new extents
unnecessarily because it doesn't know that free space is still
available, or worst-case, it may attempt to re-use blocks which are
already full.  The basic pushhash (see L<Genezzo::PushHash::hph>
routines are designed to be robust if an operation runs out of space,
so this situation is not insurmountable.

Need hooks to update segment header.  Allocating space without
updating the segment header is fine, since the operation to obtain new
free blocks can view the list of extents with free blocks in the segment
header, and then it can probe the extent headers to check if space is
still available.  The converse problem is that deletes may free up
blocks or even entire extents, and this information must get back to
the segment header so it knows that space is available.  At minimum,
an operation which causes an extent to transition from full to at
least one block free should update the segment header.

=head1 FUNCTIONS

=over 4

=item _track_usage

update local block XHP (eXtent Header Position) with new percent used

=item block_push_hook

call track_usage to update after new row pushed in block

=item block_store_hook

call track_usage to update after new row stored in block

=item block_delete_hook

call track_usage to update after row deleted from block

=item block_pre_untie_hook

if current block is the extent header, update now, else setup Contrib
data structs to pass usage info to post_untie

=item block_post_untie_hook

use the usage info from pre_untie to update the extent header

=item block_post_tie_hook

store the initial usage info for the block.  block_pre_untie_hook will
compare the current usage with the previous in order to determine
whether the extent header update is necessary.

=back


=head2 EXPORT

=head1 TODO

=over 4

=item  better error handling

=item  better error handling

=back


=head1 AUTHOR

Jeffrey I. Cohen, jcohen@genezzo.com

=head1 SEE ALSO

L<Genezzo::Block::RDBlock>, perl(1).

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
