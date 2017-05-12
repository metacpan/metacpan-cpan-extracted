use warnings;
use strict;

package Jifty::DBI::Record::Memcached;

use Jifty::DBI::Record;
use Jifty::DBI::Handle;
use base qw (Jifty::DBI::Record);

use Cache::Memcached;


=head1 NAME

Jifty::DBI::Record::Memcached - records with caching behavior

=head1 SYNOPSIS

  package Myrecord;
  use base qw/Jifty::DBI::Record::Memcached/;

=head1 DESCRIPTION

This module subclasses the main L<Jifty::DBI::Record> package to add a
caching layer.

The public interface remains the same, except that records which have
been loaded in the last few seconds may be reused by subsequent get
or load methods without retrieving them from the database.

=head1 METHODS

=cut


use vars qw/$MEMCACHED/;




# Function: _init
# Type    : class ctor
# Args    : see Jifty::DBI::Record::new
# Lvalue  : Jifty::DBI::Record::Cachable

sub _init () {
    my ( $self, @args ) = @_;
    $MEMCACHED ||= Cache::Memcached->new( {$self->memcached_config} );
    $self->SUPER::_init(@args);
}

=head2 load_from_hash

Overrides the implementation from L<Jifty::DBI::Record> to add support for caching.

=cut

sub load_from_hash {
    my $self = shift;

    # Blow away the primary cache key since we're loading.
    if ( ref($self) ) {
        my ( $rvalue, $msg ) = $self->SUPER::load_from_hash(@_);
        ## Check the return value, if its good, cache it!
        $self->_store() if ($rvalue);
        return ( $rvalue, $msg );
    } else {
        $self = $self->SUPER::load_from_hash(@_);
        ## Check the return value, if its good, cache it!
        $self->_store() if ( $self->id );
        return $self;

    }
}

=head2 load_by_cols

Overrides the implementation from L<Jifty::DBI::Record> to add support for caching.

=cut

sub load_by_cols {
    my ( $class, %attr ) = @_;

    my ($self);
    if ( ref($class) ) {
        ( $self, $class ) = ( $class, undef );
    } else {
        $self = $class->new( handle => ( delete $attr{'_handle'} || undef ) );
    }

    ## Generate the cache key
    my $key = $self->_gen_load_by_cols_key(%attr);
    if ( $self->_get($key) ) {
        if ($class) { return $self }
        else { return ( 1, "Fetched from cache" ) }
    }
    ## Fetch from the DB!
    my ( $rvalue, $msg ) = $self->SUPER::load_by_cols(%attr);
    ## Check the return value, if its good, cache it!
    if ($rvalue) {
        $self->_store();
        if ( $key ne $self->_primary_key ) {
            my $cache_key = $self->_primary_cache_key;
            $MEMCACHED->add( $key, $cache_key,
                             $self->_cache_config->{'cache_for_sec'} )
                if defined $cache_key;
            $self->{'loaded_by_cols'} = $key;
        }
    }
    if ($class) { return $self }
    else {
        return ( $rvalue, $msg );
    }
}

# Function: __set
# Type    : (overloaded) public instance
# Args    : see Jifty::DBI::Record::_Set
# Lvalue  : ?

sub __set () {
    my ( $self, %attr ) = @_;
    $self->_expire();
    return $self->SUPER::__set(%attr);

}

# Function: _delete
# Type    : (overloaded) public instance
# Args    : nil
# Lvalue  : ?

sub __delete () {
    my ($self) = @_;
    $self->_expire();
    return $self->SUPER::__delete();
}

# Function: _expire
# Type    : private instance
# Args    : string(cache_key)
# Lvalue  : 1
# Desc    : Removes this object from the cache.

sub _expire (\$) {
    my $self = shift;
    $MEMCACHED->delete($self->_primary_cache_key);
    $MEMCACHED->delete($self->{'loaded_by_cols'}) if ($self->{'loaded_by_cols'});

}

# Function: _get
# Type    : private instance
# Args    : string(cache_key)
# Lvalue  : 1
# Desc    : Get an object from the cache, and make this object that.

sub _get () {
    my ( $self, $cache_key ) = @_;
    my $data = $MEMCACHED->get($cache_key) or return;
    # If the cache value is a scalar, that's another key
    unless (ref $data) { $data = $MEMCACHED->get($data); }
    unless (ref $data) { return undef; }
    @{$self}{ keys %$data } = values %$data;    # deserialize
}

# Function: _store
# Type    : private instance
# Args    : string(cache_key)
# Lvalue  : 1
# Desc    : Stores this object in the cache.

sub _store (\$) {
    my $self = shift;
    # Blow away the primary cache key since we're loading.
    $self->{'_jifty_cache_pkey'} = undef;
    $MEMCACHED->set( $self->_primary_cache_key,
        {   values  => $self->{'values'},
            table   => $self->table,
            fetched => $self->{'fetched'},
            raw_values => $self->{'raw_values'},
        },
        $self->_cache_config->{'cache_for_sec'}
    );
}


# Function: _gen_load_by_cols_key
# Type    : private instance
# Args    : hash (attr)
# Lvalue  : 1
# Desc    : Takes a perl hash and generates a key from it.

sub _gen_load_by_cols_key {
    my ( $self, %attr ) = @_;

    my $cache_key = $self->cache_key_prefix . '-'. $self->table() . ':';
    my @items;
    while ( my ( $key, $value ) = each %attr ) {
        $key   ||= '__undef';
        $value ||= '__undef';

        if ( ref($value) eq "HASH" ) {
            $value = ( $value->{operator} || '=' ) . $value->{value};
        } else {
            $value = "=" . $value;
        }
        push @items, $key.$value;

    }
    $cache_key .= join(',',@items);
    return ($cache_key);
}

# Function: _primary_cache_key
# Type    : private instance
# Args    : none
# Lvalue: : 1
# Desc    : generate a primary-key based variant of this object's cache key
#           primary keys is in the cache

sub _primary_cache_key {
    my ($self) = @_;

    return undef unless ( defined $self->id );

    unless ( $self->{'_jifty_cache_pkey'} ) {

        my $primary_cache_key = $self->cache_key_prefix .'-' .$self->table() . ':';
        my @attributes;
        foreach my $key ( @{ $self->_primary_keys } ) {
            push @attributes, $key . '=' . $self->SUPER::__value($key);
        }

        $primary_cache_key .= join( ',', @attributes );

        $self->{'_jifty_cache_pkey'} = $primary_cache_key;
    }
    return ( $self->{'_jifty_cache_pkey'} );

}

=head2 _cache_config 

You can override this method to change the duration of the caching
from the default of 5 seconds.

For example, to cache records for up to 30 seconds, add the following
method to your class:

  sub _cache_config {
      { 'cache_for_sec' => 30 }
  }

=cut

sub _cache_config {
    {   
        'cache_for_sec' => 180,
    };
}

=head2 memcached_config

Returns a hash containing arguments to pass to L<Cache::Memcached> during construction. The defaults are like:

  (
      services => [ '127.0.0.1:11211' ],
      debug    => 0,
  )

You may want to override this method if you want a customized cache configuration:

  sub memcached_config {
      (
          servers => [ '10.0.0.15:11211', '10.0.0.15:11212',
                       '10.0.0.17:11211', [ '10.0.0.17:11211', 3 ] ],
          debug   => 0,
          compress_threshold => 10_000,
      );
  }

=cut


sub memcached_config {
    servers => ['127.0.0.1:11211'],
    debug => 0

}

=head2 cache_key_prefix

Returns the prefix we should prepend to all cache keys. If you're using one memcached for multiple
applications, you want this to be different for each application or they might end up mingling data.

=cut

sub cache_key_prefix {
    return 'Jifty-DBI';
}

1;

__END__


=head1 AUTHOR

Matt Knopp <mhat@netlag.com>

=head1 SEE ALSO

L<Jifty::DBI>, L<Jifty::DBI::Record>

=cut


