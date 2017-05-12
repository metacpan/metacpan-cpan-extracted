=head1 NAME

Gearman::WorkerSpawner::BaseWorker - Base class to simplify the process of
creating a Gearman worker for use with Gearman::WorkerSpawner

=head1 SYNOPSIS

    # create manager as normal. the contents of 'config' can be arbitrary; the
    # special 'max_jobs' option instructs the worker to exit cleanly after
    # performing that many jobs.

    my $worker_manager = Gearman::WorkerSpawner->new;
    $worker_manager->add_worker(
        class  => 'AdditionWorker',
        config => {
            left_hand => 5,
            max_jobs  => 100,
        },
    );

    # invoke run_method instead of add_task for workers derived from
    # BaseWorker. serialization of options is handled for you, and if you only care
    # about the success case you can provide only that callback

    $worker_manager->run_method(adder => { right_hand => 3 }, sub {
        my $return = shift;
        print $return->{sum};
    });

    Danga::Socket->EventLoop;

    # in the worker:

    package MethodWorker;
    use base 'Gearman::WorkerSpawner::BaseWorker';

    # Gearman::WorkerSpawner will instantiate your class; the object will
    # contain populated 'config' and 'slot' fields
    sub new {
        my MethodWorker $self = shift;
        $self = fields::new($self) unless ref $self;
        $self->SUPER::new(@_);

        print "I am worker $self->{slot}\n";
        $self->register_method(adder => \&add);
        return $self;
    }

    sub add {
        my MethodWorker $self = shift;
        my $args = shift;
        return { sum => $self->{config}{left_hand} + $args->{right_hand} };
    }

=cut

package Gearman::WorkerSpawner::BaseWorker;

use strict;
use warnings;

use base 'Gearman::Worker';

use fields (
    'config',
    'slot',
    'max_jobs',
    'jobs_done',
    'method_suffix',
);

use Storable qw(nfreeze thaw);

sub new {
    my Gearman::WorkerSpawner::BaseWorker $self = shift;
    my ($slot, $config, $gearmands, $max_jobs) = @_;

    $self = fields::new($self) unless ref $self;
    $self->SUPER::new(job_servers => $gearmands);

    $self->{slot}           = $slot;
    $self->{config}         = $config;
    $self->{max_jobs}       = $config->{max_jobs} || undef;
    $self->{jobs_done}      = 0;
    $self->{method_suffix}  = '_m';

    return $self;
}

=head1 METHODS

=item register_method($function_name)

=item register_method($function_name, $method)

=item register_method($function_name, $method, $timeout)

Registers a method to be called via Gearman::WorkerSpawner->run_method. A
Gearman function named $function_name will be registered with the server. When
a client calls that function, the method named $method (may alternatively be a
coderef) will be called with the Gearman::WorkerSpawner::BaseWorker object as
the first argument. $method defaults to be the same as $function_name if not
provided.

If $timeout is provided, the Gearman server may attempt to retry the function
if the job is not finished withint $timeout seconds.

The parameters to $method and return value (which should be a scalar) from it
are marshalled by Storable.

=cut

sub register_method {
    my Gearman::WorkerSpawner::BaseWorker $self = shift;
    my $name    = shift;
    my $method  = shift || $name;
    my $timeout = shift;

    $name .= $self->{method_suffix};

    my @timeout;
    @timeout = ($timeout) if defined $timeout;

    $self->register_function($name, @timeout, sub {
        $self->{jobs_done}++;

        my $job = shift;
        my $arg = $job->arg;

        # deserialize argument
        my $params = thaw($job->arg);

        my @retvals = $self->$method(@$params);

        # serialize return value(s)
        return \nfreeze(\@retvals);
    });
}

=item method_suffix([$suffix])

Accessor for the suffix which is appended to the method name. Defaults to '_m'.

=cut

sub method_suffix {
    my Gearman::WorkerSpawner::BaseWorker $self = shift;
    $self->{method_suffix} = shift if @_;;
    return $self->{method_suffix};
}

sub post_work {
    my Gearman::WorkerSpawner::BaseWorker $self = shift;
    return unless $self->{max_jobs};
    exit 0 if $self->{jobs_done} >= $self->{max_jobs};
}

1;
