package Mail::Decency::Helper::Cache;

use Moose;

use version 0.74; our $VERSION = qv( "v0.1.4" );

use Digest::MD5 qw/ md5_hex /;
use Data::Dumper;
use Scalar::Util qw/ weaken /;

=head1 NAME

Mail::Decency::Helper

=head1 DESCRIPTION

Helper modules for Decency policies or content filters

=cut

has cache  => ( is => 'ro', isa => 'Cache' );
has writer => ( is => 'rw', isa => 'CodeRef' );
has reader => ( is => 'rw', isa => 'CodeRef' );

sub BUILD {
    my ( $self, $args_ref ) = @_;
    
    unless ( lc( $args_ref->{ class } ) eq 'none' ) {
        
        # determine class
        my $cache_class = delete $args_ref->{ class };
        $cache_class = "Cache::$cache_class";
        
        # load class
        eval "use $cache_class";
        die "Could not load cache module $cache_class: $@\n"
            if $@;
        
        # init cache
        $self->{ cache } = $cache_class->new( %$args_ref );
        
        # fastmmap, has no timeout for set .. emulate!
        if ( $cache_class eq 'Cache::FastMmap' ) {
            $self->writer( sub {
                my ( $self, $key, $value, $timeout ) = @_;
                return $self->cache->set( $key => [ $value, $timeout ] );
            } );
            $self->reader( sub {
                my ( $self, $key ) = @_;
                my $res = $self->cache->get( $key );
                return unless $res;
                my ( $value, $timeout ) = @$res;
                if ( $timeout && $timeout < time() ) {
                    $self->remove( $key );
                    return ;
                }
                return $value;
            } );
        }
        
        # those who speek freeze directly
        elsif ( $self->cache->can( 'freeze' ) ) {
            $self->writer( sub {
                my ( $self, $key, $value, $timeout ) = @_;
                return $self->cache->freeze( $key => $value, $timeout );
            } );
            $self->reader( sub {
                my ( $self, $key ) = @_;
                return $self->cache->thaw( $key );
            } );
        }
        
        # ant the rest, freezing/thawing as needed
        else {
            
            $self->writer( sub {
                my ( $self, $key, $value, $timeout ) = @_;
                return $self->cache->set( $key => $value, $timeout );
            } );
            $self->reader( sub {
                my ( $self, $key ) = @_;
                return $self->cache->get( $key );
            } );
        }
    }
    
    else {
        $self->writer( sub {} );
        $self->reader( sub {} );
    }
    
    return $self;
}


=head2 get

Read from cache

    my $ref = $cache->get( "name" );

=cut

sub get {
    my ( $self, $key ) = @_;
    
    # no cache ?
    return unless $self->cache;
    
    # get unserialized
    my $res;
    eval {
        $res = $self->reader->( $self, $key );
    };
    $res = $self->cache->get( $key ) if $@;
    
    # de-scalar-ref if any ..
    return ref( $res ) eq 'SCALAR' ? $$res : $res;
    
    return $res;
    
}

=head2 set

Write to cache

    $cache->set( name => { some => [ "data" ] }, "5 s" );
    $cache->set( name => { some => [ "data" ] }, time() + 5 );

=cut

sub set {
    my ( $self, $key, $value, $timeout ) = @_;
    
    # no cache ?
    return unless $self->cache;
    
    # remove from cache /
    return $self->remove( $key ) unless defined $value;
    
    # set data
    $self->writer->( $self, $key, ref( $value ) ? $value : \$value, $timeout );
}

=head2 remove

Remove a key from cache

    $cache->remove( "name" );

=cut

sub remove {
    my ( $self, $key ) = @_;
    return unless $self->cache;
    return $self->cache->remove( $key );
}

=head2 entry

Return the Cache::Entry instance

    my $entry = $cache->entry( "name" );

=cut

sub entry {
    my ( $self, $key ) = @_;
    return unless $self->cache;
    return $self->cache->entry( $key );
}


=head2 hash_to_name

Transforms hash keys and values into short md5 string .. to be used for caching

=cut

sub hash_to_name {
    my ( $self, $hash_ref, @names ) = @_;
    unless ( @names ) {
        @names = sort keys %$hash_ref;
    }
    else {
        @names = sort @names;
    }
    
    my ( @data, @prefices );
    foreach my $name( @names ) {
        if ( $hash_ref->{ $name } ) {
            push @data, "$name=". ( $hash_ref->{ $name } );
            push @prefices, substr( $hash_ref->{ $name }, 0, 2 );
        }
    }
    
    return md5_hex( join( "", @data ) ). "-". join( "", @prefices );
}




=head1 AUTHOR

Ulrich Kautz <uk@fortrabbit.de>

=head1 COPYRIGHT

Copyright (c) 2010 the L</AUTHOR> as listed above

=head1 LICENCSE

This library is free software and may be distributed under the same terms as perl itself.

=cut

1;
