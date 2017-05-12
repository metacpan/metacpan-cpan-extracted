package TestWorker;

use base 'Gearman::Worker';

sub new {
    my TestWorker $self = shift;
    my ($slot, $config, $gearmands) = @_;
    $self = fields::new($self) unless ref $self;
    $self->SUPER::new(job_servers => $gearmands);
    $self->register_function(testfunc => \&testfunc);
    return $self;
}

sub testfunc {
    my $job = shift;
    my $arg = $job->arg;

    return $arg + 5;
}

1;
