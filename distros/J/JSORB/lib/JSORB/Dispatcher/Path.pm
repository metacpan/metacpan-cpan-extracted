package JSORB::Dispatcher::Path;
use Moose;

use Try::Tiny;
use Path::Router;

our $VERSION   = '0.04';
our $AUTHORITY = 'cpan:STEVAN';

with 'MooseX::Traits';

has 'namespace' => (
    is       => 'ro',
    isa      => 'JSORB::Namespace',
    trigger  => sub {
        my $self = shift;
        $self->_clear_router if $self->_has_router;
        # the router will get
        # initialized the next
        # time it is needed
    }
);

has 'router' => (
    is        => 'ro',
    isa       => 'Path::Router',
    lazy      => 1,
    builder   => '_build_router',
    clearer   => '_clear_router',
    predicate => '_has_router',
);

sub handler {
    my ($self, $call, @args) = @_;
    (blessed $call && $call->isa('JSON::RPC::Common::Procedure::Call'))
        || confess "You must pass a JSON::RPC::Common::Procedure::Call to the handler, not $call";

    my $procedure = $self->get_procedure_from_call($call);

    return $self->throw_error(
        $call, "Could not find method " . $call->method . " in " . $self->namespace->name
    ) unless defined $procedure;

    try {
        $call->return_result(
            $self->call_procedure(
                $procedure,
                $call,
                @args
            )
        );
    } catch {
        $self->throw_error($call, $_);
    };
}

sub get_procedure_from_call {
    my ($self, $call) = @_;
    my $match = $self->router->match($call->method);
    return unless $match;
    return $match->target;
}

sub call_procedure {
    my ($self, $procedure, $call, @args) = @_;
    $procedure->call( $self->assemble_params_list( $call, @args ) );
}

sub assemble_params_list {
    my ($self, $call, @args) = @_;
    return $call->params_list;
}

sub throw_error {
    my ($self, $call, $message) = @_;
    return $call->return_error(
        message => $message,
        code    => 1,
    );
}

# ........

sub _build_router {
    my $self = shift;
    my $router = Path::Router->new;
    $self->_process_elements(
        $router,
        '/',
        $self->namespace
    );
    $router;
}

sub _process_elements {
    my ($self, $router, $base_url, $namespace) = @_;

    $base_url .= lc($namespace->name) . '/';

    foreach my $element (@{ $namespace->elements }) {
        $self->_process_interface($router, $base_url, $element)
            if $element->isa('JSORB::Interface');
        $self->_process_elements($router, $base_url, $element);
    }
}

sub _process_interface {
    my ($self, $router, $base_url, $interface) = @_;

    $base_url .= lc($interface->name) . '/';

    # NOTE:
    # perhaps I want to actually do:
    #  $router->add_route(
    #      ($base_url . ':method'),
    #      target => $interface,
    #  );
    # instead so that the method becomes
    # a param and then the interface
    # itself is the target ... which
    # means I can then hand off the
    # rest of the dispatching to the
    # interface .. hmmm

    foreach my $procedure (@{ $interface->procedures }) {
        $router->add_route(
            ($base_url . lc($procedure->name)),
            target => $procedure
        );
    }
}

__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__

=pod

=head1 NAME

JSORB::Dispatcher::Path - Simple path based dispatcher

=head1 DESCRIPTION

This module will dispatch RPC methods/procedures that are in a
path-like format, such as:

  { method : 'math/simple/add', params : [ 2, 2 ] }

This will look for the C<add> procedure in the C<Math::Simple>
namespace.

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 AUTHOR

Stevan Little E<lt>stevan.little@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2008-2010 Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
