package Gantry::Plugins::PageCache;

use strict; 
use warnings;

use File::Spec;

my %registered_callbacks;

# lets export a do method and some conf accessors
use base 'Exporter';
our @EXPORT = qw( 
    gantry_pagecache_location
    gantry_pagecache_crud
    gantry_pagecache_action
    gantry_pagecache_mime_type
    gantry_pagecache_uri
    gantry_pagecache
);


#-----------------------------------------------------------
# $class->get_callbacks( $namespace )
#-----------------------------------------------------------
sub get_callbacks {
    my ( $class, $namespace ) = @_;

    return if ( $registered_callbacks{ $namespace }++ );

    return (
        { phase => 'post_init',    callback => \&gantry_pagecache_retrieve },
        { phase => 'post_process', callback => \&gantry_pagecache_store },
    );
}

#-----------------------------------------------------------
# gantry_pagecache_retrieve
#-----------------------------------------------------------
sub gantry_pagecache_retrieve {
    my ( $gobj ) = @_;

    # set config

    # 0/1
    $gobj->gantry_pagecache_crud( 
        $gobj->fish_config( 'gantry_pagecache_crud' ) || 0
    );
    
    # do_add, do_delete, ...
    $gobj->gantry_pagecache_action( 
        $gobj->fish_config( 'gantry_pagecache_action' ) || ''
    );

    # text/html, text/rss, ...
    $gobj->gantry_pagecache_mime_type( 
        $gobj->fish_config( 'gantry_pagecache_mime_type' ) || ''
    );

    # /controller1, ...
    $gobj->gantry_pagecache_location( 
        $gobj->fish_config( 'gantry_pagecache_location' ) || ''
    );

    # /controller1/view, ..., 
    $gobj->gantry_pagecache_uri( 
        $gobj->fish_config( 'gantry_pagecache_uri' ) || ''
    );
             
    my $cache_key;
    
    # special CRUD caching
    if ( $gobj->gantry_pagecache_crud() ) {

        if ( $gobj->is_post() 
            && $gobj->action() =~ /do_edit|do_add|do_delete/ ) {
        
            $cache_key = _make_gantry_cache_key( $gobj );

            # flag for cache store
            $gobj->gantry_pagecache( $cache_key );

            $gobj->cache_del( $cache_key . "content_type" );
            $gobj->cache_del( $cache_key );

            my @parts = split( '/', $cache_key );
            pop( @parts );
        
            $gobj->cache_del( join( '/', @parts ) . "content_type" );
            $gobj->cache_del( join( '/', @parts ) );
        
        }
    }

    # all other caching
    elsif ( _caching_enabled( $gobj ) ) {
        
        $cache_key = _make_gantry_cache_key( $gobj, { serialize => 1 } );
   
        if ( my $page = $gobj->cache_get( $cache_key ) ) {

            # set the content-type
            $gobj->content_type( 
                $gobj->cache_get( $cache_key . "content_type" )
            );
    
            # set cached page
            $gobj->gantry_response_page( $page );
        }
        # flag it for the cache store method
        else {
            $gobj->gantry_pagecache( $cache_key );
        } 
    }
        
}

#-----------------------------------------------------------
# gantry_pagecache_put
#-----------------------------------------------------------
sub _caching_enabled {
    my( $gobj ) = @_;

    my $cache = 0;
    
    if ( my @actions = split( /\s*,\s*/, $gobj->gantry_pagecache_action() ) ) {
        my $current_action = $gobj->action();
        foreach ( @actions ) {
            if ( $_ eq $current_action ) {
                return( 1 );
            }
        }
    }

    if ( my @types = split( /\s*,\s*/, $gobj->gantry_pagecache_mime_type() ) ) { 
        my $current_type = $gobj->content_type();
        foreach ( @types ) {
            if ( $_ eq $current_type ) {
                return( 1 );
            }
        }    
    }

    if ( my @locs = split( /\s*,\s*/, $gobj->gantry_pagecache_location() ) ) { 
        my $current_loc = $gobj->location();
        foreach ( @locs ) {
            if ( $_ eq $current_loc ) {
                return( 1 );
            }
        }    
    }
    
    if ( my @uris = split( /\s*,\s*/, $gobj->gantry_pagecache_uri() ) ) { 
        my $current_uri = $gobj->uri();
        foreach ( @uris ) {
            if ( $_ eq $current_uri ) {
                return( 1 );
            }
        }    
    }
    
    return( 0 );
}

#-----------------------------------------------------------
# gantry_pagecache_put
#-----------------------------------------------------------
sub gantry_pagecache_store {
    my ( $gobj ) = @_;

    # special CRUD caching
    if ( $gobj->gantry_pagecache_crud() ) {
        my $cache_key = $gobj->gantry_pagecache();

        if ( $gobj->action() =~ /do_edit|do_add|do_delete/ ) {

            # set page 
            $gobj->cache_set( $cache_key, $gobj->gantry_response_page() );

            # set content-type
            $gobj->cache_set( 
                ( $cache_key . 'content_type' ),
                $gobj->content_type()
            );
        }
    }
    
    # all other caching
    elsif( _caching_enabled( $gobj ) ) {
        my $cache_key = $gobj->gantry_pagecache();

        # set page 
        $gobj->cache_set( $cache_key, $gobj->gantry_response_page() );

        # set content-type
        $gobj->cache_set( 
            ( $cache_key . 'content_type' ),
            $gobj->content_type()
        );

    }   

}

#-----------------------------------------------------------
# _make_gantry_cache_key
#-----------------------------------------------------------
sub _make_gantry_cache_key {
    my( $gobj, $opt ) = @_;
     
    my @parts;   
    push( @parts,
        $gobj->namespace, 
        $gobj->uri, 
    );    

    if ( $opt->{serialize} ) {
        my $serial = _serialize_params( $gobj );        
        
        push( @parts, 
            ( $serial ? ( '?' . $serial ) : '' ),        
        );
    }
    
    return join( '', @parts );
}

#-----------------------------------------------------------
# _serialize_params
#-----------------------------------------------------------
sub _serialize_params {
    my( $gobj ) = @_;
    
    my %param = $gobj->get_param_hash;
    my @param_serial;    

    foreach my $k ( sort { $a cmp $b } keys %param ) {
        next if substr( $k, 0, 1 ) eq '.';
            
        push( @param_serial, "$k=$param{$k}" );
    }
    
    return join( '&', @param_serial );
}

#-------------------------------------------------
# $self->gantry_pagecache_crud
#-------------------------------------------------
sub gantry_pagecache_crud {
    my ( $self, $p ) = ( shift, shift );

    $$self{__GANTRY_PAGECACHE_CRUD__} = $p if defined $p;
    return( $$self{__GANTRY_PAGECACHE_CRUD__} ); 
    
} # end gantry_pagecache_crud

#-------------------------------------------------
# $self->gantry_pagecache_location
#-------------------------------------------------
sub gantry_pagecache_location {
    my ( $self, $p ) = ( shift, shift );

    $$self{__GANTRY_PAGECACHE_LOCATION__} = $p if defined $p;
    return( $$self{__GANTRY_PAGECACHE_LOCATION__} ); 
    
} # end gantry_pagecache_location

#-------------------------------------------------
# $self->gantry_pagecache_action
#-------------------------------------------------
sub gantry_pagecache_action {
    my ( $self, $p ) = ( shift, shift );

    $$self{__GANTRY_PAGECACHE_ACTION__} = $p if defined $p;
    return( $$self{__GANTRY_PAGECACHE_ACTION__} ); 
    
} # end gantry_pagecache_action

#-------------------------------------------------
# $self->gantry_pagecache_mime_type
#-------------------------------------------------
sub gantry_pagecache_mime_type {
    my ( $self, $p ) = ( shift, shift );

    $$self{__GANTRY_PAGECACHE_MIMETYPE__} = $p if defined $p;
    return( $$self{__GANTRY_PAGECACHE_MIMETYPE__} ); 
    
} # end gantry_pagecache_mime_type

#-------------------------------------------------
# $self->gantry_pagecache_uri
#-------------------------------------------------
sub gantry_pagecache_uri {
    my ( $self, $p ) = ( shift, shift );

    $$self{__GANTRY_PAGECACHE_URI__} = $p if defined $p;
    return( $$self{__GANTRY_PAGECACHE_URI__} ); 
    
} # end gantry_pagecache_uri

#-------------------------------------------------
# $self->gantry_pagecache
#-------------------------------------------------
sub gantry_pagecache {
    my ( $self, $p ) = ( shift, shift );

    $$self{__GANTRY_PAGECACHE__} = $p if defined $p;
    return( $$self{__GANTRY_PAGECACHE__} ); 
    
} # end gantry_pagecache

1;

__END__

=head1 NAME

Gantry::Plugins::PageCache - A plugin for caching application pages

=head1 SYNOPSIS

In Apache Perl startup or app.cgi or app.server:

    <Perl>
        # ...
        use MyApp qw{ 
            -Engine=CGI 
            -TemplateEngine=TT 
            Cache::FastMap # or Cache::Storable 
            PageCache 
        };
                
    </Perl>


=head1 DESCRIPTION

The purpose of the plugin is to store and retrieve cached application pages.

Note that you must include PageCache in the list of imported items when you use 
your base app module. 

=head1 CONFIGURATION

The following items can be set by configuration. If any of the following 
match then caching will be enabled. 

** At least one cache criteria must be set.

Cache pages based on a certain action.

 $self->gantry_pagecache_action( 'do_edit,do_delete,do_view' );

Cache pages based on the mime types.

 $self->gantry_pagecache_mime_type( 'text/html,text/rss' );

Cache every page that is produced by a controller.

 $self->gantry_pagecache_location( '/controller1' );

Cache distinct pages produced by a controller.

 $self->gantry_pagecache_uri( '/controller1/rss' );

=over 4

=back

=head1 METHODS

=over 4

=item get_callbacks

For use by Gantry.pm. Registers the callbacks needed for cache  management
during the PerlHandler Apache phase or its moral equivalent.

=item gantry_pagecache_store

Callback to store the cached page.

=item gantry_pagecache_retrieve

Callback to retrieve the cached page.

=item gantry_pagecache_location

Location(s) to cache

=item gantry_pagecache_action

Action(s) to cache

=item gantry_pagecache_crud

Boolean accessor for whether to attempt caching of CRUD behaviors.

=item gantry_pagecache_mime_type

MIME type(s) to cache

=item gantry_pagecache_uri

URI(s) to cache

=item gantry_pagecache

Holds the cache key if caching is enabled

=back

=head1 TODO

Add a caching scheme where you can use an L<SQL::Abstract> like syntax.

 {
    -and => {
        mime_type = [
            'text/html',
            'text/rss',
        ],
        location = [
            '/controller1',
            '/controller2',
        ],
    },
    -or => {
        mime_type => { '!=', 'img/gif' } 
    }
 }

=head1 SEE ALSO

    Gantry

=head1 AUTHOR

Tim Keefer <tim@timkeefer.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 Tim Keefer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
