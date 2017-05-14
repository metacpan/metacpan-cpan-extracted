package Mesos::Channel::Interrupt;
use Moo;
use Mesos;
use Mesos::Utils qw(import_methods);
use Mesos::Types qw(AsyncInterrupt);
use Types::Standard qw(CodeRef);
use Async::Interrupt;
import_methods('Mesos::XS::InterruptChannel');
with 'Mesos::Role::Channel';

=head1 NAME

Mesos::Channel::Interrupt

=head1 DESCRIPTION

The channel implementation for Async::Interrupt event handling.

=head1 METHODS

=head2 new(callback => $coderef)

    my $channel = Mesos::Channel::Interrupt->new(
        callback => $coderef, # required - perl callback for Async::Interrupt events
    );

=cut

has interrupt => (
    is       => 'ro',
    isa      => AsyncInterrupt,
    lazy     => 1,
    required => 1,
    builder  => '_build_interrupt',
);

has callback => (
    is       => 'ro',
    isa      => CodeRef,
    required => 1,
);

sub _build_interrupt {
    my ($self) = @_;
    return Async::Interrupt->new(cb => $self->callback);
}

sub xs_init {
    my ($self) = @_;
    $self->_xs_init($self->interrupt->signal_func);
}

1;
