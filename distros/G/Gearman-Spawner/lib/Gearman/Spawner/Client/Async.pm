=head1 NAME

Gearman::Spawner::Client::Async - asynchronous Danga::Socket client for Gearman::Spawner::Worker workers

=head1 SYNOPSIS

    $client = Gearman::Spawner::Client::Async->new(
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

package Gearman::Spawner::Client::Async;

use strict;
use warnings;

use Gearman::Client::Async;
use base 'Gearman::Client::Async';

use Carp qw( croak );
use Gearman::Spawner::Util;
use Storable qw( nfreeze thaw );

=head1 METHODS

=over 4

=item Gearman::Spawner::Client::Async->new(%options)

Creates a new client object. Options:

=over 4

=item job_servers

(Required) Arrayref of servers to connect to.

=back

=cut

sub new {
    my $ref = shift;
    my $class = ref $ref || $ref;

    my Gearman::Spawner::Client::Async $self = fields::new($class)->SUPER::new(@_);
    return $self;
}

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
    my Gearman::Spawner::Client::Async $self = shift;
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

    my %options;

    $options{timeout} = $timeout if defined $timeout;
    $options{uniq}    = $unique  if defined $unique;

    $options{on_complete} = sub {
        my $ref_to_frozen_retval = shift;

        unless (defined $ref_to_frozen_retval) {
            return $error_cb->('no serialized return value from worker');
        }

        if (!ref $ref_to_frozen_retval || ref $ref_to_frozen_retval ne 'SCALAR') {
            return $error_cb->('unexpected value type');
        }

        my $rets = eval { thaw($$ref_to_frozen_retval) };
        if ($@) {
            return $error_cb->("deserialization error: $@");
        }
        elsif (ref $rets ne 'ARRAY') {
            return $error_cb->("gearman function did not return an array");
        }

        $success_cb->(@$rets);
    };

    $options{on_fail} = sub {
        my $reason = shift;
        $error_cb->($reason);
    };

    $self->add_task(Gearman::Task->new($function, \$serialized, \%options));
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

    my %options;
    $options{uniq} = $unique if defined $unique;

    my $function = Gearman::Spawner::Util::method2function($class, $method);

    my $serialized = nfreeze([$data]);

    # XXX dispatch_background does not exist in Gearman::Client::Async
    croak "dispatch_background is not supported by Async client";
    $self->dispatch_background($function => \$serialized, \%options);

    return;
}

1;
