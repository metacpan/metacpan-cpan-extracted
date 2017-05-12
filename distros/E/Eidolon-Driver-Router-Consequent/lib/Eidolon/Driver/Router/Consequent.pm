package Eidolon::Driver::Router::Consequent;
# ==============================================================================
#
#   Eidolon
#   Copyright (c) 2009, Atma 7
#   ---
#   Eidolon/Driver/Router/Consequent.pm - consequent regexp router
#
# ==============================================================================

use base qw/Eidolon::Driver::Router/;
use List::Util qw/first/;
use warnings;
use strict;

our $VERSION  = "0.01"; # 2009-04-06 05:10:02

# ------------------------------------------------------------------------------
# find_handler()
# find query handler
# ------------------------------------------------------------------------------
sub find_handler
{
    my ($self, $r, $query, @params, $route, $ctrl, $handler);

    $self  = shift;
    $r     = Eidolon::Core::Registry->get_instance;
    $query = $r->cgi->get_query || "/";
    $route = undef;

    throw DriverError::Router::NoRoutes if (!exists $r->config->{"routes"});

    # find matching route
    $route = first { @params = $query =~ /^$_$/ } keys %{ $r->config->{"routes"} };

    # do neccessary checks
    throw DriverError::Router::NotFound($query) if (!$route);
    throw DriverError::Router::Forbidden if 
    (
        $r->loader->get_object("Eidolon::Driver::User")             && 
       !$r->loader->get_object("Eidolon::Driver::User")->authorized && 

        (
            $r->config->{"app"}->{"policy"} eq "private"          &&
           !defined($r->config->{"routes"}->{ $route }->[2])      ||
            defined($r->config->{"routes"}->{ $route }->[2])      &&
            $r->config->{"routes"}->{ $route }->[2] eq "private"
        )
    );

    $ctrl    = $r->config->{"routes"}->{ $route }->[0];
    $handler = $r->config->{"routes"}->{ $route }->[1] || "default";

    # try to load the controller
    {
        local $SIG{"__DIE__"} = sub {};
        eval "require $ctrl";
    }

    throw CoreError::Compile($@) if $@;

    $self->{"controller"} = $ctrl;
    $self->{"handler"}    = "$ctrl\::$handler";

    # delete undefined parameters
    foreach (0 .. $#params)
    {
        delete $params[$_] unless (defined $params[$_]);
    }

    $self->{"params"} = \@params;
}

1;

__END__

=head1 NAME

Eidolon::Driver::Router::Consequent - consequent request router for Eidolon.

=head1 SYNOPSIS

Somewhere in application controllers:

    my $r = Eidolon::Core::Registry->get_instance;
    my $router = $r->loader->get_object("Eidolon::Driver::Router::Consequent");

    print "Controller: " . $router->{"controller"}              . "\n";
    print "Handler: "    . $router->{"handler"}                 . "\n";
    print "Parameters: " . join(", ", @{ $router->{"params"} }) . "\n";

=head1 DESCRIPTION

The I<Eidolon::Driver::Router::Consequent> driver finds handler for each user request. 
Routing is based on application L</Routing table> in application configuration.

=head2 Routing flow

Each row of I<routing table> is sequentally checked if it matches a GET-request
string. The router keeps checking rows one by one till the matching one is
found, otherwise 
L<Eidolon::Driver::Router::Exceptions/DriverError::Router::NotFound> exception
is thrown. If a regular expression in the routing table contains elements 
enclosed in round braces I<()>, these elements assumed to be handler parameters.

After handler was found, router checks its security policy. If application
was defined as a I<private> in configuration (see L<Eidolon::Core::Config> for 
more information) and a routing rule isn't marked as I<public>  - 
L<Eidolon::Driver::Router::Exceptions/DriverError::Router::Forbidden>
exception is thrown. Also, this exception is thrown if a handler has got 
a I<private> mark, without application configuration dependencies.

=head2 Routing table

The routing table must be defined in application configuration 
(L<Eidolon::Core::Config>) hash using C<{"routes"}> key. For example, this could be
in your application's C<lib/Example/Config.pm> file:

    package Example;

    use base Eidolon::Core::Config;
    use warnings;
    use strict;

    our $VERSION  = "0.01";

    sub new
    {
        my ($class, $name, $type, $self);

        ($class, $name, $type) = @_;

        $self = $class->SUPER::new($name, $type);

        # ...

        # application routing table
        $self->{"routes"} =
        {
            "/"          => [ "Example::Controller::Default"                      ],
            "news"       => [ "Example::Controller::News"                         ],
            "news/(\d+)" => [ "Example::Controller::News",   "entry"              ],
            "admin"      => [ "Example::Controller::Admin",  "default", "private" ]
        };

        return $self;
    }

As you can see from example below, the routing table is a hash reference, and each 
key-value pair of it represents a single routing rule. 

=over 4

=item * Key 

Key is a usual regular expression without leading and trailing delimiters. C<"/">
key stands for the application root page. As was told before, if a key contains 
elements enclosed in round braces I<()>, these elements assumed to be handler 
parameters.

=item * Value

Value is an array reference. It has the following items:

=over 8

=item 1. Controller name

The full name of the controller's package. This item is mandatory.

=item 2. Handler function name

The name of the function in the controller's package. This item is optional. If
it is omitted, "default" function will be called.

=item 3. Security attribute

String, containing C<public> or C<private> value. If value is C<private>, the page
will require user authentication for view (in this case you must have user driver
loaded, see L<Eidolon::Driver::User> for more information). This array item is 
optional. If it's omitted, the routing rule assumed to be C<public>.

=back

=back

=head1 METHODS

=head2 new()

Inherited from L<Eidolon::Driver::Router/new()>.

=head2 find_handler()

Implementation of abstract method from L<Eidolon::Driver::Router/find_handler()>.

=head2 get_handler()

Inherited from L<Eidolon::Driver::Router/get_handler()>.

=head2 get_params()

Inherited from L<Eidolon::Driver::Router/get_params()>.

=head1 SEE ALSO

L<Eidolon>, L<Eidolon::Applicaton>, L<Eidolon::Driver::Router>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Anton Belousov, E<lt>abel@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (c) 2009, Atma 7, L<http://www.atma7.com>

=cut

