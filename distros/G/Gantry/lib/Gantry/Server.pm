package Gantry::Server;
use strict; use warnings;

use base qw( HTTP::Server::Simple::CGI );

use Symbol;

my $engine_object;
my $net_server;

sub set_engine_object {
    my $self       = shift;
    $engine_object = shift;
}

sub set_net_server {
    my $self       = shift;
    $net_server    = shift;
}

sub handler {
    my $self = shift;

    eval { $self->handle_request() };
    if ( $@ ) {
        warn "$@\n";
    }
}

sub handle_request_test_xml {
    my ( $self, $location, $xml ) = @_;

    $engine_object->{__POST_BODY__} = $xml;
    $ENV{ CONTENT_LENGTH } = 0;
    $ENV{ REQUEST_METHOD } = 'POST';
    $ENV{ URI            } = $location;
    $ENV{ PATH_INFO      } = $location;

    return $self->_test_helper();
}

sub handle_request_test_post {
    my ( $self, $request ) = @_;

    my $method = 'POST'; # always GET for tests
    $request =~ s/^(POST|GET)\://;
    
    my( $uri, $args ) = split( /\?/, $request );
    
    $ENV{PATH_INFO}         = $uri || $request;
    $ENV{REQUEST_METHOD}    = $method;
    $ENV{CONTENT_LENGTH}    = 0;
    $ENV{QUERY_STRING}      = ( defined $args ? $args : '' );
    $ENV{SCRIPT_NAME}       = "";

    return $self->_test_helper();
}

sub handle_request_test {
    my ( $self, $request ) = @_;

    my $method = 'GET'; # always GET for tests
    $request =~ s/^(POST|GET)\://;
    
    my( $uri, $args ) = split( /\?/, $request );
    
    $ENV{PATH_INFO}         = $uri || $request;
    $ENV{REQUEST_METHOD}    = $method;
    $ENV{CONTENT_LENGTH}    = 0;
    $ENV{QUERY_STRING}      = ( defined $args ? $args : '' );
    $ENV{SCRIPT_NAME}       = "";

    return $self->_test_helper();
}

sub _test_helper {
    my $self = @_;

    # divert STDOUT to another handle that stores the returned data
    my $out_handle      = gensym;
    my $out             = tie   *$out_handle, "Gantry::Server::Tier";
    my $original_handle = select $out_handle;

    # dispatch to the gantry engine
    my $status;
    eval {
        $status = $engine_object->dispatch();
    };
    if ( $@ ) {
        return( '401', ( "($@)" . ( $out->get_output() ) ) );
    }

    return( $status, $out->get_output() );
    
}

sub net_server {
    $net_server ? $net_server : '';    
}

sub setup_server_url {
    $ENV{SERVER_URL}
    ||= ( 
        "http://" 
        . ( $ENV{SERVER_NAME} || '' ) 
        . ":" . $ENV{SERVER_PORT} . "/" 
    );
}

sub handle_request {
    my ( $self  ) = @_;

    # divert STDOUT to another handle that stores the returned data
    my $out_handle      = gensym;
    my $out             = tie   *$out_handle, "Gantry::Server::Tier";
    my $original_handle = select $out_handle;

    # dispatch to the gantry engine
    my $status;
    eval {
        $status = $engine_object->dispatch();
    };
    if ( $@ ) {
        select $original_handle;
        print <<"EO_FAILURE_RESPONSE";
HTTP/1.0 401 Not Found
Content-type: text/html

<h1>Not Found</h1>
The requested URL $ENV{PATH_INFO} was not found on this server.
<br />
$@
EO_FAILURE_RESPONSE
        return;
    }
    
    select $original_handle;

    print "HTTP/1.0 $status\n" . $out->get_output();

}

package Gantry::Server::Tier;
use strict;

sub get_output {
    my $self = shift;

    return $self->[1] || '';
}

sub TIEHANDLE {
    my $class = shift;
    my $self  = [ shift() ];

    return bless $self, $class;
}

sub PRINT {
    my $self    = shift;

    no warnings;    
    $self->[1] .= join '', @_;
}

1;

=head1 NAME

Gantry::Server - HTTP::Server::Simple::CGI subclass providing stand alone server

=head1 SYNOPSIS

    #!/usr/bin/perl
    use strict;

    use Gantry::Server;

    use lib '/home/myhome/lib';

    use YourApp qw{ -Engine=CGI -TemplateEngine=Default };

    my $cgi_engine = Gantry::Engine::CGI->new();
    $cgi_engine->add_location( '/', 'YourApp' );

    my $server = Gantry::Server->new();
    # pass a port number to the above constructor if you don't want 8080.

    $server->set_engine_object( $cgi_engine );
    $server->run();

=head1 DESCRIPTION

This module subclasses HTTP::Server::Simple::CGI to provide a stand
alone server for any Gantry app.  Pretend you are deploying to a CGI
environment, but replace

    $cgi_engine->dispatch();

with

    use Gantry::Server;

    my $server = Gantry::Server->new();
    $server->set_engine_object( $cgi_engine );
    $server->run();

Note that you must call set_engine_object before calling run, and you
must pass it a valid Gantry::Engine::CGI object with the proper
locations and config definitions.

By default, your server will start on port 8080.  If you want a different
port, pass it to the constructor.  You can generate the above script,
with port control, in bigtop by doing this in your config section:

    config {
        engine CGI;
        CGI    Gantry { with_server 1; }
        #...
    }
    app YourApp {
        #...
    }

=head1 METHODS

=over 4

=item set_engine_object

You must call this before calling run.  Pass it a Gantry::Engine::CGI object.

=item run

This starts the server and never returns.

=item handler

This method overrides the parent version to avoid taking form parameters
prematurely.

=item handle_request

This method functions as a little web server processing http requests
(but it leans heavily on HTTP::Server::Simple::CGI).

=item handle_request_test

This method pretends to be a web server, but only handles a single request
before returning.  This is useful for testing your Gantry app without
having to use sockets.

=item handle_request_test_post

This is the same as handle_request_test, but it treats the request as a POST.
This is mainly used for form testing.

=item handle_request_test_xml

This method is like C<handle_request_test>, but for SOAP packets.  Call
it with the location you want to hit and the XML packet to PUT there.
Returns whatever the server returns.

=item net_server

Retrieves the defined Net::Sever engine type

=item set_net_server

optionaly you can set a Net::Sever engine type ( see Net::Server ).

 $server->set_net_server( 'Net::Server::PreForkSimple' );

=item setup_server_url

Builds and sets the SERVER_URL environment variable.

=back

=head1 AUTHOR

Phil Crow <philcrow2000@yahoo.com>

=head1 COPYRIGHT and LICENSE

Copyright (c) 2006, Phil Crow.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
