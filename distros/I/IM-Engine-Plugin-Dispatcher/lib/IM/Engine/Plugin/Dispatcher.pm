package IM::Engine::Plugin::Dispatcher;
use 5.008001;
use Moose;
use Moose::Util::TypeConstraints;
extends 'IM::Engine::Plugin';

our $VERSION = '0.02';

subtype 'IM::Engine::Plugin::Dispatcher::Dispatcher'
     => as 'Path::Dispatcher';

coerce 'IM::Engine::Plugin::Dispatcher::Dispatcher'
    => from 'Str'
    => via {
        my $class = $_;
        Class::MOP::load_class($class);

        if ($class->isa('Path::Dispatcher::Declarative')) {
            return $class->dispatcher;
        }
        return $class->new;
    };

has dispatcher => (
    is       => 'ro',
    isa      => 'IM::Engine::Plugin::Dispatcher::Dispatcher',
    coerce   => 1,
    required => 1,
);

sub BUILD {
    my $self = shift;
    if ($self->engine->interface->has_incoming_callback) {
        confess "When using " . __PACKAGE__ . ", do not specify an incoming_callback";
    }

    $self->engine->interface->incoming_callback(
        sub { $self->incoming(@_) },
    );
}

sub post_initialization {
    my $self = shift;
    $self->engine->each_plugin(
        role       => 'Dispatcher::AugmentsDispatcher',
        callback   => sub { shift->augment_dispatcher($self->dispatcher) },
    );
}

sub incoming {
    my $self     = shift;
    my $incoming = shift;

    my $message = $self->dispatch($incoming, @_);
    return $message if blessed $message;

    return if !defined($message);

    return $incoming->reply(
        message => $message,
    );
}

sub dispatch {
    my $self       = shift;
    my $incoming   = shift;
    my $dispatcher = $self->dispatcher;

    my $dispatch = $dispatcher->dispatch($incoming->plaintext);

    $self->engine->plugin_relay(
        role              => 'Dispatcher::ChangesDispatch',
        method            => 'change_dispatch',
        baton             => $dispatch,
        incoming          => $incoming,
        original_dispatch => $dispatch,
    );

    my $message = $self->engine->plugin_default(
        role     => 'Dispatcher::ShortcutsDispatch',
        method   => 'shortcut_dispatch',
        incoming => $incoming,
        dispatch => $dispatch,
    );

    return $message if $message;

    return $dispatch->run($incoming, @_);
}

__PACKAGE__->meta->make_immutable;
no Moose;
no Moose::Util::TypeConstraints;

1;

__END__

=encoding utf8

=head1 NAME

IM::Engine::Plugin::Dispatcher - Path::Dispatcher ♥  IM::Engine

=head1 SYNOPSIS

    package TimeBot;
    use Path::Dispatcher::Declarative -base;

    on qr/date|time/ => sub { localtime };

    IM::Engine->new(
        interface => {
            protocol => 'REPL',
        },
        plugins => {
            Dispatcher => {
                dispatcher => 'TimeBot',
            },
        },
    )->run;

=head1 DESCRIPTION

L<Path::Dispatcher> is a pretty good way of running some code based on some
string input. My personal use case for L<Path::Dispatcher> was for IM or IRC
bots, so this is me eating my own dog food.

This module is meant to be extended to improve L<Path::Dispatcher> +
L<IM::Engine> goodness. For example, the L<IM::Engine::Plugin::Dispatcher::404>
plugin extends your dispatcher with a 404 (command not found) error.

It is currently alpha quality with serious features missing and is rife with
horrible bugs. I'm releasing it under the "release early, release often"
doctrine. Backwards compatibility may be broken in subsequent releases. Or by
L<IM::Engine> releases!

=head1 AUTHOR

Shawn M Moore, C<sartak@gmail.com>

=head1 SEE ALSO

=over 4

=item L<IM::Engine>

=item L<Path::Dispatcher>

=back

=head1 COPYRIGHT AND LICENSE

Copyright 2009 Shawn M Moore.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

