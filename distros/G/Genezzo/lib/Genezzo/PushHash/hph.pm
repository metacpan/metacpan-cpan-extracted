#!/usr/bin/perl
#
# $Header: /Users/claude/fuzz/lib/Genezzo/PushHash/RCS/hph.pm,v 7.3 2006/10/20 18:53:09 claude Exp claude $
#
# copyright (c) 2003,2004,2005,2006 Jeffrey I Cohen, all rights reserved, worldwide
#
#
use strict;
use warnings;

package Genezzo::PushHash::hph;

use Genezzo::Util;
use Genezzo::PushHash::PushHash;
use Genezzo::PushHash::PHArray;
use Carp;
use warnings::register;

our @ISA = qw(Genezzo::PushHash::PushHash) ;

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

    carp $args{msg}
        if warnings::enabled();
    
};

# private
sub _init
{
    #whoami;
    #greet @_;
    my $self = shift;
    my %args = (@_);

    # array of push hashes from make_new_chunk
    $self->{ __PACKAGE__ . ":H_ARRAY"  } = [];

    # supply a closure that is a factory to manufacture pushhashes...
    my $phf = $args{factory};

    croak "No PushHash Factory"
        unless (defined($phf));
    $self->{ __PACKAGE__ . ":PushHash_Factory"  } = $phf;

    $self->{ __PACKAGE__ . ":parent"  } = ();
    $self->{ __PACKAGE__ . ":child"   } = ();
    $self->{ __PACKAGE__ . ":sibling" } = ();

    my %chunklist;
    $self->{ __PACKAGE__ . ":ChunkList" } =
        tie %chunklist, "Genezzo::PushHash::PHArray", 
        (arrayref => $self->{ __PACKAGE__ . ":H_ARRAY"  });

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

    return bless $self, $class;

} # end new

our $RIDSEP   = "/"; # row id separator
our $RIDSEPRX = "/"; # row id separator Regular eXpression
sub ridsep
{
    my $self = shift;
    if (scalar(@_))
    {
        $RIDSEP = shift ;
        # XXX: handle case of dot (.) separator. Need some work for
        # other separators that are metachars for regexp.
        if ($RIDSEP =~ m/^\.$/)
        {
            $RIDSEPRX = '\.';
        }
    }

    return $RIDSEP;

} # end name

# private routines
sub _currchunkno
{
# (Get the) current chunk number -- the insert high-water mark

    #whoami;

    my $self = shift;

    my $harr   = $self->{ __PACKAGE__ . ":H_ARRAY"  };
    my $hcount = scalar(@{$harr});

    return (undef)
        unless ($hcount);

    # NOTE: treat array as 1-based (versus 0 based)

    return ($hcount);
}

sub _get_current_chunk
{
    #whoami;

    my $self = shift;

    my $harr   = $self->{ __PACKAGE__ . ":H_ARRAY"  };
    my $hcount = scalar(@{$harr});
    unless ($hcount)
    {
        return $self->_make_new_chunk();
    }
    # NOTE: treat array as 1-based (versus 0 based)
    return $harr->[$hcount - 1];
}

our $MAXCOUNT = -1;

sub _make_new_chunk
{
    #whoami;

    my $self = shift;

    my $harr   = $self->{ __PACKAGE__ . ":H_ARRAY"  };
    my $hcount = scalar(@{$harr});

    if ($MAXCOUNT > 1)
    {
        return undef
            unless ($hcount < $MAXCOUNT);
    }
    my $tiehash = $self->{ __PACKAGE__ . ":PushHash_Factory"  }->();

    unless (defined ($tiehash))
    {
        my %earg = (self => $self, msg => "factory could not allocate pushhash");

        &$GZERR(%earg)
            if (defined($GZERR));

        return undef; # factory out of hashes
    }

    # can only work with pushhash - else die
    croak "not a pushhash"
        unless ($tiehash->isa("Genezzo::PushHash::PushHash"));

    return undef # push failed
        unless( (push @{$harr}, $tiehash) > $hcount);
    
    # NOTE: treat array as 1-based (versus 0 based)
    return $harr->[$hcount];
}

# private
sub _splitrid
{
    # split into 2 parts - chunkno and sliceno
    #whoami @_;
    unless ($_[1] =~ m/$RIDSEPRX/)
    {
        my %earg = (self => $_[0], msg => "could not split key: $_[1] ");

        &$GZERR(%earg)
            if (defined($GZERR));

        return undef; # no rid separator
    }
    my @splitval = split(/$RIDSEPRX/,($_[1]), 2);

#    greet @splitval;

    #  remove leading ridsep from the sliceno
    #$splitval[1] = substr($splitval[1], (length($RIDSEP) + 1))
    #    if (scalar(@splitval) > 1);

    return @splitval;
}

sub _joinrid
{
    my $self = shift;

    return (join ($RIDSEP, @_));
}

# return chunk based upon array offset
sub _get_a_chunk
{
    my $harr   = $_[0]->{ __PACKAGE__ . ":H_ARRAY"  };


    if ($_[1] !~ /\d+/)
    {
        my %earg = (self => $_[0], msg => "Non-numeric key: $_[1] ");

        &$GZERR(%earg)
            if (defined($GZERR));

        return (undef); # protect us from non-numeric array offsets
    }
    if (    ($_[1] > scalar(@{$harr}))
         || ($_[1] < 1))
    {
        my %earg = (self => $_[0], msg => "key out of range: $_[1] ");

        &$GZERR(%earg)
            if (defined($GZERR));

        return (undef);
    }


    return ($harr->[$_[1] - 1]);
}

# parse the rid and  
# return the chunk (a real pushhash, not the chunkno) and sliceno
sub _get_chunk_and_slice
{
    #whoami;
    my ($self, $place) = @_;
    my ($chunkno, $sliceno) = $self->_splitrid($place);
    return (undef)
        unless (defined($chunkno));

    my $chunk  = $self->_get_a_chunk($chunkno);

    unless (defined($chunk))
    {
#        carp "invalid key: $place "
#            if warnings::enabled();
        return (undef);
    }
    return ($chunk, $sliceno);
}

# private
# NOTE: different signature for realstore in hph...
sub _realSTORE
{ 
#    my ($self, $chunk, $sliceno, $value) = @_;
    #whoami;
    #greet @_;
    my $chunk  = $_[1];

    return (undef)
        unless (defined($chunk));
    # NOTE: call STORE method explicitly to avoid autovivify
    $chunk->STORE( $_[2], $_[3]);
}

# HPush public method (not part of standard hash)
sub HPush
{
    # currently loop twice : 
    # 1st time for for current chunk, 2nd attempt with new nextchunk
    # could do multiple tries on nextchunk, though
    #whoami;

    my $numtries = 2;

    for my $ii (1..$numtries)
    {
        my $chunk   = (($ii == 1) ? $_[0]->_get_current_chunk()
                       : $_[0]->_make_new_chunk() );
    
        return (undef)
            unless (defined($chunk));

        my $chunkno = $_[0]->_currchunkno();

        my $sliceno = $chunk->HPush( $_[1] );

        return $_[0]->_joinrid($chunkno, $sliceno)
            if (defined($sliceno));
    }

    return undef ;
}

sub HCount
{
# FETCHSIZE equivalent, i.e. scalar(@array)
    my $grandtot = 0;
    
    my $chunkno = $_[0]->_First_Chunkno();

    while (defined($chunkno))
    {
        my $chunk = $_[0]->_get_a_chunk($chunkno);
        return 0 # XXX XXX: should return undef for error
            unless (defined($chunk));
        $grandtot += $chunk->HCount();
        $chunkno = $_[0]->_Next_Chunkno($chunkno);
    }
    return ($grandtot); 
}

# standard hash methods follow
sub STORE
{
    #whoami;

    my ($self, $place, $value) = @_;

    if ($place =~ m/^PUSH$/)
    {
        $place = $self->HPush($value);
        return undef 
            unless (defined($place));
        return $value;
    } # end if push

    # optimize slightly - check the chunk instead of use EXISTS
    my ($chunk, $sliceno)  = $self->_get_chunk_and_slice($place);

    unless (defined($chunk)
            && $chunk->EXISTS($sliceno))
    {
        my %earg = (self => $self, msg => "No such key: $place ");

        &$GZERR(%earg)
            if (defined($GZERR));

        return undef;
    }
    return $self->_realSTORE ($chunk, $sliceno, $value);
}
 
sub FETCH    
{
    #whoami;
    my ($self, $place) = @_;
    my ($chunk, $sliceno)  = $self->_get_chunk_and_slice($place);

    unless (defined($chunk))
    {
        my %earg = (self => $self, msg => "No such key: $place ");

        &$GZERR(%earg)
            if (defined($GZERR));

        return undef;
    }

    #whoami $chunkno, $sliceno;
    return ($chunk->FETCH($sliceno));
}

sub _First_Chunkno
{
    my $self = shift;
    my $harr   = $self->{ __PACKAGE__ . ":H_ARRAY"  };
    my $hcount = scalar(@{$harr});

    return (undef)
        unless ($hcount);
    return (1);
}

sub _Next_Chunkno
{
    my ($self, $prevkey) = @_;

    return (undef)
        unless (defined ($prevkey));

    my $harr   = $self->{ __PACKAGE__ . ":H_ARRAY"  };
    my $hcount = scalar(@{$harr});

    return (undef)
        unless ($hcount && ($hcount > $prevkey) && ($prevkey > 0));
    $prevkey++;
    return ($prevkey);
}

sub FIRSTKEY 
{ 
    return $_[0]->NEXTKEY($_[0]->_joinrid("0", "0"));
}
sub NEXTKEY  
{ 
    #whoami $_[1];
    my ($self, $prevkey) = @_;

    return (undef)
        unless (defined ($prevkey));

    my ($chunkno, $prevsliceno) = $self->_splitrid($prevkey);

    if ($chunkno < 1) # first first key...
    {
        $prevsliceno = ();
        $chunkno = $self->_First_Chunkno();
    }

    while (defined($chunkno))
    {
        my $sliceno;
        my $chunk = $self->_get_a_chunk($chunkno);

        unless (defined($chunk))
        {   
            # Note: bad stuff, like running out of blocks in the
            # buffer cache
            my %earg = (self => $self, msg => "chunk $chunkno not found!");
            
            &$GZERR(%earg)
                if (defined($GZERR));

            return undef;
        }

        if (defined ($prevsliceno))
        {
            $sliceno = $chunk->NEXTKEY($prevsliceno);
        }
        else
        {
            $sliceno = $chunk->FIRSTKEY();
        }

        return $self->_joinrid($chunkno, $sliceno)
            if (defined($sliceno));

        $prevsliceno = ();
        $chunkno = $self->_Next_Chunkno($chunkno);
    }
    return (undef);
}

sub EXISTS   
{
    my ($self, $place) = @_;
    my ($chunk, $sliceno)  = $self->_get_chunk_and_slice($place);

    return (0)
        unless (defined($chunk));

    return ($chunk->EXISTS($sliceno));
}
sub DELETE   
{
    my ($self, $place) = @_;
    my ($chunk, $sliceno)  = $self->_get_chunk_and_slice($place);

    return (undef)
        unless (defined($chunk));

    return ($chunk->DELETE($sliceno));
}
sub CLEAR
{
    my $chunkno = $_[0]->_First_Chunkno();

    while (defined($chunkno))
    {
        my $chunk = $_[0]->_get_a_chunk($chunkno);
        $chunk->CLEAR()
            if (defined($chunk)); # XXX XXX: should return undef for error
        $chunkno = $_[0]->_Next_Chunkno($chunkno);
    }
    $_[0]->{ __PACKAGE__ . ":H_ARRAY"  } = []; # clear the $harr

}


END {

}

1;

__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Genezzo::PushHash::hph.pm - an impure virtual class module that defines a
*hierarchical* "push hash", a hash that generates its own unique key
for each value.  Values are "pushed" into the hash, similar to pushing
into an array.  Hierarchical pushhashes must be supplied with a
factory method which manufactures additional pushhashes as necessary.


=head1 SYNOPSIS

 use Genezzo::PushHash::hph;

 sub make_fac {
    my $tclass = shift;
    my %args = (
                @_);

    my %td_hash1  = ();

    my $newfunc = 
        sub {
            my $tiehash1 = 
                tie %td_hash1, $tclass, %args;

            return $tiehash1;
        };
    return $newfunc;
 }

 my $fac1 = make_fac('Genezzo::PushHash::PHFixed');

 %args = 
    (
     factory  => $fac1
    );

 my %tied_hash = ();

 my $tie_val = 
    tie %tied_hash, 'Genezzo::PushHash::hph', %args;

 my $newkey = $tie_val->HPush("this is a test");

 $tied_hash{$newkey} = "update this entry";

 my $getcount = $tie_val->HCount();

=head1 DESCRIPTION

A hierarchical pushhash (hph) is a pushhash built upon a collection of
other pushhashes.  A push into the top-level hash is routed into one
of the bottom hashes.  If the bottom hashes are full (push fails), the
top-level pushhash uses the factory method to create or obtain a new
pushhash.

The hph uses a split-level identifier scheme to route STOREs and
FETCHes to the appropriate bottom level hashes.  For example, the
top-level hash might have three children identified with integer
prefixes 1, 2, and 3.  Pushes into hash 1 would return keys 1/1, 1/2,
1/3, etc. until it fills up, at which point the top-level hash would
redirect pushes into hash 2, generating keys 2/1, 2/2, 2/3, etc.  When
key "1/2" is fetched, the top-level hash "splits" the key and directs
child hash "1" to fetch key "2".  Iteration over keys is similar:
the parent interates over the set of child hashes, and each child
iterates over its set of keys.

You may construct hierarchical pushhashes of arbitrary depth.

=head2 EXPORT

=over 4

=item RIDSEP -- (Row) Identifier Separator character - "/" by default.

=item RIDSEPRX -- Regular Expression for RIDSEP - used to handle case
of "."  as separator, or other regexp metachars, for internal RID join
and split operations.

=item MAXCOUNT -- no max if -1, else maximum number of elements for
this hash

=back

=head1 CONCEPTS and INTERNALS - useful for implementors


A hph is constructed of N pushhash "chunks", and the elements of each
chunk are referred to as "slices".  Typically, one chunk is "current"
-- we push into the current chunk until it fills up, at which point
the hph attempts to make a new one.  Key identifiers are called
"rids", and a rid may have multiple parts, e.g.  "1/2/3/4".  When this
rid is split, the first part, "1", is the "chunk number", and the
remainder "2/3/4" is the "slice number".  The basic implementation
uses positive integers for chunk and slice numbers -- zeroes reset the
FIRSTKEY/NEXTKEY mechanism and may indicate errors, among other
things.

The following methods are B<private> to hph and should only be
used in the construction of subclasses and friend classes.

=over 4

=item _currchunkno

get the number of the current (active) chunk.  NOTE WELL: when
constructing push hash classes, remember that "current" has the
specific meaning of the insert high-water mark -- the "current"
insertion point.  It's not necessarily the last chunk that you were
using, or the chunk that is currently cached.

=item _get_current_chunk

return the current chunk

=item _make_new_chunk

construct a new chunk and return it

=item _get_a_chunk

given a chunk number, returns the chunk

=item _get_chunk_and_slice

given a rid, it returns the actual chunk (not the chunk number)
and the slice number.

=item _joinrid/_splitrid

construct and deconstruct rid's from/to the chunknumber and the slice number
using the rid separator regular expression.

=item _First_Chunkno/_Next_Chunkno

methods to iterate over the chunk numbers.

=back

=head1 AUTHOR

Jeffrey I. Cohen, jcohen@genezzo.com

=head1 SEE ALSO

L<Genezzo::PushHash::PushHash>,
L<perl(1)>. 

Copyright (c) 2003, 2004, 2005, 2006 Jeffrey I Cohen.  All rights reserved.

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
