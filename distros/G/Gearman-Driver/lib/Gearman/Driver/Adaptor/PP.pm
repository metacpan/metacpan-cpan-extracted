package Gearman::Driver::Adaptor::PP;

use Moose;
use Gearman::Worker;

has 'worker' => (
    builder => '_build_worker',
    is      => 'ro',
    isa     => 'Gearman::Worker',
);

sub _build_worker {
    return Gearman::Worker->new;
}

sub add_servers {
    my ( $self, $server ) = @_;
    my @server = split /,/, $server;
    $self->worker->job_servers(@server);
}

sub add_function {
    my ( $self, $name, $sub ) = @_;
    $self->worker->register_function( $name => $sub );
}

sub work {
    my ($self) = @_;
    while (1) {
        $self->worker->work;
    }
}

*Gearman::Job::workload = sub {
    return shift->arg;
};

*Gearman::Job::function_name = sub {
    return shift->{func};
};

1;
