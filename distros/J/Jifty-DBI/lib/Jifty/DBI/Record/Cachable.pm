package Jifty::DBI::Record::Cachable;

use base qw(Jifty::DBI::Record);

use Jifty::DBI::Handle;

use Cache::Simple::TimedExpiry;
use Scalar::Util qw/ blessed /;

use strict;
use warnings;

=head1 NAME

Jifty::DBI::Record::Cachable - records with caching behavior

=head1 SYNOPSIS

  package Myrecord;
  use base qw/Jifty::DBI::Record::Cachable/;

=head1 DESCRIPTION

This module subclasses the main L<Jifty::DBI::Record> package to add a
caching layer.

The public interface remains the same, except that records which have
been loaded in the last few seconds may be reused by subsequent fetch
or load methods without retrieving them from the database.

=head1 METHODS

=cut

my %_CACHES = ();

sub _setup_cache {
    my $self  = shift;
    my $cache = shift;
    $_CACHES{$cache} = Cache::Simple::TimedExpiry->new();
    $_CACHES{$cache}->expire_after( $self->_cache_config->{'cache_for_sec'} );
}

=head2 flush_cache 

This class method flushes the _global_ Jifty::DBI::Record::Cachable 
cache.  All caches are immediately expired.

=cut

sub flush_cache {
    %_CACHES = ();
}

sub _key_cache {
    my $self = shift;
    my $cache
        = $self->_handle->dsn
        . "-KEYS--"
        . ( $self->{'_class'} || $self->table );
    $self->_setup_cache($cache) unless exists( $_CACHES{$cache} );
    return ( $_CACHES{$cache} );

}

=head2 _flush_key_cache

Blow away this record type's key cache

=cut

sub _flush_key_cache {
    my $self = shift;
    my $cache
        = $self->_handle->dsn
        . "-KEYS--"
        . ( $self->{'_class'} || $self->table );
    $self->_setup_cache($cache);
}

sub _record_cache {
    my $self = shift;
    my $cache
        = $self->_handle->dsn . "--" . ( $self->{'_class'} || $self->table );
    $self->_setup_cache($cache) unless exists( $_CACHES{$cache} );
    return ( $_CACHES{$cache} );

}

sub _is_in_transaction {
    my $self = shift;
    $Jifty::DBI::Handle::TRANSDEPTH > 0;
}

=head2 load_from_hash

Overrides the implementation from L<Jifty::DBI::Record> to add caching.

=cut

sub load_from_hash {
    my $self = shift;

    my ( $rvalue, $msg );
    if ( ref($self) ) {

        # Blow away the primary cache key since we're loading.
        $self->{'_jifty_cache_pkey'} = undef;
        ( $rvalue, $msg ) = $self->SUPER::load_from_hash(@_);

        ## Check the return value, if its good, cache it!
        $self->_store() if ($rvalue && !$self->_is_in_transaction);
        return ( $rvalue, $msg );
    } else {    # Called as a class method;
        $self = $self->SUPER::load_from_hash(@_);
        ## Check the return value, if its good, cache it!
        $self->_store() if ( $self->id && !$self->_is_in_transaction );
        return ($self);
    }

}

=head2 load_by_cols

Overrides the implementation from L<Jifty::DBI::Record> to add caching.

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
    my $alt_key = $self->_gen_record_cache_key(%attr);
    if ( $self->_fetch($alt_key) ) {
        if   ($class) { return $self }
        else          { return ( 1, "Fetched from cache" ) }
    }

    # Blow away the primary cache key since we're loading.
    $self->{'_jifty_cache_pkey'} = undef;

    ## Fetch from the DB!
    my ( $rvalue, $msg ) = $self->SUPER::load_by_cols(%attr);
    ## Check the return value, if its good, cache it!
    if ($rvalue && !$self->_is_in_transaction) {
        ## Only cache the object if its okay to do so.
        $self->_store();
        $self->_key_cache->set(
            $alt_key => $self->_primary_record_cache_key );

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
    my $self = shift;

    $self->_expire();
    return $self->SUPER::__set(@_);

}

# Function: delete
# Type    : (overloaded) public instance
# Args    : nil
# Lvalue  : ?

sub __delete () {
    my $self = shift;

    $self->_expire();
    return $self->SUPER::__delete(@_);

}

# Function: _expire
# Type    : private instance
# Args    : string(cache_key)
# Lvalue  : 1
# Desc    : Removes this object from the cache.

sub _expire (\$) {
    my $self = shift;
    $self->_record_cache->set( $self->_primary_record_cache_key,
        undef, time - 1 );

# We should be doing something more surgical to clean out the key cache. but we do need to expire it
    $self->_flush_key_cache;

}

# Function: _fetch
# Type    : private instance
# Args    : string(cache_key)
# Lvalue  : 1
# Desc    : Get an object from the cache, and make this object that.

sub _fetch () {
    my ( $self, $cache_key ) = @_;

    # If the alternate key is really the primary one

    my $data = $self->_record_cache->fetch($cache_key);

    unless ($data) {
        $cache_key = $self->_key_cache->fetch($cache_key);
        $data = $self->_record_cache->fetch($cache_key) if $cache_key;
    }

    return undef unless ($data);

    @{$self}{ keys %$data } = values %$data;    # deserialize
    return 1;
}

#sub __value {
#    my $self   = shift;
#    my $column = shift;
#
#    # XXX TODO, should we be fetching directly from the cache?
#    return ( $self->SUPER::__value($column) );
#}

# Function: _store
# Type    : private instance
# Args    : string(cache_key)
# Lvalue  : 1
# Desc    : Stores this object in the cache.

sub _store (\$) {
    my $self = shift;
    $self->_record_cache->set(
        $self->_primary_record_cache_key,
        {   values      => $self->{'values'},
            table       => $self->table,
            fetched     => $self->{'fetched'},
            decoded     => $self->{'decoded'},
            raw_values  => $self->{'raw_values'},
        }
    );
}

# Function: _gen_record_cache_key
# Type    : private instance
# Args    : hash (attr)
# Lvalue  : 1
# Desc    : Takes a perl hash and generates a key from it.

sub _gen_record_cache_key {
    my ( $self, %attr ) = @_;

    my @cols;

    while ( my ( $key, $value ) = each %attr ) {
        unless ( defined $value ) {
            push @cols, lc($key) . '=__undef';
        } elsif ( ref($value) eq "HASH" ) {
            push @cols,
                  lc($key)
                . ( $value->{operator} || '=' )
                . defined $value->{value} ? $value->{value} : '__undef';
        } elsif ( blessed $value and $value->isa('Jifty::DBI::Record') ) {
            push @cols, lc($key) . '=' . ( $value->id );
        } else {
            push @cols, lc($key) . "=" . $value;
        }
    }
    return ( $self->table() . ':' . join( ',', @cols ) );
}

# Function: _fetch_record_cache_key
# Type    : private instance
# Args    : nil
# Lvalue  : 1

sub _fetch_record_cache_key {
    my ($self) = @_;
    my $cache_key = $self->_cache_config->{'cache_key'};
    return ($cache_key);
}

# Function: _primary_record_cache_key
# Type    : private instance
# Args    : none
# Lvalue: : 1
# Desc    : generate a primary-key based variant of this object's cache key
#           primary keys is in the cache

sub _primary_record_cache_key {
    my ($self) = @_;

    unless ( $self->{'_jifty_cache_pkey'} ) {

        my @attributes;
        my %pk = $self->primary_keys;
        while ( my ( $key, $value ) = each %pk ) {
            return unless defined $value;
            push @attributes, lc($key) . '=' . $value;
        }

        $self->{'_jifty_cache_pkey'} = $self->table . ':' . join ',',
            @attributes;
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
    {   'cache_p'       => 1,
        'cache_for_sec' => 5,
    };
}

1;

__END__


=head1 AUTHOR

Matt Knopp <mhat@netlag.com>

=head1 SEE ALSO

L<Jifty::DBI>, L<Jifty::DBI::Record>

=cut


