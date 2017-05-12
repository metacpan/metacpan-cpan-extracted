#!/usr/bin/perl
#
# $Header: /Users/claude/fuzz/lib/Genezzo/PushHash/RCS/PushHash.pm,v 7.1 2005/07/19 07:49:03 claude Exp claude $
#
# copyright (c) 2003, 2004 Jeffrey I Cohen, all rights reserved, worldwide
#
#
use strict;
use warnings;

package Genezzo::PushHash::PushHash;

#use Genezzo::Util;
use Tie::Hash;
use Carp;
use warnings::register;

our @ISA = qw(Tie::Hash) ;

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

sub _init
{
    #whoami;
    #greet @_;
    my $self = shift;

    my %needhash = (); # supply a hash reference if needed...

    # NOTE: should always generate a new hash if PushHash is loaded as
    # factory method

    my %args = (hashref => \%needhash,
                @_);

    $self->{ __PACKAGE__ . ":CURR_ID" } = 0;
    $self->{ __PACKAGE__ . ":ADJUST"  } = 0;

    #greet $args{hashref};

    $self->{ref} = $args{hashref};
    # XXX: use UNIVERSAL::isa ?
    my $refthing = ref($self->{ref});
    croak "supplied $refthing , requires HASH" 
        unless ($refthing eq "HASH");

    if (exists($args{GZERR}))
    {
        $self->{GZERR} = $args{GZERR};
    }

    return 1;
}

sub TIEHASH
{ #sub new 
#    greet @_;
    my $invocant = shift;
    my $class = ref($invocant) || $invocant ; 
    my $self = { };

    my %args = (@_);

    return undef
        unless (_init($self,%args));

    return bless $self, $class;

} # end new

our $RADIXPOINT = ".";

# private
sub _thehash
{
    my $self = shift;

    return $self->{ref};
}

# private
my $_Next_ID = sub 
{
    my $self = shift;

    my $oldtime    = $self->{ __PACKAGE__ . ":CURR_ID"};
    my $timeadjust = $self->{ __PACKAGE__ . ":ADJUST"  };

    my $newtime = time ();
    
    if ($newtime != $oldtime) 
    {
        $timeadjust = 0  ;
    }
    else
    {
        $timeadjust++  ;
    }
    
    # add some bits to timestamp if not unique
    my $mytstamp = ($newtime . $RADIXPOINT . $timeadjust); 

    $self->{ __PACKAGE__ . ":CURR_ID"} = $newtime;
    $self->{ __PACKAGE__ . ":ADJUST"  } = $timeadjust;

    return ($mytstamp);
};

# private
sub _realSTORE
{ 
#    my ($self, $place, $value) = @_;
    $_[0]->_thehash()->{$_[1]} = $_[2];
}

# HPush public method (not part of standard hash)
sub HPush
{
    my $place = &$_Next_ID($_[0]);
    return undef 
        unless (defined($place));
    return undef 
        unless ($_[0]->_realSTORE( $place, $_[1]));
    return ($place);
}

sub HCount
{
# FETCHSIZE equivalent, i.e. scalar(@array)
    my $ref = $_[0]->_thehash ();
    return (scalar (keys %{$ref})); 
}

# standard hash methods follow
sub STORE
{
    my ($self, $place, $value) = @_;

    if ($place =~ m/^PUSH$/)
    {
        $place = $self->HPush($value);
        return undef 
            unless (defined($place));
        return $value;
    }
    else
    {
        unless ($self->EXISTS($place))
        {
            my $msg = "No such key: $place ";
            if (defined($GZERR))
            {
                &$GZERR(msg => $msg, self => $self);
            }
            else
            {
                carp $msg
                    if warnings::enabled();
            }
            return undef;
        }
    }

    return $self->_realSTORE ($place, $value);
}
 
sub FETCH    { my $ref = $_[0]->_thehash ();
               $ref->{$_[1]} }
sub FIRSTKEY { 
    #whoami;
    my $ref = $_[0]->_thehash ();
    my $a = scalar keys %{$ref}; 
    each %{$ref} }
sub NEXTKEY  { 
    #whoami $_[1];
    my $ref = $_[0]->_thehash ();
    each %{$ref} }
sub EXISTS   { my $ref = $_[0]->_thehash ();
               exists $ref->{$_[1]} }
sub DELETE   { delete $_[0]->_thehash()->{$_[1]} }
sub CLEAR    { %{$_[0]->_thehash()} = () }


END {

}


1;

__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Genezzo::PushHash::PushHash.pm - an impure virtual class module that defines a
"push hash", a hash that generates its own unique key for each value.
Values are "pushed" into the hash, similar to pushing into an array.

=head1 SYNOPSIS

 use Genezzo::PushHash::PushHash;

 my %tied_hash = ();

 my $tie_val = 
     tie %tied_hash, 'Genezzo::PushHash::PushHash';

 my $newkey = $tie_val->HPush("this is a test");

 $tied_hash{$newkey} = "update this entry";

 my $getcount = $tie_val->HCount();

=head1 DESCRIPTION

While standard perl hashes are a form of associative array, where the
user supplies a key/value pair, a PushHash is more like a multiset
which generates its own unique key for each element.  The preferred
usage is to use the HPush method, which returns the new key, but you
can use the PUSH "pseudo key" to generate a new key, e.g.:

=over 8

$tied_hash{PUSH} = "new value";

=back

Note that the result of the underlying STORE only returns the pushed
value, not the new key.  Also, expressions like:

=over 4

my $pushval = tied_hash{PUSH} = "new value";

=back

can be problematic, since the tie may try to return a FETCH of key
"PUSH", which will not work.  

=head1 WHY

Push hashes can be used to restructure code based upon references to
anonymous hashes or arrays in order to facilitate the persistent
storage of data structures.  Also, they are useful for implementing
shared data structures or data structures with transactional update
semantics, where you would want concurrent access and quick unique key
generation.  In addition, they can be used to create data structures
larger than main memory, or handle cases where multiple keys or key
traversal mechanisms get mapped to the same data.  In other words,
they are similar to SQL database ties or tied DB hashes, but
potentially more flexible and extensible.

=head1 FUNCTIONS

PushHashes support all standard hash operations, with the exception
that you cannot create or insert a user key -- you must push new
entries and use the generated key or basic iteration to retrieve your
data.  It also supports two additional methods, HPush and HCount.
Note that these methods are associated with the tie value (i.e. the
blessed ref for the PushHash class), not the tied hash.

=over 4

=item HPush

HPush returns the new key for each pushed value, or an undef if the
append fails.  It only accepts a single argument, not a list.

my $newkey = $tie_val->HPush("this is a test");

Note that there is not a corresponding "pop" operation, since the
generic PushHash does not define an ordering on the contents of the
hash.

=item HCount

Returns the count of items in the hash -- equivalent to an array
FETCHSIZE, i.e. scalar(@array).  

=back

=head2 Why use a distinctive HPush function versus an array-like PUSH?

HPush is designed to support quick appends of a single value to a
push-hash and return the new key, or return an undef if the push
fails.  The basic perl "push" appends a LIST and returns the new
number of elements in the array.

=over 4

=item Ease of obtaining new key value

HPush returns the new key in a single operation, while push returns
the size of the array.  Unlike an array, the pushhash implementation
does not have to generate keys that are simple ascending integers, so
returning the number of elements in a hash would require extra
operations to obtain the new key.  The classic "push" works well for
arrays since the number of elements in an array is essentially the
offset of the new key.

=item Ease of failure detection

If HPush fails, it returns an undef.  Push requires an extra
calculation to compare the returned count with the previous fetchsize
to see if the push succeeded.

=item Efficiency

For a standard push, you should be able to determine if it fails by
checking the array size before and after the push.  However, for many
hash implementations, counting all the elements in the data structure
may be very expensive.  One example is a disk-based persistent hash,
where the count may require a reading a file to count the entries.
For large or complex data structures, returning the local information
that an append failed should be much cheaper than calculating the
number of valid entries twice.

=back


=head2 Why use a distinctive HCount function versus an array-like FETCHSIZE?


The distinction is subtle.  An array FETCHSIZE is a cheap operation
that just returns the number of elements in the array.  HCount is a
potentially expensive operation that returns the number of valid data
elements in the pushhash.  For the example of the disk-based
persistent hash, the HCount could involve reading multiple files on
disk and special operations to distinguish between valid and deleted
data.  

=head2 EXPORT

RADIXPOINT - by default ".".  A separator for a multipart key.

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
