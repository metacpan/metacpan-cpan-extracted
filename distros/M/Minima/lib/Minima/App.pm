use v5.40;
use experimental 'class';

class Minima::App;

use Carp;
use Minima::Router;
use Path::Tiny ();
use Plack::Util;
use FindBin;

use constant DEFAULT_VERSION => 'prototype';

field $env      :param(environment)   :reader = undef;
field $config   :param(configuration) :reader = {};

field $router = Minima::Router->new;

ADJUST {
    $self->_read_config;
}

method set_env      ($e) { $env = $e }
method set_config   ($c) { $config = $c; $self->_read_config }

method development
{
    return 1 if not defined $ENV{PLACK_ENV};

    $ENV{PLACK_ENV} eq 'development'
}

method path ($p)
{
    Path::Tiny::path($p)->absolute($config->{base_dir})->stringify;
}

method run
{
    croak "Can't run without an environment.\n" unless defined $env;

    my $m = $router->match($env);

    return $self->_not_found unless $m;

    my $class  = $m->{controller};
    my $method = $m->{action};

    $self->_load_class($class);

    my $controller = $class->new(
        app => $self,
        route => $m,
    );

    my $response;

    try {
        # before_action
        if ($controller->can('before_action')) {
            my $res = $controller->before_action($method);
            return $res if $res; # halt
        }
        # actual action
        $response = $controller->$method;
        # after action
        if ($controller->can('after_action')) {
            $controller->after_action($response);
        }
    } catch ($e) {
        my $err = $router->error_route;
        # Something failed. If we're in production
        # and there is a server_error route, try it.
        if (!$self->development && $err) {
            $class  = $err->{controller};
            $method = $err->{action};
            $self->_load_class($class);
            $controller = $class->new(
                app => $self,
                route => $err,
            );
            $response = $controller->$method($e);
        } else {
            # Nothing can be done, re-throw
            die $e;
        }
    }

    # Delete body on HEAD requests
    my $auto_head = $config->{automatic_head} // 1;
    if (   $auto_head
        && length $env->{REQUEST_METHOD}
        && $env->{REQUEST_METHOD} eq 'HEAD'
    ) {
        return Plack::Util::response_cb($response, sub {
            my $res = shift;
            if ($res->[2]) {
                $res->[2] = [];
            } else {
                return sub { defined $_[0] ? '' : undef };
            }
        });
    }

    return $response;
}

method _not_found
{
    [
        404,
        [ 'Content-Type' => 'text/plain' ],
        [ "not found\n" ]
    ]
}

method _load_class ($class)
{
    try {
        my $file = $class;
        $file =~ s|::|/|g;
        require "$file.pm";
    } catch ($e) {
        croak "Could not load `$class`: $e\n";
    }
}

method _read_config
{
    # Ensure base_dir is set and absolute
    my $base = $config->{base_dir} // '.';
    $config->{base_dir} = Path::Tiny::path($base)->absolute;

    $self->_load_routes;
    $self->_set_version;
}

method _load_routes
{
    $router->clear_routes;

    my $file = $config->{routes};
    unless (defined $file) {
        # No file passed. Attempt the default route.
        $file = $self->path('etc/routes.map');
        # If it does not exist, setup a basic route
        # for the default controller only.
        unless (-e $file) {
            $router->_connect(
                '/',
                {
                    controller => 'Minima::Controller',
                    action => 'hello',
                },
            );
            return;
        }
    }

    # Controller prefix
    my $prefix = $config->{controller_prefix};
    $router->set_prefix($prefix) if defined $prefix;

    # Read routes
    $file = $self->path($file);
    $router->read_file($file);
}

method _set_version
{
    return if defined $config->{VERSION};

    if (defined $config->{version_from}) {
        my $class = $config->{version_from};
        try {
            $self->_load_class($class);
        } catch ($e) {
            croak "Failed to load version from class.\n$e\n";
        }
        $config->{VERSION} = $class->VERSION // DEFAULT_VERSION;
    } else {
        $config->{VERSION} = DEFAULT_VERSION;
    }
}

__END__

=head1 NAME

Minima::App - Application class for Minima

=head1 SYNOPSIS

    use Minima::App;

    my $app = Minima::App->new(
        environment => $env,
        configuration => { },
    );
    $app->run;

=head1 DESCRIPTION

Minima::App is the core of a Minima web application. It handles starting
the app, connecting to the router, and dispatching route matches. For
more details on this process, refer to the L<C<run>|/run> method.

Three key components of an app are the routes file, the configuration
hash, and the environment hash.

=over 4

=item *

The routes file describes the application's routes. Minima::App checks
for its existence and passes it to the router, which handles reading and
processing the routes. For details on configuring and specifying the
location of the routes file, see the L<C<routes>|/routes> configuration
key and L<Minima::Router>.

=item *

The configuration hash is central to many operations. This hash is
usually loaded from a file, though it can be passed directly to the
L<C<new>|/new> method. This is usually handled by L<Minima::Setup>.

A reference for the configuration keys used by Minima::App is provided
below. Other modules may also utilize the configuration hash, so refer
to their documentation for module-specific details.

=item *

Lastly, the environment hash is a reference to the PSGI environment.
Since it's essential for route matching, it must be set before running
the app.

=back

=head2 Configuration

=over 4

=item C<automatic_head>

Automatically remove the response body for HEAD requests. Defaults to
true. See also: L<"Routes File" in Minima::Router|Minima::Router/"ROUTES
FILE">.

=item C<base_dir>

The base directory of the application. If not specified, it defaults to
the current directory (F<.>). This is used to resolve relative paths to
absolute paths when needed.

Note that in a typical case, L<Minima::Setup> sets C<base_dir> before
Minima::App runs, defaulting to the directory of the main F<.psgi> file
unless it is explicitly set in the configuration.

=item C<controller_prefix>

The default prefix prepended to controller names in the routes file when
using the C<:> shortcut. See also: L<"Controller" in
Minima::Router|Minima::Router/Controller>.

=item C<routes>

The location of the routes file. If not specified, it defaults to
F<etc/routes.map> relative to the C<base_dir>. If no file is found at
that location and this key isn't provided, the app will load a blank
state, where it returns a 200 response for the root path and a 404 for
any other route.

=item C<VERSION>

The current application version. Instead of passing it directly, you
can use the L<C<version_from>> key to auto-populate this. If neither
C<VERSION> not C<version_from> are provided, it defaults to
C<'prototype'>.

=item C<version_from>

Name of a class from which to extract and set C<VERSION>. Only used if
C<VERSION> wasn't given explicitly.

=back

=head1 METHODS

=head2 new

    method new (environment = undef, configuration = {})

Instantiates the app with the provided Plack environment and
configuration hash. Both parameters are optional, but the environment is
required to run the app. If not passed during construction, make sure to
call C<set_env> before C<run>. Configuration keys used by Minima::App
are described under L</Configuration>.

=head2 run

    method run ()

Runs the application by querying the router for a match to C<PATH_INFO>
(the URL in the environment hash) and dispatching it. The enviroment
must already be set.

The dispatch cycle proceeds as follows:

=over 4

=item 1.

Instantiate the matched controller.

=item 2.

If the controller implements C<before_action>, it is called with the
method name about to be executed. If it returns a response, that
response is returned immediately and the action itself is skipped.

=item 3.

Call the action method on the controller.

=item 4.

If the controller implements C<after_action>, it is called with the
response returned by the action. Any changes should be made directly to
the response object.

=back

If the controller-action call fails, Minima::App checks for the
existence of an error route. If the app is I<not in development mode>
and the error route is set, it is called to handle the exception,
with the error message passed as an argument.

If no error route is set, the app dies, passing the exception forward
to be handled by any other middleware.

=head2 development

    method development ()

Utility method that returns true if C<$ENV{PLACK_ENV}> is set to
C<development> or if it is unset. Returns false otherwise.

=head2 path

    method path ($path)

Utility method that resolves a relative path against the application's
base directory. If the provided path is already absolute, it returns the
path unchanged.

=head1 ATTRIBUTES

The attributes below are accessible via reader methods and can be
set with methods of the same name prefixed by C<set_>.

=over 4

=item C<config>, C<set_config>

Returns or sets the configuration hash.

=item C<env>, C<set_env>

Returns or sets the environment hash.

=back

=head1 SEE ALSO

L<Minima>, L<Minima::Setup>, L<Minima::Router>, L<Minima::Controller>,
L<perlclass>.

=head1 AUTHOR

Cesar Tessarin, <cesar@tessarin.com.br>.

Written in September 2024.
