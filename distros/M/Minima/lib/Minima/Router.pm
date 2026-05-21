use v5.40;
use experimental 'class';

class Minima::Router;

use Carp;
use Path::Tiny;
use Router::Simple;

field $router = Router::Simple->new;
field %special;
field $prefix = 'Controller';

method match ($env)
{
    my $match = $router->match($env);
    return $match if defined $match;

    $self->not_found_route;
}

method read_file ($file)
{
    $file = path($file);
    croak "Routes file `$file` does not exist.\n"
        unless -e $file->absolute;

    # Parse routes
    for ($file->lines_utf8) {
        # Skip blank or comment lines
        next if /^\s*#|^\s*$/;

        # Extract data
        $_ = trim $_;
        my ($method, $pattern, $controller, $action) = split;

        # Build destination and options
        my %dest = $self->_build_destination($controller, $action);
        my %opt  = $self->_build_options($method);

        # Test the nature of the route
        if ($method eq '@') {
            # Special
            $special{$pattern} = \%dest;
        } else {
            # Regular
            $router->connect($pattern, \%dest, \%opt);
        }
    }
}

method _build_command ($command, $action)
{
    state %redirects = (
        redirect           => 302,
        r                  => 302,
        redirect_permanent => 301,
        rp                 => 301,
    );

    # Remove initial `@`
    $command = substr($command, 1);

    croak "Unknown route command `$command`.\n"
        unless exists $redirects{$command};

    (
        redirect        => $action,
        redirect_status => $redirects{$command}
    )
}

method _build_destination ($controller, $action)
{
    if (defined $controller) {
        # Check if it is a command
        return $self->_build_command($controller, $action)
            if $controller =~ /^@/;

        # Fix controller prefix
        $controller =~ s/^:+/${prefix}::/;
    }

    ( controller => $controller, action => $action )
}

method _build_options ($method)
{
    return () if ($method eq '*'); # Don't add a constraint
    return ( method => [ qw/ GET HEAD / ] ) if $method eq 'GET';
    return ( method => 'GET' ) if $method eq '_GET';
    return ( method => $method );
}

method _connect
{
    $router->connect(@_);
}

method clear_routes
{
    $router  = Router::Simple->new;
    %special = ( );
}

method set_prefix ($new)
{
    $prefix = $new;
}

method not_found_route  { $special{not_found} }
method error_route      { $special{server_error} }

__END__

=head1 NAME

Minima::Router - Define and match URIs to controllers and methods

=head1 SYNOPSIS

    use Minima::Router;

    my $router = Minima::Router->new;

    $router->read_file('etc/routes.map');
    my $match = $router->match($env); # Plack env

    # unless ($match) ... handle a no match case

    my $controller = $match->{controller};
    my $method = $match->{action};

    try {
        $controller->$action;
    } catch ($e) {
        $match = $router->error_route;
        # handle error
    }

=head1 DESCRIPTION

Minima::Router is built on top of L<Router::Simple> and serves as a
dispatcher for web applications, interfacing between a routes file and
the router itself.

This module parses a custom syntax (see below) for determining routes
and is tightly integrated with the Minima framework, being used by
L<Minima::App> automatically.

=head2 Using This Module Outside Minima

A matched route returns, by definition, a controller name and action in
the form of a hash reference. This hash may contain more data, such as
data extracted from the URI by L<Router::Simple>. The main controller
and action keys may be undefined if not provided in the routes file.

As long as your use case accepts this hash, there is nothing preventing
you from using this module independently.

=head1 ROUTES FILE

=head2 Syntax

A routes file contains one route per line and follows a rigid structure
of four columns separated by whitespace (spaces or tabs):

    <method or directive>  <route name>  <controller>  <action>

Blank lines are discarded, and lines beginning with C<#> are considered
comments and are also discarded. Your routes file may be placed anywhere
and have any extension.

=over 4

=item B<Method or Directive>

The name of the HTTP method to which this route applies (GET, POST,
etc.). This value may also be set to C<*>, in which case any method is
permitted for this route. If set to C<@>, the route represents a special
directive determined in conjunction with the next column.

B<Note>: C<GET> matches both GET and HEAD requests. To match GET
exclusively, use C<_GET> instead.

=item B<Route Name>

The name or pattern of this route, in any format understood by
L<Router::Simple>. If this route is a directive, the currently accepted
values for the route name and their meanings are:

=over 4

=item C<not_found>

Registers the controller and action pair as the return value for cases
where the router didn't find any valid match.

=item C<server_error>

Registers the controller and action pair as the return value for the
method L<C<error_route>|/error_route>. B<Note:> Use a controller that
requires minimal setup as your error handler. If your controller failed
due to a database error, for instance, there is no point in trying to
start it again just to show an error page.

Minima::App will call the error method with an argument representing the
exception. If desired, the method can utilize this argument.

=back

=item B<Controller>

The controller column determines how Minima handles a matching route.
It may be written in one of the following forms:

=over 4

=item C<My::Controller>

A plain controller name. This value is returned in the match hash
reference with the key C<controller>.

=item C<:Main>

A controller name beginning with C<:>. In this form, a prefix
(defaulting to C<Controller>) is automatically prepended, with the C<::>
package separator added by the router. For example, C<:Main> maps to
C<Controller::Main>. This prefix can be customized using
L<C<set_prefix>|/set_prefix>.

B<Note:> When using L<Minima::Router> through the default Minima::App,
the controller prefix may also be set via the
L<C<controller_prefix>|Minima::App/controller_prefix> configuration key,
without needing to call C<set_prefix> directly.

=item C<@command>

A route command, not a controller name. Commands are handled directly by
the framework instead of being loaded as controller classes. See
L</Commands> for the available route commands.

=back

This column may be left blank only if the next column is also blank,
which will be translated as C<undef> in the match hash.

=item B<Action>

Name of the method that should be called on the controller for this
match, returned in the match hash reference with the key C<action>. For
route commands, this value is interpreted by the command.

This may be left blank, which will be translated as C<undef> in the
match hash.

=back

For editing support in Vim, see
L<vim-minima|https://github.com/tessarin/vim-minima>.

=head2 Commands

Route commands are placed in the controller column and begin with C<@>.
They use the action column according to the command being called.

=over 4

=item C<@redirect>, C<@r>

Redirects to the path or URL specified in the action column with a
C<302> response.

=item C<@redirect_permanent>, C<@rp>

Redirects to the path or URL specified in the action column with a
C<301> response.

=back

=head2 Example

    # Main Routes
    *       /               :Main         home
    GET     /about          :Main         about_page
    GET     /blog/{post}    Blog::Main    article
    GET     /old            @redirect     /new
    GET     /legacy         @rp           /archive

    # Form processing
    POST    /contact        :Form         contact

    # Special
    @       not_found       :Main         not_found_page
    @       server_error    :Error        error_page

=head1 METHODS

=head2 new

Constructs a new object. No arguments required.

=head2 clear_routes

    method clear_routes ()

Removes all registered routes.

=head2 error_route

    method error_route ()

Returns the controller-action pair registered with the
L<C<server_error>|/server_error> directive. If nothing was registered,
returns C<undef>.

=head2 match

    method match ($env)

Performs a match on the passed Plack C<$env>, or URI, and returnes a
hash reference containing the controller-action pair as well as extra
data extracted from the URI match.

    { controller => '...', action => '...', post => 123 }

The extra keys (like C<post> above) are available in the controller
through the L<route attribute in
Minima::Controller|Minima::Controller/route>.

If no match is made and a not found route is registered (via the
L<C<not_found>|/not_found> directive), its data is returned. If no match
is found and no special directive is present in the routes file, it
returns C<undef>.

Note that this does not call the controller. It's up to the user to do
that in order to perform the intended action. In a typical application,
L<Minima::App> will perform the call.

=head2 not_found_route

    method not_found_route ()

Returns the controller-action pair registered with the
L<C<not_found>|/not_found> directive. If nothing was registered, returns
C<undef>.

=head2 read_file

    method read_file ($file)

Parses the routes file given as an argument and registers the routes.
This method can be called multiple times on the same instance to process
more than one file.

=head2 set_prefix

    method set_prefix ($prefix)

Sets the prefix for completing controller names when using the C<:>
notation. Defaults to C<Controller>. See L</Controller> for details.
Pass only the namespace prefix itself, without trailing C<:> or C<::>;
the router adds C<::> automatically.

If you are using Minima::Router through the default L<Minima::App>
integration, you do not need to call this method directly. Instead, set
the L<C<controller_prefix>|Minima::App/controller_prefix> key in the
configuration hash passed to Minima::App, and it will configure the
router automatically.

=head1 SEE ALSO

L<Minima>, L<Minima::Controller>, L<Router::Simple>, L<Plack>,
L<perlclass>, L<vim-minima|https://github.com/tessarin/vim-minima>.

=head1 AUTHOR

Cesar Tessarin, <cesar@tessarin.com.br>.

Written in September 2024.
