package Eidolon::Driver::Router;
# ==============================================================================
#
#   Eidolon
#   Copyright (c) 2009, Atma 7
#   ---
#   Eidolon/Driver/Router.pm - router generic driver
#
# ==============================================================================

use base qw/Eidolon::Driver/;
use Eidolon::Driver::Router::Exceptions;
use warnings;
use strict;

our $VERSION  = "0.02"; # 2009-05-14 05:25:08

# ------------------------------------------------------------------------------
# \% new()
# constructor
# ------------------------------------------------------------------------------
sub new
{
    my ($class, $self);

    $class = shift;
    $self  = 
    {
        "controller" => undef,  # relative path to controller
        "handler"    => undef,  # handler reference
        "params"     => undef   # handler params
    };

    bless $self, $class;

    return $self;
}

# ------------------------------------------------------------------------------
# find_handler()
# find a query handler
# ------------------------------------------------------------------------------
sub find_handler
{
    throw CoreError::AbstractMethod;
}

# ------------------------------------------------------------------------------
# get_handler()
# get handler reference
# ------------------------------------------------------------------------------
sub get_handler
{
    return $_[0]->{"handler"};
}

# ------------------------------------------------------------------------------
# get_params()
# get handler params
# ------------------------------------------------------------------------------
sub get_params
{
    return $_[0]->{"params"};
}

1;

__END__

=head1 NAME

Eidolon::Driver::Router - Eidolon generic router driver.

=head1 SYNOPSIS

Example router driver:

    package MyApp::Driver::Router;
    use base qw/Eidolon::Driver::Router/;

    sub find_handler
    {
        my $self = shift;

        # ...

        throw DriverError::Router::NotFound unless $handler_found;
        
        $self->{"handler"} = ...;
        $self->{"params"}  = ...;
    }

=head1 DESCRIPTION

The I<Eidolon::Driver::Router> is a generic router driver for I<Eidolon>.
It declares some basic functions that are common for all driver types and one 
abstract method, that I<must> be overloaded in ancestor classes. All router 
drivers should subclass this package.

=head1 METHODS

=head2 new()

Class constructor. 

=head2 find_handler()

Finds a query handler. Abstract method, should be overloaded by the ancestor class.

=head2 get_handler()

Returns a reference to the query handler subroutine.

=head2 get_params()

Returns a reference to the array of query handler parameters.

=head1 ATTRIBUTES

The I<Eidolon::Driver::Router> package has got several useful class 
attributes that filled in during request routing. These variables could 
be accessed through router object using hashref syntax:

    my ($r, $router, $params);

    $r      = Eidolon::Core::Registry->get_instance;
    $router = $r->loader->get_object("Eidolon::Driver::Router");
    $params = $router->{"params"};

=head2 controller

Contoller class name, that was selected for request handling.

=head2 handler

Handler code reference in selected controller.

=head2 params

Reference to array of handler parameters. Actually, these parameters will be 
passed to a request handler function, but they could be accessed this way too.

=head1 SEE ALSO

L<Eidolon>, L<Eidolon::Application>, L<Eidolon::Driver::Router::Exceptions>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Anton Belousov, E<lt>abel@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (c) 2009, Atma 7, L<http://www.atma7.com>

=cut

