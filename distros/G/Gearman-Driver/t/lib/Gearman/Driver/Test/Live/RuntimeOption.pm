package    # hide from PAUSE
  Gearman::Driver::Test::Live::RuntimeOption;

use base qw(Gearman::Driver::Test::Base::All);
use Moose;

has 'foo' => (
    isa => 'Str',
    is  => 'rw',
    default => 'foo' 
);

has 'global_foo' => (
    isa => 'Str',
    is  => 'rw',
    default => 'foo' 
);

sub job1 : Job {
    my ( $self, $job, $workload ) = @_;
    return $self->foo;
}

sub job2 : Job {
    my ( $self, $job, $workload ) = @_;
    return $self->global_foo;
}

1;
