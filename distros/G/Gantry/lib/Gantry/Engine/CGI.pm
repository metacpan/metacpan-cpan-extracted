package Gantry::Engine::CGI;
require Exporter;

use strict;
use Carp qw( croak );
use CGI::Simple;
use File::Basename;
use Gantry::Utils::DBConnHelper::Script;

use vars qw( @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS );

############################################################
# Variables                                                #
############################################################
@ISA        = qw( Exporter );
@EXPORT     = qw( 
    apache_param_hash
    apache_uf_param_hash
    apache_request
    base_server
    cgi_obj
    config
    cast_custom_error
    consume_post_body
    declined_response
    dispatch_location
    engine
    engine_init
    err_header_out
    fish_location
    fish_method
    fish_path_info
    fish_uri
    fish_user
    fish_config
    get_auth_dbh
    get_cached_config
    get_config
    get_dbh
    get_post_body
    locations
    log_error
    get_arg_hash
    header_in
    header_out
    hostname
    is_connection_secure
    is_status_declined
    port
    print_output
    redirect_response
    remote_ip
    send_http_header
    set_cached_config
    set_content_type
    set_no_cache
    set_req_params
    status_const
    send_error_output
    success_code
    server_root
    file_upload
);

@EXPORT_OK  = qw( );
                    
############################################################
# Functions                                                #
############################################################

#--------------------------------------------------
# $self->new( { locations => {..}, config => {..} } );
#--------------------------------------------------
sub new {
    my( $class, $self ) = ( shift, shift || {} );

    bless $self, $class;

    my $config = $self->{config};

    if ( $self->{config}{ GantryConfInstance } ) {
        $config = $self->get_config(
                        $self->{config}{ GantryConfInstance },
                        $self->{config}{ GantryConfFile     },
                  );
    }

    Gantry::Utils::DBConnHelper::Script->set_conn_info(
        {
            dbconn => $config->{dbconn},
            dbuser => $config->{dbuser},
            dbpass => $config->{dbpass},
        }
    );

    Gantry::Utils::DBConnHelper::Script->set_auth_conn_info(
        {
            auth_dbconn => $config->{auth_dbconn},
            auth_dbuser => $config->{auth_dbuser},
            auth_dbpass => $config->{auth_dbpass},
        }
    );

    $CGI::Simple::DISABLE_UPLOADS = $config->{disable_uploads} || 0;
    $CGI::Simple::POST_MAX        = $config->{post_max} ||'20000000000';
    
    return $self;
    
} # end new

#--------------------------------------------------
# $self->add_config( key, value );
#--------------------------------------------------
sub add_config {
    my( $self, $key, $val ) = @_;
    $self->{cgi_obj}{config}->{$key} = $val;

} # end add_config

#--------------------------------------------------
# $self->add_location( key, value )
#--------------------------------------------------
sub add_location {
    my( $self, $key, $val ) = @_;

    $self->{locations}->{$key} = $val;

} # end add_location

#--------------------------------------------------
# $self->consume_post_body();
#--------------------------------------------------
sub consume_post_body {
    my $self = shift;
    my $cgi  = shift;

    my $content_length = $ENV{ CONTENT_LENGTH };

    return unless $content_length; # nothing to consume

    $content_length    = 1e6 if $content_length > 1e6; # limit to ~ 1Meg

    # just read STDIN
    my $content;
    my $buffer;
    while ( read( STDIN, $buffer, $content_length ) ) {
        $content .= $buffer;

        $content_length -= length $buffer;
    }

    $self->{__POST_BODY__} = $content;
}

#--------------------------------------------------
# $self->get_post_body();
#--------------------------------------------------
sub get_post_body {
    my $self = shift;

    return $self->{__POST_BODY__} || $self->{ cgi_obj }->{__POST_BODY__};
    # the value is in the cgi_obj during testing
}

#--------------------------------------------------
# $self->dispatch();
#--------------------------------------------------
sub dispatch {
    my( $self ) = @_;

    my @path = ( split( m|/|, $ENV{PATH_INFO}||'' ) );         

    LOOP:
    while ( @path ) {

        $self->{config}->{location} = join( '/', @path );

        if ( defined $self->{locations}->{ $self->{config}->{location} } ) {
            my $mod = $self->{locations}->{ $self->{config}->{location} }; 
            
            die "module not defined for location $self->{config}->{location}"
                unless $mod;
        
            eval "use $mod";
            if ( $@ ) { die $@; }

            return $mod->handler( $self );

        }

        pop( @path );
    
    } # end while path
    
    $self->{config}->{location} = '/';
    my $mod = $self->{locations}->{ '/' }; 

    eval "use $mod" if $mod;
    if ( $@ ) { die $@; }

    return $mod->handler( $self );

} # end dispatch

#-------------------------------------------------
# Exported methods
#-------------------------------------------------

#-------------------------------------------------
# $self->file_upload( param_name )
#-------------------------------------------------
sub file_upload {
    my( $self, $param ) = @_;

    die "file param required" if ! $param;
    
    my $q = $self->cgi();
    my $filename = $q->param( $param );
    $filename =~ s/\\/\//g;
    
    my( $name, $path, $suffix ) = fileparse( 
        $filename, 
        qr/\.(tar\.gz$|[^.]*)/ 
    );  
    
    return( {
        unique_key => time . rand( 6 ),
        fullname   => ( $name . $suffix ),
        name       => $name,
        suffix     => $suffix,
        size       => ( $q->upload_info( $filename, 'size' ) || 0 ),
        mime       => $q->upload_info( $filename, 'mime' ),
        filehandle => $q->upload( $filename ),
    } );

}

#-------------------------------------------------
# $self->cast_custom_error( error )
#-------------------------------------------------
sub cast_custom_error {
    my( $self, $error_page, $die_msg ) = @_;
    
    my $status = $self->status() ? $self->status() : '400 Bad Request';
    
    eval {
        print $self->cgi->header(
            -type => 'text/html',
            -status => $status,
        );
    };
    if ( $@ ) {
        die "Error encountered in cast_custom_error: $@\n"
            .   "I was trying to say $error_page\n";
    }

    $self->print_output( $error_page );

    return $status;

}

#-------------------------------------------------
# $self->apache_param_hash( $req )
#-------------------------------------------------
sub apache_param_hash {
    my( $self ) = @_;

    #my %hash_ref = $self->cgi->Vars;
    #return( \%hash_ref );  
    return( $self->cgi_obj->{params} );

} # end: apache_param_hash

#-------------------------------------------------
# $self->apache_uf_param_hash( $req )
#-------------------------------------------------
sub apache_uf_param_hash {
    my( $self ) = @_;

    return( $self->cgi_obj->{uf_params} );

} # end: apache_uf_param_hash

#-------------------------------------------------
# $self->apache_request( )
#-------------------------------------------------
sub apache_request {
    my( $self, $r ) = @_;
        
} # end: apache_request

#-------------------------------------------------
# $self->base_server( $r )
#-------------------------------------------------
sub base_server {
    my( $self ) = ( shift );

    return( $ENV{HTTP_SERVER} || $ENV{HTTP_HOST} );
    
} # end base_server

#-------------------------------------------------
# $self->hostname( )
#-------------------------------------------------
sub hostname {
    my( $self ) = ( shift );

    return( $ENV{HTTP_SERVER} || $ENV{HTTP_HOST} );
    
} # end hostname

#--------------------------------------------------
# $self->cgi_obj( $hash_ref )
#--------------------------------------------------
sub cgi_obj {
    my( $self, $hash_ref ) = @_;

    if ( defined $hash_ref ) {
        $self->{cgi_obj} = $hash_ref;
    }

    return $self->{cgi_obj};
} # end cgi_obj

#--------------------------------------------------
# $self->config( $hash_ref )
#--------------------------------------------------
sub config {
    my( $self, $hash_ref ) = @_;

    if ( defined $hash_ref ) {
        $self->{cgi_obj}{config} = $hash_ref;
    }

    return $self->{cgi_obj}{config};
} # end config

#-------------------------------------------------
# $self->declined_response( )
#-------------------------------------------------
sub declined_response {
    my( $self, $action )  = @_;
    
    print $self->cgi->header(
            -type => 'text/html',
            -status => '404 Not Found',
    );

    my $current_location = $self->config->{ location };

    print( $self->custom_error(
                "Declined - undefined method<br />"
                . "<span style='font-size: .8em'>"
                . "Method: $action<br />"
                . "Location: " . $current_location . "<br />"
                . "Module: " . (
                    $self->locations->{ $current_location }
                    || 'No module defined for this location' )
                . "</span>"
           )
    );
    
    return '404 Not Found';
    
} # END declined_response

#-------------------------------------------------
# $self->dispatch_location( )
#-------------------------------------------------
sub dispatch_location {
    my $self   = shift;

    return( $ENV{ PATH_INFO }, $self->config->{location} );
} # END dispatch_location

#--------------------------------------------------
# $self->engine
#--------------------------------------------------
sub engine {
    return __PACKAGE__;
} # engine

#-------------------------------------------------
# $self->engine_init( $cgi_obj )
#-------------------------------------------------
sub engine_init {
    my $self    = shift;
    my $cgi_obj = shift;
    my $c = new CGI::Simple();

    $c->parse_query_string() if $ENV{ REQUEST_METHOD } eq 'POST';
    $self->cgi( $c );

    # check for CGI::Simple errors
    if ( $c->{'.cgi_error'} ) {
        my $error = $c->{'.cgi_error'};
        my ( $status ) = ( $error =~ s/^(\d+)\s+// );
        $self->status( $status || 400 );
        die( "$error\n" );
    }

    # fix up params so the multiselects are arraays
    my $params    = {};
    my $uf_params = {};

    foreach my $field ( $c->param ) {
        my @values = $c->param( $field );

        if ( scalar @values > 1 ) {
            $uf_params->{$field} = [ @values ];

            # Replace angle brackets and quotes with named-entity equivalents.
            $_ =~ s/</&lt;/g foreach @values;
            $_ =~ s/>/&gt;/g foreach @values;
            $_ =~ s/"/&#34;/g foreach @values;
            $_ =~ s/'/&#39;/g foreach @values;

            # Trim leading / trailing whitespace.
            $_ =~ s/^\s+//o foreach @values;
            $_ =~ s/\s+$//o foreach @values;

            $params->{$field} = [ @values ];
        }

        else {
            $params->{$field} = $c->param( $field );
            $uf_params->{$field} = $params->{$field};

            # Replace angle brackets and quotes with named-entity equivalents.
            $params->{$field} =~ s/</&lt;/g;
            $params->{$field} =~ s/>/&gt;/g;
            $params->{$field} =~ s/"/&#34;/g;
            $params->{$field} =~ s/'/&#39;/g;
            
            # Trim leading / trailing whitespace.
            $params->{$field} =~ s/^\s+//o;
            $params->{$field} =~ s/\s+$//o;
        }
    }

    # add in the fieldnames
    $params->{'.fieldnames'} = [ $c->param ];
    $uf_params->{'.fieldnames'} = [ $c->param ];

    # If the application has specified that it wants the unfiltered params
    # by default, then make it happen.
    if ($self->fish_config( 'unfiltered_params' ) && $self->fish_config( 'unfiltered_params' ) =~ /(1|on)/i) {
        $cgi_obj->{params} = $uf_params;
    }

    # Else, the application gets the request parameters filtered by default.
    # NOTE: It's got access to the unfiltered hash, in case it needs a
    # request/field to have the parameters in such a way.
    else {
        $cgi_obj->{params} = $params;
        $cgi_obj->{uf_params} = $uf_params;
    }

    $self->cgi_obj( $cgi_obj );

} # END engine_init

#-------------------------------------------------
# $self->err_header_out( $header_key, $header_value )
#-------------------------------------------------
sub err_header_out {
    # Gantry.pm calls this for mod_perl's benefit.
} # end err_header_out

#-------------------------------------------------
# $self->fish_location( )
#-------------------------------------------------
sub fish_location {
    my $self = shift;

    my $app_rootp = $self->fish_config( 'app_rootp' ) || '';
    my $location  = $self->fish_config( 'location' )  || '';

    return( $app_rootp . $location );
} # END fish_location

#-------------------------------------------------
# $self->fish_method( )
#-------------------------------------------------
sub fish_method {
    my $self = shift;

    return $ENV{ REQUEST_METHOD };
} # END fish_method

#-------------------------------------------------
# $self->fish_path_info( )
#-------------------------------------------------
sub fish_path_info {
    my $self = shift;

    return $ENV{ PATH_INFO };
} # END fish_path_info

#-------------------------------------------------
# $self->fish_uri( )
#-------------------------------------------------
sub fish_uri {
    my $self = shift;

    my $sn = $ENV{SCRIPT_NAME} || '';
    my $pi = $ENV{PATH_INFO}   || '';
    
    return( "${sn}${pi}" );
} # END fish_uri

#-------------------------------------------------
# $self->fish_user( )
#-------------------------------------------------
sub fish_user {
    my $self = shift;

    return $self->user() || $self->{cgi_obj}{config}{user} || '';
} # END fish_user

#--------------------------------------------------
# $self->fish_config( $param )
#--------------------------------------------------
sub fish_config {
    my $self     = shift;
    my $param    = shift;

    # see if there is Gantry::Conf data
    my $conf     = $self->get_config();

    return $$conf{ $param } if ( defined $conf and defined $$conf{ $param } );

    # otherwise, look in the cgi engine object
    # ... starting at the location levels
    if ( $self->{ cgi_obj }{ config }{ GantryLocation } ) {
        my $glocs = $self->{ cgi_obj }{ config }{ GantryLocation };
        my $loc   = $self->location;
        my @path  = split( '/', $loc );

        while( @path ) {

            my $path = join( '/', @path );

            if ( defined $glocs->{ $path }
                    and
                 defined $glocs->{ $path }{ $param }
            ) {
                return $glocs->{ $path }{ $param };
            }

            pop @path;
        }
    }

    # ... then defaulting to the top level
    return $self->{cgi_obj}{config}{ $param };

}

#--------------------------------------------------
# $self->get_config
#--------------------------------------------------
sub get_config {
    my $self     = shift;
    my $instance = shift || $self->{cgi_obj}{config}{ GantryConfInstance };

    return unless defined $instance;

    my $file     = shift || $self->{cgi_obj}{config}{ GantryConfFile };

    my $conf;
    my $cached   = 0;
    my $location = '';


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
    
    # There will be an error if this method was called during construction
    # that is before their is a Gantry descended object as the invocant.
    # In that case, we don't care about the location anyway.    
    require Gantry::Conf;

    $conf      ||= Gantry::Conf->retrieve(
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

my %conf_cache;

sub get_cached_config {
    my $self     = shift;
    my $instance = shift;
    my $location = shift;
    
    return $conf_cache{ $instance . $location } || undef;
}

sub set_cached_config {
    my $self     = shift;
    my $instance = shift;
    my $location = shift;                 # not using location, this cache good for one page
    my $conf     = shift;

    $conf_cache{ $instance . $location } = $conf;
}

#-------------------------------------------------
# $self->get_arg_hash
#-------------------------------------------------
sub get_arg_hash {
    my( $self ) = @_;

    #my %hash_ref = $self->cgi->Vars;
    
    return wantarray ? %{ $self->cgi_obj->{params} }
                     :    $self->cgi_obj->{params}; 
                                        
} # end get_arg_hash

#-------------------------------------------------
# $self->get_auth_dbh( )
#-------------------------------------------------
sub get_auth_dbh {
    Gantry::Utils::DBConnHelper::Script->get_auth_dbh;
}

#-------------------------------------------------
# $self->get_dbh( )
#-------------------------------------------------
sub get_dbh {
    Gantry::Utils::DBConnHelper::Script->get_dbh;
}

#-------------------------------------------------
# $self->header_in( )
#-------------------------------------------------
sub header_in {
    my( $self, $key ) = @_;

    return $ENV{uc $key} || $ENV{$key} || '';
} # end header_in

#-------------------------------------------------
# $self->header_out( $header_key, $header_value )
#-------------------------------------------------
sub header_out {
    my( $self, $k, $v ) = @_;
        
    # $self->{__HEADERS_OUT__}->{$k} = $v if defined $k;  
    # return( $self->{__HEADERS_OUT__} );

    return $self->response_headers( $k, $v );

} # end header_out

#--------------------------------------------------
# $self->locations( $hash_ref )
#--------------------------------------------------
sub locations {
    my( $self, $hash_ref ) = @_;

    if ( defined $hash_ref ) {
        $self->{cgi_obj}{locations} = $hash_ref;
    }

    return $self->{cgi_obj}{locations};
} # end locations

#--------------------------------------------------
# $self->log_error( $text )
#--------------------------------------------------
sub log_error {
    my ( $self, $text ) = @_;

    warn "$text\n";
}

#-------------------------------------------------
# $self->redirect_response( )
#-------------------------------------------------
sub redirect_response {
    my $self = shift;

    my $cookies = '';
    foreach my $cookie ( @{ $self->cookie_stash() } ) {
        print "Set-Cookie: $cookie\n";
    }
    
    my $p = {};
    $p->{uri} = $self->response_headers->{location};

    print $self->cgi->redirect( $p );
    
    return 302;
} # END redirect_response

#-------------------------------------------------
# $self->remote_ip( $r )
#-------------------------------------------------
sub remote_ip {
    my( $self ) = ( shift, shift );
    
    return( $ENV{REMOTE_ADDR} );

} # end remote_ip

#-------------------------------------------------
# $self->print_output( $response_page )
#-------------------------------------------------
sub print_output {
    my $self          = shift;
    my $response_page = shift;

    print $response_page;

} # print_output

#-------------------------------------------------
# $self->port( $r )
#-------------------------------------------------
sub port {
    my( $self ) = ( shift );
    
    return( $ENV{SERVER_PORT} );

} # end port

#-------------------------------------------------
# $self->server_root( $r )
#-------------------------------------------------
sub server_root {
    my( $self ) = ( shift );
    
    return( $ENV{HTTP_SERVER} );

} # end server_root

#-------------------------------------------------
# $self->status_const( 'OK | DECLINED | REDIRECT' )
#-------------------------------------------------
sub status_const {
    my( $self, $status ) = @_;

    return '404'         if uc $status eq 'DECLINED';
    return '200'         if uc $status eq 'OK';
    return '301'         if uc $status eq 'MOVED_PERMANENTLY';
    return '302'         if uc $status eq 'REDIRECT';
    return '403'         if uc $status eq 'FORBIDDEN';
    return '401'         if uc $status eq 'AUTH_REQUIRED';
    return '401'         if uc $status eq 'HTTP_UNAUTHORIZED';
    return '400'         if uc $status eq 'BAD_REQUEST';
    return '500'         if uc $status eq 'SERVER_ERROR';

    die( "Undefined constant $status" );
    

} # end status_const

#-------------------------------------------------
# $self->is_connection_secure()
#-------------------------------------------------
sub is_connection_secure {
    my $self = shift;

    return $ENV{'SSL_PROTOCOL'} ? 1 : 0;
} # END is_connection_secure

#-------------------------------------------------
# $self->is_status_declined( $status )
#-------------------------------------------------
sub is_status_declined {
    my $self = shift;

    my $status = $self->status || '';

    return 1 if ( $status eq 'DECLINED' );
} # END is_status_declined

#-------------------------------------------------
# $self->send_error_output( $@ )
#-------------------------------------------------
sub send_error_output {
    my $self     = shift;

    print $self->cgi->header(
            -type   => 'text/html',
            -status => '500 Server Error',
    );

    $self->do_error( $@ );
    print( $self->custom_error( $@ ) );

} # END send_error_output

#-------------------------------------------------
# $self->send_http_header( )
#-------------------------------------------------
sub send_http_header {
    my $self = shift;

    my $cookies = '';
    foreach my $cookie ( @{ $self->cookie_stash() } ) {
        print "Set-Cookie: $cookie\n";
    }

    my $header_for = $self->response_headers();
    
    foreach my $variable ( keys %{ $header_for } ) {
        print "$variable: $header_for->{ $variable }\n";
    }

    print $self->cgi->header(
        -type => ( $self->content_type ? $self->content_type : 'text/html' ),
        -status => ( $self->status() ? $self->status() : '200 OK' ),
    );
    
} # send_http_header

#-------------------------------------------------
# $self->set_content_type( )
#-------------------------------------------------
sub set_content_type {


# This method is for mod_perl engines.  They need to transfer
# the content_type from the site object to the apache request object.
# We don't need to do that.

} # set_content_type

#-------------------------------------------------
# $self->set_no_cache( )
#-------------------------------------------------
sub set_no_cache {
    my $self = shift;

    $self->cgi->no_cache( 1 ) if $self->no_cache;
} # set_no_cache

#-------------------------------------------------
# $self->set_req_params( )
#-------------------------------------------------
sub set_req_params {
    my $self = shift;

    $self->params( $self->cgi_obj->{params} );
    $self->uf_params( $self->cgi_obj->{uf_params} );

} # END set_req_params

#-------------------------------------------------
# $self->success_code( )
#-------------------------------------------------
sub success_code {

    return '200';
# This is for mod_perl engines.  They need to tell apache that
# things went well.

} # END success_code

sub parse_env {
    my $data;
    my $hash = {};

    my $ParamSeparator = '&';

    if ( defined $ENV{REQUEST_METHOD} 
            && $ENV{REQUEST_METHOD} eq "POST" ) {

        read STDIN , $data , $ENV{CONTENT_LENGTH} ,0;

        if ( $ENV{QUERY_STRING} ) {
            $data .= $ParamSeparator . $ENV{QUERY_STRING};
        }

    } 
    elsif ( defined $ENV{REQUEST_METHOD} 
        && $ENV{REQUEST_METHOD} eq "GET" ) {
     
        $data = $ENV{QUERY_STRING};
    } 
    elsif ( defined $ENV{REQUEST_METHOD} ) {
        print "Status: 405 Method Not Allowed\r\n\r\n";
        exit;
    }

    return {} unless (defined $data and $data ne '');


    $data =~ s/\?$//;
    my $i=0;

    my @items = grep {!/^$/} (split /$ParamSeparator/o, $data);
    my $thing;

    foreach $thing (@items) {

        my @res = $thing=~/^(.*?)=(.*)$/;
        my ( $name, $value, @value );

        if ( $#res <= 0 ) {
            $name  = $i++;
            $value = $thing;
        } 
        else {
            ( $name, $value ) = @res;
        }
        
        $name =~ tr/+/ /;
        $name =~ s/%(\w\w)/chr(hex $1)/ge;

        $value =~ tr/+/ /;
        $value =~ s/%(\w\w)/chr(hex $1)/ge;

        if ( $hash->{$name} ) {
            if ( ref $hash->{$name} ) {
                push( @{$hash->{$name}}, $value );
            } 
            else {
                $hash->{$name} = [ $hash->{$name}, $value];
            }
        } 
        else {
            $hash->{$name} = $value;
        }
    }
    
    return( $hash );
}

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

Gantry::Engine::CGI - CGI plugin ( or mixin )

=head1 SYNOPSIS


 use strict;
 use CGI::Carp qw(fatalsToBrowser);
 use MyApp qw( -Engine=CGI -TemplateEngine=Default );
 use Gantry::Engine::CGI;

 my $cgi = Gantry::Engine::CGI->new( {
   locations => {
     '/'        => 'MyApp',
     '/music'  => 'MyApp::Music',
   },
   config => {
      img_rootp           => '/malcolm/images',
      css_rootp           => '/malcolm/style',
      app_rootp           => '/cgi-bin/theworld.cgi',
   }
 } );

 # optional: templating variables
 $cgi->add_config( 'template_wrapper', 'wrapper.tt' );
 $cgi->add_config( 'root', '/home/httpd/templates' );
  
 # optional: database connection variables
 $cgi->add_config( 'dbconn', 'dbi:Pg:dbname=mydatabase' );
 $cgi->add_config( 'dbuser','apache' );

 # optional: add another location
 $cgi->add_location( '/music/artists', 'MyApp::Music::Artists' );
 
 # Standard CGI 
 $cgi->dispatch;   

 # Fast-CGI
 use FCGI;
 my $request = FCGI::Request();
  
 while( $request->Accept() >= 0 ) {
   $cgi->dispatch;
 }

=head1 Fast-CGI

Be sure add the nesscessary while loop around the cgi dispatch method call.

 use FCGI;
 my $request = FCGI::Request();

 while( $request->Accept() >= 0 ) {
   $cgi->dispatch;
 }

=head1 Fast-CGI and Apache

To enable Fast-CGI for Apache goto http://www.fastcgi.com/

 Alias /cgi-bin/ "/home/httpd/cgi-bin/"
 <Location /cgi-bin>
     Options +ExecCGI
     AddHandler fastcgi-script cgi
 </Location>

=head1 DESCRIPTION

This module is the binding between the Gantry framework and the CGI API.
This particluar module contains the standard CGI specific bindings. 

=head1 METHODS of this CLASS

=over 4

=item new

cgi object that can be used to dispatch request to corresonding

=item dispatch

This method dispatchs the current request to the corresponding module.

=item add_config

Adds a configuration item to the cgi object

=item add_location

Adds a location to the cgi object

=item $self->parse_env

Used internally.  Destroys posted form data.

Places all query string and form parameters into a hash, which it returns
by reference.

=back

=head1 METHODS MIXED into the SITE OBJECT

=over 4

=item $self->apache_param_hash

Returns the hash reference of form and query string params.

=item $self->apache_uf_param_hash

Returns the hash reference of form and query string params unfiltered.

=item $self->apache_request

This method does nothing.  It is here to conform the engine api.  mod_perl
engines return their apache request object in response to this method.

=item $self->base_server

Returns the physical server this connection came in 
on (main server or vhost):

=item $self->cast_custom_error

Delivers error output to the browser.

=item $self->cgi_obj

Dual accessor for the CGI::Simple object.

=item $self->config

Dual accessor for updating the config hash in the CGI engine object.

=item $self->consume_post_body

This method is for plugins to use at the pre_init phase to catch XML
requests and the like.  It is imcompatible with normal form processing.
For example L<Gantry::Plugins::SOAP::Doc> uses it.

=item $self->declined_response

Returns the proper numerical code for DECLINED response.

=item $self->dispatch_location

The uri tail specific to this request.  Returns:

    $ENV{ PATH_INFO }, $self->config->location

Note that this a two element list.

=item $self->engine

Returns the name for the engine

=item engine_init

For use during site object init, by Gantry.pm.

=item err_header_out

Does nothing, but meet the engine API.

=item $self->fish_config

Pass this method the name of a conf parameter you need.  Returns the
value for the parameter.

=item $self->fish_location

Returns the location for the current request.

=item $self->fish_method

Returns the HTTP method of the current request.

=item $self->fish_path_info

Returns the path info for the current request.

=item $self->fish_uri

Returns the uri for the current request.

=item $self->fish_user

Returns the currently logged-in user.

=item $self->get_arg_hash

returns a hash of url arguments.

/some/where?arg1=don&arg2=johnson

=item $self->get_auth_dbh

Returns the auth db handle (if there is one).

=item $self->get_cached_config

You should normally call get_config instead of this.

Used internally to store the config hash for a full page hit cycle.

=item $self->get_config

If you are using Gantry::Conf, this will return the config hash reference
for the current location.

=item $self-> get_cached_conf/set_cached_conf

These cache the Gantry::Conf config hash in a lexical hash.  Override them if
you want more persistent caching.  These are instance methods.  get
receives the invoking object, the name of the GantryConfInstance,
and the current location (for ease of use, its also in the invocant).
set receives those plus the conf hash it should cache.

=item $self->get_dbh

Returns the db handle (if there is one).

=item $self->get_post_body

Returns whatever C<consume_post_body> took from the post body.  Use this
if you also use a plugin that consumes the post body like
L<Gantry::Plugins::SOAP::Doc> does.

=item $self->header_in

Does nothing but meet the engine API.  mod_perl engines use this.

=item $self->header_out( $header_key, $header_value )

Deprecated, merely calls response_headers (defined in Gantry.pm)
for you, which you should have done yourself.

Change the value of a response header, or create a new one.

=item $self->hostname

Returns the current host name from the HTTP_SERVER or the HTTP_HOST
environment variables.  HTTP_SERVER takes precedence.

=item $self->is_connection_secure()

Return whether the current request is being served by an SSL-enabled host.

=item $self->is_status_declined

Returns true if the current status is DECLINED, or false otherwise.

=item $self->log_error

Prints text to STDERR so you can do the same thing under mod_perl
without code changes.

=item $self->locations

Dual accessor for the locations hash passed to the constructor
or built up with add_location.

=item $self->remote_ip

Returns the IP address for the remote user

=item $self->port

Returns port number in which the request came in on.

=item $self->print_output

Prints whatever you pass to it.

=item $self->redirect_response

Prints a redirection to the current header_out location.

=item $self->send_error_output

Prints an error header and passes the value of $@ to custom_error.

=item $self->send_http_header

Prints the header for the current content_type.

=item $self->server_root

Returns the value set by the top-level ServerRoot directive

=item $self->set_cached_config

For internal use only.  Stores the conf hash from Gantry::Conf so it
doesn't have to be refetched during a single page hit.

=item $self->set_content_type

You should use the dual accessor content_type supplied by Gantry.pm.

This method does nothing except meet the API.  mod_perl engines use this
to move the content type from the site object to the request object.

=item $self->set_no_cache

You should use the dual accessor no_cache supplied by Gantry.pm instead
of this.

Transfers the no_cache flag from the site object to the cgi object.

=item $self->set_req_params

Used by Gantry during site object init to transfer params from the cgi
engine object to the site object.

=item $self->status_const( 'OK | DECLINED | REDIRECT' )

Get or set the reply status for the client request. The Apache::Constants 
module provide mnemonic names for the status codes.

=item $self->success_code

Does nothing but meet the engine API.  mod_perl engines use it to report
the numerical success code.

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

Gantry(3)

=head1 LIMITATIONS


=head1 AUTHOR

Tim Keefer <tkeefer@gmail.com>

=head1 COPYRIGHT and LICENSE

Copyright (c) 2005-6, Tim Keefer.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
