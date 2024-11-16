use v5.40;
use experimental 'class';

class Minima::Router;

use Carp;
use Path::Tiny;
use Router::Simple;

field $router = Router::Simple->new;
field %special;

method match ($env)
{
    $router->match($env) // $special{not_found};
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
        my ($method, $pattern, $controller, $action) = split;

        # Fix controller prefix
        $controller =~ s/^:+/Controller::/;

        # Build destination and options
        my %dest = ( controller => $controller, action => $action );
        my %opt;
        if ($method eq '*') {
            # Do nothing -- don't add a constraint
        } elsif ($method eq 'GET') {
            $opt{method} = [ qw/ GET HEAD / ];
        } elsif ($method eq '_GET') {
            $opt{method} = 'GET';
        } else {
            $opt{method} = $method;
        }

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

method _connect
{
    $router->connect(@_);
}

method error_route
{
    $special{server_error}
}

method clear_routes
{
    $router  = Router::Simple->new;
    %special = ( );
}

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

The name of the controller that will respond to this match, returned in
the match hash reference with the key C<controller>. If the controller
name starts with C<:>, then C<Controller:> will be automatically
prepended.

This may be left blank only if the next column is also blank, which will
be translated as C<undef> in the match hash.

=item B<Action>

Name of the method that should be called on the controller to this
match, returned in the match hash reference with the key C<action>.

This may be left blank, which will be translated as C<undef> in the
match hash.

=back

=head2 Example

    # Main Routes
    *       /               :Main         home
    GET     /about          :Main         about_page
    GET     /blog/{post}    Blog::Main    article

    # Form processing
    POST    /contact        :Form         contact

    # Special
    @       not_found       :Main         not_found_page
    @       server_error    :Error        error_page

=head1 METHODS

=head2 new

Constructs a new object. No arguments required.

=head2 read_file

    method read_file ($file)

Parses the routes file given as an argument and registers the routes.
This method can be called multiple times on the same instance to process
more than one file.

=head2 match

    method match ($env)

Performs a match on the passed Plack C<$env>, or URI, and returnes a
hash reference containing the controller-action pair as well as extra
data extracted from the URI match.

    { controller => '...', action => '...' }

If no match is made and a not found route is registered (via the
L<C<not_found>|/not_found> directive), its data is returned. If no match
is found and no special directive is present in the routes file, it
returns C<undef>.

Note that this does not call the controller. It's up to the user to do
that in order to perform the intended action.

=head2 error_route

    method error_route ()

Returns the controller-action pair registered with the
L<C<server_error>|/server_error> directive. If nothing was registered,
returns C<undef>.

=head2 clear_routes

    method clear_routes ()

Removes all registered routes.

=head1 SEE ALSO

L<Minima>, L<Minima::Controller>, L<Router::Simple>, L<Plack>,
L<perlclass>.

=head1 AUTHOR

Cesar Tessarin, <cesar@tessarin.com.br>.

Written in September 2024.
