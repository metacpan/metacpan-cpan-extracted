package Gearman::Driver::Adaptor::XS;

use Moose;
use Gearman::XS::Worker;
use Gearman::XS qw(:constants);

has 'worker' => (
    builder => '_build_worker',
    is      => 'ro',
    isa     => 'Gearman::XS::Worker',
);

sub _build_worker {
    return Gearman::XS::Worker->new;
}

sub add_function {
    my ( $self, $name, $sub ) = @_;
    my $ret = $self->worker->add_function( $name, 0, $sub, '' );
    if ( $ret != GEARMAN_SUCCESS ) {
        die $self->gearman->error;
    }
}

sub work {
    my ($self) = @_;

    # Make sure that the current job is processed until the end before shutting
    # down.
    my $must_stop;
    local $SIG{TERM} = sub {
        $must_stop = 1;
    };

    $self->worker->add_options(GEARMAN_WORKER_NON_BLOCKING);

    while (!$must_stop) {
        my $ret = $self->worker->work;
        if (!$must_stop && ($ret == GEARMAN_IO_WAIT || $ret == GEARMAN_NO_JOBS )) {
            local $SIG{TERM} = 'DEFAULT';
            $self->worker->wait;
        }
        elsif ($ret != GEARMAN_SUCCESS ) {
            die $self->worker->error;
        }
    }
}

sub add_servers {
    my $self = shift;
    return $self->worker->add_servers(@_);
}

1;
