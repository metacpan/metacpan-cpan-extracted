package IM::Engine::Plugin::Dispatcher::404;
use Moose;
extends 'IM::Engine::Plugin';
with 'IM::Engine::Plugin::Dispatcher::ShortcutsDispatch';

has message => (
    is      => 'rw',
    isa     => 'Str',
    default => 'Unknown command.',
);

sub shortcut_dispatch {
    my $self = shift;
    my $args = shift;

    return if $args->{dispatch}->has_matches;

    return $self->message;
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__

=head1 NAME

IM::Engine::Plugin::Dispatcher::404

=head1 DESCRIPTION

This plugin simply extends your dispatcher with a 404 (command not found)
error.

=cut

