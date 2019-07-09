use 5.006;
use strict;
use warnings;

package Hash::Ordered;
# ABSTRACT: A fast, pure-Perl ordered hash class

our $VERSION = '0.014';

use Carp ();

use constant {
    _DATA => 0, # unordered data
    _KEYS => 1, # ordered keys
    _INDX => 2, # index into _KEYS (on demand)
    _OFFS => 3, # index offset for optimized shift/unshift
    _GCNT => 4, # garbage count
    _ITER => 5, # for tied hash support
};

use constant {
    _INDEX_THRESHOLD => 25, # max size before indexing/tombstone deletion
    _TOMBSTONE       => \1, # ref to arbitrary scalar
};

# 'overloading.pm' not available until 5.10.1 so emulate with Scalar::Util
BEGIN {
    if ( $] gt '5.010000' ) {
        ## no critic
        eval q{
            sub _stringify { no overloading; "$_[0]" }
            sub _numify { no overloading; 0+$_[0] }
        };
        die $@ if $@;       # uncoverable branch true
    }
    else {
        ## no critic
        eval q{
            require Scalar::Util;
            sub _stringify { sprintf("%s=ARRAY(0x%x)",ref($_[0]),Scalar::Util::refaddr($_[0])) }
            sub _numify { Scalar::Util::refaddr($_[0]) }
        };
        die $@ if $@;       # uncoverable branch true
    }
}

use overload
  q{""}    => \&_stringify,
  q{0+}    => \&_numify,
  q{bool}  => sub { !!scalar %{ $_[0]->[_DATA] } },
  fallback => 1;

#pod =method new
#pod
#pod     $oh = Hash::Ordered->new;
#pod     $oh = Hash::Ordered->new( @pairs );
#pod
#pod Constructs an object, with an optional list of key-value pairs.
#pod
#pod The position of a key corresponds to the first occurrence in the list, but
#pod the value will be updated if the key is seen more than once.
#pod
#pod Current API available since 0.009.
#pod
#pod =cut

sub new {
    my $class = shift;

    Carp::croak("new() requires key-value pairs") unless @_ % 2 == 0;

    my ( %data, @keys, $k );
    while (@_) {
        # must stringify keys for _KEYS array
        $k = shift;
        push @keys, "$k" unless exists $data{$k};
        $data{$k} = shift;
    }
    return bless [ \%data, \@keys, undef, 0, 0 ], $class;
}

#pod =method clone
#pod
#pod     $oh2 = $oh->clone;
#pod     $oh2 = $oh->clone( @keys );
#pod
#pod Creates a shallow copy of an ordered hash object.  If no arguments are
#pod given, it produces an exact copy.  If a list of keys is given, the new
#pod object includes only those keys in the given order.  Keys that aren't
#pod in the original will have the value C<undef>.
#pod
#pod =cut

sub clone {
    my $self = CORE::shift;
    my $clone;
    if (@_) {
        my %subhash;
        @subhash{@_} = @{ $self->[_DATA] }{@_};
        $clone = [ \%subhash, [ map "$_", @_ ], undef, 0, 0 ];
    }
    elsif ( $self->[_INDX] ) {
        $clone =
          [ { %{ $self->[_DATA] } }, [ grep !ref($_), @{ $self->[_KEYS] } ], undef, 0, 0 ];
    }
    else {
        $clone =
          [ { %{ $self->[_DATA] } }, [ @{ $self->[_KEYS] } ], undef, 0, 0 ];

    }
    return bless $clone, ref $self;
}

#pod =method keys
#pod
#pod     @keys = $oh->keys;
#pod     $size = $oh->keys;
#pod
#pod In list context, returns the ordered list of keys.  In scalar context, returns
#pod the number of elements.
#pod
#pod Current API available since 0.005.
#pod
#pod =cut

sub keys {
    my ($self) = @_;
    return wantarray
      ? ( grep !ref($_), @{ $self->[_KEYS] } )
      : @{ $self->[_KEYS] } - $self->[_GCNT];
}

#pod =method values
#pod
#pod     @values = $oh->values;
#pod     @values = $oh->values( @keys );
#pod
#pod Returns an ordered list of values.  If no arguments are given, returns
#pod the ordered values of the entire hash.  If a list of keys is given, returns
#pod values in order corresponding to those keys.  If a key does not exist, C<undef>
#pod will be returned for that value.
#pod
#pod In scalar context, returns the number of elements.
#pod
#pod Current API available since 0.006.
#pod
#pod =cut

sub values {
    my $self = CORE::shift;
    return
      wantarray
      ? ( map { $self->[_DATA]{$_} } ( @_ ? @_ : grep !ref($_), @{ $self->[_KEYS] } ) )
      : @{ $self->[_KEYS] } - $self->[_GCNT];
}

#pod =method get
#pod
#pod     $value = $oh->get("some key");
#pod
#pod Returns the value associated with the key, or C<undef> if it does not exist in
#pod the hash.
#pod
#pod =cut

sub get {
    return $_[0]->[_DATA]{ $_[1] };
}

#pod =method set
#pod
#pod     $oh->set("some key" => "some value");
#pod
#pod Associates a value with a key and returns the value.  If the key does not
#pod already exist in the hash, it will be added at the end.
#pod
#pod =cut

sub set {
    my ( $self, $key ) = @_; # don't copy $_[2] in case it's large
    if ( !exists $self->[_DATA]{$key} ) {
        my $keys = $self->[_KEYS];
        if ( my $indx = $self->[_INDX] ) {
            $indx->{$key} = @$keys ? $indx->{ $keys->[-1] } + 1 : 0;
        }
        CORE::push @{ $self->[_KEYS] }, "$key"; # stringify key
    }
    return $self->[_DATA]{$key} = $_[2];
}

#pod =method exists
#pod
#pod     if ( $oh->exists("some key") ) { ... }
#pod
#pod Test if some key exists in the hash (without creating it).
#pod
#pod =cut

sub exists {
    return exists $_[0]->[_DATA]{ $_[1] };
}

#pod =method delete
#pod
#pod     $value = $oh->delete("some key");
#pod
#pod Removes a key-value pair from the hash and returns the value.
#pod
#pod =cut

sub delete {
    my ( $self, $key ) = @_;
    if ( exists $self->[_DATA]{$key} ) {
        my $keys = $self->[_KEYS];

        # JIT an index if hash is "large"
        if ( !$self->[_INDX] && @$keys > _INDEX_THRESHOLD ) {
            my %indx;
            $indx{ $keys->[$_] } = $_ for 0 .. $#{$keys};
            $self->[_INDX] = \%indx;
        }

        if ( $self->[_INDX] ) {

            # tombstone
            $keys->[ delete( $self->[_INDX]{$key} ) + $self->[_OFFS] ] = _TOMBSTONE;

            # GC keys and remove index if more than half keys are tombstone.
            # Index will be recreated if needed on next delete
            if ( ++$self->[_GCNT] > @$keys / 2 ) {
                @{ $self->[_KEYS] } = grep !ref($_), @{ $self->[_KEYS] };
                $self->[_INDX] = undef;
                $self->[_OFFS] = 0;
                $self->[_GCNT] = 0;
            }
            # or maybe garbage collect start of list
            elsif ( ref( $keys->[0] ) ) {
                my $i = 0;
                $i++ while ref( $keys->[$i] );
                splice @$keys, 0, $i;
                $self->[_GCNT] -= $i;
                $self->[_OFFS] -= $i;
            }
            # or maybe garbage collect end of list
            elsif ( ref( $keys->[-1] ) ) {
                my $i = $#{$keys};
                $i-- while ref( $keys->[$i] );
                $self->[_GCNT] -= $#{$keys} - $i;
                splice @$keys, $i + 1;
            }
        }
        else {
            my $i;
            for ( 0 .. $#{$keys} ) {
                if ( $keys->[$_] eq $key ) { $i = $_; last; }
            }
            splice @$keys, $i, 1;
        }

        return delete $self->[_DATA]{$key};
    }
    return undef; ## no critic
}

#pod =method clear
#pod
#pod     $oh->clear;
#pod
#pod Removes all key-value pairs from the hash.  Returns undef in scalar context
#pod or an empty list in list context.
#pod
#pod Current API available since 0.003.
#pod
#pod =cut

sub clear {
    my ($self) = @_;
    @$self = ( {}, [], undef, 0, 0 );
    return;
}

#pod =method push
#pod
#pod     $oh->push( one => 1, two => 2);
#pod
#pod Add a list of key-value pairs to the end of the ordered hash.  If a key already
#pod exists in the hash, it will be deleted and re-inserted at the end with the new
#pod value.
#pod
#pod Returns the number of keys after the push is complete.
#pod
#pod =cut

sub push {
    my $self = CORE::shift;
    my ( $data, $keys ) = @$self;
    while (@_) {
        my ( $k, $v ) = splice( @_, 0, 2 );
        $self->delete($k) if exists $data->{$k};
        $data->{$k} = $v;
        if ( my $indx = $self->[_INDX] ) {
            $indx->{$k} = @$keys ? $indx->{ $keys->[-1] } + 1 : 0;
        }
        CORE::push @$keys, "$k"; # stringify keys
    }
    return @$keys - $self->[_GCNT];
}

#pod =method pop
#pod
#pod     ($key, $value) = $oh->pop;
#pod     $value = $oh->pop;
#pod
#pod Removes and returns the last key-value pair in the ordered hash.
#pod In scalar context, only the value is returned.  If the hash is empty,
#pod the returned key and value will be C<undef>.
#pod
#pod =cut

sub pop {
    my ($self) = @_;
    if ( $self->[_INDX] ) {
        my $key = $self->[_KEYS][-1];
        return $key, $self->delete($key);
    }
    else {
        my $key = CORE::pop @{ $self->[_KEYS] };
        return defined($key) ? ( $key, delete $self->[_DATA]{$key} ) : ();
    }
}

#pod =method unshift
#pod
#pod     $oh->unshift( one => 1, two => 2 );
#pod
#pod Adds a list of key-value pairs to the beginning of the ordered hash.  If a key
#pod already exists, it will be deleted and re-inserted at the beginning with the
#pod new value.
#pod
#pod Returns the number of keys after the unshift is complete.
#pod
#pod =cut

sub unshift {
    my $self = CORE::shift;
    my ( $data, $keys ) = @$self;
    while (@_) {
        my ( $k, $v ) = splice( @_, -2, 2 );
        $self->delete($k) if exists $data->{$k};
        $data->{$k} = $v;
        CORE::unshift @$keys, "$k"; # stringify keys
        $self->[_INDX]{$k} = -( ++$self->[_OFFS] ) if $self->[_INDX];
    }
    return @$keys - $self->[_GCNT];
}

#pod =method shift
#pod
#pod     ($key, $value) = $oh->shift;
#pod     $value = $oh->shift;
#pod
#pod Removes and returns the first key-value pair in the ordered hash.
#pod In scalar context, only the value is returned.  If the hash is empty,
#pod the returned key and value will be C<undef>.
#pod
#pod =cut

sub shift {
    my ($self) = @_;
    if ( $self->[_INDX] ) {
        my $key = $self->[_KEYS][0];
        return $key, $self->delete($key);
    }
    else {
        my $key = CORE::shift @{ $self->[_KEYS] };
        return defined($key) ? ( $key, delete $self->[_DATA]{$key} ) : ();
    }
}

#pod =method merge
#pod
#pod     $oh->merge( one => 1, two => 2 );
#pod
#pod Merges a list of key-value pairs into the ordered hash.  If a key already
#pod exists, its value is replaced.  Otherwise, the key-value pair is added at
#pod the end of the hash.
#pod
#pod =cut

sub merge {
    my $self = CORE::shift;
    while (@_) {
        my ( $k, $v ) = splice( @_, 0, 2 );
        if ( !exists $self->[_DATA]{$k} ) {
            my $size = CORE::push @{ $self->[_KEYS] }, "$k"; # stringify key
            $self->[_INDX]{$k} = $size - 1 if $self->[_INDX];
        }
        $self->[_DATA]{$k} = $v;
    }
    return @{ $self->[_KEYS] } - $self->[_GCNT];
}

#pod =method as_list
#pod
#pod     @pairs = $oh->as_list;
#pod     @pairs = $oh->as_list( @keys );
#pod
#pod Returns an ordered list of key-value pairs. If no arguments are given, all
#pod pairs in the hash are returned.  If a list of keys is given, the returned list
#pod includes only those key-value pairs in the given order.  Keys that aren't in
#pod the original will have the value C<undef>.
#pod
#pod =cut

sub as_list {
    my $self = CORE::shift;
    return
      map { ; $_ => $self->[_DATA]{$_} }
      ( @_ ? @_ : grep !ref($_), @{ $self->[_KEYS] } );
}

#pod =method iterator
#pod
#pod     $iter = $oh->iterator;
#pod     $iter = $oh->iterator( reverse $oh->keys ); # reverse
#pod
#pod     while ( my ($key,$value) = $iter->() ) { ... }
#pod
#pod Returns a code reference that returns a single key-value pair (in order) on
#pod each invocation, or the empty list if all keys are visited.
#pod
#pod If no arguments are given, the iterator walks the entire hash in order.  If a
#pod list of keys is provided, the iterator walks the hash in that order. Unknown
#pod keys will return C<undef>.
#pod
#pod The list of keys to return is set when the iterator is generator.  Keys added
#pod later will not be returned.  Subsequently deleted keys will return C<undef>
#pod for the value.
#pod
#pod =cut

# usually we avoid copying keys in @_; here we must for the closure
sub iterator {
    my ( $self, @keys ) = @_;
    @keys = grep !ref($_), @{ $self->[_KEYS] } unless @keys;
    my $data = $self->[_DATA];
    return sub {
        return unless @keys;
        my $key = CORE::shift(@keys);
        return ( $key => $data->{$key} );
    };
}

#pod =method preinc
#pod
#pod     $oh->preinc($key);      # like ++$hash{$key}
#pod
#pod This method is sugar for incrementing a key without having to call C<set> and
#pod C<get> explicitly. It returns the new value.
#pod
#pod Current API available since 0.005.
#pod
#pod =cut

sub preinc {
    return ++$_[0]->[_DATA]{ $_[1] };
}

#pod =method postinc
#pod
#pod     $oh->postinc($key);     # like $hash{$key}++
#pod
#pod This method is sugar for incrementing a key without having to call C<set> and
#pod C<get> explicitly.  It returns the old value.
#pod
#pod Current API available since 0.005.
#pod
#pod =cut

sub postinc {
    return $_[0]->[_DATA]{ $_[1] }++;
}

#pod =method predec
#pod
#pod     $oh->predec($key);      # like --$hash{$key}
#pod
#pod This method is sugar for decrementing a key without having to call C<set> and
#pod C<get> explicitly. It returns the new value.
#pod
#pod Current API available since 0.005.
#pod
#pod =cut

sub predec {
    return --$_[0]->[_DATA]{ $_[1] };
}

#pod =method postdec
#pod
#pod     $oh->postdec($key);      # like $hash{$key}--
#pod
#pod This method is sugar for decrementing a key without having to call C<set> and
#pod C<get> explicitly.  It returns the old value.
#pod
#pod Current API available since 0.005.
#pod
#pod =cut

sub postdec {
    return $_[0]->[_DATA]{ $_[1] }--;
}

#pod =method add
#pod
#pod     $oh->add($key, $n);     # like $hash{$key} += $n
#pod
#pod This method is sugar for adding a value to a key without having to call
#pod C<set> and C<get> explicitly. With no value to add, it is treated as "0".
#pod It returns the new value.
#pod
#pod Current API available since 0.005.
#pod
#pod =cut

sub add {
    return $_[0]->[_DATA]{ $_[1] } += $_[2] || 0;
}

#pod =method subtract
#pod
#pod     $oh->subtract($key, $n);  # like $hash{$key} -= $n
#pod
#pod This method is sugar for subtracting a value from a key without having to call
#pod C<set> and C<get> explicitly. With no value to subtract, it is treated as "0".
#pod It returns the new value.
#pod
#pod Current API available since 0.005.
#pod
#pod =cut

sub subtract {
    return $_[0]->[_DATA]{ $_[1] } -= $_[2] || 0;
}

#pod =method concat
#pod
#pod     $oh->concat($key, $str); # like $hash{$key} .= $str
#pod
#pod This method is sugar for concatenating a string onto the value of a key without
#pod having to call C<set> and C<get> explicitly. It returns the new value.  If the
#pod value to append is not defined, no concatenation is done and no warning is
#pod given.
#pod
#pod Current API available since 0.005.
#pod
#pod =cut

sub concat {
    if ( defined $_[2] ) {
        return $_[0]->[_DATA]{ $_[1] } .= $_[2];
    }
    else {
        return $_[0]->[_DATA]{ $_[1] };
    }
}

#pod =method or_equals
#pod
#pod     $oh->or_equals($key, $str); # like $hash{$key} ||= $str
#pod
#pod This method is sugar for assigning to a key if the existing value is false
#pod without having to call C<set> and C<get> explicitly. It returns the new value.
#pod
#pod Current API available since 0.005.
#pod
#pod =cut

sub or_equals {
    my ($self,$key) = @_;

    if ( my $val = $self->get($key) ) {
        return $val;
    }

    return $self->set($key,$_[2]);
}

#pod =method dor_equals
#pod
#pod     $oh->dor_equals($key, $str); # like $hash{$key} //= $str
#pod
#pod This method is sugar for assigning to a key if the existing value is not
#pod defined without having to call C<set> and C<get> explicitly. It returns the new
#pod value.
#pod
#pod Current API available since 0.005.
#pod
#pod =cut

sub dor_equals {
    my ($self,$key) = @_;

    if ( defined( my $val = $self->get($key) ) ) {
        return $val;
    }

    return $self->set($key,$_[2]);
}

#--------------------------------------------------------------------------#
# tied hash support -- slower, but I maybe some thing are more succinct
#--------------------------------------------------------------------------#

{
    no strict 'refs';

    *{ __PACKAGE__ . '::TIEHASH' } = \&new;
    *{ __PACKAGE__ . '::STORE' }   = \&set;
    *{ __PACKAGE__ . '::FETCH' }   = \&get;
    *{ __PACKAGE__ . '::EXISTS' }  = \&exists;
    *{ __PACKAGE__ . '::DELETE' }  = \&delete;
    *{ __PACKAGE__ . '::CLEAR' }   = \&clear;
}

sub FIRSTKEY {
    my ($self) = @_;
    my @keys = grep !ref($_), @{ $self->[_KEYS] };
    $self->[_ITER] = sub {
        return unless @keys;
        return CORE::shift(@keys);
    };
    return $self->[_ITER]->();
}

sub NEXTKEY {
    return defined( $_[0]->[_ITER] ) ? $_[0]->[_ITER]->() : undef;
}

sub SCALAR {
    return scalar %{ $_[0]->[_DATA] };
}

1;


# vim: ts=4 sts=4 sw=4 et:

__END__

=pod

=encoding UTF-8

=head1 NAME

Hash::Ordered - A fast, pure-Perl ordered hash class

=head1 VERSION

version 0.014

=head1 SYNOPSIS

    use Hash::Ordered;

    my $oh = Hash::Ordered->new( a => 1 );

    $oh->get( 'a' );
    $oh->set( 'a' => 2 );

    $oh->exists( 'a' );
    $val = $oh->delete( 'a' );

    @keys  = $oh->keys;
    @vals  = $oh->values;
    @pairs = $oh->as_list

    $oh->push( c => 3, d => 4 );
    $oh->unshift( e => 5, f => 6 );

    ( $k, $v ) = $oh->pop;
    ( $k, $v ) = $oh->shift;

    $iter = $oh->iterator;
    while( ( $k, $v ) = $iter->() ) { ... }

    $copy     = $oh->clone;
    $subset   = $oh->clone( qw/c d/ );
    $reversed = $oh->clone( reverse $oh->keys );

    @value_slice = $oh->values(  qw/c f/ ); # qw/3 6/
    @pairs_slice = $oh->as_list( qw/f e/ ); # qw/f 6 e 5/

    $oh->postinc( 'a' );          # like $oh{a}++
    $oh->add( 'a', 5 );           # like $oh{a} += 5
    $oh->concat( 'a', 'hello' );  # like $oh{a} .= 'hello'
    $oh->or_equals( 'g', '23' );  # like $oh{g} ||= 23
    $oh->dor_equals( 'g', '23' ); # like $oh{g} //= 23

=head1 DESCRIPTION

This module implements an ordered hash, meaning that it associates keys with
values like a Perl hash, but keeps the keys in a consistent order.  Because it
is implemented as an object and manipulated with method calls, it is much
slower than a Perl hash.  This is the cost of keeping order.

However, compared to other B<ordered> hash implementations, Hash::Ordered is
optimized for getting and setting individual elements and is generally faster
at most other tasks as well.  For specific details, see
L<Hash::Ordered::Benchmarks>.

=head1 METHODS

=head2 new

    $oh = Hash::Ordered->new;
    $oh = Hash::Ordered->new( @pairs );

Constructs an object, with an optional list of key-value pairs.

The position of a key corresponds to the first occurrence in the list, but
the value will be updated if the key is seen more than once.

Current API available since 0.009.

=head2 clone

    $oh2 = $oh->clone;
    $oh2 = $oh->clone( @keys );

Creates a shallow copy of an ordered hash object.  If no arguments are
given, it produces an exact copy.  If a list of keys is given, the new
object includes only those keys in the given order.  Keys that aren't
in the original will have the value C<undef>.

=head2 keys

    @keys = $oh->keys;
    $size = $oh->keys;

In list context, returns the ordered list of keys.  In scalar context, returns
the number of elements.

Current API available since 0.005.

=head2 values

    @values = $oh->values;
    @values = $oh->values( @keys );

Returns an ordered list of values.  If no arguments are given, returns
the ordered values of the entire hash.  If a list of keys is given, returns
values in order corresponding to those keys.  If a key does not exist, C<undef>
will be returned for that value.

In scalar context, returns the number of elements.

Current API available since 0.006.

=head2 get

    $value = $oh->get("some key");

Returns the value associated with the key, or C<undef> if it does not exist in
the hash.

=head2 set

    $oh->set("some key" => "some value");

Associates a value with a key and returns the value.  If the key does not
already exist in the hash, it will be added at the end.

=head2 exists

    if ( $oh->exists("some key") ) { ... }

Test if some key exists in the hash (without creating it).

=head2 delete

    $value = $oh->delete("some key");

Removes a key-value pair from the hash and returns the value.

=head2 clear

    $oh->clear;

Removes all key-value pairs from the hash.  Returns undef in scalar context
or an empty list in list context.

Current API available since 0.003.

=head2 push

    $oh->push( one => 1, two => 2);

Add a list of key-value pairs to the end of the ordered hash.  If a key already
exists in the hash, it will be deleted and re-inserted at the end with the new
value.

Returns the number of keys after the push is complete.

=head2 pop

    ($key, $value) = $oh->pop;
    $value = $oh->pop;

Removes and returns the last key-value pair in the ordered hash.
In scalar context, only the value is returned.  If the hash is empty,
the returned key and value will be C<undef>.

=head2 unshift

    $oh->unshift( one => 1, two => 2 );

Adds a list of key-value pairs to the beginning of the ordered hash.  If a key
already exists, it will be deleted and re-inserted at the beginning with the
new value.

Returns the number of keys after the unshift is complete.

=head2 shift

    ($key, $value) = $oh->shift;
    $value = $oh->shift;

Removes and returns the first key-value pair in the ordered hash.
In scalar context, only the value is returned.  If the hash is empty,
the returned key and value will be C<undef>.

=head2 merge

    $oh->merge( one => 1, two => 2 );

Merges a list of key-value pairs into the ordered hash.  If a key already
exists, its value is replaced.  Otherwise, the key-value pair is added at
the end of the hash.

=head2 as_list

    @pairs = $oh->as_list;
    @pairs = $oh->as_list( @keys );

Returns an ordered list of key-value pairs. If no arguments are given, all
pairs in the hash are returned.  If a list of keys is given, the returned list
includes only those key-value pairs in the given order.  Keys that aren't in
the original will have the value C<undef>.

=head2 iterator

    $iter = $oh->iterator;
    $iter = $oh->iterator( reverse $oh->keys ); # reverse

    while ( my ($key,$value) = $iter->() ) { ... }

Returns a code reference that returns a single key-value pair (in order) on
each invocation, or the empty list if all keys are visited.

If no arguments are given, the iterator walks the entire hash in order.  If a
list of keys is provided, the iterator walks the hash in that order. Unknown
keys will return C<undef>.

The list of keys to return is set when the iterator is generator.  Keys added
later will not be returned.  Subsequently deleted keys will return C<undef>
for the value.

=head2 preinc

    $oh->preinc($key);      # like ++$hash{$key}

This method is sugar for incrementing a key without having to call C<set> and
C<get> explicitly. It returns the new value.

Current API available since 0.005.

=head2 postinc

    $oh->postinc($key);     # like $hash{$key}++

This method is sugar for incrementing a key without having to call C<set> and
C<get> explicitly.  It returns the old value.

Current API available since 0.005.

=head2 predec

    $oh->predec($key);      # like --$hash{$key}

This method is sugar for decrementing a key without having to call C<set> and
C<get> explicitly. It returns the new value.

Current API available since 0.005.

=head2 postdec

    $oh->postdec($key);      # like $hash{$key}--

This method is sugar for decrementing a key without having to call C<set> and
C<get> explicitly.  It returns the old value.

Current API available since 0.005.

=head2 add

    $oh->add($key, $n);     # like $hash{$key} += $n

This method is sugar for adding a value to a key without having to call
C<set> and C<get> explicitly. With no value to add, it is treated as "0".
It returns the new value.

Current API available since 0.005.

=head2 subtract

    $oh->subtract($key, $n);  # like $hash{$key} -= $n

This method is sugar for subtracting a value from a key without having to call
C<set> and C<get> explicitly. With no value to subtract, it is treated as "0".
It returns the new value.

Current API available since 0.005.

=head2 concat

    $oh->concat($key, $str); # like $hash{$key} .= $str

This method is sugar for concatenating a string onto the value of a key without
having to call C<set> and C<get> explicitly. It returns the new value.  If the
value to append is not defined, no concatenation is done and no warning is
given.

Current API available since 0.005.

=head2 or_equals

    $oh->or_equals($key, $str); # like $hash{$key} ||= $str

This method is sugar for assigning to a key if the existing value is false
without having to call C<set> and C<get> explicitly. It returns the new value.

Current API available since 0.005.

=head2 dor_equals

    $oh->dor_equals($key, $str); # like $hash{$key} //= $str

This method is sugar for assigning to a key if the existing value is not
defined without having to call C<set> and C<get> explicitly. It returns the new
value.

Current API available since 0.005.

=head1 OVERLOADING

=head2 Boolean

    if ( $oh ) { ... }

When used in boolean context, a Hash::Ordered object is true if it has any entries
and false otherwise.

=head2 String

    say "$oh";

When used in string context, a Hash::Ordered object stringifies like typical
Perl objects. E.g. C<Hash::Ordered=ARRAY(0x7f815302cac0)>

Current API available since 0.005.

=head2 Numeric

    $count = 0 + $oh;

When used in numeric context, a Hash::Ordered object numifies as the decimal
representation of its memory address, just like typical Perl objects. E.g.
C<140268162536552>

For the number of keys, call the L</keys> method in scalar context.

Current API available since 0.005.

=head2 Fallback

Other L<overload> methods are derived from these three, if possible.

=head1 TIED INTERFACE

Using C<tie> is slower than using method calls directly.  But for
compatibility with libraries that can only take hashes, it's available if
you really need it:

    tie my %hash, "Hash::Ordered", @pairs;

If you want to access the underlying object for method calls, use C<tied>:

    tied( %hash )->unshift( @data );

Tied hash API available since 0.005.

=head1 CAVEATS

=head2 Deletion and order modification with push, pop, etc.

This can be expensive, as the ordered list of keys has to be updated.  For
small hashes with no more than 25 keys, keys are found and spliced out with
linear search.  As an optimization for larger hashes, the first change to the
ordered list of keys will construct an index to the list of keys.  Thereafter,
removed keys will be marked with a "tombstone" record.  Tombstones will be
garbage collected whenever the number of tombstones exceeds the number of valid
keys.

These internal implementation details largely shouldn't concern you.  The
important things to note are:

=over 4

=item *

The costs of efficient deletion are deferred until you need it

=item *

Deleting lots of keys will temporarily appear to leak memory until garbage collection occurs

=back

=head1 MOTIVATION

For a long time, I used L<Tie::IxHash> for ordered hashes, but I grew
frustrated with things it lacked, like a cheap way to copy an IxHash object or
a convenient iterator when not using the tied interface.  As I looked at its
implementation, it seemed more complex than I though it needed, with an extra
level of indirection that slows data access.

Given that frustration, I started experimenting with the simplest thing I
thought could work for an ordered hash: a hash of key-value pairs and an array
with key order.

As I worked on this, I also started searching for other modules doing similar
things.  What I found fell broadly into two camps: modules based on tie (even
if they offered an OO interface), and pure OO modules.  They all either lacked
features I deemed necessary or else seemed overly-complex in either
implementation or API.

Hash::Ordered attempts to find the sweet spot with simple implementation,
reasonably good efficiency for most common operations, and a rich, intuitive
API.

After discussions with Mario Roy about the potential use of Hash::Ordered
with L<MCE>, I optimized deletion of larger hashes and provided a tied
interface for compatibility.  Mario's suggestions and feedback about
optimization were quite valuable.  Thank you, Mario!

=head1 SEE ALSO

This section describes other ordered-hash modules I found on CPAN.  For
benchmarking results, see L<Hash::Ordered::Benchmarks>.

=head2 Tie modules

The following modules offer some sort of tie interface.  I don't like ties,
in general, because of the extra indirection involved over a direct method
call. Still, you can make any tied interface into a faster OO one with
C<tied>:

    tied( %tied_hash )->FETCH($key);

L<Tie::Hash::Indexed> is implemented in XS and thus seems promising if
pure-Perl isn't a criterion; it generally fails tests on Perl 5.18 and
above due to the hash randomization change.  Despite being XS, it is slower
than Hash::Ordered at everything exception creation and deletion.

L<Tie::IxHash> is probably the most well known and includes an OO API.
Given the performance problems it has, "well known" is the only real reason
to use it.

These other modules below have very specific designs/limitations and I
didn't find any of them suitable for general purpose use:

=over 4

=item *

L<Tie::Array::AsHash> — array elements split with separator; tie API only

=item *

L<Tie::Hash::Array> — ordered alphabetically; tie API only

=item *

L<Tie::InsertOrderHash> — ordered by insertion; tie API only

=item *

L<Tie::LLHash> — linked-list implementation; quite slow

=item *

L<Tie::StoredOrderHash> — ordered by last update; tie API only

=back

=head2 Other ordered hash modules

Other modules stick with an object-oriented API, with a wide variety of
implementation approaches.

L<Array::AsHash> is essentially an inverse implementation from
Hash::Ordered.  It keeps pairs in an array and uses a hash to index into
the array.  This indirection would already make hash-like operations
slower, but the specific implementation makes it even worse, with
abstractions and function calls that make getting or setting individual
items up to 10x slower than Hash::Ordered.

However, C<Array::AsHash> takes an arrayref to initialize, which is very
fast and can return the list of pairs faster, too.  If you mostly create
and list out very large ordered hashes and very rarely touch individual
entries, I think this could be something to very cautiously consider.

These other modules below have restrictions or particularly complicated
implementations (often relying on C<tie>) and thus I didn't think any of
them really suitable for use:

=over 4

=item *

L<Array::Assign> — arrays with named access; restricted keys

=item *

L<Array::OrdHash> — overloads array/hash deref and uses internal tied data

=item *

L<Data::Pairs> — array of key-value hashrefs; allows duplicate keys

=item *

L<Data::OMap> — array of key-value hashrefs; no duplicate keys

=item *

L<Data::XHash> — blessed, tied hashref with doubly-linked-list

=back

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/dagolden/Hash-Ordered/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/dagolden/Hash-Ordered>

  git clone https://github.com/dagolden/Hash-Ordered.git

=head1 AUTHOR

David Golden <dagolden@cpan.org>

=head1 CONTRIBUTORS

=for stopwords Andy Lester Benct Philip Jonsson Mario Roy

=over 4

=item *

Andy Lester <andy@petdance.com>

=item *

Benct Philip Jonsson <bpjonsson@gmail.com>

=item *

Mario Roy <marioeroy@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by David Golden.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
