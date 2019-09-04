###############################################################################
## ----------------------------------------------------------------------------
## A hybrid LRU-plain cache helper class.
##
## An optimized, pure-Perl LRU implementation with extra performance when
## fetching items from the upper-section of the cache.
##
###############################################################################

package MCE::Shared::Cache;

use strict;
use warnings;

use 5.010001;

no warnings qw( threads recursion uninitialized numeric );

our $VERSION = '1.848';

## no critic (Subroutines::ProhibitExplicitReturnUndef)
## no critic (TestingAndDebugging::ProhibitNoStrict)

use Scalar::Util qw( dualvar looks_like_number );
use Time::HiRes qw( time );

use MCE::Shared::Base ();
use base 'MCE::Shared::Base::Common';
use bytes;

use constant {
   _DATA => 0,  # unordered data
   _KEYS => 1,  # LRU queue
   _INDX => 2,  # index into _KEYS
   _BEGI => 3,  # begin offset value
   _GCNT => 4,  # garbage count
   _EXPI => 5,  # max age, default disabled
   _SIZE => 6,  # max keys, default disabled
   _HREF => 7,  # for hash-like dereferencing
   _ITER => 8,  # for tied hash support
};

use overload (
   q("")    => \&MCE::Shared::Base::_stringify,
   q(0+)    => \&MCE::Shared::Base::_numify,
   q(%{})   => sub {
      no overloading;
      $_[0]->[_HREF] || do {
         # no circular reference to original, therefore no memory leaks
         tie my %h, __PACKAGE__.'::_href', bless([ @{ $_[0] } ], __PACKAGE__);
         $_[0]->[_HREF] = \%h;
      };
   },
   fallback => 1
);

###############################################################################
## ----------------------------------------------------------------------------
## TIEHASH, STORE, FETCH, DELETE, FIRSTKEY, NEXTKEY, EXISTS, CLEAR, SCALAR
##
###############################################################################

# TIEHASH ( max_keys => undef, max_age => undef );  # default
# TIEHASH ( { options }, @pairs );
# TIEHASH ( )

sub TIEHASH {
   my $class = shift;
   my $opts  = ( ref $_[0] eq 'HASH' ) ? shift : undef;

   if ( !defined $opts ) {
      $opts = {};
      for my $cnt ( 1 .. 2 ) {
         if ( @_ && $_[0] =~ /^(max_keys|max_age)$/ ) {
            $opts->{ $1 } = $_[1];
            splice @_, 0, 2;
         }
      }
   }

   my ( $begi, $gcnt ) = ( 0, 0 );
   my $expi = MCE::Shared::Cache::_secs( $opts->{'max_age' } // undef );
   my $size = MCE::Shared::Cache::_size( $opts->{'max_keys'} // undef );

   my $obj = bless [ {}, [], {}, \$begi, \$gcnt, \$expi, \$size ], $class;

   $obj->mset(@_) if @_;
   $obj;
}

# STORE ( key, value [, expires_in ] )

sub STORE {
   my ( $data, $keys, $indx, $begi, $gcnt, $expi, $size ) = @{ $_[0] };
   my $exptime = ( @_ == 4 ) ? $_[3] : ${ $expi };

   if ( !defined $exptime ) {
      $exptime = -1;
   } elsif ( !looks_like_number $exptime ) {
      $exptime = MCE::Shared::Cache::_secs( $exptime );
   }

   # update existing key
   if ( defined ( my $off = $indx->{ $_[1] } ) ) {
      $off -= ${ $begi };

      # update expiration
      $keys->[ $off ] = ( $exptime >= 0 )
         ? dualvar( time + $exptime, $_[1] )
         : dualvar( -1, $_[1] );

      # promote key if not last, inlined for performance
      if ( ! $off ) {
         return $data->{ $_[1] } = $_[2] if @{ $keys } == 1;

         push @{ $keys }, shift @{ $keys };
         $indx->{ $_[1] } = ++${ $begi } + @{ $keys } - 1;

         MCE::Shared::Cache::_gckeys_head( $keys, $begi, $gcnt )
            if ( ${ $gcnt } && !defined $keys->[ 0 ] );

         # safety to not overrun
         $_[0]->purge if ( ${ $begi } > 1e9 );
      }
      elsif ( $off != @{ $keys } - 1 ) {
         push @{ $keys }, delete $keys->[ $off ];
         $indx->{ $_[1] } = ${ $begi } + @{ $keys } - 1;

         # GC keys if the gcnt:size ratio is greater than 2:3
         $_[0]->purge if ( ++${ $gcnt } > @{ $keys } * 0.667 );
      }

      return $data->{ $_[1] } = $_[2];
   }

   # insert key-value pair
   $data->{ $_[1] } = $_[2];
   $indx->{ $_[1] } = ${ $begi } + @{ $keys };

   push @{ $keys }, ( $exptime >= 0 )
      ? dualvar( time + $exptime, $_[1] )
      : dualvar( -1, $_[1] );

   # evict the least used key, inlined for performance
   if ( defined ${ $size } && @{ $keys } - ${ $gcnt } > ${ $size } ) {
      my $key = shift @{ $keys };
      ${ $begi }++; delete $data->{ $key }; delete $indx->{ $key };

      MCE::Shared::Cache::_gckeys_head( $keys, $begi, $gcnt )
         if ( ${ $gcnt } && !defined $keys->[ 0 ] );

      # safety to not overrun
      $_[0]->purge if ( ${ $begi } > 1e9 );
   }

   $_[2];
}

# FETCH ( key )

sub FETCH {

   # cache miss
   return undef if !defined ( my $off = $_[0]->[_INDX]{ $_[1] } );

   # cache hit
   my ( $data, $keys, $indx, $begi, $gcnt ) = @{ $_[0] };

   $off -= ${ $begi };

   # key expired
   $_[0]->del( $_[1] ), return undef if (
      $keys->[ $off ] >= 0 && $keys->[ $off ] < time
   );

   # promote key if not upper half, inlined for performance
   if ( ! $off ) {
      return $data->{ $_[1] } if @{ $keys } == 1;

      push @{ $keys }, shift @{ $keys };
      $indx->{ $_[1] } = ++${ $begi } + @{ $keys } - 1;

      MCE::Shared::Cache::_gckeys_head( $keys, $begi, $gcnt )
         if ( ${ $gcnt } && !defined $keys->[ 0 ] );

      # safety to not overrun
      $_[0]->purge if ( ${ $begi } > 1e9 );
   }
   elsif ( $off - ${ $gcnt } < ( ( @{ $keys } - ${ $gcnt } ) >> 1 ) ) {
      push @{ $keys }, delete $keys->[ $off ];
      $indx->{ $_[1] } = ${ $begi } + @{ $keys } - 1;

      # GC keys if the gcnt:size ratio is greater than 2:3
      $_[0]->purge if ( ++${ $gcnt } > @{ $keys } * 0.667 );
   }

   $data->{ $_[1] };
}

# DELETE ( key )

sub DELETE {
   my ( $data, $keys, $indx, $begi, $gcnt ) = @{ $_[0] };

   return undef if !defined ( my $off = delete $indx->{ $_[1] } );

   $off -= ${ $begi };

   # check the first key
   if ( ! $off ) {
      ${ $begi }++; shift @{ $keys };

      if ( ${ $gcnt } && !defined $keys->[ 0 ] ) {
         MCE::Shared::Cache::_gckeys_head( $keys, $begi, $gcnt );
      } elsif ( ! @{ $keys } ) {
         ${ $begi } = 0;
      }

      return delete $data->{ $_[1] };
   }

   # check the last key
   elsif ( $off == @{ $keys } - 1 ) {
      pop @{ $keys };

      if ( ${ $gcnt } && !defined $keys->[ -1 ] ) {
         MCE::Shared::Cache::_gckeys_tail( $keys, $gcnt );
      } elsif ( ! @{ $keys } ) {
         ${ $begi } = 0;
      }

      return delete $data->{ $_[1] };
   }

   # must be a key somewhere in-between
   $keys->[ $off ] = undef;   # tombstone

   # GC keys if the gcnt:size ratio is greater than 2:3
   $_[0]->purge if ( ++${ $gcnt } > @{ $keys } * 0.667 );

   delete $data->{ $_[1] };
}

# FIRSTKEY ( )

sub FIRSTKEY {
   my $self = shift;
   $self->[_ITER] = [ $self->keys ];

   $self->NEXTKEY;
}

# NEXTKEY ( )

sub NEXTKEY {
   shift @{ $_[0]->[_ITER] };
}

# EXISTS ( key )

sub EXISTS {
   my ( $self, $key ) = @_;
   return '' if !defined ( my $off = $self->[_INDX]{ $key } );

   $off -= ${ $self->[_BEGI] };

   $self->del( $key ), return '' if (
      $self->[_KEYS][ $off ] >= 0 &&
      $self->[_KEYS][ $off ] < time
   );

   1;
}

# CLEAR ( )

sub CLEAR {
   my ( $data, $keys, $indx, $begi, $gcnt ) = @{ $_[0] };

   %{ $data } = @{ $keys } = %{ $indx } = ();
   ${ $begi } = ${ $gcnt } = 0;

   delete $_[0]->[_ITER];

   return;
}

# SCALAR ( )

sub SCALAR {
   $_[0]->_prune_head;

   scalar keys %{ $_[0]->[_DATA] };
}

###############################################################################
## ----------------------------------------------------------------------------
## Internal routines for preserving dualvar KEYS data during freeze-thaw ops.
##
###############################################################################

## Storable freeze-thaw

sub STORABLE_freeze {
   my ( $self, $cloning ) = @_;
   return if $cloning;

   my @TIME; $self->purge;

   for my $key ( @{ $self->[_KEYS] } ) {
      push @TIME, 0 + $key;
   }

   return '', [ @{ $self }, \@TIME ];
}

sub STORABLE_thaw {
   my ( $self, $cloning, $serialized, $ret ) = @_;
   return if $cloning;

   my $TIME = pop @{ $ret };
   @{ $self } = @{ $ret };

   my ( $i, $keys ) = ( 0, $self->[_KEYS] );

   for my $time ( @{ $TIME } ) {
      $keys->[ $i ] = dualvar( $time, $keys->[ $i ] );
      $i++;
   }

   return;
}

## Sereal freeze-thaw

sub FREEZE {
   my ( $self ) = @_;
   my @TIME; $self->purge;

   for my $key ( @{ $self->[_KEYS] } ) {
      push @TIME, 0 + $key;
   }

   return [ @{ $self }, \@TIME ];
}

sub THAW {
   my ( $class, $serializer, $data ) = @_;
   my $TIME = pop @{ $data };
   my $self = $class->new;

   @{ $self } = @{ $data };

   my ( $i, $keys ) = ( 0, $self->[_KEYS] );

   for my $time ( @{ $TIME } ) {
      $keys->[ $i ] = dualvar( $time, $keys->[ $i ] );
      $i++;
   }

   return $self;
}

###############################################################################
## ----------------------------------------------------------------------------
## _gckeys_head, _gckeys_tail, _inskey, _prune_head, _secs, _size
##
###############################################################################

# GC start of list

sub _gckeys_head {
   my ( $keys, $begi, $gcnt ) = @_;
   my $i = 1;

   $i++ until ( defined $keys->[ $i ] );
   ${ $begi } += $i, ${ $gcnt } -= $i;
   splice @{ $keys }, 0, $i;

   return;
}

# GC end of list

sub _gckeys_tail {
   my ( $keys, $gcnt ) = @_;
   my $i = $#{ $keys } - 1;

   $i-- until ( defined $keys->[ $i ] );
   ${ $gcnt } -= $#{ $keys } - $i;
   splice @{ $keys }, $i + 1;

   return;
}

# insert or promote key

sub _inskey {
   my ( $data, $keys, $indx, $begi, $gcnt, $expi, $size ) = @{ $_[0] };
   my $exptime = ( @_ == 3 ) ? $_[2] : ${ $expi };

   if ( !defined $exptime ) {
      $exptime = -1;
   } elsif ( !looks_like_number $exptime ) {
      $exptime = MCE::Shared::Cache::_secs( $exptime );
   }

   # update existing key
   if ( defined ( my $off = $indx->{ $_[1] } ) ) {
      $off -= ${ $begi };

      # unset value if expired
      $data->{ $_[1] } = undef
         if ( $keys->[ $off ] >= 0 && $keys->[ $off ] < time );

      # update expiration
      $keys->[ $off ] = ( $exptime >= 0 )
         ? dualvar( time + $exptime, $_[1] )
         : dualvar( -1, $_[1] );

      # promote key if not last, inlined for performance
      if ( ! $off ) {
         return if @{ $keys } == 1;

         push @{ $keys }, shift @{ $keys };
         $indx->{ $_[1] } = ++${ $begi } + @{ $keys } - 1;

         MCE::Shared::Cache::_gckeys_head( $keys, $begi, $gcnt )
            if ( ${ $gcnt } && !defined $keys->[ 0 ] );

         # safety to not overrun
         $_[0]->purge if ( ${ $begi } > 1e9 );
      }
      elsif ( $off != @{ $keys } - 1 ) {
         push @{ $keys }, delete $keys->[ $off ];
         $indx->{ $_[1] } = ${ $begi } + @{ $keys } - 1;

         # GC keys if the gcnt:size ratio is greater than 2:3
         $_[0]->purge if ( ++${ $gcnt } > @{ $keys } * 0.667 );
      }

      return;
   }

   # insert key
   $indx->{ $_[1] } = ${ $begi } + @{ $keys };

   push @{ $keys }, ( $exptime >= 0 )
      ? dualvar( time + $exptime, $_[1] )
      : dualvar( -1, $_[1] );

   # evict the least used key, inlined for performance
   if ( defined ${ $size } && @{ $keys } - ${ $gcnt } > ${ $size } ) {
      my $key = shift @{ $keys };
      ${ $begi }++; delete $data->{ $key }; delete $indx->{ $key };

      MCE::Shared::Cache::_gckeys_head( $keys, $begi, $gcnt )
         if ( ${ $gcnt } && !defined $keys->[ 0 ] );

      # safety to not overrun
      $_[0]->purge if ( ${ $begi } > 1e9 );
   }

   return;
}

# prune start of list

sub _prune_head {
   my ( $data, $keys, $indx, $begi, $gcnt ) = @{ $_[0] };
   my ( $i, $time ) = ( 0, time );

   for my $k ( @{ $keys } ) {
      $i++, ${ $gcnt }--, next unless ( defined $k );
      last if ( $keys->[ $i ] < 0 || $keys->[ $i ] > $time );

      delete $data->{ $k };
      delete $indx->{ $k };

      $i++;
   }

   ${ $begi } += $i, splice @{ $keys }, 0, $i if $i;

   return;
}

# compute seconds

{
   # seconds, minutes, hours, days, weeks
   my %secs = ( '' => 1, s => 1, m => 60, h => 3600, d => 86400, w => 604800 );

   sub _secs {
      my ( $secs ) = @_;

      return undef if ( !defined $secs || $secs eq 'never' );
      return 0 if ( !$secs || $secs eq 'now' );
      return 0.0001 if ( $secs < 0.0001 );

      $secs = $1 * $secs{ lc($2) }
         if ( $secs =~ /^(\d*\.?\d*)\s*([smhdw]?)/i );

      $secs;
   }
}

# compute size

{
   # kibiBytes (KiB), mebiBytes (MiB)
   my %size = ( '' => 1, k => 1024, m => 1048576 );

   # Digital Information Sizes Calculator
   # http://dr-lex.be/info-stuff/bytecalc.html

   sub _size {
      my ( $size ) = @_;

      return undef if ( !defined $size || $size eq 'unlimited' );
      return 0 if ( !$size || $size < 0 );

      $size = $1 * $size{ lc($2) }
         if ( $size =~ /^(\d*\.?\d*)\s*([km]?)/i );

      $size = int( $size + 0.5 );
   }
}

###############################################################################
## ----------------------------------------------------------------------------
## _find, iterator, keys, pairs, values
##
###############################################################################

# _find ( { getkeys => 1 }, "query string" )
# _find ( { getvals => 1 }, "query string" )
# _find ( "query string" ) # pairs

sub _find {
   my $self   = shift;
   my $params = ref($_[0]) eq 'HASH' ? shift : {};
   my $query  = shift;

   MCE::Shared::Base::_find_hash( $self->[_DATA], $params, $query, $self );
}

# iterator ( key [, key, ... ] )
# iterator ( "query string" )
# iterator ( )

sub iterator {
   my ( $self, @keys ) = @_;
   my $data = $self->[_DATA];

   if ( ! @keys ) {
      @keys = $self->keys;
   }
   elsif ( @keys == 1 && $keys[0] =~ /^(?:key|val)[ ]+\S\S?[ ]+\S/ ) {
      @keys = $self->keys($keys[0]);
   }
   else {
      $self->_prune_head;
   }

   return sub {
      return unless @keys;
      my $key = shift @keys;
      return ( $key => $data->{ $key } );
   };
}

# keys ( key [, key, ... ] )
# keys ( "query string" )
# keys ( )

sub keys {
   my $self = shift;
   $self->_prune_head;

   if ( @_ == 1 && $_[0] =~ /^(?:key|val)[ ]+\S\S?[ ]+\S/ ) {
      $self->_find( { getkeys => 1 }, @_ );
   }
   else {
      if ( wantarray ) {
         my $data = $self->[_DATA];
         @_ ? map { exists $data->{ $_ } ? $_ : undef } @_
            : $self->_keys;
      }
      else {
         scalar CORE::keys %{ $self->[_DATA] };
      }
   }
}

# _keys ( )

sub _keys {
   my $self = shift;

   map { ''. $_ } ${ $self->[_GCNT] }
      ? grep defined($_), reverse @{ $self->[_KEYS] }
      : reverse @{ $self->[_KEYS] };
}

# pairs ( key [, key, ... ] )
# pairs ( "query string" )
# pairs ( )

sub pairs {
   my $self = shift;
   $self->_prune_head;

   if ( @_ == 1 && $_[0] =~ /^(?:key|val)[ ]+\S\S?[ ]+\S/ ) {
      $self->_find( @_ );
   }
   else {
      if ( wantarray ) {
         my $data = $self->[_DATA];
         @_ ? map { $_ => $data->{ $_ } } @_
            : map { $_ => $data->{ $_ } } $self->_keys;
      }
      else {
         scalar CORE::keys %{ $self->[_DATA] };
      }
   }
}

# values ( key [, key, ... ] )
# values ( "query string" )
# values ( )

sub values {
   my $self = shift;
   $self->_prune_head;

   if ( @_ == 1 && $_[0] =~ /^(?:key|val)[ ]+\S\S?[ ]+\S/ ) {
      $self->_find( { getvals => 1 }, @_ );
   }
   else {
      if ( wantarray ) {
         @_ ? @{ $self->[_DATA] }{ @_ }
            : @{ $self->[_DATA] }{ $self->_keys };
      }
      else {
         scalar CORE::keys %{ $self->[_DATA] };
      }
   }
}

###############################################################################
## ----------------------------------------------------------------------------
## assign, max_age, max_keys, mdel, mexists, mget, mset, peek, purge
##
###############################################################################

# assign ( key, value [, key, value, ... ] )

sub assign {
   $_[0]->clear; shift()->mset(@_);
}

# max_age ( [ secs ] )

sub max_age {
   my ( $self, $secs ) = @_;
   my $expi = $self->[_EXPI];

   if ( @_ == 2 && defined $secs ) {
      ${ $expi } = MCE::Shared::Cache::_secs( $secs );
   }
   elsif ( @_ == 2 ) {
      ${ $expi } = undef;
   }

   if ( defined wantarray ) {
      defined ${ $expi } ? ${ $expi } > 0 ? ${ $expi } : 'now' : 'never';
   }
}

# max_keys ( [ size ] )

sub max_keys {
   my ( $self, $size ) = @_;

   if ( @_ == 2 && defined $size ) {
      $size = MCE::Shared::Cache::_size( $size );
      $self->purge;

      my ( $data, $keys, $indx, $begi ) = @{ $self };
      my $count = CORE::keys( %{ $data } ) - $size;

      # evict the least used keys
      while ( $count-- > 0 ) {
         my $key = shift @{ $keys };
         ${ $begi }++; delete $data->{ $key }; delete $indx->{ $key };

         # safety to not overrun
         $self->purge if ( ${ $begi } > 1e9 );
      }

      ${ $self->[_SIZE] } = $size;
   }
   elsif ( @_ == 2 ) {
      ${ $self->[_SIZE] } = undef;
   }

   if ( defined wantarray ) {
      defined ${ $self->[_SIZE] } ? ${ $self->[_SIZE] } : 'unlimited';
   }
}

# mdel ( key [, key, ... ] )

sub mdel {
   my $self = shift;
   my $cnt  = 0;

   while ( @_ ) {
      my $key = shift;
      $cnt++, $self->del( $key ) if $self->exists( $key );
   }

   $cnt;
}

# mexists ( key [, key, ... ] )

sub mexists {
   my $self = shift;

   while ( @_ ) {
      return '' unless $self->exists( shift );
   }

   1;
}

# mget ( key [, key, ... ] )

sub mget {
   my $self = shift;

   @_ ? map { $self->get( $_ ) } @_ : ();
}

# mset ( key, value [, key, value, ... ] )

sub mset {
   my $self = shift;

   while ( @_ ) {
      $self->set( splice( @_, 0, 2 ) );
   }

   defined wantarray ? $self->SCALAR : ();
}

# peek ( key )

sub peek {
   $_[0]->[_DATA]{ $_[1] };
}

# purge ( )

sub purge {
   my ( $data, $keys, $indx, $begi, $gcnt ) = @{ $_[0] };
   my $i;  $i = ${ $begi } = ${ $gcnt } = 0;

   # purge in-place for minimum memory consumption

   my $time = time;

   for my $k ( @{ $keys } ) {
      delete($data->{ $k }), delete($indx->{ $k }), next
         if ( defined $k && $k >= 0 && $k < $time );

      $keys->[ $i ] = $k, $indx->{ $k } = $i++
         if ( defined $k );
   }

   splice @{ $keys }, $i;

   return;
}

###############################################################################
## ----------------------------------------------------------------------------
## Sugar API, mostly resembles http://redis.io/commands#string primitives.
##
###############################################################################

# append ( key, string [, expires_in ] )

sub append {
   $_[0]->_inskey( $_[1], defined $_[3] ? $_[3] : () );
   length( $_[0]->[_DATA]{ $_[1] } .= $_[2] // '' );
}

# decr ( key [, expires_in ] )

sub decr {
   $_[0]->_inskey( $_[1], defined $_[2] ? $_[2] : () );
   --$_[0]->[_DATA]{ $_[1] };
}

# decrby ( key, number [, expires_in ] )

sub decrby {
   $_[0]->_inskey( $_[1], defined $_[3] ? $_[3] : () );
   $_[0]->[_DATA]{ $_[1] } -= $_[2] || 0;
}

# incr ( key [, expires_in ] )

sub incr {
   $_[0]->_inskey( $_[1], defined $_[2] ? $_[2] : () );
   ++$_[0]->[_DATA]{ $_[1] };
}

# incrby ( key, number [, expires_in ] )

sub incrby {
   $_[0]->_inskey( $_[1], defined $_[3] ? $_[3] : () );
   $_[0]->[_DATA]{ $_[1] } += $_[2] || 0;
}

# getdecr ( key [, expires_in ] )

sub getdecr {
   $_[0]->_inskey( $_[1], defined $_[2] ? $_[2] : () );
   $_[0]->[_DATA]{ $_[1] }-- // 0;
}

# getincr ( key [, expires_in ] )

sub getincr {
   $_[0]->_inskey( $_[1], defined $_[2] ? $_[2] : () );
   $_[0]->[_DATA]{ $_[1] }++ // 0;
}

# getset ( key, value [, expires_in ] )

sub getset {
   $_[0]->_inskey( $_[1], defined $_[3] ? $_[3] : () );

   my $old = $_[0]->[_DATA]{ $_[1] };
   $_[0]->[_DATA]{ $_[1] } = $_[2];

   $old;
}

# len ( key )
# len ( )

sub len {
   $_[0]->_prune_head;

   ( defined $_[1] )
      ? length $_[0]->get( $_[1] )
      : scalar CORE::keys %{ $_[0]->[_DATA] };
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
   *{ __PACKAGE__.'::remove' } = \&delete;
   *{ __PACKAGE__.'::merge'  } = \&mset;
   *{ __PACKAGE__.'::vals'   } = \&values;
}

# For on-demand hash-like dereferencing.

package # hide from rpm
   MCE::Shared::Cache::_href;

sub TIEHASH { $_[1] }

1;

__END__

###############################################################################
## ----------------------------------------------------------------------------
## Module usage.
##
###############################################################################

=head1 NAME

MCE::Shared::Cache - A hybrid LRU-plain cache helper class

=head1 VERSION

This document describes MCE::Shared::Cache version 1.848

=head1 DESCRIPTION

A cache helper class for use as a standalone or managed by L<MCE::Shared>.

This module implements a least-recently used (LRU) cache with its origin based
on L<MCE::Shared::Ordhash>, for its performance and low-memory characteristics.
It is both a LRU and plain implementation. LRU logic is applied to new items
and subsequent updates. A fetch however, involves LRU reorder only if the item
is found in the lower section of the cache. This equates to extra performance
for the upper section as fetch behaves similarly to accessing a plain cache.
Upon reaching its size restriction, it prunes items from the bottom of the
cache.

The 50% LRU-mode (bottom section), 50% plain-mode (upper-section) applies to
fetches only.

=head1 SYNOPSIS

 # non-shared or local construction for use by a single process

 use MCE::Shared::Cache;

 my $ca;

 $ca = MCE::Shared::Cache->new(); # max_keys => undef, max_age => undef
 $ca = MCE::Shared::Cache->new( { max_keys => 500 }, @pairs );

 $ca = MCE::Shared::Cache->new( max_keys => "unlimited", max_age => "never" );
 $ca = MCE::Shared::Cache->new( max_keys => undef, max_age => undef ); # ditto
 $ca = MCE::Shared::Cache->new( max_keys => 500, max_age => "1 hour" );
 $ca = MCE::Shared::Cache->new( max_keys => "4 KiB" ); # 4*1024
 $ca = MCE::Shared::Cache->new( max_keys => "1 MiB" ); # 1*1024*1024

 $ca = MCE::Shared::Cache->new( max_age  => "43200 seconds" );
 $ca = MCE::Shared::Cache->new( max_age  => 43200 );   # ditto
 $ca = MCE::Shared::Cache->new( max_age  => "720 minutes" );
 $ca = MCE::Shared::Cache->new( max_age  => "12 hours" );
 $ca = MCE::Shared::Cache->new( max_age  => "0.5 days" );
 $ca = MCE::Shared::Cache->new( max_age  => "1 week" );
 $ca = MCE::Shared::Cache->new( max_age  => undef );   # no expiration
 $ca = MCE::Shared::Cache->new( max_age  => 0 );       # now

 # construction for sharing with other threads and processes

 use MCE::Shared;

 my $ca;

 $ca = MCE::Shared->cache(); # max_keys => undef, max_age => undef
 $ca = MCE::Shared->cache( { max_keys => 500 }, @pairs );

 $ca = MCE::Shared->cache( max_keys => "unlimited", max_age => "never" );
 $ca = MCE::Shared->cache( max_keys => undef, max_age => undef ); # ditto
 $ca = MCE::Shared->cache( max_keys => 500, max_age => "1 hour" );
 $ca = MCE::Shared->cache( max_keys => "4 KiB" ); # 4*1024
 $ca = MCE::Shared->cache( max_keys => "1 MiB" ); # 1*1024*1024

 $ca = MCE::Shared->cache( max_age  => "43200 seconds" );
 $ca = MCE::Shared->cache( max_age  => 43200 );   # ditto
 $ca = MCE::Shared->cache( max_age  => "720 minutes" );
 $ca = MCE::Shared->cache( max_age  => "12 hours" );
 $ca = MCE::Shared->cache( max_age  => "0.5 days" );
 $ca = MCE::Shared->cache( max_age  => "1 week" );
 $ca = MCE::Shared->cache( max_age  => undef );   # no expiration
 $ca = MCE::Shared->cache( max_age  => 0 );       # now

 # hash-like dereferencing

 my $val = $ca->{$key};
 $ca->{$key} = $val;

 %{$ca} = ();

 # OO interface

 if ( !defined ( $val = $ca->get("some_key") ) ) {
    $val = $ca->set( some_key => "some_value" );
 }

 $val   = $ca->set( $key, $val );
 $val   = $ca->get( $key );
 $val   = $ca->delete( $key );              # del is an alias for delete
 $bool  = $ca->exists( $key );
 void   = $ca->clear();
 $len   = $ca->len();                       # scalar keys %{ $ca }
 $len   = $ca->len( $key );                 # length $ca->{ $key }

 $iter  = $ca->iterator( @keys );           # ($key, $val) = $iter->()
 @keys  = $ca->keys( @keys );               # @keys is optional
 %pairs = $ca->pairs( @keys );
 @vals  = $ca->values( @keys );             # vals is an alias for values

 $len   = $ca->assign( $key/$val pairs );   # equivalent to ->clear, ->mset
 $cnt   = $ca->mdel( @keys );
 @vals  = $ca->mget( @keys );
 $bool  = $ca->mexists( @keys );            # true if all keys exists
 $len   = $ca->mset( $key/$val pairs );     # merge is an alias for mset

 # included, sugar methods without having to call set/get explicitly

 $len   = $ca->append( $key, $string );     #   $val .= $string
 $val   = $ca->decr( $key );                # --$val
 $val   = $ca->decrby( $key, $number );     #   $val -= $number
 $val   = $ca->getdecr( $key );             #   $val--
 $val   = $ca->getincr( $key );             #   $val++
 $val   = $ca->incr( $key );                # ++$val
 $val   = $ca->incrby( $key, $number );     #   $val += $number
 $old   = $ca->getset( $key, $new );        #   $o = $v, $v = $n, $o

 # pipeline, provides atomicity for shared objects, MCE::Shared v1.09+

 @vals  = $ca->pipeline(                    # ( "a_a", "b_b", "c_c" )
    [ "set", foo => "a_a" ],
    [ "set", bar => "b_b" ],
    [ "set", baz => "c_c" ],
    [ "mget", qw/ foo bar baz / ]
 );

For normal hash behavior, the TIE interface is supported.

 # non-shared or local construction for use by a single process

 use MCE::Shared::Cache;

 tie my %ca, "MCE::Shared::Cache", max_keys => undef, max_age => undef;
 tie my %ca, "MCE::Shared::Cache", max_keys => 500, max_age => "1 hour";
 tie my %ca, "MCE::Shared::Cache", { max_keys => 500 }, @pairs;

 # construction for sharing with other threads and processes
 # one option is needed minimally to know to use MCE::Shared::Cache

 use MCE::Shared;

 tie my %ca, "MCE::Shared", max_keys => undef, max_age => undef;
 tie my %ca, "MCE::Shared", max_keys => 500, max_age => "1 hour";
 tie my %ca, "MCE::Shared", { max_keys => 500 }, @pairs;

 # usage

 my $val;

 if ( !defined ( $val = $ca{some_key} ) ) {
    $val = $ca{some_key} = "some_value";
 }

 $ca{some_key} = 0;

 tied(%ca)->incrby("some_key", 20);
 tied(%ca)->incrby(some_key => 20);

=head1 SYNTAX for QUERY STRING

Several methods take a query string for an argument. The format of the string
is described below. In the context of sharing, the query mechanism is beneficial
for the shared-manager process. It is able to perform the query where the data
resides versus the client-process grep locally involving lots of IPC.

 o Basic demonstration

   @keys = $ca->keys( "query string given here" );
   @keys = $ca->keys( "val =~ /pattern/" );

 o Supported operators: =~ !~ eq ne lt le gt ge == != < <= > >=
 o Multiple expressions delimited by :AND or :OR, mixed case allowed

   "key eq 'some key' :or (val > 5 :and val < 9)"
   "key eq some key :or (val > 5 :and val < 9)"
   "key =~ /pattern/i :And val =~ /pattern/i"
   "val eq foo baz :OR key !~ /pattern/i"

   * key matches on keys in the cache
   * likewise, val matches on values

 o Quoting is optional inside the string

   "key =~ /pattern/i :AND val eq 'foo bar'"   # val eq "foo bar"
   "key =~ /pattern/i :AND val eq foo bar"     # val eq "foo bar"

Examples.

 # search capability key/val: =~ !~ eq ne lt le gt ge == != < <= > >=
 # key/val means to match against actual key/val respectively

 @keys  = $ca->keys( "key eq 'some key' :or (val > 5 :and val < 9)" );
 @keys  = $ca->keys( "key eq some key :or (val > 5 :and val < 9)" );

 @keys  = $ca->keys( "key =~ /$pattern/i" );
 @keys  = $ca->keys( "key !~ /$pattern/i" );
 @keys  = $ca->keys( "val =~ /$pattern/i" );
 @keys  = $ca->keys( "val !~ /$pattern/i" );

 %pairs = $ca->pairs( "key == $number" );
 %pairs = $ca->pairs( "key != $number :and val > 100" );
 %pairs = $ca->pairs( "key <  $number :or key > $number" );
 %pairs = $ca->pairs( "val <= $number" );
 %pairs = $ca->pairs( "val >  $number" );
 %pairs = $ca->pairs( "val >= $number" );

 @vals  = $ca->vals( "key eq $string" );
 @vals  = $ca->vals( "key ne $string with space" );
 @vals  = $ca->vals( "key lt $string :or val =~ /$pat1|$pat2/" );
 @vals  = $ca->vals( "val le $string :and val eq 'foo bar'" );
 @vals  = $ca->vals( "val le $string :and val eq foo bar" );
 @vals  = $ca->vals( "val gt $string" );
 @vals  = $ca->vals( "val ge $string" );

=head1 API DOCUMENTATION

This module involves TIE when accessing the object via hash-like behavior.
Both non-shared and shared instances are impacted if doing so. Although likely
fast enough for many use cases, the OO interface is recommended for best
performance.

Accessing an item is likely to involve moving its key to the top of the cache.
Various methods described below state with C<Reorder: Yes> or C<Reorder: No>
as an indication.

The methods C<keys>, C<pairs>, and C<values> return the most frequently
accessed items from the upper section of the cache first before the lower
section. Returned values may not be ordered as expected. This abnormally is
normal for this hybrid LRU-plain implementation. It comes from fetches not
involving LRU movement on keys residing in the upper section of the cache.

When C<max_age> is set, accessing an item which has expired will behave
similarly to a non-existing item.

=head2 MCE::Shared::Cache->new ( { options }, key, value [, key, value, ... ] )

=head2 MCE::Shared->cache ( { options }, key, value [, key, value, ... ] )

Constructs a new object.

 # non-shared or local construction for use by a single process

 use MCE::Shared::Cache;

 $ca = MCE::Shared::Cache->new(); # max_keys => undef, max_age => undef
 $ca = MCE::Shared::Cache->new( { max_keys => 500 }, @pairs );

 $ca = MCE::Shared::Cache->new( max_keys => "unlimited", max_age => "never" );
 $ca = MCE::Shared::Cache->new( max_keys => undef, max_age => undef ); # ditto
 $ca = MCE::Shared::Cache->new( max_keys => 500, max_age => "1 hour" );
 $ca = MCE::Shared::Cache->new( max_keys => "4 KiB" ); # 4*1024
 $ca = MCE::Shared::Cache->new( max_keys => "1 MiB" ); # 1*1024*1024

 $ca = MCE::Shared::Cache->new( max_age  => "43200 seconds" );
 $ca = MCE::Shared::Cache->new( max_age  => 43200 );   # ditto
 $ca = MCE::Shared::Cache->new( max_age  => "720 minutes" );
 $ca = MCE::Shared::Cache->new( max_age  => "12 hours" );
 $ca = MCE::Shared::Cache->new( max_age  => "0.5 days" );
 $ca = MCE::Shared::Cache->new( max_age  => "1 week" );
 $ca = MCE::Shared::Cache->new( max_age  => undef );   # no expiration
 $ca = MCE::Shared::Cache->new( max_age  => 0 );       # now

 $ca->assign( @pairs );

 # construction for sharing with other threads and processes

 use MCE::Shared;

 $ca = MCE::Shared->cache(); # max_keys => undef, max_age => undef
 $ca = MCE::Shared->cache( { max_keys => 500 }, @pairs );

 $ca = MCE::Shared->cache( max_keys => "unlimited", max_age => "never" );
 $ca = MCE::Shared->cache( max_keys => undef, max_age => undef ); # ditto
 $ca = MCE::Shared->cache( max_keys => 500, max_age => "1 hour" );
 $ca = MCE::Shared->cache( max_keys => "4 KiB" ); # 4*1024
 $ca = MCE::Shared->cache( max_keys => "1 MiB" ); # 1*1024*1024

 $ca = MCE::Shared->cache( max_age  => "43200 seconds" );
 $ca = MCE::Shared->cache( max_age  => 43200 );   # ditto
 $ca = MCE::Shared->cache( max_age  => "720 minutes" );
 $ca = MCE::Shared->cache( max_age  => "12 hours" );
 $ca = MCE::Shared->cache( max_age  => "0.5 days" );
 $ca = MCE::Shared->cache( max_age  => "1 week" );
 $ca = MCE::Shared->cache( max_age  => undef );   # no expiration
 $ca = MCE::Shared->cache( max_age  => 0 );       # now

 $ca->assign( @pairs );

Reorder: Yes, when given key-value pairs contain duplicate keys

=head2 assign ( key, value [, key, value, ... ] )

Clears the cache, then sets multiple key-value pairs and returns the number of
keys stored in the cache. This is equivalent to C<clear>, C<mset>.

 $len = $ca->assign( "key1" => "val1", "key2" => "val2" );

Reorder: Yes, when given key-value pairs contain duplicate keys

=head2 clear

Removes all key-value pairs from the cache.

 $ca->clear;
 %{$ca} = ();

=head2 delete ( key )

Deletes and returns the value by given key or C<undef> if the key does not
exists in the cache.

 $val = $ca->delete( "some_key" );
 $val = delete $ca->{ "some_key" };

=head2 del

C<del> is an alias for C<delete>.

=head2 exists ( key )

Determines if a key exists in the cache.

 if ( $ca->exists( "some_key" ) ) { ... }
 if ( exists $ca->{ "some_key" } ) { ... }

Reorder: No

=head2 get ( key )

Gets the value of a cache key or C<undef> if the key does not exists.
LRU reordering occurs only if the key is found in the lower section of the
cache. See C<peek> to not promote the key internally to the top of the list.

 $val = $ca->get( "some_key" );
 $val = $ca->{ "some_key" };

Reorder: Yes

=head2 iterator ( key [, key, ... ] )

When C<max_age> is set, prunes any expired keys at the head of the list.

Returns a code reference for iterating a list of key-value pairs stored in
the cache when no arguments are given. Otherwise, returns a code reference for
iterating the given keys in the same order. Keys that do not exist will have
the C<undef> value.

The list of keys to return is set when the closure is constructed. Later keys
added to the hash are not included. Subsequently, the C<undef> value is
returned for deleted keys.

 $iter = $ca->iterator;
 $iter = $ca->iterator( "key1", "key2" );

 while ( my ( $key, $val ) = $iter->() ) {
    ...
 }

Reorder: No

=head2 iterator ( "query string" )

When C<max_age> is set, prunes any expired keys at the head of the list.

Returns a code reference for iterating a list of key-value pairs that match
the given criteria. It returns an empty list if the search found nothing.
The syntax for the C<query string> is described above.

 $iter = $ca->iterator( "val eq some_value" );
 $iter = $ca->iterator( "key eq some_key :AND val =~ /sun|moon|air|wind/" );
 $iter = $ca->iterator( "val eq sun :OR val eq moon :OR val eq foo" );
 $iter = $ca->iterator( "key =~ /$pattern/" );

 while ( my ( $key, $val ) = $iter->() ) {
    ...
 }

Reorder: No

=head2 keys ( key [, key, ... ] )

When C<max_age> is set, prunes any expired keys at the head of the list.

Returns all keys in the cache by most frequently accessed when no arguments
are given. Otherwise, returns the given keys in the same order. Keys that do
not exist will have the C<undef> value. In scalar context, returns the size
of the cache.

 @keys = $ca->keys;
 @keys = $ca->keys( "key1", "key2" );
 $len  = $ca->keys;

Reorder: No

=head2 keys ( "query string" )

When C<max_age> is set, prunes any expired keys at the head of the list.

Returns only keys that match the given criteria. It returns an empty list
if the search found nothing. The syntax for the C<query string> is described
above. In scalar context, returns the size of the resulting list.

 @keys = $ca->keys( "val eq some_value" );
 @keys = $ca->keys( "key eq some_key :AND val =~ /sun|moon|air|wind/" );
 @keys = $ca->keys( "val eq sun :OR val eq moon :OR val eq foo" );
 $len  = $ca->keys( "key =~ /$pattern/" );

Reorder: No

=head2 len ( key )

When C<max_age> is set, prunes any expired keys at the head of the list.

Returns the size of the cache when no arguments are given. For the given key,
returns the length of the value stored at key or the C<undef> value if the
key does not exists.

 $size = $ca->len;
 $len  = $ca->len( "key1" );
 $len  = length $ca->{ "key1" };

Reorder: Yes, only when key is given

=head2 max_age ( [ secs ] )

Returns the maximum age set on the cache or "never" if not defined internally.
It sets the default expiry time when seconds is given.

 $age = $ca->max_age;

 $ca->max_age( "43200 seconds" );
 $ca->max_age( 43200 );     # ditto
 $ca->max_age( "720 minutes" );
 $ca->max_age( "12 hours" );
 $ca->max_age( "0.5 days" );
 $ca->max_age( "1 week" );
 $ca->max_age( undef );     # no expiration
 $ca->max_age( 0 );         # now

=head2 max_keys ( [ size ] )

Returns the size limit set on the cache or "unlimited" if not defined
internally. When size is given, it adjusts the cache accordingly to the
new size by pruning the head of the list if necessary.

 $size = $ca->max_keys;

 $ca->max_keys( undef );    # unlimited
 $ca->max_keys( "4 KiB" );  # 4*1024
 $ca->max_keys( "1 MiB" );  # 1*1024*1024
 $ca->max_keys( 500 );

=head2 mdel ( key [, key, ... ] )

Deletes one or more keys in the cache and returns the number of keys deleted.
A given key which does not exist in the cache is not counted.

 $cnt = $ca->mdel( "key1", "key2" );

=head2 mexists ( key [, key, ... ] )

Returns a true value if all given keys exists in the cache. A false value is
returned otherwise.

 if ( $ca->mexists( "key1", "key2" ) ) { ... }

Reorder: No

=head2 mget ( key [, key, ... ] )

Gets the values of all given keys. It returns C<undef> for keys which do not
exists in the cache.

 ( $val1, $val2 ) = $ca->mget( "key1", "key2" );

Reorder: Yes

=head2 mset ( key, value [, key, value, ... ] )

Sets multiple key-value pairs in a cache and returns the number of keys stored
in the cache.

 $len = $ca->mset( "key1" => "val1", "key2" => "val2" );

Reorder: Yes

=head2 merge

C<merge> is an alias for C<mset>.

=head2 pairs ( key [, key, ... ] )

When C<max_age> is set, prunes any expired keys at the head of the list.

Returns key-value pairs in the cache by most frequently accessed when no
arguments are given. Otherwise, returns key-value pairs for the given keys
in the same order. Keys that do not exist will have the C<undef> value.
In scalar context, returns the size of the cache.

 @pairs = $ca->pairs;
 @pairs = $ca->pairs( "key1", "key2" );
 $len   = $ca->pairs;

Reorder: No

=head2 pairs ( "query string" )

When C<max_age> is set, prunes any expired keys at the head of the list.

Returns only key-value pairs that match the given criteria. It returns an
empty list if the search found nothing. The syntax for the C<query string> is
described above. In scalar context, returns the size of the resulting list.

 @pairs = $ca->pairs( "val eq some_value" );
 @pairs = $ca->pairs( "key eq some_key :AND val =~ /sun|moon|air|wind/" );
 @pairs = $ca->pairs( "val eq sun :OR val eq moon :OR val eq foo" );
 $len   = $ca->pairs( "key =~ /$pattern/" );

Reorder: No

=head2 peek ( key )

Same as C<get> without changing the order of the keys. Gets the value of a
cache key or C<undef> if the key does not exists.

 $val = $ca->get( "some_key" );
 $val = $ca->{ "some_key" };

Reorder: No

=head2 pipeline ( [ func1, @args ], [ func2, @args ], ... )

Combines multiple commands for the object to be processed serially. For shared
objects, the call is made atomically due to single IPC to the shared-manager
process. The C<pipeline> method is fully C<wantarray>-aware and receives a list
of commands and their arguments. In scalar or list context, it returns data
from the last command in the pipeline.

 @vals = $ca->pipeline(                     # ( "a_a", "b_b", "c_c" )
    [ "set", foo => "a_a" ],
    [ "set", bar => "b_b" ],
    [ "set", baz => "c_c" ],
    [ "mget", qw/ foo bar baz / ]
 );

 $len = $ca->pipeline(                      # 3, same as $ca->len
    [ "set", foo => "i_i" ],
    [ "set", bar => "j_j" ],
    [ "set", baz => "k_k" ],
    [ "len" ]
 );

 $ca->pipeline(
    [ "set", foo => "m_m" ],
    [ "set", bar => "n_n" ],
    [ "set", baz => "o_o" ]
 );

Reorder: Very likely, see API on given method

=head2 pipeline_ex ( [ func1, @args ], [ func2, @args ], ... )

Same as C<pipeline>, but returns data for every command in the pipeline.

 @vals = $ca->pipeline_ex(                  # ( "a_a", "b_b", "c_c" )
    [ "set", foo => "a_a" ],
    [ "set", bar => "b_b" ],
    [ "set", baz => "c_c" ]
 );

Reorder: Very likely, see API on given command

=head2 purge ( )

Remove all tombstones and expired data from the cache.

 $ca->purge;

=head2 remove

C<remove> is an alias for C<delete>.

=head2 set ( key, value [, expires_in ] )

Sets the value of the given cache key and returns its new value.
Optionally in v1.839 and later releases, give the number of seconds
before the key is expired.

 $val = $ca->set( "key", "value" );
 $val = $ca->{ "key" } = "value";

 $val = $ca->set( "key", "value", 3600  );  # or "60 minutes"
 $val = $ca->set( "key", "value", undef );  # or "never"
 $val = $ca->set( "key", "value", 0     );  # or "now"

 $val = $ca->set( "key", "value", "2 seconds" );  # or "2s"
 $val = $ca->set( "key", "value", "2 minutes" );  # or "2m"
 $val = $ca->set( "key", "value", "2 hours"   );  # or "2h"
 $val = $ca->set( "key", "value", "2 days"    );  # or "2d"
 $val = $ca->set( "key", "value", "2 weeks"   );  # or "2w"

Reorder: Yes

=head2 values ( key [, key, ... ] )

When C<max_age> is set, prunes any expired keys at the head of the list.

Returns all values in the cache by most frequently accessed when no arguments
are given. Otherwise, returns values for the given keys in the same order.
Keys that do not exist will have the C<undef> value. In scalar context,
returns the size of the cache.

 @vals = $ca->values;
 @vals = $ca->values( "key1", "key2" );
 $len  = $ca->values;

Reorder: No

=head2 values ( "query string" )

When C<max_age> is set, prunes any expired keys at the head of the list.

Returns only values that match the given criteria. It returns an empty list
if the search found nothing. The syntax for the C<query string> is described
above. In scalar context, returns the size of the resulting list.

 @vals = $ca->values( "val eq some_value" );
 @vals = $ca->values( "key eq some_key :AND val =~ /sun|moon|air|wind/" );
 @vals = $ca->values( "val eq sun :OR val eq moon :OR val eq foo" );
 $len  = $ca->values( "key =~ /$pattern/" );

Reorder: No

=head2 vals

C<vals> is an alias for C<values>.

=head1 SUGAR METHODS

This module is equipped with sugar methods to not have to call C<set>
and C<get> explicitly. In shared context, the benefit is atomicity and
reduction in inter-process communication.

The API resembles a subset of the Redis primitives
L<http://redis.io/commands#strings> with key representing the cache key.

Optionally in v1.839 and later releases, give the number of seconds
before the key is expired, similarly to C<set>.

=head2 append ( key, string [, expires_in ] )

Appends a value to a key and returns its new length.

 $len = $ca->append( $key, "foo" );

Reorder: Yes

=head2 decr ( key [, expires_in ] )

Decrements the value of a key by one and returns its new value.

 $num = $ca->decr( $key );

Reorder: Yes

=head2 decrby ( key, number [, expires_in ] )

Decrements the value of a key by the given number and returns its new value.

 $num = $ca->decrby( $key, 2 );

Reorder: Yes

=head2 getdecr ( key [, expires_in ] )

Decrements the value of a key by one and returns its old value.

 $old = $ca->getdecr( $key );

Reorder: Yes

=head2 getincr ( key [, expires_in ] )

Increments the value of a key by one and returns its old value.

 $old = $ca->getincr( $key );

Reorder: Yes

=head2 getset ( key, value [, expires_in ] )

Sets the value of a key and returns its old value.

 $old = $ca->getset( $key, "baz" );

Reorder: Yes

=head2 incr ( key [, expires_in ] )

Increments the value of a key by one and returns its new value.

 $num = $ca->incr( $key );

Reorder: Yes

=head2 incrby ( key, number [, expires_in ] )

Increments the value of a key by the given number and returns its new value.

 $num = $ca->incrby( $key, 2 );

Reorder: Yes

=head1 INTERNAL METHODS

Internal C<Sereal> freeze-thaw hooks for exporting shared-cache object.

=over 3

=item FREEZE

=item THAW

=back

Internal C<Storable> freeze-thaw hooks for exporting shared-cache object.

=over 3

=item STORABLE_freeze

=item STORABLE_thaw

=back

=head1 PERFORMANCE TESTING

One might want to benchmark this module. If yes, remember to use the non-shared
construction for running on a single core.

 use MCE::Shared::Cache;

 my $cache = MCE::Shared::Cache->new( max_keys => 500_000 );

Otherwise, the following is a parallel version for a L<benchmark script|https://blog.celogeek.com/201401/426/perl-benchmark-cache-with-expires-and-max-size> found on the web. The serial version was created by Celogeek for benchmarking various caching modules.

The MCE C<progress> option makes it possible to track progress while running
parallel. This script involves IPC to and from the shared-manager process,
where the data resides. In regards to IPC, fetches may take longer on Linux
versus Darwin or FreeBSD.

 #!/usr/bin/perl

 use strict;
 use warnings;
 use feature qw( say );

 use Digest::MD5 qw( md5_base64 );
 use Time::HiRes qw( time );
 use MCE 1.814;
 use MCE::Shared;

 $| = 1; srand(0);

 # construct shared variables
 # serialization is handled automatically

 my $c     = MCE::Shared->cache( max_keys => 500_000 );
 my $found = MCE::Shared->scalar( 0 );

 # construct and spawn MCE workers
 # workers increment a local variable $f

 my $mce = MCE->new(
     chunk_size  => 4000,
     max_workers => 4,
     user_func   => sub {
         my ($mce, $chunk_ref, $chunk_id) = @_;
         if ( $mce->user_args()->[0] eq 'setter' ) {
             for ( @{ $chunk_ref } ) { $c->set($_, {md5 => $_})  }
         }
         else {
             my $f = 0;
             for ( @{ $chunk_ref } ) { $f++ if ref $c->get($_) eq 'HASH' }
             $found->incrby($f);
         }
     }
 )->spawn();

 say "Mapping";
 my @todo = map { md5_base64($_) } ( 1 .. 600_000 );

 say "Starting";
 my ( $read, $write );

 {
     my $s = time;
     $mce->process({
         progress  => sub { print "Write: $_[0]\r" },
         user_args => [ 'setter' ],
     }, \@todo);
     $write = time - $s;
 }

 say "Write: ", sprintf("%0.3f", scalar(@todo) / $write);

 {
     my $s = time;
     $found->set(0);
     $mce->process({
         progress  => sub { print "Read $_[0]\r" },
         user_args => [ 'getter' ],
     }, \@todo);
     $read = time - $s;
 }

 $mce->shutdown();

 say "Read : ", sprintf("%0.3f", scalar(@todo) / $read);
 say "Found: ", $found->get();

The C<progress> option is further described on Metacpan. Several examples
are provided, accommodating all input data-types in MCE.

L<Progress Demonstrations|https://metacpan.org/pod/MCE::Core#PROGRESS-DEMONSTRATIONS>

=head1 SEE ALSO

=over 3

=item * L<CHI>

=item * L<Cache::FastMmap>

=item * L<Cache::LRU>

=item * L<Cache::Ref>

=item * L<Tie::Cache::LRU>

=item * L<Tie::Cache::LRU::Expires>

=back

=head1 INDEX

L<MCE|MCE>, L<MCE::Hobo>, L<MCE::Shared>

=head1 AUTHOR

Mario E. Roy, S<E<lt>marioeroy AT gmail DOT comE<gt>>

=cut

