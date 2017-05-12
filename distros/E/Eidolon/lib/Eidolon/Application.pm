package Eidolon::Application;
# ==============================================================================
#
#   Eidolon
#   Copyright (c) 2009, Atma 7
#   ---
#   Eidolon/Application.pm - application class
#
# ==============================================================================

use Eidolon::Core::Exceptions;
use Eidolon::Core::Registry;
use Eidolon::Core::Loader;
use Eidolon::Core::CGI;
use warnings;
use strict;

our $VERSION = "0.02"; # 2009-05-12 05:12:54

# application interface types
use constant
{
    "TYPE_CGI"  => 0,
    "TYPE_FCGI" => 1
};

# ------------------------------------------------------------------------------
# \% new()
# constructor
# ------------------------------------------------------------------------------
sub new
{
    my ($class, $self);

    $class = shift;

    $self = {};
    bless $self, $class;

    return $self;
}

# ------------------------------------------------------------------------------
# start($type)
# start the application
# ------------------------------------------------------------------------------
sub start
{
    my ($self, $name, $type, $r, $config);

    ($self, $type) = @_;

    $name = ref $self;
    $type = TYPE_CGI unless defined $type;

    $r = Eidolon::Core::Registry->new;
    $config = "$name\::Config";

    # load config
    {
        local $SIG{"__DIE__"} = sub {};
        eval "require $config";
    }

    throw CoreError::Compile($@) if $@;
    $r->config( $config->new($name, $type) );
}

# ------------------------------------------------------------------------------
# handle_request()
# handle HTTP request
# ------------------------------------------------------------------------------
sub handle_request
{
    my ($self, $r, $e, $ctrl, $handler, $router);

    $self = shift;
    $r    = Eidolon::Core::Registry->get_instance;

    eval 
    { 
        local $SIG{"__DIE__"} = sub 
        {
            $_[0]->rethrow if ($_[0] eq "Eidolon::Core::Exception");
            throw CoreError($_[0]);
        };

        # some useful classes
        $r->cgi   ( Eidolon::Core::CGI->new    );
        $r->loader( Eidolon::Core::Loader->new );

        # load drivers specified in config
        foreach (@{ $r->config->{"drivers"} })
        {
            $r->loader->load
            ( 
                $_->{"class"}, 
                exists $_->{"params"} ? @{ $_->{"params"} } : () 
            );
        }

        # get a router
        $router = $r->loader->get_object("Eidolon::Driver::Router");
        throw CoreError::NoRouter unless $router;

        # find and start a request handler
        $router->find_handler;

        {
            no strict "refs";
            &{ $router->get_handler }( @{ $router->get_params || [] } );
        }
    };

    # if something went wrong
    if ($@) 
    {
        $e = $@;

        throw CoreError::NoErrorHandler($e) unless $r->config->{"app"}->{"error"};    
        $ctrl = $r->config->{"app"}->{"error"}->[0] || undef;

        eval "require $ctrl";
        throw CoreError::Compile($@) if $@;

        # find the error handler
        $handler = $r->config->{"app"}->{"error"}->[1];
        throw CoreError::NoErrorHandler($e) unless $handler;

        $handler = "$ctrl\::$handler";

        {
            no strict "refs";
            &{ $handler }( ( $e ) );
        }
    }

    # cleanup
    $r->free;
}

1;

__END__

=head1 NAME

Eidolon::Application - Eidolon application base class.

=head1 SYNOPSIS

Example application package (C<lib/ExampleApp.pm>):

    package ExampleApp;
    use base qw/Eidolon::Application/;

    our $VERSION = "0.01";

    1;

CGI application gateway (C<index.cgi>):

    use lib "./lib";
    use ExampleApp;

    my $app = ExampleApp->new;
    $app->start($app->TYPE_CGI);
    $app->handle_request;

=head1 DESCRIPTION

The I<Eidolon::Application> class is the base high-level class of a usual 
I<Eidolon> application. It creates various system objects, reads 
application configuration and handles user requests. 

Should never be used directly, subclass it from your application's main
package instead.

=head2 Request processing flow

These steps are performed while processing user request. This sequence can be 
redefined by the ancestor class, but in most cases you won't need to do this.

=over 4

=item 1. Create system registry

Registry is the system information structure. This step is done first, because
other parts of the system depend on the registry. For more information see 
L<Eidolon::Core::Registry/Mount points> and L<Eidolon::Core::Registry> module 
documentation.

=item 2. Load application configuration

In this step application loads and instantiates the application configuration 
class. It contains all basic system settings. Application configuration in
example application would be stored in C<lib/ExampleApp/Config.pm>. For more 
information see L<Eidolon::Core::Config>.

=item 3. Accept requests (I<FastCGI application only>)

FastCGI application works like a I<daemon> - it resides in memory, accepting
connections from the web server. Whence a new connection is established, 
the application goes to the next step.

=item 4. Handle request

Actually, all the work is done in this step. First of all, the application
creates the L<Eidolon::Core::CGI> object, that is used to process all incoming 
data. Next, application loads system drivers using the L<Eidolon::Core::Loader> 
object. The list of required drivers must be specified in the application 
configuration (note, that you I<must> specify a router driver, otherwise the 
application will not handle requests properly). Afterwards, the 
application transfers execution to a router driver, which tries to find the 
request handler and then calls it.

If an error occurs on this step, the application calls an error handler,
that is specified in application configuration (or uses the default one - 
Eidolon::Error).

After request (or error) handling, a CGI application shuts down, but FastCGI
application goes next.

=item 5. Go to step #3 (I<FastCGI application only>!)

When a user request is handled, our I<daemon>-like application is ready to
serve another clients I<without termination>, so we save a bit of system
resources.

=back

=head1 METHODS

=head2 new()

Class constructor. Creates an application object.

=head2 start($type)

Application initialization. Creates system registry and loads application
configuration. C<$type> - application type (see L</CONSTANTS> section below).

=head2 handle_request()

User request processing. This function parses and routes the request, then it
transfers execution to request handler. If any exception occurs during 
processing, it tries to start application's error handler. If no such handler 
was found, application dies.

=head1 CONSTANTS

=head2 TYPE_CGI

CGI application is the default type. It is suitable for low-loaded 
applications. When this type is used, the web server starts one interpreter 
instance per user request, so if you issue high CPU usage or high memory 
load - use the next application type.

=head2 TYPE_FCGI

FastCGI application type is suitable for high-loaded applications with a lot
of concurrent connections. It's faster than CGI I<up to 2000%>. This type 
suggests L<FCGI> module to be installed, otherwise application won't work.

=head1 SEE ALSO

L<Eidolon>, L<Eidolon::Debug>, 
L<Eidolon::Core::Registry>,
L<Eidolon::Core::Config>,
L<Eidolon::Core::CGI>,
L<Eidolon::Core::Loader>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Anton Belousov, E<lt>abel@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (c) 2009, Atma 7, L<http://www.atma7.com>

=cut
