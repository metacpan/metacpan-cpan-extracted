#!/usr/bin/perl
#
# $Header: /Users/claude/fuzz/lib/Genezzo/Index/RCS/bt2.pm,v 7.1 2005/07/19 07:49:03 claude Exp claude $
#
# copyright (c) 2003, 2004 Jeffrey I Cohen, all rights reserved, worldwide
#
#
use strict;
use warnings;

package Genezzo::Index::bt2;

use Genezzo::Util;
use Genezzo::Block::Std;
use Genezzo::Block::RowDir;
use Genezzo::PushHash::PushHash;
use Genezzo::Block::RDBlk_NN;
use Genezzo::Block::RDBlkA;
use Genezzo::Block::RDBArray;
use Genezzo::BufCa::BufCa;
use Carp;
use warnings::register;

BEGIN {
    use Exporter   ();
    our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

    # set the version for version checking
#    $VERSION     = 1.00;
    # if using RCS/CVS, this may be preferred
    $VERSION = do { my @r = (q$Revision: 7.1 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r }; # must be all one line, for MakeMaker

    @ISA         = qw(Exporter);
    @EXPORT      = ();

    %EXPORT_TAGS = ();     # eg: TAG => [ qw!name1 name2! ],

    # your exported package globals go here,
    # as well as any optionally exported functions
    @EXPORT_OK   = qw($bt2numcmp $bt2strcmp
                      $bt2numeq $bt2streq);
    
};

BEGIN {

    # Use Greg Bacon's design for array-based objects as demonstrated
    # in Mark Rogaski's <wendigo> Tree::Ternary
    #
    # Left, right, and nodeid are the only ones that will be used in
    # every node, the others will only be defined in the leftmost
    # (original root).  
    #
    # left, right: immediate left and right siblings
    #
    # leftmost node (original root) holds height, (current) root
    # nodeid, and rightmost nodeid

    my @ATTRIBUTES = qw(
                        A_LEFT
                        A_RIGHT
                        A_NODEID

                        A_HEIGHT
                        A_ROOT
                        A_RIGHTMOST
    );

    # (from Tree::Ternary)
    # Construct the code to declare our constants, execute, and check for
    # errors (this was so much simpler in Pascal!)
    #
    my $attrcode = join "\n",
			map qq[ sub $ATTRIBUTES[$_] () { $_ } ],
			0..$#ATTRIBUTES;

    eval $attrcode;

    if ($@) {
    	require Carp;
    	Carp::croak("Failed to initialize module index: $@\n");
    }

    sub attrname {
        return undef
            unless (scalar(@_));
        return undef
            if (($_[0] !~ /\d+/) || ($_[0] > $#ATTRIBUTES));
        return $ATTRIBUTES[$_[0]];
    }
};


# basic numeric and string comparison functions

our $bt2numcmp = sub
{
    return ($_[0] < $_[1]);
};

our $bt2numeq = sub
{
    return ($_[0] == $_[1]);
};

our $bt2strcmp = sub
{
    return ($_[0] lt $_[1]);
};

our $bt2streq = sub
{
    return ($_[0] eq $_[1]);
};

# Packing/UnPacking functions: 

# pr1 - single scalar key, single scalar value
our $pr1  = sub { return PackRow(@_); } ;
our $upr1 = sub { return UnPackRow(@_, $Genezzo::Util::UNPACK_TEMPL_ARR); } ; 

# pr2 - array key, single scalar value
our $pr2  = sub { 
    my @k1;
    push @k1, @{$_[0]->[0]}; # get key portion
    push @k1, $_[0]->[1];    # get value
 #   greet @k1;
    return PackRow(\@k1); 
} ;
our $upr2 = sub { 
    my @a1 = UnPackRow(@_, $Genezzo::Util::UNPACK_TEMPL_ARR); 
    my @entry;
#    greet @a1;
    $entry[1] = pop @a1; # remove value from end
    $entry[0] = \@a1;    # key in remainder of array
#    greet @entry;
    return @entry;
} ; 

# pr3 - single scalar key, array value
our $pr3  = sub { 
#    greet "pr3";
    my @k1;
    push @k1, $_[0]->[0];     # get key portion
    push @k1, @{$_[0]->[1]};  # get value

#    greet @k1;
    return PackRow(\@k1); 
} ;
our $upr3 = sub {
#    greet "upr3"; 
    my @a1 = UnPackRow(@_, $Genezzo::Util::UNPACK_TEMPL_ARR); 
    my @entry;
#    greet @a1;
    $entry[0] = shift @a1;  # key in front of array
    $entry[1] = \@a1;       # value in remainder of array
#    greet @entry;
    return @entry;
} ; 

# pr4 - array key of specified length, variable values
our $pr4  = sub { 
    my @k1;
    push @k1, @{$_[0]->[0]}; # get key portion
    push @k1, $_[0]->[1]     # get value
        if (defined($_[0]->[1]));
#    greet @k1;
    return PackRow(\@k1); 
} ;
our $upr4 = sub { 
    my @args = @_;
    # XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX
    # NOTE: keycount is first argument
    # XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX
    my $keycount = shift @args;
    my @a1 = UnPackRow(@args, $Genezzo::Util::UNPACK_TEMPL_ARR); 
    my @entry;
#    greet @a1;
    # extract key vector of size keycount - remainder is value array
    my $numelts = scalar(@a1);

    if ($numelts == $keycount)
    {
        $entry[0] = \@a1;    # key is entire array
        $entry[1] = $a1[-1]; # value is last part of key column
    }
    elsif ($numelts == ($keycount + 1))
    {
        $entry[1] = pop @a1; # remove value from end
        $entry[0] = \@a1;    # key in remainder of array
    }
    else
    {
        # splice off the key portion
        my @kk = splice(@a1, 0, $keycount);
        $entry[0] = \@kk;    # key
        $entry[1] = \@a1;    # value is an array
    }
#    greet @entry;
    return @entry;
} ; 


=head1 _build_cmp_and_eq

construct comparison/equality callbacks 

    my $cmp1 = sub 
    {
        my ($k1, $k2) = @_;

        # NOTE: use "spaceship" (-1,0,1) comparison with 
        # short-circuit OR (which returns 0 or VALUE, not 0 or 1) 
        # to perform multi-column key comparison 
        # a la Schwartzian Transform

        return (
                (   ($k1->[0] <=> $k2->[0])
                 || ($k1->[1] <=> $k2->[1])) == -1
                );
    };

    my $eq1 = sub 
    {
        my ($k1, $k2) = @_;
        return (($k1->[0] == $k2->[0]) 
                && ($k1->[1] == $k2->[1]) 
                );
    };

=cut

# XXX: note - not a class or instance method
sub _build_cmp_and_eq
{
    my $keyvec = shift @_;

    my $lastcol = (scalar(@{$keyvec}) - 1);

    my ($eq_expr, $cmp_expr) = ('(', '((');

    for my $i (0..$lastcol)
    {
        unless (0 == $i)
        {
            $eq_expr  .= ' && ';
            $cmp_expr .= ' || ';
        }
        my $ix = $i . ']';
        my $k1 = '$k1->[' . $ix;
        my $k2 = '$k2->[' . $ix;
        my ($eq_op, $cmp_op) = 
            ($keyvec->[$i] =~ m/n/) ? (' == ', ' <=> ') : (' eq ', ' cmp ');

        $eq_expr  .= '('  . $k1 . $eq_op  . $k2 . ')';
        $cmp_expr .= '('  . $k1 . $cmp_op . $k2 . ')';

    }
    $eq_expr  .= ')';
    $cmp_expr .= ') == -1)';

    my ($eq1, $cmp1);


    my $eq_sub = '$eq1 = sub {my ($k1, $k2) = @_; ';
#    if (1 && !$Genezzo::Util::QUIETWHISPER)
#    {
#        $eq_sub .= 'greet $k1, $k2; ';
#    }
    $eq_sub .= 'return (' . $eq_expr . ');};';

#    greet $eq_sub;
    eval $eq_sub;
    if ($@)
    {
        whisper "failed to evaluate $eq_sub";
        return undef;
    }

    my $cmp_sub = '$cmp1 = sub {my ($k1, $k2) = @_; ';
#    if (1 && !$Genezzo::Util::QUIETWHISPER)
#    {
#        $cmp_sub .= 'greet $k1, $k2; ';            
#    }
    $cmp_sub .= 'return (' . $cmp_expr . ');};';

#    greet $cmp_sub;
    eval $cmp_sub;
    if ($@)
    {
        whisper "failed to evaluate $cmp_sub";
        return undef;
    }

    return ($eq1, $cmp1);
} # end build cmp and eq

sub new
{ #sub new 
#    greet @_;
#    whoami;
    my $invocant = shift;
    my $class = ref($invocant) || $invocant ; 
    my $self = { };

#    my $self->{root} = ();
    my %optional = (maxsize => 50, numblocks => 100, 
                    blocksize => $Genezzo::Block::Std::DEFBLOCKSIZE,
                    compare => $bt2strcmp, equal => $bt2streq,
                    pack_fn => $pr1, unpack_fn => $upr1,
                    use_IOT => 0,
                    unique_key => 0,
                    );
    my %args = (%optional,
                @_);
    $self->{maxsize}    = $args{maxsize};
    $self->{blocksize}  = $args{blocksize};
    # XXX XXX: max key len at 1/3 blocksize, need at least 2 keys per block
    $self->{maxkeysize} = $args{blocksize} / 3;
    $self->{maxblockno} = $args{numblocks};

    # NOTE: index-organized tables have an array of values, versus a
    # single value.  Need to make distinction for case of link entries
    # (single val) in branch versus branch entries (array val)
    $self->{use_IOT}    = $args{use_IOT}; # XXX XXX: needed for makenodeentry

    if (exists($args{key_type}))
    {
        my $ktype = $args{key_type};
#        greet $ktype;

        if (ref($args{key_type}))
        {
            my $ref_type = ref($args{key_type});
#            greet $ref_type;

            if ($ref_type ne "ARRAY")
            {
                whisper "no packing function for $ref_type";
                return 0;
            }

            my $use_keycount = 0;

            if ($args{use_keycount})
            {
                # special packing/unpacking for case of multiple keys,
                # variable number [ 0..n ] of values.
                $self->{keycount} = scalar(@{$ktype});
                $use_keycount = 1;
            }
            else
            {
                $self->{keycount} = 0;
            }

            if ($self->{use_IOT})
            {
                whisper "no packing function for IOT with array key";
                return 0;
            }

            # construct callbacks for comparison, equality
            my @foo = _build_cmp_and_eq($ktype);
            return 0
                unless (scalar(@foo) == 2);

            my ($eq1, $cmp1) = @foo;
                

            if ($use_keycount)
            {
                # packing function takes keycount
                $self->{pack_fn}    = $pr4;
                $self->{unpack_fn}  = $upr4;
            }
            else
            {
                # array key, single scalar value
                $self->{pack_fn}    = $pr2;
                $self->{unpack_fn}  = $upr2;
            }

            $self->{compare}    = $cmp1;
            $self->{equal}      = $eq1;

        }
        else # either char or numeric scalar key
        {
            unless ($ktype =~ m/^(c|n)$/)
            {
                whisper "unknown key type $ktype";
                return 0;
            }
            if ($self->{use_IOT})
            { # single scalar key, array value
                $self->{pack_fn}    = $pr3;
                $self->{unpack_fn}  = $upr3;
            }
            else
            { # single scalar key, single scalar value
                $self->{pack_fn}    = $pr1;
                $self->{unpack_fn}  = $upr1;
            }

            ($self->{compare}, $self->{equal})  = 
                ($ktype =~ m/^n$/) ? 
                ($bt2numcmp, $bt2numeq) 
                : ($bt2strcmp, $bt2streq);
        }
        
    }
    else # no key_type specified - 
         # get packing and comparison functions from @args
    {
        $self->{pack_fn}    = $args{pack_fn};
        $self->{unpack_fn}  = $args{unpack_fn};

        $self->{compare}    = $args{compare};
        $self->{equal}      = $args{equal};
    }

    # force uniqueness via a check at insert time.  Should have no
    # duplicates in leaves or branches.  Calling searchR at height
    # zero in insertR should be okay, since the recursive calling
    # convention is identical at the branch level for both functions.
    $self->{unique_key} = $args{unique_key};

#    whoami %args;

    return undef
        unless _more_init($self, %args);

    return bless $self, $class;

} # end new

sub _more_init
{
    my $self = shift;

    $self->{maxnodeid} = 0;
    $self->{blocknum}  = 0;

    if ($self->{maxblockno})
    {

        # don't create a buffer cache if numblocks = 0 
        # (Note: need a new getarr and make_new_block methods in
        # subclass if no bc created...)
        $self->{bc} = 
            Genezzo::BufCa::BufCa->new(blocksize => $self->{blocksize}, 
                                    numblocks => $self->{maxblockno});

        return 0
            unless (defined($self->{bc}));
    }

#    $self->{maxblockno} = -1;

    $self->{statistics}  = {
        count         => 0, 
        lastkey_count => 0,
        last_was_last => 0,
        keysize       => {max => 0, min => 0}
            
        };
    return 1;
}

sub stats
{
    my $self = shift;
    my %stats;

    $stats{count}         = $self->{statistics}->{count};
    $stats{lastkey_count} = $self->{statistics}->{lastkey_count};
    $stats{keysize}       = $self->{statistics}->{keysize};
    $stats{makeysize}     = $self->{maxkeysize};
    
    $stats{height}        = $self->{height};
    $stats{nodecount}     = $self->{maxnodeid};

    return %stats;

}

sub _pack_row
{
    my $self = shift;

    # packs an "entry", which is a reference to a 2 element array, a
    # key/value or key/link pair.  key and value can be scalars or
    # vectors -- it is the responsiblity of the packing function to
    # convert them to a byte string.

    my $p1 = $self->{pack_fn};

    return &$p1(@_);

    # returns a byte string - flattened row

}
sub _unpack_row
{
    my $self = shift;

    # unpacks a byte string and returns an array.  Callers assume the
    # array is a two element key/value or key/link pair, which is
    # identical the output of makenodeentry.

    my $up1 = $self->{unpack_fn};

    return &$up1($self->{keycount}, @_)
        if ($self->{keycount});

    return &$up1(@_);
}

sub _make_new_block
{
    my $self = shift;

#    whoami;

    my $blocknum = $self->{blocknum};
    $self->{blocknum} += 1;
    $self->{maxnodeid} += 1;

    return $blocknum;
}

sub _getarr
{
    my ($self, $blocknum) = @_;
    my @outi;

    my $bceref   = $self->{bc}->ReadBlock(blocknum => $blocknum);
 
    push @outi, $bceref; # block stays pinned as long as bceref is in scope

    # obtain the actual Buffer Cache Element
    my $bce = $$bceref;
     
    local $Genezzo::Block::Std::DEFBLOCKSIZE = $self->{blocksize};
    my $buff = $bce->{bigbuf};
    
    my %h1;
    
    my $blockclass = "Genezzo::Block::RDBlkA";
#    my $blockclass = "Genezzo::Block::RDBlk_NN";
    # tie a hash using the buffer
    my $tie_thing = tie %h1, $blockclass, (refbufstr => $buff,
                                           pctfree => 0,);

    # XXX XXX XXX: should be able to use pctfree=0, but get some
    # errors in Index1.t; Not sure if the broken code is in bt2 or
    # rdblock...

    my @a1;

    # tie an array using the rdblka tied hash
    my %args1 = (RDBlockHash => $tie_thing, RDBlock_Class => $blockclass);
    my $t2 = tie @a1, "Genezzo::Block::RDBArray", %args1;

    push @outi, $tie_thing;
    push @outi, \%h1;

    # return the tied array first, then the bceref, then the tied hash
    unshift @outi, \@a1;

    return @outi;
}

sub _makenode
{
    my $self = shift;
    my %optional = (height => 0
                    );
    my %args = (%optional,
                @_);

    # at height zero check if enough space to handle splits at every
    # level
    unless ($args{height})
    {
        return undef
            unless $self->_spacecheck($self->{height});
    }

    # build the metadata:
    #          left,  right, nodeid
    my @foo = ('',     '',    $self->{maxnodeid});

    my $blocknum = $self->_make_new_block();

    # store metadata in buffer
    my ($currarr, $curr_bce, $curr_ph)  = $self->_getarr($blocknum);    

    $self->_SetMeta($curr_ph,\@foo);

    return $blocknum;
}

sub _makenodeentry
{
    my $self = shift;
# %optional,
    my %args = ( 
                @_);
    # key, link|value

#    greet %args;

    return undef
        unless (exists($args{key}));

    if (exists($args{value}))
    {
        my @outi = ($args{key}, $args{value});
        return \@outi;
    }
    elsif (exists($args{link}))
    {
        # convert link to array (to match value array) for IOT case
        # so packing/unpacking functions can work correctly
        my $link1 = ($self->{use_IOT}) ? [$args{link}] : $args{link};

        my @outi = ($args{key}, $link1);
        return \@outi;
    }
    # XXX XXX XXX : else value TBD - callback fn
    return undef;
}

my %ins_stat = (
                ins_fail   => "insert failed",
                split_ok   => "insert failed, but split okay",
                split_fail =>   "insert okay, but split failed",
                no_joy     => "failed badly"
                );

sub _setMainMeta
{
    my $self = shift;

    my ($lftmost_arr, $lftmost_bce, $lftmost_ph) = 
        $self->_getarr($self->{leftmost});

    my @lftmost_meta1 = $self->_GetMeta($lftmost_ph);
    
#    greet @lftmost_meta1;

    $lftmost_meta1[A_HEIGHT]    =  $self->{height};
    $lftmost_meta1[A_ROOT]      =  $self->{root};
    $lftmost_meta1[A_RIGHTMOST] =  $self->{rightmost};

#    greet @lftmost_meta1;

    return ($self->_SetMeta($lftmost_ph,\@lftmost_meta1));
}

sub _getMainMeta
{
    my ($self, $blocknum) = @_;

    my ($lftmost_arr, $lftmost_bce, $lftmost_ph) = 
        $self->_getarr($blocknum);

    my @lftmost_meta1 = $self->_GetMeta($lftmost_ph);
    
#    greet @lftmost_meta1;

    $self->{leftmost}  = $blocknum;

    $self->{height}    = $lftmost_meta1[A_HEIGHT];
    $self->{root}      = $lftmost_meta1[A_ROOT];
    $self->{rightmost} = $lftmost_meta1[A_RIGHTMOST];

#    greet @lftmost_meta1;

    return (1);
}

sub insert
{
    my ($self, $key, $val, $val_TBD_callback) = @_;

    my $entry = $self->_makenodeentry(key => $key, value => $val); 

    # XXX XXX: use pack_row to invoke val TBD callback, so skip length
    # check until hit insertR for this case

    my $keysize = length($self->_pack_row($entry));

    unless ($keysize < $self->{maxkeysize})
    {
        whisper "key too long\n";
        return 0;
    }

    unless (exists($self->{root}))
    {
        $self->{height} = 0;
        $self->{root} = $self->_makenode();

        # in this implementation, the original head remains the
        # leftmost leaf node of the tree, so we can start a full
        # forward scan of leaves from {leftmost}

        $self->{leftmost} = $self->{root};

        # start with rightmost at head, reset the rightmost on splits
        # if necessary

        $self->{rightmost} = $self->{root}; 

        # store additional metadata in leftmost
        $self->_setMainMeta();
    } 

    my $head = $self->{root};

    my @splithead = $self->_insertR($head, $entry, $self->{height});

    return 1
        unless (scalar(@splithead));

    my $istat;
    if (scalar(@splithead) > 1)
    {
        $istat = shift @splithead;
        my $mess1 = $ins_stat{$istat};

        if ($istat =~ m/split_fail/)
        {
            # split failed, but insert succeeded.  Most likely out of
            # free blocks, but still have left over space in existing
            # blocks.
            whisper $mess1, "\n";
            return 1;
        }
        if ($istat =~ m/ins_fail|no_joy/)
        {
            use Data::Dumper;

            shift @splithead;
            my $kk = shift @splithead;
            my $mess2 = shift @splithead;

            # insert failed - either key was too large or failed to
            # split at height zero (leaf node)
            my $key_info;
            $key_info = ("SCALAR" eq ref($kk)) ? $kk : 
                Dumper($kk);
            $key_info =~ s/\n/ /g ; # no newlines from dumper
            $key_info =~ s/\t/ /g ; # no tabs from dumper

            whisper "$mess1 for key $key_info"; 
            whisper $mess2;
            return 0;
        }
    }

    # the head was split.  splithead is a new node to the right of
    # current head.  Build a new head with two children - the current
    # head on the left, the splithead on the right.

    my $newhead = $self->_makenode();
    my ($nh_arr, $nh_bce, $nh_ph)  =  $self->_getarr($newhead);

    for my $childnode ($head, $splithead[0])
    {
        my ($cnarr, $cn_bce)  = $self->_getarr($childnode);

        my @row = $self->_unpack_row($cnarr->[0]);
        my $cnentry  = $self->_makenodeentry(key  => $row[0],
                                             link => $childnode);

        push (@{$nh_arr}, $self->_pack_row($cnentry));
    }

    $self->{root} = $newhead;
    $self->{height} = $self->{height} + 1;

    # store additional metadata in leftmost
    $self->_setMainMeta();

#   greet $newhead;

    # split ok even though insert failed.  Successfully built a new
    # head, but must report an error
    if (defined($istat))
    {
        my $mess1 = $ins_stat{$istat};

        if ($istat =~ m/split_ok/)
        {
            # split ok, but insert failed.  Valid if key is too large
            # (greater than one-half block in size)
            shift @splithead;
            my $kk = shift @splithead;
            my $mess2 = shift @splithead;
            whisper $mess1, " for key ", $kk, "\n", $mess2, "\n";
            return 0;
        }
    }

    return 1;
}

#  recursive insert returns array retval
#
# possible return statuses for success:
# @retval = () -> successful insert
# @retval = (new_right) -> successful insert, but node was split
#
# possible return statuses for failure:
# @retval = ('ins_fail', undef, key, message, ...)
# @retval = ('split_ok', new_right, key, message, ...)
# @retval = ('split_fail', undef, key, message, ...)
#
# 
sub _insertR
{
    my ($self, $currnode, $entry, $height) = @_;

#    greet $entry;
#    return 0
#        unless (defined($currnode));
    
#    return 0
#        unless (defined($entry));

    my ($currarr, $curr_bce, $curr_ph)  = $self->_getarr($currnode);
    my $arrsize  = scalar(@{$currarr});

    my $key = $entry->[0];
    my $i   = 0;
    my (@retval, @err_stack);

    my $icmp = $self->{compare}; # get the comparison function

    if (0 == $height)
    {
        if ($self->{unique_key})
        {
            # test if key already exists
            my @tempo = $self->_searchR($currnode, $key, $height, 
                                        $self->{equal},
                                        $icmp, 1);
#            greet @tempo;
            if (scalar(@tempo))
            { # fail due to duplicate key
                @retval = ('ins_fail', $currnode, $key, 
                           "duplicate key found");
                return @retval;
            }
        }

        $i = $self->_insert_estimate($key, $arrsize, $height, $currarr, $icmp)
            if ($arrsize > 5);

        for (; $i < $arrsize; $i++)
        {
            # break if can insert key before 
            my @row = $self->_unpack_row($currarr->[$i]);
            last
                if (&$icmp ($key, $row[0]));
#                if ($key < $row[0]);
        }
    }
    else
    {
        $i = $self->_insert_estimate($key, $arrsize, $height, $currarr, $icmp)
            if ($arrsize > 5);

        for (; $i < $arrsize; $i++)
        {
            # use array->[i=0] as sentinel record 

            my @r1;
            @r1 = $self->_unpack_row($currarr->[$i + 1])
                if (($i + 1) < $arrsize);

            if ((($i + 1) == $arrsize) ||
                (&$icmp ($key, $r1[0])))
#                ($key < $r1[0]))
            {
                my @r2 = $self->_unpack_row($currarr->[$i]);
                $i++;

                # link is array for IOT case
                my $link1 = ($self->{use_IOT}) ? $r2[1]->[0] : $r2[1];

                # insert recursively into the link and increment i
                my @newnode = 
                    $self->_insertR($link1, $entry, $height-1);

                return @retval
                    unless (scalar(@newnode));

                # a single value is just the newnode in arr[0], else
                # have an error stack
                if (scalar(@newnode) > 1)
                {
                    my $istat = $newnode[0];

                    # if the insert failed just return the error stack
                    # or if the insert succeed but the split failed
                    # return as well.

                    return @newnode
                        if ($istat =~ m/ins_fail|split_fail|no_joy/);

                    # save the old return status info
                    push (@err_stack, @newnode);

                    # the recursive insert failed, but the split
                    # succeeded, so we need to handle it at this
                    # level.  newnode is at arr[1], so shift it to
                    # arr[0]
                    shift @newnode;
                }

                # the insert split the node below us and returned the
                # new node, so we need to add an entry in current node
                # for the new node.

                whisper "build a new entry\n";
                my ($nnarr, $nn_bce)  = $self->_getarr($newnode[0]);

                # build a new entry 
                my @r3 = $self->_unpack_row($nnarr->[0]);
                $key = $r3[0];
                $entry = $self->_makenodeentry(key  => $r3[0], 
                                               link => $newnode[0]); 

                last;
            }
        }
    }


    if (0 == $height)
    { # save the statistics
        $self->{statistics}->{count}++;

        if ($i == $arrsize)
        {  # this insert appends a new last key
            $self->{statistics}->{lastkey_count}++;
            $self->{statistics}->{last_was_last} = 1;
            }
        else
        {   # last insert was not last key in index
            $self->{statistics}->{last_was_last} = 0;
        }
    }

    my $ins_ok = 1;

    my $left_arr   = $currarr;
    my $left_ph    = $curr_ph;
    my $left_size  = $arrsize;
    my $lt_bce     = $curr_bce;
    my ($new_right_node, $right_arr, $right_ph);
    my $right_size = 0;
    my $rt_bce;

    my $pack_entry = $self->_pack_row($entry);

    if (0 == $height)
    { # save key size statistics
        my $keysize = length($pack_entry);
        if ($keysize > $self->{statistics}->{keysize}->{max})
        {
            $self->{statistics}->{keysize}->{max} = $keysize;
        }
        elsif ($keysize < $self->{statistics}->{keysize}->{min})
        {
            $self->{statistics}->{keysize}->{min} = $keysize;
        }
            
    }

    my $preemptive_split = 0;

    for my $num_tries (1..2)
    { # try to splice or push into current node, 
      # else split (current node becomes left, new node is right) 
      # and try again

        $preemptive_split = 0; # split pre-emptively when block is low on space

        if ($i < $left_size)
        {
            my $err_str;

##            whisper "splice $key left\n";

            $left_ph->HeSplice(\$err_str, $i, 0, $pack_entry);

            if (defined($err_str))
            {
                my $entry_val = $entry->[1];
                whisper "splice error is: [$err_str] for key: $key";
                whisper " val: $entry_val , height $height\n";
                $ins_ok = 0;
            }
            else
            {
                # Assumption: keys are about the same size.  If the
                # current splice succeeded, see if there is enough
                # space to fit another key of current size.  If not,
                # do a pre-emptive split (which is cheaper than
                # failing a splice and backing it out)
                # NOTE: this is the RDBlock::_spacecheck, 
                # not bt2::_spacecheck
                unless ($left_ph->_spacecheck(length($pack_entry)))
                {
                    greet "preemptive split for splice, key $key";
                    $preemptive_split = 1;
                }

            }
        }
        else # no room to left splice
        {
            if ($right_size == 0) 
            {
                # normal case -- no split.

##                whisper "push $key left\n";
                if (defined($left_ph->HPush($pack_entry)))
                {
                    # Do the same key size check for the push that you
                    # would do for a splice.  If there is not enough
                    # space to fit another key of current size, do a
                    # pre-emptive split (which is cheaper than failing
                    # a push and backing it out
                    # NOTE: this is the RDBlock::_spacecheck, 
                    # not bt2::_spacecheck
                    unless ($left_ph->_spacecheck(length($pack_entry)))
                    {
                        greet "preemptive split for push, key $key";
                        $preemptive_split = 1;
                    }
                }
                else
                {
                    my $entry_val = $entry->[1];
                    whisper "push out of space ";
                    whisper "for key: $key";
                    whisper " val: $entry_val , height $height\n";
                    $ins_ok = 0;
                }
            }
            else # have a right node already
            {
                # since we just split the current node in half, look
                # to insert the entry in the right side (since the
                # offset is greater than the size of the left array) .
                # subtract size of left array from offset $i to get
                # offset into right array.

                $i -= $left_size;
                if ($i < $right_size)
                {
                    whisper "splice $key right\n";
                    splice (@{$right_arr}, $i, 0, $pack_entry);
                }
                else
                {
                    whisper "push $key right\n";
                    push ( @{$right_arr}, $pack_entry);
                }
            } # end have right node
        } # end no room to left splice

      L_ins_ok:
        if ($ins_ok) # best case - key was inserted and we are happy
        {
            # return if we are not pre-emptively splitting, or if on
            # the second pass
            if (
                (!$preemptive_split &&
                 (!$self->{maxsize} || ($arrsize < $self->{maxsize})))
                || (2 == $num_tries)
                )
            {
                # XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX
                #
                # return an undef (no split) on the first pass if insert
                # succeeded and we aren't pre-emptively splitting, or
                # return the new right (post split) if we split the
                # currnode and the insert succeeded on the second pass.
                #
                # XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX

                if (defined($new_right_node))
                {
                    @retval = ($new_right_node);
                }
                else
                {
                    @retval = (); # insert succeed with no split
                }
                
                # if the recursive insert failed but had a successful
                # split [err_stack is 'split_ok'] we need to process the
                # err_stack correctly for this level.
                if (scalar(@err_stack))
                { # recursive error stack
                    my @e2;
                    
                    # need to keep original error stack because might not
                    # return here
                    push @e2, @err_stack; 
                    
                    # discard the ins_status and the newnode -- we will
                    # return our own newnode to our parent if necessary
                    shift @e2; 
                    shift @e2;
                    
                    if (scalar(@retval))
                    {
                        # split was successful at this level, but insert
                        # failed recursively, so return split ok
                        
                        unshift @retval, $err_stack[0]; # prepend with err msg
                        push @retval, @e2;   # append rest of err stack
                    }
                    else
                    {
                        # successfully updated this level, and didn't
                        # split, but insert failed recursively, so return
                        # ins_fail
                        
                        push @retval, @err_stack;   # append whole err stack 
                        $retval[0] = 'ins_fail';
                        $retval[1] = undef;
                    }
                } # end if recursive error stack

                return @retval;
            }
        } # end if ins_ok

        # Note: can only split current node on first pass -- if get
        # here on second pass we are in trouble.  

        if (2 == $num_tries)
        {
            # XXX XXX : should never have a key larger than a
            # half-empty block!!
            @retval = ('ins_fail', $new_right_node, $key, "key too big!");
            push @retval, @err_stack; # add the recursive error stack
            return @retval;
#            croak "key too big!";
        }

        # insert exceeded (or will exceed) space, so split the current
        # node and return the new right neighbor node to our caller.

        $new_right_node = $self->_bsplit($currnode, $height);

        # Note: just return the new right node if the insert
        # succeeded, but we split preemptively.  

        if ($ins_ok) # return only if insert has succeeded
        {
            # insert succeed, and we were splitting pre-emptively
            
            # XXX XXX: set num_tries to 2 to force return, and go
            # back to the ins_ok routine above, which handles the
            # return statuses correctly.
            #
            # NOTE: if the split didn't succeed and we had an
            # error_stack previously [split ok but insert failed] then
            # will just return insert failed, which is bad enough

            if (defined($new_right_node) ||
                scalar(@err_stack))
            {
                $num_tries = 2;
                goto L_ins_ok;
            # return @retval
            }
            else
            {
                # the pre-emptive split failed and there was no
                # previous error stack, so return split_fail
                
                @retval = ('split_fail', undef, $key, 
                           "pre-emptive split failed");

                return @retval;
            }
        } # end ins_ok after pre-emptive split
        
        unless (defined($new_right_node))
        {
            # we are hosed.  We had to split and ran out of space.
            # bsplit/makenode is supposed to be nice and fail
            # prematurely in the leaf (height zero) if there are
            # insufficient free blocks to split the whole tree.  Pray
            # that this is the case.

            if (0 == $height) # split failure at 0 is an insert failure
            {
                @retval = ('ins_fail', $new_right_node, $key, 
                           "split out of space");
                return @retval;
            }

            # if we are performing concurrent operations on the tree
            # we could run out of space at any point.

            # crud.  we need to undo the operations that got us to
            # this point.  We better have transaction support.
            @retval = ('no_joy', $new_right_node, $key, 
                       "split out of space");
            return @retval;
        }

        # Note: insert failed on first pass, so we split the node.  On
        # the second pass we try to insert into either the left or the
        # right nodes.  Insert should usually succeed because both of
        # these nodes are only half full.

        ($right_arr, $rt_bce, $right_ph)  = $self->_getarr($new_right_node);
        ($left_arr, $lt_bce, $left_ph)    = $self->_getarr($currnode);

        $left_size  = scalar(@{$left_arr});
        $right_size = scalar(@{$right_arr});

        $ins_ok = 1;
        @retval = ();
    } # end for num tries

    return @retval;

} # end insertR


# estimate an insertion point - improve the linear scan
sub _insert_estimate
{
    my ($self, $key, $arrsize, $height, $currarr, $icmp) = @_;

    my $offset = 0;
    my $retval = 0;

 #   greet $arrsize, $currarr, scalar(@{$currarr});

#    $arrsize = scalar(@{$currarr});

    return 0
        if ($arrsize < 10);

    $arrsize -= 2;

    unless ($height == 0)
    {
        $arrsize--; # handle the sentinel record in non-leaf nodes
        $offset++;  
    }

    my @row;

    # check the last position first -- speedup for insert of ascending
    # sequences, like primary keys.  Test if 80% of inserts were to
    # end of index
    if (($self->{statistics}->{last_was_last})
        && (
            ($self->{statistics}->{lastkey_count}/$self->{statistics}->{count})
            > 0.8 ))
    {
        @row = $self->_unpack_row($currarr->[$arrsize+$offset]);
        if (scalar(@row))
        {
            unless (&$icmp ($key, $row[0]))
            {
#                greet "lastkey match!";
                return ($arrsize); # insert (append) at end of current array
            }
        }
    }

    # TODO: binary search, interpolation search

    # XXX: interpolation only for numeric searching, vs insert??

#    if ($icmp == $bt2numcmp)
    {
        use POSIX ; #  need some rounding

        # An iterative binary search.  Note that we aren't looking for
        # a match, just a start location for the linear scan in
        # insertR.  

        my $lefty  = 0;
        my $righty = $arrsize;
        $righty--;

#        my $iter = 0;
        while (1)
        {
#            $iter++;
            last
                if ($lefty >= $righty);

            my $middle = POSIX::floor(($lefty+$righty)/2);

            @row = $self->_unpack_row($currarr->[$middle+$offset]);

            last # just kick out if some malformed row...
                unless (scalar(@row));

            if (&$icmp ($key, $row[0]))
            {
                # if key < current entry then keep moving left
                # (eliminate the right interval)

                $righty = $middle - 1;
            }
            else
            {
                # if key >= current entry then keep moving right
                # (eliminate the left interval).  Note that the return
                # value for the estimate gets bumped up to the current
                # position, because we can start a linear scan from
                # this location

                $retval = $middle;
                $lefty  = $middle + 1;
            }
        } # end while

#        greet $key, $retval, $arrsize, $currarr, $iter;

    }

    return $retval;
}

sub _GetMeta
{
    my ($self, $ph) = @_;
    my @ggg;

    my $row = $ph->_get_meta_row("I"); # "I" for Index

    return @ggg
        unless (defined($row));

    return @{$row};
}

sub _SetMeta
{
    my ($self, $ph, $rrow) = @_;

    return ($ph->_set_meta_row("I", $rrow)); # "I" for Index
}

sub _spacecheck
{
    my ($self, $height) = @_;

    # degenerate case: splitting root (height zero) requires two
    # additional blocks -- new head plus new sibling

    my $maxsp = $height + 2;
    my $spaceleft = $self->{maxblockno} - $self->{maxnodeid};
    whisper "_spacecheck: need $maxsp blocks, $spaceleft left"
        unless ($spaceleft > $maxsp);

    return ($spaceleft > $maxsp);
}

# create a new right neighbor for the current node and split the
# contents betweeen the current and new node.
# return the new node
sub _bsplit
{
    my ($self, $currnode, $height) = @_;

    # XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX
    # number of possible nodes created by recursive splits is
    # ((self->{height} - height) + 2).  If we run out of space in
    # during a recursive split this could leave the tree in an
    # inconsistent state, so need to check if space is available, else
    # split should fail.  Since we use bottom up splitting, at height
    # 0 check if (self->{height} + 2) blocks are available, else fail
    # the insert.  With a transactional layer we can be a bit more lax
    # since rolling back the transaction would restore intermediate
    # split nodes.  See spacecheck in makenode

    # XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX

    my $newnode = $self->_makenode(height => $height);

    return undef
        unless (defined($newnode)); # makenode ran out of space

    my ($currarr, $currbce, $currph)  = $self->_getarr($currnode);
    my ($nn_arr, $nn_bce, $nn_ph)     = $self->_getarr($newnode);

    my @curr_meta1 = $self->_GetMeta($currph);
    my @nn_meta1   = $self->_GetMeta($nn_ph);

    $nn_meta1[A_LEFT]  = $currnode;
    $nn_meta1[A_RIGHT] = $curr_meta1[A_RIGHT];

    # if have a right neighbor
    if ($curr_meta1[A_RIGHT] =~ /\d+/)
    {
        my ($rt_arr, $rt_bce, $rt_ph) = 
            $self->_getarr($curr_meta1[A_RIGHT]);

        my @rt_meta1 = $self->_GetMeta($rt_ph);
        $rt_meta1[A_LEFT] = $newnode;  
        $self->_SetMeta($rt_ph,\@rt_meta1);
    }
    else
    {
        if (0 == $height)
        {

#                unless (defined($newnode->{right}))
            {
                # new node is rightmost if has no right neighbor
                whisper "new rightmost ",$nn_meta1[A_NODEID],"\n";
                $self->{rightmost} = $newnode;
                if ($currnode eq $self->{leftmost})
                {
                    # if already have leftmost, don't need an
                    # additional call to set the main metadata
                    $curr_meta1[A_RIGHTMOST] = $newnode;
                }
                else
                {
                    # store additional metadata in leftmost
                    $self->_setMainMeta();
                }
            }
        }
    }
    $curr_meta1[A_RIGHT] = $newnode;

    $self->_SetMeta($currph,\@curr_meta1);
    $self->_SetMeta($nn_ph,\@nn_meta1);

    # finally, after the big setup, copy half of entries in the
    # current node to the new right neighbor
    my $arrsize  = scalar(@{$currarr});
    my $SplitLocation = $arrsize/2;

    my $doOpt  = 1; # XXX XXX: leave on - ~20% speedup for strict ascending
    my $maxPct = 0.15;  # 0.09; # .15

    if ($doOpt
        && ($arrsize > 60) # optimize for ascending sequences...
        && ($self->{statistics}->{last_was_last})
        && (
            ($self->{statistics}->{lastkey_count}/$self->{statistics}->{count})
            > 0.95 )
        # XXX XXX: don't do this is key is large (> 15% maximum)
#  && (($self->{statistics}->{keysize}->{max}/$self->{maxkeysize}) < $maxPct)
#&& (($self->{maxkeysize}/$self->{statistics}->{keysize}->{max}) > 5)
        )

    {
        whisper "lopsided split";
        # leave the current array really full instead of 1/2 full
        $SplitLocation = $arrsize - 3;
    }

    my @newarr   = splice(@{$currarr}, $SplitLocation);

    push (@{$nn_arr},@newarr);

    return $newnode;
} # end bsplit

sub delete
{
    my ($self, $key, $value) = @_;

    # Note: value is optional to do deletes with duplicate keys

    my @outi = $self->search($key);

    return undef
        unless (scalar(@outi) > 1);

    shift @outi; # key 
    my $outval = shift @outi; 
    my $nodeid = shift @outi; 
    my $offset = shift @outi; 

    my ($currarr, $curr_bce, $curr_ph)  = $self->_getarr($nodeid);    

    unless (defined($value))
    {
#    greet $currarr, $offset;
        my $stat = (delete ($currarr->[$offset]));
#    greet $currarr;

        return $outval 
            if (defined($stat));
        return undef;
    }

    # XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX
    # ugly hack for non-unique

    # scan index, looking for a matching value...
    my $place = 
        $self->_joinplace("A",
                          $nodeid,
                          $offset);

    my ($prefix, $currnode);
    while (defined($place))
    {
        my @row = $self->offsetFETCH($place);
        last 
            unless (scalar(@row) > 1);

        if ($row[-1] eq $value)
        {
            whisper "found it!";
            ($prefix, $currnode, $offset) = $self->_splitplace($place);  
            ($currarr, $curr_bce, $curr_ph)  = $self->_getarr($currnode);    

            my $stat = (delete ($currarr->[$offset]));

            return $outval 
                if (defined($stat));
            last;
        }       
        $place = $self->offsetNEXTKEY($place);
    } # end while def

    return undef;
}

sub search
{
    my ($self, $start_key, $f_eq, $f_cmp) = @_;

    return $self->_search2($start_key, 0 , $f_eq, $f_cmp);
}

sub _search2
{
    my ($self, $start_key, $nearest, $f_eq, $f_cmp) = @_;
#    whoami;

    my $std_search = (scalar(@_) < 4);

    return undef
        unless (exists($self->{root}));

    my $head = $self->{root};

    my $ieq  = (defined($f_eq))  ? $f_eq  : $self->{equal};
    my $icmp = (defined($f_cmp)) ? $f_cmp : $self->{compare};

    return $self->_searchR($head, $start_key, $self->{height}, $ieq, $icmp, 
                           $std_search, $nearest);
}

# XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX 
# Note that this search works for a partial match because it always
# scans from left to right.  We can't just switch the equality
# comparison to a binary search and have it work correctly.
# XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX XXX 
sub _searchR
{
    my ($self, $currnode, $key, $height, $ieq, $icmp,
        $std_search, $near) = @_;

    my $nearest = $near || 0;

L_starti:
    my ($currarr, $curr_bce, $curr_ph)  = $self->_getarr($currnode);
    my $arrsize  = scalar(@{$currarr});

#    greet "near = 1", $currnode, $height, $currarr
#        if $nearest;

    my $i   = 0;

    my @retval;

    if (0 == $height)
    {
        $i = $self->_insert_estimate($key, $arrsize, $height, $currarr, $icmp)
            if ($std_search && ($arrsize > 5));

        for (; $i < $arrsize; $i++)
        {
            my $packval = $currarr->[$i];
#            next unless (defined($packval));
            # break if can insert key before 
            my @row = $self->_unpack_row($packval);
#                if ($key == $row[0]);
            if (&$ieq ($key, $row[0]))
            {
                # key might be partial, so return row[0]
                push @retval, $row[0], $row[1], $currnode, $i;
                last;
            }
            else
            {
                # NOTE: check if we passed the key!!
                unless (&$icmp ($row[0], $key))
#                (key > row[0])
                {
#                    whisper "passed the key!";
#                    greet $key, @row;
                    # we passed the key
                    push @retval, $row[0], $row[1], $currnode, $i 
                        if ($nearest);
                    last;
                }
            }
        } # end for
    }    
    else
    {
        $i = $self->_insert_estimate($key, $arrsize, $height, $currarr, $icmp)
            if ($std_search && ($arrsize > 5));

        for (; $i < $arrsize; $i++)
        {
            # use array->[i=0] as sentinel record 
            my $packval = $currarr->[$i + 1];
#            next unless (defined($packval));

            my @r1;
            @r1 = $self->_unpack_row($packval)
                if (($i + 1) < $arrsize);

            if ((($i + 1) == $arrsize) ||
                (&$icmp ($key, $r1[0])))
#                ($key < $r1[0]))
            {
                $packval = $currarr->[$i];

                # XXX XXX: need to save prevkey versus just decrement
                # i+1 if have possible null entries in branch nodes
                # unless (defined($packval))

                my @r2 = $self->_unpack_row($packval);

                # link is array for IOT case
                my $link1 = ($self->{use_IOT}) ? $r2[1]->[0] : $r2[1];

                # search recursively 
                return ($self->_searchR($link1, $key, $height-1,
                                        $ieq, $icmp,
                                        $std_search, $nearest));
            }
        }
    }

    return @retval
        if (scalar(@retval) || !$nearest);

    if ($nearest && (0 == $height) && (0 == scalar(@retval)))
    {
        my @curr_meta1 = $self->_GetMeta($curr_ph);
        
        whisper "search right";
        # find right neighbor and keep looking
        $currnode = $curr_meta1[A_RIGHT];

        goto L_starti
            if ((defined($currnode)) && ($currnode =~ /\d+/));
    }
    
    return @retval;
} # end searchR

sub btCLEAR
{
    my $self = shift;

    my $currnode = $self->{root}; 

    return undef
        unless ((defined($currnode)) && ($currnode =~ /\d+/));

    return $self->_clearR($currnode, $self->{height});
}

sub _clearR
{
    my ($self, $currnode, $height) = @_;

    whoami $currnode;

    my ($currarr, $curr_bce, $curr_ph)  = $self->_getarr($currnode);
    my $arrsize  = scalar(@{$currarr});

    my $i = 0;

    my $retval;

    if (0 == $height)
    {
#        return $curr_ph->CLEAR();
        return splice(@{$currarr}); # use splice so the metadata isn't cleared
    }    
    else
    {
        for (; $i < $arrsize; $i++)
        {
            # use array->[i=0] as sentinel record 
            my @r2 = $self->_unpack_row($currarr->[$i]);
            # clear recursively 

            # link is array for IOT case
            my $link1 = ($self->{use_IOT}) ? $r2[1]->[0] : $r2[1];

            $retval = ($self->_clearR($link1, $height-1));
        }
    }
    return $retval;
} # end clearR


# the array offset and hash key iterator functions take a "place"
# argument.  Place arguments consist of a prefix, a node id, and a
# position.  If the prefix is H for hash, then the position is a hash
# key in the pushhash tied to the current node.  If the prefix is A
# for array, then the position is the array offset in the array tied
# to the current node.

our $PLACESEP   = ":"; # place separator
our $PLACESEPRX = ":"; # place separator Regular eXpression

# private
sub _splitplace
{
    # split into 3 parts - prefix, node, position, 
    # where position is either an array offset or a hash key.
    # prefix is A for array, H for hash
#    whoami @_;
    unless ($_[1] =~ m/$PLACESEPRX/)
    {
        carp "could not split key: $_[1] "
            if warnings::enabled();
        return undef; # no separator
    }
    my @splitval = split(/$PLACESEPRX/,($_[1]), 3);

    return @splitval;
}

sub _joinplace
{
    my $self = shift;

    return (join ($PLACESEP, @_));
}

sub offsetFIRSTKEY 
{ 
    my $self = shift;

    my $currnode = $self->{leftmost}; 

    return undef
        unless ((defined($currnode)) && ($currnode =~ /\d+/));

    return $self->offsetNEXTKEY($self->_joinplace("A", $currnode, -1));
}

sub offsetNEXTKEY  
{ 
    my ($self, $prevkey) = @_;
#    whoami $prevkey;

    # ASSERT PREFIX
    my ($prefix, $currnode, $offset) = $self->_splitplace($prevkey);

    while ((defined($currnode)) && ($currnode =~ /\d+/))
    {
        my ($currarr, $currbce, $currph)  = $self->_getarr($currnode);
        my $arrsize  = scalar(@{$currarr});

        $offset++;
        return $self->_joinplace("A", $currnode, $offset)
            if ($offset < $arrsize);

        my @curr_meta1 = $self->_GetMeta($currph);

        $currnode = $curr_meta1[A_RIGHT];
        $offset = -1;
    }

    return undef;
}

# reverse iterator
sub offsetLASTKEY
{
    my $self = shift;

    my $currnode = $self->{rightmost}; 

    return undef
        unless ((defined($currnode)) && ($currnode =~ /\d+/));

    my ($currarr, $currbce, $currph)  = $self->_getarr($currnode);
    my $arrsize  = scalar(@{$currarr});

    # XXX XXX arrsize - 1 ? or just return currnode:arrsize (no nextkey)?

    return $self->offsetPREVKEY($self->_joinplace("A", $currnode, $arrsize));

}

sub offsetPREVKEY
{
    my ($self, $nextkey) = @_;

    # ASSERT PREFIX
    my ($prefix, $currnode, $offset) = $self->_splitplace($nextkey);

    while ((defined($currnode)) && ($currnode =~ /\d+/))
    {
        my ($currarr, $currbce, $currph)  = $self->_getarr($currnode);
        $offset--;

        unless ($offset < scalar(@{$currarr}))
        {
            whisper "bad offset $offset, node $currnode";
            last;
        }

        return $self->_joinplace("A", $currnode, $offset)
            if ($offset > -1);

        my @curr_meta1 = $self->_GetMeta($currph);

        $currnode = $curr_meta1[A_LEFT];

        last
            unless ((defined($currnode)) && ($currnode =~ /\d+/));

        ($currarr, $currbce, $currph)  = $self->_getarr($currnode);
        $offset  = scalar(@{$currarr});
    }

    return undef;

}

# hkeyFUNCTION : iterator functions using underlying RDBlock data
# entry hash keys, not the RDBArray offsets.

sub hkeyFIRSTKEY 
{ 
    my $self = shift;

    my $currnode = $self->{leftmost}; 

    return undef
        unless ((defined($currnode)) && ($currnode =~ /\d+/));

    return $self->hkeyNEXTKEY($self->_joinplace("H", $currnode, -1));
}

sub hkeyNEXTKEY  
{ 
    my ($self, $prevkey) = @_;
#    whoami $prevkey;

    # NOTE: use currph hash key, not offsets!
    # ASSERT PREFIX
    my ($prefix, $currnode, $hkey) = $self->_splitplace($prevkey);

    while ((defined($currnode)) && ($currnode =~ /\d+/))
    {
        my ($currarr, $currbce, $currph)  = $self->_getarr($currnode);

        if ($hkey < 0)
        {
            $hkey = $currph->FIRSTKEY();
        }
        else
        {
            $hkey = $currph->NEXTKEY($hkey);
        }

        return $self->_joinplace("H", $currnode ,$hkey)
            if (defined($hkey));

        my @curr_meta1 = $self->_GetMeta($currph);

        $currnode = $curr_meta1[A_RIGHT];
        $hkey = -1;
    }

    return undef;
}

# reverse iterator
sub hkeyLASTKEY
{
    my $self = shift;

    my $currnode = $self->{rightmost}; 

    return undef
        unless ((defined($currnode)) && ($currnode =~ /\d+/));

    return $self->hkeyPREVKEY($self->_joinplace("H", $currnode, -1));
}

sub hkeyPREVKEY
{
    my ($self, $nextkey) = @_;

    # NOTE: use currph hash key, not offsets!
    # ASSERT PREFIX
    my ($prefix, $currnode, $hkey) = $self->_splitplace($nextkey);

    while ((defined($currnode)) && ($currnode =~ /\d+/))
    {
        my ($currarr, $currbce, $currph)  = $self->_getarr($currnode);

        if ($hkey < 0)
        {
            $hkey = $currph->_lastkey();
        }
        else
        {
            $hkey = $currph->_prevkey($hkey);
        }

        return $self->_joinplace("H", $currnode, $hkey)
            if (defined($hkey));

        my @curr_meta1 = $self->_GetMeta($currph);

        $currnode = $curr_meta1[A_LEFT];
        $hkey = -1;
    }

    return undef;

}

# fetch a btree "row" using the array offset
#
# NOTE: set getplace to return row value in searchR format
sub _fetch_row
{
    my ($self, $place, $getplace) = @_;

    # ASSERT PREFIX
    my ($prefix, $currnode, $position) = $self->_splitplace($place);

    while ((defined($currnode)) && ($currnode =~ /\d+/))
    {
        my ($currarr, $currbce, $currph)  = $self->_getarr($currnode);
        my @row;

        if ($prefix =~ /A/) # ARRAY
        {
            my $offset  = $position;
            my $arrsize = scalar(@{$currarr});

            return undef
                unless ($offset < $arrsize);

            @row = $self->_unpack_row($currarr->[$offset]);
        }
        elsif ($prefix =~ /H/) # HASH
        {
            my $val = $currph->FETCH($position);

            return undef
                unless (defined($val));

            @row = $self->_unpack_row($val);
        }
        else
        {
            # XXX XXX: bad prefix
            return undef;
        }
        # append the currnode and offset if requested to match searchR
        # format
        push @row, $currnode, $position
            if (defined($getplace));

        return @row;
    }

    return undef;
} # end _fetch_row

# NOTE: set getplace to return row value in searchR format
sub offsetFETCH
{
    my $self = shift;
    return $self->_fetch_row(@_);
}

# fetch a btree "row" using the underlying RDBlock data entry hash key
sub hkeyFETCH
{
    my $self = shift;
    return $self->_fetch_row(@_);
}

sub HCount
{
    my $self = shift;
    my $grandtot = 0;

    my $currnode = $self->{leftmost};

    while ((defined($currnode)) && ($currnode =~ /\d+/))
    {
        my ($currarr, $currbce, $currph) = $self->_getarr($currnode);

#        $grandtot += $currph->HCount();
        $grandtot += $currph->FETCHSIZE(); # Note: the RDBlock class isn't a 
                                           # true PushHash, so it doesn't have
                                           # an HCount method...

        my @curr_meta1 = $self->_GetMeta($currph);
        $currnode = $curr_meta1[A_RIGHT];
    }
    return ($grandtot); 
} # end HCount

# build a search handle similar to a DBI statement handle
#
sub SQLPrepare # get a DBI-style statement handle
{
#    whoami;
    my $self = shift;
    my %optional = (ieq  => $self->{equal},
                    icmp => $self->{compare},
                    BT_Fetch_Fix   => 0);

    my %args = (%optional,
                @_); # start_key, stop_key

    my $sth = Genezzo::Index::bt2_search->new(btree => $self, %args);

    return $sth;
}

package Genezzo::Index::bt2_search;
use strict;
use warnings;
use Genezzo::Util;

sub _init
{
    my $self = shift;
    my %args = (@_);

    return 0
        unless (defined($args{btree}));

    $self->{btree} = $args{btree};

    # NOTE: start_key..stop_key is an inclusive interval -- the
    # interval [1,10] is 1,2,3,4,5,6,7,8,9,10.  Should find all
    # duplicate values for start and stop keys as well.  Use filters
    # or adjust the start/stop keys as necessary for queries like:
    # "select * from emp where id > 10 and id < 20"

    if (exists($args{start_key}))
    {
        $self->{start_key} = $args{start_key};
    }

    if (exists($args{stop_key}))
    {
        $self->{stop_key}  = $args{stop_key};
    }

    $self->{ieq}   = $args{ieq};
    $self->{icmp}  = $args{icmp};

    $self->{state} = 0;

    $self->{exact_match} = 0;

    if (   exists($args{start_key})
        && exists($args{stop_key}))
    {
        # we are looking for an exact key match if have
        # identical start/stop keys
        my $ieq = $args{ieq};
        $self->{exact_match} = &$ieq($self->{start_key},
                                     $self->{stop_key});
    }

    $self->{fetch_fix} = $args{BT_Fetch_Fix};
#    greet "fetch_fix:" , $args{BT_Fetch_Fix};

    return 1;
} # end init

sub new
{
 #   whoami;
    my $invocant = shift;
    my $class = ref($invocant) || $invocant ; 
    my $self = { };

    my %args = (@_);
    return undef
        unless (_init($self,%args));

    return bless $self, $class;

} # end new

# SQL-style execute and fetch functions
sub SQLExecute
{
    my $self = shift;

    $self->{state} = 1;

    # XXX: define filters and fetchcols
    return (1);
}

# XXX XXX XXX XXX: create a separate dynamic package to hold the fetch
# state, vs keeping the fetch state in the base btree.  Then can
# maintain multiple independent SQLFetches open on same btree object.

# combine NEXTKEY and FETCH in a single operation
sub SQLFetch
{

    # XXX XXX XXX XXX NOTE: must always supply equality function to
    # get filtering ?  Why???  Need to fix this API to support startkey/stopkey

#    whoami;
    my ($self, $f_eq, $k2) = @_;

#    greet $f_eq, $k2;

    if (0 == $self->{state})
    {
        # error - not started
        return undef;

        # NB: States are:
        #
        # 0 - not started
        # 1 - first fetch
        # 2 - subsequent fetch (and stopkey not found)
        # 3 - subsequent fetch after stopkey discovered
    }

    while (1)
    {
        my @row;

        if (1 == $self->{state}) # first fetch
        {
            if (exists($self->{start_key}))
            { # search for start key

                # Note: do "nearest" search if start_key != stop_key
                @row = $self->{btree}->_search2(
                                                $self->{start_key},
                                                !$self->{exact_match},
                                                $self->{ieq},
                                                $self->{icmp}
                                                );
            }
            else # scan from first key
            {
#                whisper "no startkey";

                my $bt    = $self->{btree};
                my $place = $bt->offsetFIRSTKEY();

                last # Note: don't fetch if index is empty...
                    unless (defined($place));

                @row      = $bt->offsetFETCH($place, 1)
            }

            $self->{state}++; # advance the state

        } # end firstfetch
        else
        {
            # states 2, 3 - subsequent fetches

            last
                unless (exists($self->{SQLFetchKey})
                        && defined($self->{SQLFetchKey}));
            
            my $bt = $self->{btree};
            my ($key, $val, $currnode, $offset) = @{$self->{SQLFetchKey}};
            my $place = 
                $bt->offsetNEXTKEY(
                                   $bt->_joinplace("A",
                                                   $currnode,
                                                   $offset));

            last
                unless (defined($place));
                
            @row = $bt->offsetFETCH($place, 1);

        }

#        greet "rw", @row, "gg";

        last
            unless (scalar(@row) > 1);

#        my $ieq  = (defined($f_eq))  ? $f_eq  : $self->{ieq};
        my $ieq = $f_eq;

        # XXX XXX XXX XXX XXX XXX : OBSOLETE - do filtering separately
        if (defined($ieq)) # all rows must match this function
        {
            # if we have an equality function, (and a match key), make sure
            # the next row matches

            $k2 = $row[0]
                unless (defined($k2));

            last # EOF if no match
                unless (&$ieq ($k2, $row[0]));

            # if matched, save fetchkey
        }

        # XXX XXX: could optimize the stop key test by searching to
        # find the location, then only testing when get to the
        # appropriate leaf node -- maybe an api like 
        # searchX returns [startkey (nearest), stop_nodeid]?
        # 'cos the current stop_key is just a filter...

        if (exists($self->{stop_key}))
        {
            my $stop_key = $self->{stop_key};
            my $ieq      = $self->{ieq};
            my $icmp     = $self->{icmp};

            if (3 == $self->{state}) # in a stop key region
            {
                # if in a stop key region and no longer matches
                # stopkey then we are done
                unless (&$ieq($self->{stop_key}, $row[0]))
                {
#                    whisper "stopped!";
                    last;
                }
            }
            elsif (2 == $self->{state}) # find first stop key 
            {
                # move to state 3 if found first stop key --
                # EOF when find first non-stopkey.
                if (&$ieq($self->{stop_key}, $row[0]))
                {
#                    whisper "found stopkey";
                    $self->{state}++;
                }
                else
                {
                    # NOTE: check if we passed the key!!
                    unless (&$icmp ($row[0], $self->{stop_key}))
#                   (key > row[0])
                    {
                        whisper "passed the key";
#                        greet $self->{stop_key}, @row;
                        last;
                    }
                }
            }
            else
            { # XXX XXX XXX
                whisper "bad state";
                last;
            }
        } # end if stopkey

        my @foo = @row;
        $self->{SQLFetchKey} = \@foo;

        if ($self->{fetch_fix})
        {

            # Note: fixes to make btHash SQLFetch like RSTab.  Make
            # the sqlfetch return a standard rid/rowvalue pair, where
            # the rid is the index row rid (not the table rid _trid),
            # and the row value is the concatenated index key and
            # value as an array.  We need to re-arrange the current
            # @row into a suitable format.

            my @baz = @row;
            my $offset   = pop @baz; # remove the array offset
            my $currnode = pop @baz; # remove the currnode 
            @row = ();
            my $place = $self->_joinplace("A", $currnode, $offset);
            push @row, $place;      

            # add _trid (single value) to index key to make a single
            # array "rowvalue"
            push @{$baz[0]}, $baz[1]; 

            # push the rowvalue into the row after the rid
            push @row, $baz[0]; 
#            greet @row; # row now in key/@val format
        }
        return @row;
#        return splice(@row, 0, 2);

        last;
    } # end while

    delete $self->{SQLFetchKey};
    return undef;
}

sub AUTOLOAD 
{
    my $self = shift;
    my $bt = $self->{btree};

    our $AUTOLOAD;
    my $newfunc = $AUTOLOAD;
    $newfunc =~ s/.*:://;
    return if $newfunc eq 'DESTROY';

#    greet $newfunc;
    return ($bt->$newfunc(@_));
}


END {

}

# insert code here

1;


__END__
    
# Below is stub documentation for your module. You better edit it!
    
=head1 NAME
    
Genezzo::Index::bt2 - basic btree

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

This package supports a constructor "new", plus standard b-tree
methods like insert, delete, search.

=head2 "new" constructor

The "new" constructor takes many arguments, but they are all optional.
If none are specified, the constructor will allocate 100 blocks of the
default size for a b-tree.  The default assumption is to support
scalar string keys with a scalar string values.  The tree will have a
maximum of 50 entries per node.

=over 4

=item maxsize (default 50)

The maximum number of entries in a node.  If set to zero, the insert
will pack as many entries as space allows in each node

=item numblocks (default 100)

The constructor will allocate a private buffer cache for the b-tree of
up to the number of blocks specified.  If numblocks=0, no cache is
created.  In this case, the user must create a subclass to overload
the make_new_block and getarr methods.

=item blocksize (default DEFBLOCKSIZE)

The size of each block in the b-tree

=item key_type (null by default)

The key type is either a single scalar "c" (for char) or "n" (for
number), or a ref to an array of "c" and/or "n" values.  If key_type
is specified, bt2 finds or constructs the appropriate compare/equals
and pack/unpack functions, overriding any user-supplied arguments.  
If key type is not specified, bt2 processes the insert keys as a scalar
strings.

=item compare, equal (default string comparison -- ignored if key_type argument specified)

Supply methods to compare your key.  This package contains
special comparison methods for numeric and multi-column keys, and
their associated packing functions.

=item pack_fn/unpack_fn (default single scalar key and value -- ignored if key_type specified)

"Packing" functions convert key/value pairs to and from a byte
representation which gets stored in the nodes of the b-tree.  The
b-tree package supports scalar keys and values by default.  It also
contains methods for multi-column keys with a single value.

=item use_IOT (default off)

special flag for Index Organized Tables, which means the "value" can be
an array, not a scalar.  This approach requires  a couple extra
checks in the branch nodes, since branches contain (key, nodeid)
pairs, and leaves contain (key, array of values).  Normally, indexes
only have a scalar value: a nodeid or a rid.

=item unique_key (default off)

Enforce uniqueness (no duplicates) at insertion time

=item use_keycount (default off)

Special case for building non-unique indexes where the "value" is null
because it is already part of the key vector.  In this usage, we
construct a unique index (unique_key=1) where the key vector is the
key columns *plus* the table rid, and the value is null.  The key
columns might be duplicates, but the addition of the rid guarantees
uniqueness.  The fetch is asymmetric: the table rid is returned as
both the last key column and the value.

Q:  Why not just have a non-unique index and store the rids as regular
values?
A: This approach clusters related rids, so index scans are more
efficient and deletes are easier.  Note that the basic index row
physical storage is unaffected.  Only the unpack function needs an
extra argument to describe the number of key columns.
Q: But doesn't the extra comparison for the rid column make inserts
more expensive?
A: Yes, but we're trading off insert performance against index scan
performance.  The workload of most database applications is typically
dominated by selects, not inserts.

=back

=head2 functions 

=over 4

=item insert

=item delete

=item search

=item btCLEAR

=item hash_key/array_offset iterators: FIRSTKEY, NEXTKEY, FETCH, 
      plus reverse iterators LASTKEY, PREVKEY.

=item DBI-style search interface: SQLPrepare, Execute, Fetch

=back

=head2 EXPORT

none

=head1 TODO

=over 4

=item hkey/offset functions: should be able to convert between
      different "place" formats (Array and Hash prefixes), like
      the common fetch routine, or ASSERT that prefix matches.

=item add reverse scan to search/SQLFetch

=item support multicol keys, non-unique keys (via combo of key + rid as unique)

=item support transaction unique constraints -- probably via treat key+rid as
      unique, then turn on true unique key, and scan for duplicates?

=item find out why can't do pctfree=0

=item Work on RDBlk_NN support.

=item search with startkey/stopkey support, vs supplying compare/equal methods.
      restricting the search api to straight "=","<" comparisons means can
      try the estimation function

=item need to handle partial startkey/stopkey comparison in searchR/SQLFetch
      for multi-col keys

=item semantics of nulls in multi-col keys -- sort low?

=item simplify _pack_row with splice and a supplied split position, something
      like -1 for normal indexes (n-1 key cols, 1 val col, so pop the val)
      or "N=?" for index-organized tables (N key cols, M val cols, so splice N)

=item reorganize along the lines of "GiST"
      Generalized Search Trees (Paul Aoki, J. Hellerstein, UCB)

=item ecount support?

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
