package Mesos::Test::Scheduler;
use Moose::Meta::Class;

sub new {
    my ($test, %methods) = @_;

    while (my ($name, $code) = each %methods) {
        $methods{$name} = sub {
            my ($self, $driver, @args) = @_;
            $self->add_event([$name, @args]);
            return $code->(@_);
        }
    }

    $methods{add_event}  = sub { push @{$_[0]->events}, $_[1] };
    $methods{last_event} = sub { shift->events->[-1] };

    my $class = Moose::Meta::Class->create_anon_class(
        superclasses => [qw(Mesos::Scheduler)],
        attributes   => [
            Moose::Meta::Attribute->new('events',
                is      => 'ro',
                default => sub { [] },
            ),
        ],
        methods => \%methods,
    );

    return $class->new_object;
}

1;
