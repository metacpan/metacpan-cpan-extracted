package Mesos::ExecutorDriver;
use Mesos::XS;
use Mesos::Types qw(:all);
use Type::Params qw(validate);
use Types::Standard qw(Str);
use Moo;
use namespace::autoclean;
with 'Mesos::Role::HasDispatcher';

=head1 NAME

Mesos::ExecutorDriver - perl interface to MesosExecutorDriver

=head1 ATTRIBUTES

=head2 autoflush

Enable or disable autoflush for STDOUT. By default autoflush is enabled while the driver is running, and returned to its previous state when the driver has stopped. This is to ensure that STDOUT gets logged in Mesos. Otherwise, perl defaults to using block buffering on STDOUT, and there are no guarantees it will be flushed before the driver shuts down.

=head2 dispatcher

Either a Mesos::Dispatcher instance, or the short name of a dispatcher to instantiate(such as AnyEvent). The short name cannot be used if the dispatcher has required arguments.

Defaults to AnyEvent

=head2 executor

A Mesos::Executor instance

=cut

has autoflush => (
    is      => 'ro',
    default => 1,
);

has executor => (
    is       => 'ro',
    isa      => Executor,
    required => 1,
);
sub event_handler { shift->executor }

around sendStatusUpdate => sub {
    my ($orig, $self, @args) = @_;
    return $self->$orig(validate \@args, TaskStatus);
};

around sendFrameworkMessage => sub {
    my ($orig, $self, @args) = @_;
    return $self->$orig(validate \@args, Str);
};

after start => sub {
    my ($self) = @_;
    $|++ if $self->autoflush;
};

before stop => sub {
    my ($self) = @_;
    $|-- if $self->autoflush;
};

sub BUILD {
    my ($self) = @_;
    $self->_xs_init($self->dispatcher);
}

=head1 METHODS

=over 4

=item new(%args)

    my $driver = Mesos::ExecutorDriver->new(%args);

        %args
            REQUIRED executor
            OPTIONAL dispatcher


=item new(executor => $executor)

=item Status start()

=item Status stop()

=item Status abort()

=item Status join()

=item Status run()

=item Status sendStatusUpdate($status)

=item Status sendFrameworkMessage($data)

=back

=cut


1;
