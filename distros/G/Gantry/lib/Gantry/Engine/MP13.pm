package Gantry::Engine::MP13;
require Exporter;

use strict;
use Carp qw( croak );

use Apache::Constants qw( DECLINED OK REDIRECT HTTP_MOVED_PERMANENTLY
                          AUTH_REQUIRED SERVER_ERROR FORBIDDEN BAD_REQUEST );
use Apache::Request;
use File::Basename;
use Gantry::Conf;
use Gantry::Utils::DBConnHelper::MP13;
use CGI::Simple::Util ();

use vars qw( @ISA @EXPORT ); 

############################################################
# Variables                                                #
############################################################
@ISA        = qw( Exporter );
@EXPORT     = qw( 
    apache_param_hash
    apache_uf_param_hash
    apache_request
    base_server
    cast_custom_error
    consume_post_body
    declined_response
    dispatch_location
    engine
    engine_init
    err_header_out
    fish_config
    fish_location
    fish_method
    fish_path_info
    fish_uri
    fish_user
    get_arg_hash
    get_auth_dbh
    get_cached_config
    get_config
    get_dbh
    get_post_body
    header_in
    header_out
    hostname
    is_connection_secure
    is_status_declined
    log_error
    port
    print_output
    redirect_response
    remote_ip
    send_http_header
    send_error_output
    server_root 
    set_cached_config
    set_content_type
    set_no_cache
    set_req_params
    status_const
    success_code
    file_upload
    url_encode
    url_decode
);

############################################################
# Functions                                                #
############################################################

#-------------------------------------------------
# $self->file_upload( param_name )
#-------------------------------------------------
sub file_upload {
    my( $self, $param ) = @_;

    die "param required" if ! $param;

    my $apr = $self->ap_req;
    my $status = $apr->parse;

    if ( $status ) { die "upload error: $status" };

    my $upload = $apr->upload( $param );
    
    my $filename = $upload->filename;
    $filename =~ s/\\/\//g;
    
    my( $name, $path, $suffix ) = fileparse( 
		$filename, 
		qr/\.(tar\.gz$|[^.]*)/ 
	);  
    
    return( {
        unique_key => time . rand( 6 ),
        name       => $name,
        suffix     => $suffix,
        fullname   => ( $name . $suffix ),
        size       => ( $upload->size || 0 ),
        mime       => $upload->type,
        filehandle => $upload->fh,
    } );
    
}

#-------------------------------------------------
# $self->log_error( error )
#-------------------------------------------------
sub log_error {
    my( $self, $msg ) = @_;

    $self->r->log_error( $msg );

}

#-------------------------------------------------
# $self->cast_custom_error( error )
#-------------------------------------------------
sub cast_custom_error {
    my( $self, $error_page, $die_msg ) = @_;

    $error_page ||= '';
    $die_msg    ||= '';

    my $status = ( $self->status() ? $self->status() 
        : $self->status_const( 'BAD_REQUEST' ) );
    
    $self->r->log_error( $die_msg ) if defined $die_msg;
    
    $self->r->custom_response( $status, $error_page );
    
    return( $status );
}

#-------------------------------------------------
# $self->apache_param_hash( $req )
#-------------------------------------------------
sub apache_param_hash {
    my( $self, $req ) = @_;

    # If the application has specified that they want the unfiltered params
    # by default, then make it happen.
    if ($self->fish_config( 'unfiltered_params' ) && $self->fish_config( 'unfiltered_params' ) =~ /(1|on)/i) {
        return $self->apache_uf_param_hash( $req );
    }

    my $hash = {};
    my @param_names = $req->param;

    foreach my $p ( @param_names ) {
        my @values = $req->param( $p );

        # Replace angle brackets and quotes with named-entity equivalents.
        $_ =~ s/</&lt;/g foreach @values;
        $_ =~ s/>/&gt;/g foreach @values;
        $_ =~ s/"/&#34;/g foreach @values;
        $_ =~ s/'/&#39;/g foreach @values;

        # Trim leading / trailing whitespace.
        $_ =~ s/^\s+//o foreach @values;
        $_ =~ s/\s+$//o foreach @values;

        $hash->{$p} = ( scalar @values == 1 ) ? shift @values : [ @values ];
    }

    return( $hash );

} # end: apache_param_hash

#-------------------------------------------------
# $self->apache_uf_param_hash( $req )
#-------------------------------------------------
sub apache_uf_param_hash {
    my( $self, $req ) = @_;

    my $hash = {};
    my @param_names = $req->param;

    foreach my $p ( @param_names ) {
        my @values = $req->param( $p );

        $hash->{$p} = ( scalar @values == 1 ) ? shift @values : [ @values ];
    }

    return( $hash );

} # end: apache_uf_param_hash

#-------------------------------------------------
# $self->apache_request( )
#-------------------------------------------------
sub apache_request {
    my ( $self, $r ) = @_;

    unless ( $self->{__AP_REQ__} ) {
        $self->{__AP_REQ__} = Apache::Request->new(
            $self->r,
            POST_MAX => ( $self->fish_config( 'post_max' ) || '20000000' )
        );
    }

    return $self->{__AP_REQ__};
} # end: apache_request

#-------------------------------------------------
# $self->base_server( $r )
#-------------------------------------------------
sub base_server {
    my( $self, $r ) = ( shift, shift );

    return( 
        $r ? $r->server->server_hostname
        : $self->r->server->server_hostname );
    
} # end base_server

#-------------------------------------------------
# $self->hostname( $r )
#-------------------------------------------------
sub hostname {
    my( $self, $r ) = ( shift, shift );

    return( 
        $r ? $r->hostname
        : $self->r->hostname );
    
} # end hostname

#-------------------------------------------------
# $self->consume_post_body( $r )
#-------------------------------------------------
sub consume_post_body {
    my $self = shift;
    my $r    = shift;

    my $content_length = $r->headers_in->{'Content-length'};

    return unless $content_length;

     $content_length    = 1e6 if $content_length > 1e6; # limit to ~ 1Meg

    my ( $content, $buffer );

    while ( $r->read( $buffer, $content_length ) ) {
        $content .= $buffer;
    }

    $self->{__POST_BODY__} = $content;
}

#-------------------------------------------------
# $self->declined_response( )
#-------------------------------------------------
sub declined_response {
    my $self     = shift;

    return $self->status_const( 'DECLINED' );
} # END declined_response

#-------------------------------------------------
# $self->dispatch_location( )
#-------------------------------------------------
sub dispatch_location {
    my $self     = shift;

    return $self->uri, $self->location;
} # END dispatch_location

#-------------------------------------------------
# $self->engine
#-------------------------------------------------
sub engine {
    return __PACKAGE__;

} # end engine

#-------------------------------------------------
# $self->engine_init( )
#-------------------------------------------------
sub engine_init {
    my $self = shift;
    my $r    = shift;
    
    $self->r( $r );
} # END engine_init

#-------------------------------------------------
# $self->err_header_out( $key, $value ) 
#-------------------------------------------------
sub err_header_out {
    my( $self, $k, $v ) = @_;
    
    $self->r->err_headers_out->add( $k => $v );

} # end err_header_out

#-------------------------------------------------
# $self->fish_config( $param )
#-------------------------------------------------
sub fish_config {
    my ( $self, $param ) = @_;

    # see if there is Gantry::Conf data
    my $conf     = $self->get_config();

    return $$conf{$param} if ( defined $conf and defined $$conf{$param} );
    
    # otherwise, use dir_config for traditional approach
    return $self->r()->dir_config( $param );

} # END fish_config

#-------------------------------------------------
# $self->fish_location( )
#-------------------------------------------------
sub fish_location {
    my $self = shift;

    return $self->r()->location;
} # END fish_location

#-------------------------------------------------
# $self->fish_method( )
#-------------------------------------------------
sub fish_method {
    my $self = shift;

    return $self->r()->method;
} # END fish_method

#-------------------------------------------------
# $self->fish_path_info( )
#-------------------------------------------------
sub fish_path_info {
    my $self = shift;

    return $self->r()->path_info;
} # END fish_path_info

#-------------------------------------------------
# $self->fish_uri( )
#-------------------------------------------------
sub fish_uri {
    my $self = shift;

    return $self->r()->uri;
} # END fish_uri

#-------------------------------------------------
# $self->fish_user( )
#-------------------------------------------------
sub fish_user {
    my $self = shift;

    return $self->user() || $self->r()->user;
} # END fish_user

#-------------------------------------------------
# $self->get_arg_hash
#-------------------------------------------------
sub get_arg_hash {
    my( $self, $r ) = @_;
    
    my %args;
    if ( $r ) {
        %args = $r->args;
    }
    else {
        %args = $self->r->args;
    }
    
    return wantarray ? %args : \%args;

} # end get_arg_hash

#-------------------------------------------------
# $self->get_auth_dbh( )
#-------------------------------------------------
sub get_auth_dbh {
    return Gantry::Utils::DBConnHelper::MP13->get_auth_dbh;
}

#-------------------------------------------------
# $self->get_config( )
#-------------------------------------------------
sub get_config {
    my ( $self ) = @_;

    # see if there Gantry::Conf data
    my $instance  = $self->r()->dir_config( 'GantryConfInstance' );

    return unless defined $instance;

    my $file      = $self->r()->dir_config( 'GantryConfFile'     );
    
    my $conf;
    my $cached    = 0;
    my $location  = '';
    
    eval {
        $location = $self->location;
    };

    $conf = $self->get_cached_config( $instance, $location );

    if ( defined $conf ) {
        return $conf;
    }
 
    my $gantry_cache     = 0;
    my $gantry_cache_key = '';
    my $gantry_cache_hit = 0;
    eval { 
        ++$gantry_cache if $self->cache_inited();
    };
    
    # are we using gantry cache ?
    if ( $gantry_cache ) {

        $self->cache_namespace('gantry');

        # blow the gantry conf cache when server starts
        if ( $self->engine_cycle() == 1 ) {
            
            eval {
                foreach my $key ( @{ $self->cache_keys() } ) {
                    my @a = split( ':', $key );                
                    if ( $a[0] eq 'gantryconf' ) {
                        $self->cache_del( $key );
                    }
                }
            };
        }
                
        # build cache key
        $gantry_cache_key = join( ':',
            "gantryconf",
            ( $self->namespace() || '' ),
            $instance,
            $location
        );
    
        $conf = $self->cache_get( $gantry_cache_key );
        
        ++$gantry_cache_hit if defined $conf;
    }
    
    $conf ||= Gantry::Conf->retrieve(
        {
            instance    => $instance, 
            config_file => $file,
            location    => $location
        }
    );

    if ( defined $conf ) {        
        $self->set_cached_config( $instance, $location, $conf );
    
        if ( $gantry_cache && ! $gantry_cache_hit ) {
            $self->cache_set( $gantry_cache_key, $conf );
        }
    }
            
    return $conf;

} # END get_config

#-------------------------------------------------
# $self->get_cached_config( $instance, $location )
#-------------------------------------------------
sub get_cached_config {
    my $self     = shift;
    my $instance = shift;
    my $location = shift;

    return $self->r()->pnotes( "conf_${instance}_${location}" );
}

#-------------------------------------------------
# $self->set_cached_config( $instance, $location, $conf )
#-------------------------------------------------
sub set_cached_config {
    my $self     = shift;
    my $instance = shift;
    my $location = shift;  
    my $conf     = shift;

    $self->r()->pnotes( "conf_${instance}_${location}", $conf );
}

#-------------------------------------------------
# $self->get_dbh( )
#-------------------------------------------------
sub get_dbh {
    return Gantry::Utils::DBConnHelper::MP13->get_dbh;
}

#-------------------------------------------------
# $self->get_post_body( )
#-------------------------------------------------
sub get_post_body {
    my $self = shift;

    return $self->{__POST_BODY__};
}

#-------------------------------------------------
# $self->header_in( $key )
#-------------------------------------------------
sub header_in {
    my( $self, $key ) = @_;
    
    return $self->r->header_in($key);

} # end header_in

#-------------------------------------------------
# $self->header_out( $header_key, $header_value )
#-------------------------------------------------
sub header_out {
    my( $self, $k, $v ) = @_;
    
    $self->r->header_out( $k => $v );   

} # end header_out

#-------------------------------------------------
# $self->is_connection_secure()
#-------------------------------------------------
sub is_connection_secure {
    my $self = shift;

    return $self->r->subprocess_env('HTTPS') ? 1 : 0;
} # END is_connection_secure

#-------------------------------------------------
# $self->is_status_declined( $status )
#-------------------------------------------------
sub is_status_declined {
    my $self = shift;

    my $status = $self->status || '';

    return 1 if ( $status eq $self->status_const( 'DECLINED' ) );
} # END is_status_declined

#-------------------------------------------------
# $self->port( $r ) - NOT TIED TO API YET
#-------------------------------------------------
sub port {
    my( $self, $r ) = ( shift, shift );
        
    return( '' );
    
} # end port

#-------------------------------------------------
# $self->print_output( )
#-------------------------------------------------
sub print_output {
    my $self     = shift;
    my $response = shift;

    $self->r()->print( $response );
} # END print_output

#-------------------------------------------------
# $self->redirect_response( )
#-------------------------------------------------
sub redirect_response {
    my $self     = shift;

    return $self->status_const( 'REDIRECT' );
} # END redirect_response

#-------------------------------------------------
# $self->remote_ip( $r )
#-------------------------------------------------
sub remote_ip {
    my( $self, $r ) = @_;

    return( 
        $r ? $r->connection->remote_ip
        : $self->r->connection->remote_ip );

} # end remote_ip

#-------------------------------------------------
# $self->send_error_output( $@ )
#-------------------------------------------------
sub send_error_output {
    my $self     = shift;

    $self->do_error( $@ );
    return( $self->custom_error( $@ ) );

} # END send_error_output

#-------------------------------------------------
# $self->send_http_header( )
#-------------------------------------------------
sub send_http_header {
    my( $self ) = @_;
    
    $self->r->send_http_header; 

} # end send_http_header

#-------------------------------------------------
# $self->server_root( $r ) - NOT TIED TO API YET
#-------------------------------------------------
sub server_root {
    my( $self, $r ) = ( shift, shift );

    return('');
    
} # end server_root

#-------------------------------------------------
# $self->set_content_type( )
#-------------------------------------------------
sub set_content_type {
    my $self = shift;

    $self->r()->content_type( $self->content_type );
} # END set_content_type

#-------------------------------------------------
# $self->set_no_cache( )
#-------------------------------------------------
sub set_no_cache {
    my $self = shift;

    $self->r()->no_cache( 1 ) if ( $self->no_cache );
} # END set_no_cache

#-------------------------------------------------
# $self->set_req_params( )
#-------------------------------------------------
sub set_req_params {
    my $self = shift;

    $self->ap_req( $self->apache_request( $self->r ) );
    $self->params( $self->apache_param_hash( $self->ap_req ) );
    $self->uf_params( $self->apache_uf_param_hash( $self->ap_req ) );

} # END set_req_params

#-------------------------------------------------
# $self->status_const( 'OK | DECLINED | REDIRECT' )
#-------------------------------------------------
sub status_const {
    my( $self, $status ) = @_;
  
    # Upper case our status 
    $status = uc $status; 
    
    return BAD_REQUEST      if $status eq 'BAD_REQUEST';
    return DECLINED         if $status eq 'DECLINED';
    return OK               if $status eq 'OK';
    return REDIRECT         if $status eq 'REDIRECT'; 
    return HTTP_MOVED_PERMANENTLY
                            if $status eq 'MOVED_PERMANENTLY';
    return FORBIDDEN        if $status eq 'FORBIDDEN'; 
    return AUTH_REQUIRED    if $status eq 'AUTH_REQUIRED';
    return AUTH_REQUIRED    if $status eq 'HTTP_UNAUTHORIZED';
    return SERVER_ERROR     if $status eq 'SERVER_ERROR';

    die( "Undefined constant $status" );

} # end status_const

#-------------------------------------------------
# $self->success_code( )
#-------------------------------------------------
sub success_code {
    my $self = shift;

    return $self->status_const( 'OK' );
} # END success_code

#-------------------------------------------------
# $self->url_encode( )
#-------------------------------------------------
sub url_encode {
    my $self = shift;
    my $value = shift;
    
    return CGI::Simple::Util::escape( $value );
} # END url_encode

#-------------------------------------------------
# $self->url_decode( )
#-------------------------------------------------
sub url_decode {
    my $self = shift;
    my $value = shift;
    
    return CGI::Simple::Util::unescape( $value );
} # END url_decode

# EOF
1;

__END__

=head1 NAME

Gantry::Engine::MP13 - mod_perl 1.0 plugin ( or mixin )

=head1 SYNOPSIS

  use Gantry::Engine::MP13;


=head1 DESCRIPTION

This module is the binding between the Gantry framework and the mod_perl API.
This particluar module contains the mod_perl 1.0 specific bindings.

See mod_perl documentation for a more detailed description for some of these
bindings.

=head1 METHODS

=over 4

=item $self->apache_param_hash

Return a hash reference to the apache request body parameters.

=item $self->apache_uf_param_hash

Return a hash reference to the apache request body parameters unfiltered.

=item $self->apache_request

Apache::Request is a subclass of the Apache class, which adds methods
for parsing GET requests and POST requests where Content-type is one of
application/x-www-form-urlencoded or multipart/form-data. See the
libapreq(3) manpage for more details.

=item $self->base_server

Returns the physical server this connection came in
on (main server or vhost):

=item $self->hostname

Returns the virtual server name 

=item $self->cast_custom_error

Called by the handler in Gantry.pm when things go wrong.  It receives
html output and a death message.  It logs the death message and sets
the html output via the custom_response routine of the request object.
Returns FORBIDDEN status code.

=item $self->consume_post_body

This must be used by a plugin at the pre_init phase.  It takes all of the
data from the body of the HTTP POST request, storing it for retrieval
via C<get_post_body>.  You cannot mix this with regular form handling.

=item $self->declined_response

Returns the proper numeric status code for DECLINED.

=item dispatch_location

The uri tail specific to this request.  Returns:

    $self->uri, $self->location

Note that this is a two element list.

=item $self->engine

Returns the name of the engine, i.e. Gantry::Engine::MP13

=item $self->engine_init

Receives the request object and stores it in the site object.  Returns
nothing useful.

=item $self->err_header_out

The $r->err_headers_out method will return a %hash of server response
headers. This can be used to initialize a perl hash, or one could use
the $r->err_header_out() method (described below) to retrieve or set a
specific header value directly

See mod_perl docs.

=item fish_config

Pass this method the name of a conf parameter you need.  Returns the
value for the parameter.

=item fish_location

Returns the location for the current request.

=item fish_method

Returns the HTTP method of the current request.

=item fish_path_info

Returns the path info for the current request.

=item fish_uri

Returns the uri for the current request.

=item fish_user

Returns the currently logged-in user.

=item $self->get_arg_hash

    returns a hash of url arguments.

    /some/where?arg1=don&arg2=johnson

=item $self->get_auth_dbh

Same as get_dbh, but for the authentication database.

=item $self->get_cached_config

Users should call get_config instead.

Pulls the config object out of the pnotes so Gantry::Conf doesn't have
to regenerate it repeatedly.  (See set_cached_config.)

=item get_config

If you are using Gantry::Conf, this will return the config hash reference
for the current location.

=item get_cached_conf/set_cached_conf

These cache the Gantry::Conf config hash in pnotes.  Override them if
you want more persistent caching.  These are instance methods.  get
receives the invoking object, the name of the GantryConfInstance,
and the current location (for ease of use, its also in the invocant).
set receives those plus the conf hash it should cache.

=item $self->get_dbh

Returns the current regular database connection if one is available or
undef otherwise.

=item $self->get_post_body

If C<consume_post_body> was used by a plugin during the pre_init phase,
this method returns the consumed body of the HTTP POST request.

=item $self->header_in

The $r->headers_in method will return a %hash of client request headers.
This can be used to initialize a perl hash, or one could use the
$r->header_in() method (described below) to retrieve a specific header
value directly.

See mod_perl docs.

=item $self->header_out( $r, $header_key, $header_value )

Change the value of a response header, or create a new one.

=item $self->is_connection_secure()

Return whether the current request is being served by an SSL-enabled host.

=item $self->is_status_declined

Returns a true value if the status is currently DECLINED or false otherwise.

=item $self->log_error( message )

Writes message to the apache web server log

=item $self->port

Returns port number in which the request came in on.

=item $self->print_output( $response_page )

This method sends the contents of $response page back to apache.  It
uses the print method on the request object.

=item $self->redirect_response

Returns the proper numeric status code for REDIRECT.

=item $self->remote_ip

Returns the IP address for the remote user

=item $self->send_error_output

Returns the content of custom_error.  It gives $@ to the custom_error method.

=item $self->send_http_header( $r )

Send the response line and all headers to the client. Takes an optional
parameter indicating the content-type of the response, i.e. 'text/html'.

This method will create headers from the $r->content_xxx() and $r->no_cache() 
attributes (described below) and then append the headers defined by 
$r->header_out (or $r->err_header_out if status indicates an error).

See mod_perl 1.0 docs.

=item $self->server_root

Returns the value set by the top-level ServerRoot directive

=item set_cached_config

For internal use.  Used to place a config hash into pnotes for reuse
during the current page request.

=item $self->set_content_type()

Sets the content type stored in the site object's content_type attribute
on the apache request object.

=item $self->set_no_cache

Sets the no_cache flag in the apache request object with the value
for no_cache in the site object.

=item set_req_params

Sets up the apreq object and the form parameters from it.

=item $self->status_const( 'OK | DECLINED | REDIRECT' )

Get or set the reply status for the client request. The Apache::Constants
module provide mnemonic names for the status codes.

=item $self->success_code

Returns the proper numeric status code for OK.

=item url_encode

  url_encode($value)

Accepts a value and returns it url encoded.

=item url_decode

  url_decode($value)

Accepts a value and returns it url decoded.

=item $self->file_upload

Uploads a file from the client's disk.

Parameter: The name of the file input element on the html form.

Returns: A hash with these keys:

=over 4

=item unique_key

a unique identifier for this upload

=item name

the base name of the file

=item suffix

the extension (file type) of the file

=item fullname

name.suffix

=item size

bytes in file

=item mime

mime type of file

=item filehandle

a handle you can read the file from

=back

=back

=head1 SEE ALSO

mod_perl(3), Gantry(3) 

=head1 LIMITATIONS


=head1 AUTHOR

Tim Keefer <tkeefer@gmail.com>

=head1 COPYRIGHT and LICENSE

Copyright (c) 2005-6, Tim Keefer.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
