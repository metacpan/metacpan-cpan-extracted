package LargeWorker;

use base 'Gearman::Worker';

sub new {
    my ($class, $slot, $config, $gearmands) = @_;

    # use some memory
    my $x = '1' x 100000;

    # use some cpu
    my $done = 0;
    $SIG{ALRM} = sub { $done++ };
    alarm 1;
    1 until $done;

    my $self = fields::new($class);
    $self->SUPER::new(job_servers => $gearmands);
    return $self;
}

1;
