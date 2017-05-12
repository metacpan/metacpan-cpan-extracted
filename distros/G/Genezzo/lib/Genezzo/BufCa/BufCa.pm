#!/usr/bin/perl
#
# $Header: /Users/claude/fuzz/lib/Genezzo/BufCa/RCS/BufCa.pm,v 7.3 2006/08/02 06:01:21 claude Exp claude $
#
# copyright (c) 2003, 2004 Jeffrey I Cohen, all rights reserved, worldwide
#
#
use strict;
use warnings;

package Genezzo::BufCa::BufCa;

use Genezzo::BufCa::PinScalar;
use Genezzo::BufCa::BufCaElt;
use Genezzo::Util;
use Carp;
use warnings::register;


BEGIN {
    use Exporter   ();
    our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

    # set the version for version checking
#    $VERSION     = 1.00;
    # if using RCS/CVS, this may be preferred
    $VERSION = do { my @r = (q$Revision: 7.3 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r }; # must be all one line, for MakeMaker

    @ISA         = qw(Exporter);
#    @EXPORT      = qw(&func1 &func2 &func4 &func5);
    @EXPORT      = ( );
    %EXPORT_TAGS = ( );     # eg: TAG => [ qw!name1 name2! ],

    # your exported package globals go here,
    # as well as any optionally exported functions
#    @EXPORT_OK   = qw($Var1 %Hashit &func3 &func5);
    @EXPORT_OK   = ( );

}

our @EXPORT_OK;

# non-exported package globals go here


# initialize package globals, first exported ones
#my $Var1   = '';
#my %Hashit = ();

# then the others (which are still accessible as $Some::Module::stuff)
#$stuff  = '';
#@more   = ();

# all file-scoped lexicals must be created before
# the functions below that use them.

# file-private lexicals go here
#my $priv_var    = '';
#my %secret_hash = ();
# here's a file-private function as a closure,
# callable as &$priv_func;  it cannot be prototyped.
#my $priv_func = sub {
    # stuff goes here.
#};

# make all your functions, whether exported or not;
# remember to put something interesting in the {} stubs
#sub func1      {print "hi";}    # no prototype
#sub func2()    {}    # proto'd void
#sub func3($$)  {}    # proto'd to 2 scalars
#sub func5      {print "ho";}    # no prototype

sub _init
{
    #whoami;
    my $self = shift;
#    greet @_;

    my %required = (
                    blocksize => "no blocksize !"
                    );

    my %args = (
                numblocks => 10,
                @_);

    return 0
        unless (Validate(\%args, \%required));

    return 0 
        unless (NumVal(
                       verbose => warnings::enabled(),
                       name => "blocksize",
                       val => $args{blocksize},
                       MIN => 1));

    return 0 
        unless (NumVal(
                       verbose => warnings::enabled(),
                       name => "numblocks",
                       val => $args{numblocks},
                       MIN => 1));

    $self->{blocksize} = $args{blocksize};

    $self->{bce_arr}   = [];

    for (my $i = 0; $i <  $args{numblocks}; $i++)
    {
        my $bce = Genezzo::BufCa::BufCaElt->new(blocksize => $args{blocksize});

        unless (defined($bce))
        {
            carp "failed to allocate Buffer Cache Element $i"
                if warnings::enabled();
            return 0;
        }

        push (@{$self->{bce_arr}}, $bce);

    }

    # keep track of virgin (never used) buffers to speed GetFree
    # allocation.  degenerate to linear search after all buffers used
    # once.
    # XXX: after bcfile flush bufs may still be pinned so cannot reset
    $self->{virgin} = [0, $args{numblocks} - 1];

    return 1;
}

sub new 
{
    my $invocant = shift;
    my $class = ref($invocant) || $invocant ; 
    my $self = { };

    my %args = (@_);

    return undef
        unless (_init($self,%args));

    return bless $self, $class;

} # end new

sub Dump
{
    whoami;
    my $self = shift;

    my %hashi = (blocksize => $self->{blocksize},
                 numblocks => scalar(@{$self->{bce_arr}}),
                 unused    => $self->{virgin}
                 );

    return \%hashi;
}

sub Resize
{
    whoami;
    my $self = shift;

    my $newsize = shift;

    if ($newsize > scalar(@{$self->{bce_arr}}))
    {
        my $i = scalar(@{$self->{bce_arr}});

        for (; $i < $newsize; $i++)
        {
            my $bce = Genezzo::BufCa::BufCaElt->new(blocksize => 
                                                 $self->{blocksize});

            unless (defined($bce))
            {
                carp "failed to allocate Buffer Cache Element $i"
                    if warnings::enabled();
                last;
            }
            push (@{$self->{bce_arr}}, $bce);
        }
    }

    if ($newsize < scalar(@{$self->{bce_arr}}))
    {
        my $i = scalar(@{$self->{bce_arr}});

        $i--;

        for (; $i >= $newsize; $i--)
        {
            my $bce = $self->{bce_arr}->[$i];

#            greet $bce;

            # XXX: must be able to lock exclusive here...
            unless (defined($bce) && (!$bce->_pin()))
            {
                carp "failed to pin Buffer Cache Element $i"
                    if warnings::enabled();
                last;
            }

            pop (@{$self->{bce_arr}});
        }
    }
    $self->{virgin}->[1] = scalar(@{$self->{bce_arr}});

    return scalar(@{$self->{bce_arr}});
}


sub ReadBlock 
{
    my $self   = shift;

    my %required = (
                    blocknum => "no blocknum !"
                    );

    my %args = (
                @_);

    return undef
        unless (Validate(\%args, \%required));

    my $bnum = $args{blocknum};
    my $maxrang = scalar(@{$self->{bce_arr}});

    return undef
        unless (NumVal(
                       verbose => warnings::enabled(),
                       name => "Buffer Cache Element",
                       val => $bnum,
                       MIN => 0,
                       MAX => $maxrang));
    # XXX: do exists check?
#    return $self->{bce_arr}->[$bnum];
    my $bce;
    my $tie_bce = tie $bce, "Genezzo::BufCa::PinScalar";

    $bce = $self->{bce_arr}->[$bnum];
    $bce->_pin(1);

    # NB: construct a closure to unpin a bce when its reference
    # is destroyed
    my $unpin_closure = sub {
        my $self = shift;
#    greet $self;
#        whisper "creator: $self->{package}, ";
#        whisper "$self->{filename}, $self->{lineno} - unpin \n";
        unless (defined($self))
        {
            whisper "self already destroyed";
            return;
        }
        my $dee_ref = ${ $self->{ref} };
        unless (defined($dee_ref))
        {
            whisper "self->ref already destroyed";
            return;
        }

        $dee_ref->_pin(-1);
    }; # end unpin_closure sub

    $tie_bce->_DestroyCB($unpin_closure);

    return \$bce;

} # end ReadBlock

sub _dcb  {
    my $self = shift;
    greet $self;
    print "creator: $self->{package}, ";
    print "$self->{filename}, $self->{lineno} - unpin \n";
    my $dee_ref = ${ $self->{ref} };
    $dee_ref->_pin(-1);
}

sub GetFree
{

    # XXX: free blocks must be exclusive locked, then downgraded to
    # share.

    my $self = shift;
    my @outi;

    my $i = 0;
    my $unuse_check = 0;

    if (exists($self->{virgin}))
    {
        $unuse_check = ($self->{virgin}->[0] < $self->{virgin}->[1]);
        if ($unuse_check)
        {
            $i = $self->{virgin}->[0];
            $self->{virgin}->[0]++;
        }
        else
        {
#            whisper "all blocks used -- search for a free one";
        }
    }

  L_for1:
    while ($i < scalar(@{$self->{bce_arr}}))
    {
        my $bce = $self->{bce_arr}->[$i];
        # XXX: must be able to lock exclusive here...
        unless ($bce->_pin())
        {
            push @outi, $i;
#            whisper "got block $i ! \n";
            push @outi, ($self->ReadBlock(blocknum => $i));
            return \@outi;
        }

        if ($unuse_check)
        {
            # if "unused" block was pinned just search from beginning
            $unuse_check = 0;
            $i = 0;
            next;
        }

        $i++;
    }
    return \@outi;

} # end getfree

# XXX: don't write back blocks for array implementation of buffer cache
sub WriteBlock 
{
    my $self   = shift;

    if (0)
    {
#    my $fh     = shift @_;
#    my $blknum = shift @_;
#    my $refbuf = shift @_;
#
#    sysseek ($fh, ($blknum * $Genezzo::Util::DEFBLOCKSIZE), 0 )
#        or die "bad seek - block $blknum : $! \n";
#
#    gnz_write ($fh, $$refbuf, $Genezzo::Util::DEFBLOCKSIZE )
#        == $Genezzo::Util::DEFBLOCKSIZE
#        or die "bad write - block $blknum : $! \n";
    }

    return 1;

} # end WriteBlock

sub DESTROY
{
    my $self   = shift;
#    whoami;

    if (exists($self->{bce_arr}))
    {
        while (scalar(@{$self->{bce_arr}}))
        {
            shift (@{$self->{bce_arr}}) ;
        }
    }

}

END { }       # module clean-up code here (global destructor)

## YOUR CODE GOES HERE

1;  # don't forget to return a true value from the file

__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

 Genezzo::BufCa::BufCa.pm - A simple in-memory buffer cache for a
 single process, without locking.    

=head1 SYNOPSIS

 use Genezzo::BufCa::BufCa;
 
 # get a buffer cache
 my $bc = Genezzo::BufCa::BufCa->new(blocksize => 10, numblocks => 5);
 
 # find a free block
 my $free_arr =  $bc->GetFree();
 
 # get the block number and a reference to a Buffer Cache Element
 my $blocknum = shift (@{$free_arr});
 my $bceref   = shift (@{$free_arr});
 
 # obtain the actual Buffer Cache Element
 my $bce = $$bceref;
 
 # can later use the block number to revisit this Buffer Cache Element
 .
 .
 .
 # get back the same block 
 $bceref = $bc->ReadBlock(blocknum => $blocknum);
 $bce = $$bceref;

=head1 DESCRIPTION

 The in-memory buffer cache is a simple module designed to form the
 basis of a more complicated, file-based, multi-process buffer cache
 with locking.  The buffer cache contains a number of Buffer Cache
 Elements (BCEs), a special wrapper class for simple byte buffers
 (blocks).  The BCE has two callback functions or closures of note:
 
=over 4
 
=item pin
 
 A block is pinned as long as the bceref (returned via GetFree or
 ReadBlock) is in scope.  BufCa uses a scalar tie class to unpin the
 block when the bceref is garbage collected.  The basic pin function
 acts as a form of advisory locking, and could be upgraded to a true
 locking mechanism.

=item dirty

 a block is marked as dirty if it is modified.  

=back

=head1 FUNCTIONS
  
=over 4

=item new

 Takes arguments blocksize (required, in bytes), numblocks (10 by
 default).  Returns a new buffer cache of the specified number of
 blocks of size blocksize.

=item GetFree

 Returns an array @free = (block number, bceref).  The bceref and its
 associated blocknumber are for a block that is currently not in use.
 Note that the block might be dirty.  Also, GetFree is not a space
 allocator -- it only indicates that a block is not in use.

=item ReadBlock  

 Takes argument blocknum, which must be a valid block number.  Returns
 a bceref

=item WriteBlock - unused for in-memory cache

=back

=head2 EXPORT

 None by default.


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
