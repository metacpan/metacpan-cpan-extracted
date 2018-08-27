package List::Unique::DeterministicOrder;

use 5.010;
use Carp;
use strict;
use warnings;
use List::Util 1.45 qw /uniq/;

our $VERSION = 0.001;

#no autovivification;

use constant {
    _ARRAY => 0, # ordered keys
    _HASH  => 1, # unordered keys
};

use overload
    q{bool}  => sub { !!%{ $_[0]->[_HASH] } },
    fallback => 1;

sub new {
    my ($package, %args) = @_;

    my $self = [ [], {} ];
    
    #  use data if we were passed some
    if (my $data = $args{data}) {
        my %hash;
        @hash{@$data} = (0..$#$data);
        #  rebuild the lists if there were dups
        if (scalar keys %hash != scalar @$data) {
            my @uniq = uniq @$data;
            @hash{@uniq} = (0..$#uniq);
            $self->[_ARRAY] = \@uniq;
        }
        else {
            $self->[_ARRAY] = [@$data];
        }
        $self->[_HASH] = \%hash;
    }
    
    return bless $self, $package;
}

sub exists {
    exists $_[0]->[_HASH]{$_[1]};
}

sub keys {
    wantarray
      ? @{$_[0]->[_ARRAY]}
      : scalar @{$_[0]->[_ARRAY]};
}

sub push {
    return if exists $_[0]->[_HASH]{$_[1]};
    
    push @{$_[0]->[_ARRAY]}, $_[1];
    $_[0]->[_HASH]{$_[1]} = $#{$_[0]->[_ARRAY]};
}

sub pop {
    my $key = pop @{$_[0]->[_ARRAY]};
    delete $_[0]->[_HASH]{$key};
    $key;
}

#  returns undef if key not in hash
sub get_key_pos {
    $_[0]->[_HASH]{$_[1]};
}


#  returns undef if index is out of bounds
sub get_key_at_pos {
    $_[0]->[_ARRAY][$_[1]];
}

#  does nothing if key does not exist
sub delete {
    my ($self, $key) = @_;
    
    #  get the index while cleaning up
    my $pos = CORE::delete $self->[_HASH]{$key}
      // return;
    
    my $move_key = CORE::pop @{$self->[_ARRAY]};
    #  make sure we don't just reinsert the last item
    #  from a single item list
    if ($move_key ne $key) {
        $self->[_HASH]{$move_key} = $pos;
        $self->[_ARRAY][$pos] = $move_key;
    }
    
    return $key;
}

#  Delete the key at the specified position
#  and move the last key into it.
#  Does nothing if key does not exist
sub delete_key_at_pos {
    my ($self, $pos) = @_;
    
    my $key = $self->[_ARRAY][$pos]
      // return;
    
    my $move_key = CORE::pop @{$self->[_ARRAY]};
    CORE::delete $self->[_HASH]{$key};
    
    #  make sure we don't just reinsert the last item
    #  from a single item list
    if ($move_key ne $key) {
        $self->[_HASH]{$move_key} = $pos;
        $self->[_ARRAY][$pos] = $move_key;
    }
    
    return $key;
}

#  Delete the key at the specified position
#  and move the last key into it.
#  Not a true splice, but one day might work
#  on multiple indices.
#sub splice {
#    my ($self, $pos) = @_;
#    
#    my $key = $self->[_ARRAY][$pos]
#      // return;
#    
#    my $move_key = CORE::pop @{$self->[_ARRAY]};
#    $self->[_HASH]{$move_key} = $pos;
#    $self->[_ARRAY][$pos] = $move_key;
#    CORE::delete $self->[_HASH]{$key};
#    return $key;
#}


sub _paranoia {
    my ($self) = @_;
    
    my $array_len = @{$self->[_ARRAY]};
    my $hash_len  = CORE::keys %{$self->[_HASH]};
    croak "array and hash key mismatch" if $array_len != $hash_len;
    
    foreach my $key (@{$self->[_ARRAY]}) {
        croak "Key mismatch between array and hash lists"
          if !CORE::exists $self->[_HASH]{$key}; 
    }
    
    return 1;
}

1;

=head1 NAME

List::Unique::DeterministicOrder - Store and access 
a list of keys using a deterministic order based on
the sequence of insertions and deletions

=head1 VERSION

Version 0.01

=cut

=head1 SYNOPSIS

This module provides a structure to store a list
of keys, without duplicates, and be able to access
them by either key name or index.


    use List::Unique::DeterministicOrder;

    my $foo = List::Unique::DeterministicOrder->new(
        data => [qw /foo bar quux fetangle/]
    );
    
    print $foo->keys;
    #  foo bar quux fetangle
    
    $foo->delete ('bar')
    print $foo->keys;
    #  foo fetangle quux 
    
    print $foo->get_key_at_pos(2);
    #  quux
    print $foo->get_key_at_pos(20);
    #  undef
    
    $foo->push ('bardungle')
    print $foo->keys;
    #  foo fetangle quux bardungle
    
    #  keys are stored only once,
    #  just like with a normal hash
    $foo->push ('fetangle')
    print $foo->keys;
    #  foo fetangle quux bardungle
    
    print $foo->exists ('gelert');
    #  false
    
    print $foo->pop;
    #  bardungle
    

=head1 DISCUSSION

The algorithm used is from
L<https://stackoverflow.com/questions/5682218/data-structure-insert-remove-contains-get-random-element-all-at-o1/5684892#5684892>

The algorithm used inserts keys at the end, but
swaps keys around on deletion.  Hence it is
deterministic and repeatable, but only if the
sequence of insertions and deletions is replicated
exactly.  

So why would one use this in the first place?
The motivating use-case was a randomisation process
where keys would be selected from a pool of keys,
and sometimes inserted.  e.g. the process might
select and remove the 10th key, then the 257th,
then insert a new key, followed by more selections
and removals.  The randomisations needed to 
produce the same results same for the same given
PRNG sequence for reproducibility purposes.


Using a hash to store the data provides rapid access,
but getting the nth key requires the key list be generated
each time, and Perl's hashes do not provide their
keys in a deterministic
order across all versions and platforms.  
Binary searches over sorted lists proved very
effective for a while, but bottlenecks started
to manifest when the data sets became
much larger and the number of lists
became both abundant and lengthy.

Since the order itself does not matter,
only the ability to replicate it, this module was written.

One could also use L<Hash::Ordered>, but it has the overhead
of storing values, which are not needed here.
I also wrote this module before I benchmarked
against L<Hash::Ordered>.  Regardless, this module is faster
for the example use-case described above - see the
benchmarking results in bench.pl (which is part of
this distribution).  That said, some of the implementation
details have been adapted/borrowed from L<Hash::Ordered>.


=head1 METHODS

Note that most methods take a single argument
(if any), so while the method names look
hash-like, this is essentially cosmetic.
In particular, it does not yet support splicing.  

=head2 new

    $foo->new();
    $foo->new(data => [/a b c d e/]);

Create a new object.
Optionally pass data using the data
keyword.  Duplicate keys are
stored once only.


=cut

=head2 exists

True or false for if the key exists.

=cut

=head2 delete

    $foo->delete('some key');

Deletes the key passed as an argument.
Returns the key name if successful, undef if
the key was not found.

=cut

=head2 delete_key_at_pos

    $foo->delete_key_at_pos(1);

Removes a single key from the set at the specified position.


=cut

=head2 get_key_at_pos

    $foo->get_key_at_pos(5);

Returns the key at some position.

=cut

=head2 get_key_pos

    $foo->get_key_pos('quux');

Returns the position of a key.

=cut

=head2 keys

Returns the list of keys in list context,
and the number of keys in scalar context.

=cut

=head2 pop

    $foo->pop;

Removes and returns the last key in the list.

=cut

=head2 push

    $foo->push('quux');

Appends the specified key to the end of the list,
unless it is already in the list.

=cut




=head1 AUTHOR

Shawn Laffan, C<< <shawnlaffan at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests via L<https://github.com/shawnlaffan/perl-List-Unique-DeterministicOrder/issues>.  


=head1 ACKNOWLEDGEMENTS

The algorithm used is from
L<https://stackoverflow.com/questions/5682218/data-structure-insert-remove-contains-get-random-element-all-at-o1/5684892#5684892>

Some implementation details have been borrowed/adapted from L<Hash::Ordered>.

=head1 SEE ALSO

L<Hash::Ordered> (and modules listed in its "See Also" section)

L<List::BinarySearch>

L<List::MoreUtils>


=head1 LICENSE AND COPYRIGHT

Copyright 2018 Shawn Laffan 

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

