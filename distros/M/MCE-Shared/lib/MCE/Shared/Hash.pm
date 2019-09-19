###############################################################################
## ----------------------------------------------------------------------------
## Hash helper class.
##
###############################################################################

package MCE::Shared::Hash;

use strict;
use warnings;

use 5.010001;

no warnings qw( threads recursion uninitialized numeric );

our $VERSION = '1.862';

## no critic (TestingAndDebugging::ProhibitNoStrict)

use MCE::Shared::Base ();
use base 'MCE::Shared::Base::Common';
use bytes;

use overload (
   q("")    => \&MCE::Shared::Base::_stringify,
   q(0+)    => \&MCE::Shared::Base::_numify,
   fallback => 1
);

###############################################################################
## ----------------------------------------------------------------------------
## Based on Tie::StdHash from Tie::Hash.
##
###############################################################################

sub TIEHASH {
   my $self = bless {}, shift;
   %{ $self } = @_ if @_;

   $self;
}

sub STORE    { $_[0]->{ $_[1] } = $_[2] }
sub FETCH    { $_[0]->{ $_[1] } }
sub DELETE   { delete $_[0]->{ $_[1] } }
sub FIRSTKEY { my $a = keys %{ $_[0] }; each %{ $_[0] } }
sub NEXTKEY  { each %{ $_[0] } }
sub EXISTS   { exists $_[0]->{ $_[1] } }
sub CLEAR    { %{ $_[0] } = () }
sub SCALAR   { scalar keys %{ $_[0] } }

###############################################################################
## ----------------------------------------------------------------------------
## _find, clone, flush, iterator, keys, pairs, values
##
###############################################################################

# _find ( { getkeys => 1 }, "query string" )
# _find ( { getvals => 1 }, "query string" )
# _find ( "query string" ) # pairs

sub _find {
   my $self   = shift;
   my $params = ref($_[0]) eq 'HASH' ? shift : {};
   my $query  = shift;

   MCE::Shared::Base::_find_hash( $self, $params, $query );
}

# clone ( key [, key, ... ] )
# clone ( )

sub clone {
   my $self = shift;
   my $params = ref($_[0]) eq 'HASH' ? shift : {};
   my %data;

   if ( @_ ) {
      @data{ @_ } = @{ $self }{ @_ };
   }
   else {
      %data = %{ $self };
   }

   $self->clear() if $params->{'flush'};

   bless \%data, ref $self;
}

# flush ( key [, key, ... ] )
# flush ( )

sub flush {
   shift()->clone( { flush => 1 }, @_ );
}

# iterator ( key [, key, ... ] )
# iterator ( "query string" )
# iterator ( )

sub iterator {
   my ( $self, @keys ) = @_;

   if ( ! @keys ) {
      @keys = CORE::keys %{ $self };
   }
   elsif ( @keys == 1 && $keys[0] =~ /^(?:key|val)[ ]+\S\S?[ ]+\S/ ) {
      @keys = $self->keys($keys[0]);
   }

   return sub {
      return unless @keys;
      my $key = shift @keys;
      return ( $key => $self->{ $key } );
   };
}

# keys ( key [, key, ... ] )
# keys ( "query string" )
# keys ( )

sub keys {
   my $self = shift;

   if ( @_ == 1 && $_[0] =~ /^(?:key|val)[ ]+\S\S?[ ]+\S/ ) {
      $self->_find({ getkeys => 1 }, @_);
   }
   else {
      if ( wantarray ) {
         @_ ? map { exists $self->{ $_ } ? $_ : undef } @_
            : CORE::keys %{ $self };
      }
      else {
         scalar CORE::keys %{ $self };
      }
   }
}

# pairs ( key [, key, ... ] )
# pairs ( "query string" )
# pairs ( )

sub pairs {
   my $self = shift;

   if ( @_ == 1 && $_[0] =~ /^(?:key|val)[ ]+\S\S?[ ]+\S/ ) {
      $self->_find(@_);
   }
   else {
      if ( wantarray ) {
         @_ ? map { $_ => $self->{ $_ } } @_
            : %{ $self };
      }
      else {
         scalar CORE::keys %{ $self };
      }
   }
}

# values ( key [, key, ... ] )
# values ( "query string" )
# values ( )

sub values {
   my $self = shift;

   if ( @_ == 1 && $_[0] =~ /^(?:key|val)[ ]+\S\S?[ ]+\S/ ) {
      $self->_find({ getvals => 1 }, @_);
   }
   else {
      if ( wantarray ) {
         @_ ? @{ $self }{ @_ }
            : CORE::values %{ $self };
      }
      else {
         scalar CORE::keys %{ $self };
      }
   }
}

###############################################################################
## ----------------------------------------------------------------------------
## assign, mdel, mexists, mget, mset
##
###############################################################################

# assign ( key, value [, key, value, ... ] )

sub assign {
   $_[0]->clear; shift()->mset(@_);
}

# mdel ( key [, key, ... ] )

sub mdel {
   my $self = shift;
   my ( $cnt, $key ) = ( 0 );

   while ( @_ ) {
      $key = shift;
      $cnt++, delete($self->{ $key }) if ( exists $self->{ $key } );
   }

   $cnt;
}

# mexists ( key [, key, ... ] )

sub mexists {
   my $self = shift;
   my $key;

   while ( @_ ) {
      $key = shift;
      return '' unless ( exists $self->{ $key } );
   }

   1;
}

# mget ( key [, key, ... ] )

sub mget {
   my $self = shift;

   @_ ? @{ $self }{ @_ } : ();
}

# mset ( key, value [, key, value, ... ] )

sub mset {
   my ( $self, $key ) = ( shift );

   while ( @_ ) {
      $key = shift, $self->{ $key } = shift;
   }

   defined wantarray ? scalar CORE::keys %{ $self } : ();
}

###############################################################################
## ----------------------------------------------------------------------------
## Sugar API, mostly resembles http://redis.io/commands#string primitives.
##
###############################################################################

# append ( key, string )

sub append {
   length( $_[0]->{ $_[1] } .= $_[2] // '' );
}

# decr    ( key )
# decrby  ( key, number )
# incr    ( key )
# incrby  ( key, number )
# getdecr ( key )
# getincr ( key )

sub decr    { --$_[0]->{ $_[1] }               }
sub decrby  {   $_[0]->{ $_[1] } -= $_[2] || 0 }
sub incr    { ++$_[0]->{ $_[1] }               }
sub incrby  {   $_[0]->{ $_[1] } += $_[2] || 0 }
sub getdecr {   $_[0]->{ $_[1] }--        // 0 }
sub getincr {   $_[0]->{ $_[1] }++        // 0 }

# getset ( key, value )

sub getset {
   my $old = $_[0]->{ $_[1] };
   $_[0]->{ $_[1] } = $_[2];

   $old;
}

# len ( key )
# len ( )

sub len {
   ( defined $_[1] )
      ? length $_[0]->{ $_[1] }
      : scalar CORE::keys %{ $_[0] };
}

{
   no strict 'refs';

   *{ __PACKAGE__.'::new'    } = \&TIEHASH;
   *{ __PACKAGE__.'::set'    } = \&STORE;
   *{ __PACKAGE__.'::get'    } = \&FETCH;
   *{ __PACKAGE__.'::delete' } = \&DELETE;
   *{ __PACKAGE__.'::exists' } = \&EXISTS;
   *{ __PACKAGE__.'::clear'  } = \&CLEAR;
   *{ __PACKAGE__.'::del'    } = \&delete;
   *{ __PACKAGE__.'::merge'  } = \&mset;
   *{ __PACKAGE__.'::vals'   } = \&values;
}

1;

__END__

###############################################################################
## ----------------------------------------------------------------------------
## Module usage.
##
###############################################################################

=head1 NAME

MCE::Shared::Hash - Hash helper class

=head1 VERSION

This document describes MCE::Shared::Hash version 1.862

=head1 DESCRIPTION

A hash helper class for use as a standalone or managed by L<MCE::Shared>.

=head1 SYNOPSIS

 # non-shared or local construction for use by a single process

 use MCE::Shared::Hash;

 my $ha = MCE::Shared::Hash->new( @pairs );

 # construction for sharing with other threads and processes

 use MCE::Shared;

 my $ha = MCE::Shared->hash( @pairs );

 # hash-like dereferencing

 my $val = $ha->{$key};
 $ha->{$key} = $val;

 %{$ha} = ();

 # OO interface

 if ( !defined ( $val = $ha->get("some_key") ) ) {
    $val = $ha->set( some_key => "some_value" );
 }

 $val   = $ha->set( $key, $val );
 $val   = $ha->get( $key );
 $val   = $ha->delete( $key );              # del is an alias for delete
 $bool  = $ha->exists( $key );
 void   = $ha->clear();
 $len   = $ha->len();                       # scalar keys %{ $ha }
 $len   = $ha->len( $key );                 # length $ha->{ $key }

 $ha2   = $ha->clone( @keys );              # @keys is optional
 $ha3   = $ha->flush( @keys );
 $iter  = $ha->iterator( @keys );           # ($key, $val) = $iter->()
 @keys  = $ha->keys( @keys );
 %pairs = $ha->pairs( @keys );
 @vals  = $ha->values( @keys );             # vals is an alias for values

 $len   = $ha->assign( $key/$val pairs );   # equivalent to ->clear, ->mset
 $cnt   = $ha->mdel( @keys );
 @vals  = $ha->mget( @keys );
 $bool  = $ha->mexists( @keys );            # true if all keys exists
 $len   = $ha->mset( $key/$val pairs );     # merge is an alias for mset

 # included, sugar methods without having to call set/get explicitly

 $len   = $ha->append( $key, $string );     #   $val .= $string
 $val   = $ha->decr( $key );                # --$val
 $val   = $ha->decrby( $key, $number );     #   $val -= $number
 $val   = $ha->getdecr( $key );             #   $val--
 $val   = $ha->getincr( $key );             #   $val++
 $val   = $ha->incr( $key );                # ++$val
 $val   = $ha->incrby( $key, $number );     #   $val += $number
 $old   = $ha->getset( $key, $new );        #   $o = $v, $v = $n, $o

 # pipeline, provides atomicity for shared objects, MCE::Shared v1.09+

 @vals  = $ha->pipeline(                    # ( "a_a", "b_b", "c_c" )
    [ "set", foo => "a_a" ],
    [ "set", bar => "b_b" ],
    [ "set", baz => "c_c" ],
    [ "mget", qw/ foo bar baz / ]
 );

For normal hash behavior, the TIE interface is supported.

 # non-shared or local construction for use by a single process

 use MCE::Shared::Hash;

 tie my %ha, "MCE::Shared::Hash";

 # construction for sharing with other threads and processes

 use MCE::Shared;

 tie my %ha, "MCE::Shared";

 # usage

 my $val;

 if ( !defined ( $val = $ha{some_key} ) ) {
    $val = $ha{some_key} = "some_value";
 }

 $ha{some_key} = 0;

 tied(%ha)->incrby("some_key", 20);
 tied(%ha)->incrby(some_key => 20);

=head1 SYNTAX for QUERY STRING

Several methods take a query string for an argument. The format of the string
is described below. In the context of sharing, the query mechanism is beneficial
for the shared-manager process. It is able to perform the query where the data
resides versus the client-process grep locally involving lots of IPC.

 o Basic demonstration

   @keys = $ha->keys( "query string given here" );
   @keys = $ha->keys( "val =~ /pattern/" );

 o Supported operators: =~ !~ eq ne lt le gt ge == != < <= > >=
 o Multiple expressions delimited by :AND or :OR, mixed case allowed

   "key eq 'some key' :or (val > 5 :and val < 9)"
   "key eq some key :or (val > 5 :and val < 9)"
   "key =~ /pattern/i :And val =~ /pattern/i"
   "val eq foo baz :OR key !~ /pattern/i"

   * key matches on keys in the hash
   * likewise, val matches on values

 o Quoting is optional inside the string

   "key =~ /pattern/i :AND val eq 'foo bar'"   # val eq "foo bar"
   "key =~ /pattern/i :AND val eq foo bar"     # val eq "foo bar"

Examples.

 # search capability key/val: =~ !~ eq ne lt le gt ge == != < <= > >=
 # key/val means to match against actual key/val respectively

 @keys  = $ha->keys( "key eq 'some key' :or (val > 5 :and val < 9)" );
 @keys  = $ha->keys( "key eq some key :or (val > 5 :and val < 9)" );

 @keys  = $ha->keys( "key =~ /$pattern/i" );
 @keys  = $ha->keys( "key !~ /$pattern/i" );
 @keys  = $ha->keys( "val =~ /$pattern/i" );
 @keys  = $ha->keys( "val !~ /$pattern/i" );

 %pairs = $ha->pairs( "key == $number" );
 %pairs = $ha->pairs( "key != $number :and val > 100" );
 %pairs = $ha->pairs( "key <  $number :or key > $number" );
 %pairs = $ha->pairs( "val <= $number" );
 %pairs = $ha->pairs( "val >  $number" );
 %pairs = $ha->pairs( "val >= $number" );

 @vals  = $ha->vals( "key eq $string" );
 @vals  = $ha->vals( "key ne $string with space" );
 @vals  = $ha->vals( "key lt $string :or val =~ /$pat1|$pat2/" );
 @vals  = $ha->vals( "val le $string :and val eq 'foo bar'" );
 @vals  = $ha->vals( "val le $string :and val eq foo bar" );
 @vals  = $ha->vals( "val gt $string" );
 @vals  = $ha->vals( "val ge $string" );

=head1 API DOCUMENTATION

This module may involve TIE when accessing the object via hash-like behavior.
Only shared instances are impacted if doing so. Although likely fast enough for
many use cases, the OO interface is recommended for best performance.

=head2 MCE::Shared::Hash->new ( key, value [, key, value, ... ] )

=head2 MCE::Shared->hash ( key, value [, key, value, ... ] )

Constructs a new object, with an optional list of key-value pairs.

 # non-shared or local construction for use by a single process

 use MCE::Shared::Hash;

 $ha = MCE::Shared::Hash->new( @pairs );
 $ha = MCE::Shared::Hash->new( );

 # construction for sharing with other threads and processes

 use MCE::Shared;

 $ha = MCE::Shared->hash( @pairs );
 $ha = MCE::Shared->hash( );

=head2 assign ( key, value [, key, value, ... ] )

Clears the hash, then sets multiple key-value pairs and returns the number of
keys stored in the hash. This is equivalent to C<clear>, C<mset>.

 $len = $ha->assign( "key1" => "val1", "key2" => "val2" );  # 2
 $len = %{$ha} = ( "key1" => "val1", "key2" => "val2" );    # 4

API available since 1.007.

=head2 clear

Removes all key-value pairs from the hash.

 $ha->clear;
 %{$ha} = ();

=head2 clone ( key [, key, ... ] )

Creates a shallow copy, a C<MCE::Shared::Hash> object. It returns an exact
copy if no arguments are given. Otherwise, the object includes only the given
keys. Keys that do not exist in the hash will have the C<undef> value.

 $ha2 = $ha->clone( "key1", "key2" );
 $ha2 = $ha->clone;

=head2 delete ( key )

Deletes and returns the value by given key or C<undef> if the key does not
exists in the hash.

 $val = $ha->delete( "some_key" );
 $val = delete $ha->{ "some_key" };

=head2 del

C<del> is an alias for C<delete>.

=head2 exists ( key )

Determines if a key exists in the hash.

 if ( $ha->exists( "some_key" ) ) { ... }
 if ( exists $ha->{ "some_key" } ) { ... }

=head2 flush ( key [, key, ... ] )

Same as C<clone>. Though, clears all existing items before returning.

=head2 get ( key )

Gets the value of a hash key or C<undef> if the key does not exists.

 $val = $ha->get( "some_key" );
 $val = $ha->{ "some_key" };

=head2 iterator ( key [, key, ... ] )

Returns a code reference for iterating a list of key-value pairs stored in
the hash when no arguments are given. Otherwise, returns a code reference for
iterating the given keys in the same order. Keys that do not exist will have
the C<undef> value.

The list of keys to return is set when the closure is constructed. Later keys
added to the hash are not included. Subsequently, the C<undef> value is
returned for deleted keys.

 $iter = $ha->iterator;
 $iter = $ha->iterator( "key1", "key2" );

 while ( my ( $key, $val ) = $iter->() ) {
    ...
 }

=head2 iterator ( "query string" )

Returns a code reference for iterating a list of key-value pairs that match
the given criteria. It returns an empty list if the search found nothing.
The syntax for the C<query string> is described above.

 $iter = $ha->iterator( "val eq some_value" );
 $iter = $ha->iterator( "key eq some_key :AND val =~ /sun|moon|air|wind/" );
 $iter = $ha->iterator( "val eq sun :OR val eq moon :OR val eq foo" );
 $iter = $ha->iterator( "key =~ /$pattern/" );

 while ( my ( $key, $val ) = $iter->() ) {
    ...
 }

=head2 keys ( key [, key, ... ] )

Returns all keys in the hash when no arguments are given. Otherwise, returns
the given keys in the same order. Keys that do not exist will have the C<undef>
value. In scalar context, returns the size of the hash.

 @keys = $ha->keys( "key1", "key2" );

 @keys = $ha->keys;     # faster
 @keys = keys %{$ha};   # involves TIE overhead

 $len  = $ha->keys;     # ditto
 $len  = keys %{$ha};

=head2 keys ( "query string" )

Returns only keys that match the given criteria. It returns an empty list
if the search found nothing. The syntax for the C<query string> is described
above. In scalar context, returns the size of the resulting list.

 @keys = $ha->keys( "val eq some_value" );
 @keys = $ha->keys( "key eq some_key :AND val =~ /sun|moon|air|wind/" );
 @keys = $ha->keys( "val eq sun :OR val eq moon :OR val eq foo" );
 $len  = $ha->keys( "key =~ /$pattern/" );

=head2 len ( key )

Returns the size of the hash when no arguments are given. For the given key,
returns the length of the value stored at key or the C<undef> value if the
key does not exists.

 $size = $ha->len;
 $len  = $ha->len( "key1" );
 $len  = length $ha->{ "key1" };

=head2 mdel ( key [, key, ... ] )

Deletes one or more keys in the hash and returns the number of keys deleted.
A given key which does not exist in the hash is not counted.

 $cnt = $ha->mdel( "key1", "key2" );

=head2 mexists ( key [, key, ... ] )

Returns a true value if all given keys exists in the hash. A false value is
returned otherwise.

 if ( $ha->mexists( "key1", "key2" ) ) { ... }

=head2 mget ( key [, key, ... ] )

Gets the values of all given keys. It returns C<undef> for keys which do not
exists in the hash.

 ( $val1, $val2 ) = $ha->mget( "key1", "key2" );

=head2 mset ( key, value [, key, value, ... ] )

Sets multiple key-value pairs in a hash and returns the number of keys stored
in the hash.

 $len = $ha->mset( "key1" => "val1", "key2" => "val2" );

=head2 merge

C<merge> is an alias for C<mset>.

=head2 pairs ( key [, key, ... ] )

Returns key-value pairs in the hash when no arguments are given. Otherwise,
returns key-value pairs for the given keys in the same order. Keys that do not
exist will have the C<undef> value. In scalar context, returns the size of the
hash.

 @pairs = $ha->pairs( "key1", "key2" );

 @pairs = $ha->pairs;
 $len   = $ha->pairs;

=head2 pairs ( "query string" )

Returns only key-value pairs that match the given criteria. It returns an
empty list if the search found nothing. The syntax for the C<query string> is
described above. In scalar context, returns the size of the resulting list.

 @pairs = $ha->pairs( "val eq some_value" );
 @pairs = $ha->pairs( "key eq some_key :AND val =~ /sun|moon|air|wind/" );
 @pairs = $ha->pairs( "val eq sun :OR val eq moon :OR val eq foo" );
 $len   = $ha->pairs( "key =~ /$pattern/" );

=head2 pipeline ( [ func1, @args ], [ func2, @args ], ... )

Combines multiple commands for the object to be processed serially. For shared
objects, the call is made atomically due to single IPC to the shared-manager
process. The C<pipeline> method is fully C<wantarray>-aware and receives a list
of commands and their arguments. In scalar or list context, it returns data
from the last command in the pipeline.

 @vals = $ha->pipeline(                     # ( "a_a", "b_b", "c_c" )
    [ "set", foo => "a_a" ],
    [ "set", bar => "b_b" ],
    [ "set", baz => "c_c" ],
    [ "mget", qw/ foo bar baz / ]
 );

 $len = $ha->pipeline(                      # 3, same as $ha->len
    [ "set", foo => "i_i" ],
    [ "set", bar => "j_j" ],
    [ "set", baz => "k_k" ],
    [ "len" ]
 );

 $ha->pipeline(
    [ "set", foo => "m_m" ],
    [ "set", bar => "n_n" ],
    [ "set", baz => "o_o" ]
 );

Current API available since 1.809.

=head2 pipeline_ex ( [ func1, @args ], [ func2, @args ], ... )

Same as C<pipeline>, but returns data for every command in the pipeline.

 @vals = $ha->pipeline_ex(                  # ( "a_a", "b_b", "c_c" )
    [ "set", foo => "a_a" ],
    [ "set", bar => "b_b" ],
    [ "set", baz => "c_c" ]
 );

Current API available since 1.809.

=head2 set ( key, value )

Sets the value of the given hash key and returns its new value.

 $val = $ha->set( "key", "value" );
 $val = $ha->{ "key" } = "value";

=head2 values ( key [, key, ... ] )

Returns all values in the hash when no arguments are given. Otherwise, returns
values for the given keys in the same order. Keys that do not exist will have
the C<undef> value. In scalar context, returns the size of the hash.

 @vals = $ha->values( "key1", "key2" );

 @vals = $ha->values;     # faster
 @vals = values %{$ha};   # involves TIE overhead

 $len  = $ha->values;     # ditto
 $len  = values %{$ha};

=head2 values ( "query string" )

Returns only values that match the given criteria. It returns an empty list
if the search found nothing. The syntax for the C<query string> is described
above. In scalar context, returns the size of the resulting list.

 @vals = $ha->values( "val eq some_value" );
 @vals = $ha->values( "key eq some_key :AND val =~ /sun|moon|air|wind/" );
 @vals = $ha->values( "val eq sun :OR val eq moon :OR val eq foo" );
 $len  = $ha->values( "key =~ /$pattern/" );

=head2 vals

C<vals> is an alias for C<values>.

=head1 SUGAR METHODS

This module is equipped with sugar methods to not have to call C<set>
and C<get> explicitly. In shared context, the benefit is atomicity and
reduction in inter-process communication.

The API resembles a subset of the Redis primitives
L<http://redis.io/commands#strings> with key representing the hash key.

=head2 append ( key, string )

Appends a value to a key and returns its new length.

 $len = $ha->append( $key, "foo" );

=head2 decr ( key )

Decrements the value of a key by one and returns its new value.

 $num = $ha->decr( $key );

=head2 decrby ( key, number )

Decrements the value of a key by the given number and returns its new value.

 $num = $ha->decrby( $key, 2 );

=head2 getdecr ( key )

Decrements the value of a key by one and returns its old value.

 $old = $ha->getdecr( $key );

=head2 getincr ( key )

Increments the value of a key by one and returns its old value.

 $old = $ha->getincr( $key );

=head2 getset ( key, value )

Sets the value of a key and returns its old value.

 $old = $ha->getset( $key, "baz" );

=head2 incr ( key )

Increments the value of a key by one and returns its new value.

 $num = $ha->incr( $key );

=head2 incrby ( key, number )

Increments the value of a key by the given number and returns its new value.

 $num = $ha->incrby( $key, 2 );

=head1 CREDITS

The implementation is inspired by L<Tie::StdHash>.

=head1 INDEX

L<MCE|MCE>, L<MCE::Hobo>, L<MCE::Shared>

=head1 AUTHOR

Mario E. Roy, S<E<lt>marioeroy AT gmail DOT comE<gt>>

=cut

