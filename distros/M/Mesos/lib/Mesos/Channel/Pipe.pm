package Mesos::Channel::Pipe;
use Moo;
use Mesos;
use Mesos::Utils qw(import_methods);
import_methods('Mesos::XS::PipeChannel');
with 'Mesos::Role::Channel';

=head1 NAME

Mesos::Channel::Pipe

=head1 DESCRIPTION

The channel implementation for AnyEvent event handling.

=head1 METHODS

=head2 fd

    Returns the underlying read file descriptor. Mainly used for passing to AnyEvent watchers or IO::Select.

=cut

sub xs_init {
    my ($self) = @_;
    $self->_xs_init;
}

1;
