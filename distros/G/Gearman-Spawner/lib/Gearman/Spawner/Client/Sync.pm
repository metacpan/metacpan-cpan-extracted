=head1 NAME

Gearman::Spawner::Client::Sync - synchronous client for Gearman::Spawner::Worker workers

=head1 SYNOPSIS

    $client = Gearman::Spawner::Client::Sync->new(
        job_servers => ['localhost:4730']
    );

    eval {
        my $result = $client->run_method(
            class  => 'MyWorker',
            method => 'sing',
            arg    => [qw( do re mi )],
        );
        say "success! result is $result";
    };
    if ($@) {
        say "failed because $@";
    }

=cut

package Gearman::Spawner::Client::Sync;

use strict;
use warnings;

use Gearman::Client;
use base 'Gearman::Client';

use Carp qw( croak );
use Gearman::Spawner::Util;
use Storable qw( nfreeze thaw );

=head1 METHODS

=over 4

=item Gearman::Spawner::Client::Sync->new(%options)

Creates a new client object. Options:

=over 4

=item job_servers

(Required) Arrayref of servers to connect to.

=back

=cut

sub new {
    my $ref = shift;
    my $class = ref $ref || $ref;

    my Gearman::Spawner::Client::Sync $self = fields::new($class)->SUPER::new(@_);

    return $self;
}

=item $client->run_method(%options)

Dispatches a foreground job to a worker.

Returns the deserialized result. If an error occurs, an exception is thrown.

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

sub run_method {
    my Gearman::Spawner::Client::Sync $self = shift;
    my %params = @_;

    my $class       = delete $params{class}         || croak "need class";
    my $method      = delete $params{method}        || croak "need method";
    my $data        = delete $params{data}          || undef;
    my $unique      = delete $params{unique}        || undef;

    croak "unknown parameters to run_method: @{[%params]}" if %params;

    my %options;
    $options{uniq} = $unique if defined $unique;

    my $function = Gearman::Spawner::Util::method2function($class, $method);

    my $serialized = nfreeze([$data]);

    my $ref_to_frozen_retval = $self->do_task($function => $serialized, \%options);

    unless (defined $ref_to_frozen_retval) {
        die 'no return value from worker';
    }

    if (!ref $ref_to_frozen_retval || ref $ref_to_frozen_retval ne 'SCALAR') {
        die 'unexpected value type';
    }

    my $rets = eval { thaw($$ref_to_frozen_retval) };
    if ($@) {
        die "deserialization error: $@";
    }
    elsif (ref $rets ne 'ARRAY') {
        die "gearman function did not return an array";
    }

    return wantarray ? @$rets : $rets->[0];
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
    my Gearman::Spawner::Client::Sync $self = shift;
    my %params = @_;

    my $class       = delete $params{class}         || croak "need class";
    my $method      = delete $params{method}        || croak "need method";
    my $data        = delete $params{data}          || undef;
    my $unique      = delete $params{unique}        || undef;

    croak "unknown parameters to run_method: @{[%params]}" if %params;

    my $function = Gearman::Spawner::Util::method2function($class, $method);

    my $serialized = nfreeze([$data]);

    my %options;
    $options{uniq} = $unique if defined $unique;

    $self->dispatch_background($function => $serialized, \%options);

    return;
}

1;
