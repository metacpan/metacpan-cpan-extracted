=head1 NAME

Gearman::Spawner::Client::AnyEvent - asynchronous AnyEvent client for Gearman::Spawner::Worker workers

=head1 SYNOPSIS

    $client = Gearman::Spawner::Client::AnyEvent->new(
        job_servers => ['localhost:4730']
    );

    $client->run_method(
        class  => 'MyWorker',
        method => 'sing',
        arg    => [qw( do re mi )],
        success_cb => sub {
            my $result = shift;
            say "success! result is $result";
        },
        error_cb => sub {
            my $reason = shift;
            say "failed because $reason";
        },
        timeout => 3,
    });

=cut

package Gearman::Spawner::Client::AnyEvent;

use strict;
use warnings;

use Any::Moose;

extends 'AnyEvent::Gearman::Client';

has cancel_timers => (
    is => 'rw',
    isa => 'HashRef',
);

no Any::Moose;

use AnyEvent;
use Gearman::Spawner::Util;

use Carp qw( croak );
use Storable qw( nfreeze thaw );

=head1 METHODS

=over 4

=item Gearman::Spawner::Client::AnyEvent->new(%options)

Creates a new client object. Options:

=over 4

=item job_servers

(Required) Arrayref of servers to connect to.

=back

=item $client->run_method(%options)

Dispatches a foreground job to a worker. Options:

=over 4

=item class

(Required) The name of the worker class.

=item method

(Required) The name of the method in I<class> to call.

=item success_cb

(Required) The coderef to be called when the job completes successfully. The
first argument to it will be the deserialized result returned by the worker
method.

=item error_cb

(Required) The coderef to be called if the job does not complete. This may
occur for several reasons, including but not limited to: the worker code threw
an exception; the server did not respond before the timeout period; or the
number of job retries was exceeded.

The first argument passed to I<error_cb> is a string providing the best
available information about the error.

=item data

(Optional) The job-specific data to pass to the worker. Any structure that can
be serialized with Storable is allowed. If omitted, undef is sent.

=item timeout

(Optional) If the job has not completed or failed within this amount of time,
I<error_cb> will be called. Even if the job subsequently completes,
I<success_cb> will not be called.

=item unique

(Optional) The opaque unique tag for coalescing jobs.

=back

=cut

sub run_method {
    my $self = shift;
    my %params = @_;

    my $class       = delete $params{class}         || croak "need class";
    my $method      = delete $params{method}        || croak "need method";
    my $success_cb  = delete $params{success_cb}    || croak "need success_cb";
    my $error_cb    = delete $params{error_cb}      || croak "need error_cb";
    my $data        = delete $params{data}          || undef;
    my $timeout     = delete $params{timeout}       || undef;
    my $unique      = delete $params{unique}        || undef;

    croak "unknown parameters to run_method: @{[%params]}" if %params;

    my $function = Gearman::Spawner::Util::method2function($class, $method);

    my $serialized = nfreeze([$data]);

    my $timer;
    my $cancel_timeout;
    if (defined $timeout) {
        $cancel_timeout = sub {
            delete $self->{cancel_timers}{"$timer"};
            undef $timer;
        };
        $timer = AE::timer($timeout, 0, sub {
            $cancel_timeout->();
            $error_cb->("timeout");
        });
        $self->{cancel_timers}{"$timer"} = $timer;
    }

    my %options;

    $options{unique} = $unique if defined $unique;

    $options{on_complete} = sub {
        return if defined $timeout && !$timer; # timeout already fired
        $cancel_timeout->() if $cancel_timeout;

        my ($task, $frozen_retval) = @_;

        unless (defined $frozen_retval) {
            return $error_cb->('no serialized return value from worker');
        }

        my $rets = eval { thaw($frozen_retval) };
        if ($@) {
            return $error_cb->("deserialization error: $@");
        }
        elsif (ref $rets ne 'ARRAY') {
            return $error_cb->("gearman function did not return an array");
        }

        $success_cb->(@$rets);
    };

    $options{on_fail} = sub {
        return if defined $timeout && !$timer; # timeout already fired
        my ($task, $reason) = @_;
        $cancel_timeout->() if $cancel_timeout;
        $error_cb->($reason);
    };

    $self->add_task($function, $serialized, %options);
}

=item run_method_background

Dispatches a background job to a worker.

Options:

=over 4

=item class

(Required) The name of the worker class.

=item method

(Required) The name of the method in I<class> to call.

=item data

(Optional) The job-specific data to pass to the worker. Any structure that can
be serialized with Storable is allowed. If omitted, undef is sent.

=item unique

(Optional) The opaque unique tag for coalescing jobs.

=back

=cut

sub run_method_background {
    my $self = shift;
    my %params = @_;

    my $class       = delete $params{class}         || croak "need class";
    my $method      = delete $params{method}        || croak "need method";
    my $data        = delete $params{data}          || undef;
    my $unique      = delete $params{unique}        || undef;

    croak "unknown parameters to run_method_background: @{[%params]}" if %params;

    my $function = Gearman::Spawner::Util::method2function($class, $method);

    my $serialized = nfreeze([$data]);

    my %options;

    $options{unique} = $unique if defined $unique;

    $self->add_task_bg($function => $serialized, %options);

    return;
}

=back

=cut

1;
