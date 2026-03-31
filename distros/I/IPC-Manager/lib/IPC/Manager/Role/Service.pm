package IPC::Manager::Role::Service;
use strict;
use warnings;

our $VERSION = '0.000009';

# Not included in role:
use Carp qw/croak/;
use POSIX qw/:sys_wait_h/;
use List::Util qw/any/;
use Time::HiRes qw/time sleep/;
use Test2::Util::UUID qw/gen_uuid/;

use IPC::Manager::Service::Handle();
use IPC::Manager::Service::Peer();

use Role::Tiny;

with 'IPC::Manager::Role::Service::Select';
with 'IPC::Manager::Role::Service::Requests';

# Included in role:
use IPC::Manager::Util qw/pid_is_running/;

requires qw{
    new
    orig_io
    name
    run
    ipcm_info
    pid
    set_pid
    watch_pids
    handle_request
};

sub cycle            { 0.2 }
sub interval         { 0.2 }
sub use_posix_exit   { 0 }
sub intercept_errors { 0 }

sub terminated    { $_[0]->{_TERMINATED} }
sub is_terminated { defined $_[0]->{_TERMINATED} ? 1 : 0 }
sub terminate     { $_[0]->{_TERMINATED} ||= pop if @_ > 1; $_[0]->{_TERMINATED} //= 0 }

sub peer_class   { 'IPC::Manager::Service::Peer' }
sub handle_class { 'IPC::Manager::Service::Handle' }

sub signals_to_grab { () }

sub redirect      { }
sub pre_fork_hook { }

sub run_on_all             { }
sub run_on_cleanup         { }
sub run_on_general_message { }
sub run_on_interval        { }
sub run_on_peer_delta      { }
sub run_on_sig             { }
sub run_on_start           { }
sub run_should_end         { }

sub run_on_unhandled {
    my $self = shift;
    my ($activity) = @_;

    my @unhandled = keys %$activity;
    return unless @unhandled;

    die "Failed to handle activity: " . join(", " => @unhandled);
}

#<<<    Do not tidy this
sub _run_on_all        { my ($self, @args) = @_; $self->try(sub { $self->run_on_all(@args)        }) }
sub _run_on_cleanup    { my ($self, @args) = @_; $self->try(sub { $self->run_on_cleanup(@args)    }) }
sub _run_on_interval   { my ($self, @args) = @_; $self->try(sub { $self->run_on_interval(@args)   }) }
sub _run_on_message    { my ($self, @args) = @_; $self->try(sub { $self->run_on_message(@args)    }) }
sub _run_on_peer_delta { my ($self, @args) = @_; $self->try(sub { $self->run_on_peer_delta(@args) }) }
sub _run_on_sig        { my ($self, @args) = @_; $self->try(sub { $self->run_on_sig(@args)        }) }
sub _run_on_start      { my ($self, @args) = @_; $self->try(sub { $self->run_on_start(@args)      }) }
sub _run_on_unhandled  { my ($self, @args) = @_; $self->try(sub { $self->run_on_unhandled(@args)  }) }
sub _run_should_end    { my ($self, @args) = @_; $self->try(sub { $self->run_should_end(@args)    }) }
#>>>

sub clear_service_fields {
    my $self = shift;

    $self->clear_serviceselect_fields;
    $self->clear_servicerequests_fields();

    delete $self->{_CLIENT};
    delete $self->{_LAST_INTERVAL};
    delete $self->{_ORIG_SIG};
    delete $self->{_PEER_CACHE};
    delete $self->{_PEER_STATE};
    delete $self->{_SIGS_SEEN};
    delete $self->{_TERMINATED};
    delete $self->{_WORKERS};
}

sub register_worker {
    my $self = shift;
    my ($name, $pid) = @_;

    $self->{_WORKERS}->{$pid} = $name;
}

sub workers {
    my $self = shift;
    return $self->{_WORKERS};
}

sub reap_workers {
    my $self = shift;

    my $workers = $self->{_WORKERS} or return;

    my %out;
    for my $pid (keys %$workers) {
        local $?;
        my $check = waitpid($pid, WNOHANG) or next;
        my $exit = $?;

        my $name = delete $workers->{$pid};

        if ($check == $pid) {
            $out{$pid} = {name => $name, exit => $exit};
        }
        elsif ($check < 0) {
            $out{$pid} = {name => $name, exit => $check};
        }
        else {
            die "Nonsensical return from waitpid";
        }
    }

    return \%out;
}

sub run_on_message {
    my $self = shift;
    my ($msg) = @_;

    my $c = $msg->content;

    if (ref($c) eq 'HASH') {
        return $self->run_on_request_message($msg)  if $c->{ipcm_request_id};
        return $self->run_on_response_message($msg) if $c->{ipcm_response_id};
    }

    return $self->run_on_general_message($msg);
}

sub run_on_response_message {
    my $self = shift;
    my ($msg) = @_;

    my $resp = $msg->content;
    $self->handle_response($resp, $msg);

    return;
}

sub send_response {
    my $self = shift;
    my ($peer, $id, $resp) = @_;

    $self->client->send_message(
        $peer,
        {
            ipcm_response_id => $id,
            response         => $resp,
        }
    );
}

sub run_on_request_message {
    my $self = shift;
    my ($msg) = @_;

    my $peer = $msg->from;

    my $req  = $msg->content;

    # return empty list to not send a response yet.
    # return one item (can be undef, 0, '', or any other value)
    my @resp = $self->handle_request($req, $msg);

    return unless @resp;
    croak "Incorrect number of responses to request" if @resp != 1;

    $self->send_response($peer, $req->{ipcm_request_id}, $resp[0]);

    return;
}

sub client {
    return $_[0]->{_CLIENT} if $_[0]->{_CLIENT};
    require IPC::Manager;
    return $_[0]->{_CLIENT} = IPC::Manager->connect($_[0]->name, $_[0]->ipcm_info);
}

sub in_correct_pid {
    my $self = shift;
    my $pid  = $self->pid;
    croak "Incorrect PID (did your fork leak? $$ vs $pid)" unless $$ == $pid;
}

sub kill {
    my $self = shift;
    my ($sig) = @_;
    croak "A signal is required" unless defined $sig;
    CORE::kill($sig, $self->pid);
}

sub debug {
    my $self = shift;

    my $io = $self->orig_io;
    my $fh = $io ? $io->{stderr} // $io->{stdout} // \*STDERR : \*STDERR;

    print $fh @_;
}

sub handle {
    my $self = shift;
    my (%params) = @_;

    croak "'name' is a required parameter" unless $params{name};

    return $self->handle_class->new(
        %params,
        service_name => $self->name,
        ipcm_info    => $self->ipcm_info,
    );
}

sub peer {
    my $self = shift;
    my ($name, %params) = @_;

    croak "peer() can only be called on the service in the service process"
        unless $self->pid == $$;

    return $self->{_PEER_CACHE}->{$name} //= $self->peer_class->new(
        %params,

        name      => $name,
        service   => $self,
        ipcm_info => $self->ipcm_info,
    );
}

sub try {
    my $self = shift;
    my ($cb) = @_;

    unless ($self->intercept_errors) {
        my $out = $cb->();
        return {ok => 1, err => '', out => $out};
    }

    my $err;
    {
        local $@;
        my $out;
        if (eval { $out = $cb->(); 1 }) {
            return {ok => 1, err => '', out => $out};
        }
        $err  = $@;
    }

    $self->debug("Peer '" . $self->name . "' caught exception: $err");
    warn $err;

    return {ok => 0, err => $err};
}

sub peer_delta {
    my $self = shift;
    my (%params) = @_;

    my $prev = $self->{_PEER_STATE};
    my $curr = {map {($_ => 1)} $self->client->peers};

    my $delta = { %$curr };
    if ($prev) {
        # Any that exist, and already existed will be set to 0
        # Any that used to exist, but do not now will be set to -1
        # Any that did not exist, but do now will be set to 1
        for my $peer (keys %$prev) {
            $delta->{$peer}--;
            delete $delta->{$peer} unless $delta->{$peer};
        }
    }

    $self->{_PEER_STATE} = $curr unless $params{peek};

    return $delta if keys %$delta;
    return undef;
}

sub select_handles {
    my $self = shift;
    my $client = $self->client;

    my @message_handles = $client->have_handles_for_select      ? $client->handles_for_select      : ();
    my @peer_handles    = $client->have_handles_for_peer_change ? $client->handles_for_peer_change : ();

    return (@message_handles, @peer_handles);
}

sub watch {
    my $self = shift;

    my $sig           = $self->{_SIGS_SEEN} // {};
    my $cycle         = $self->cycle;
    my $client        = $self->client;
    my $interval      = $self->interval;
    my $have_interval = defined $interval;

    my $last_interval = $self->{_LAST_INTERVAL} //= time;

    my $term = $self->terminated;

    while (1) {
        my @messages;
        my %activity;

        $self->reap_workers;

        my $select = $self->select;

        if ($select) {
            if ($select->can_read($cycle)) {
                @messages = $client->get_messages;
                $client->reset_handles_for_peer_change if $client->have_handles_for_peer_change;
            }
        }
        else {
            @messages = $client->get_messages;
        }

        my $term2 = $self->terminated;
        if (defined($term2) && !(defined($term) && $term == $term2)) {
            $activity{terminated} = {value => $term2};
        }

        $activity{messages} = \@messages if @messages;
        $activity{sigs}     = $sig       if keys %$sig;

        if (my $delta = $self->peer_delta) {
            $activity{peer_delta} = $delta;
        }

        my $now = time;
        if ($now - $last_interval >= $interval) {
            $activity{interval} = 1;

            # This will get reset when we run our callbacks, but put this here as a safety
            $self->{_LAST_INTERVAL} = $now;
        }

        if (my $pids = $self->watch_pids) {
            $activity{pid_watch} = 1 if any { !$self->pid_is_running($_) } @$pids;
        }

        return \%activity if keys %activity;

        sleep $cycle unless $select;
    }
}

sub run {
    my $self = shift;

    $self->in_correct_pid;

    my %sig_seen;
    $self->{_ORIG_SIG}  = {%SIG};
    $self->{_SIGS_SEEN} = \%sig_seen;

    for my $sig ($self->signals_to_grab) {
        my $key = "$sig";
        $SIG{$key} = sub { $sig_seen{$key}++ };
    }

    my $start_res = $self->_run_on_start();

    # If there was an exception on startup we do not keep going
    die "Exception in process startup, aborting" unless $start_res->{ok};

    $self->peer_delta; # Initialize it
    until ($self->is_terminated) {
        my $activity;
        $self->try(sub { $activity = $self->watch(\%sig_seen) })->{ok} or next;
        next unless $activity;

        $self->_run_on_all($activity);

        if (my $sigs = delete $activity->{sigs}) {
            for my $sig (keys %$sigs) {
                my $count = delete $sigs->{$sig} or next;
                $self->_run_on_sig($sig) for $count;
            }
        }

        if (delete $activity->{pid_watch}) {
            $self->terminate(0);
            last;
        }

        if (delete $activity->{interval}) {
            $self->_run_on_interval();
            $self->{_LAST_INTERVAL} = time;
        }

        $self->_run_on_peer_delta(delete $activity->{peer_delta}) if $activity->{peer_delta};

        if (my $msgs = delete $activity->{messages}) {
            for my $msg (@$msgs) {
                $self->terminate(0) if $msg->is_terminate;
                $self->try(sub { $self->_run_on_message($msg) });
            }
        }

        $self->_run_on_unhandled($activity) if keys %$activity;

        $self->terminate(0) if $self->_run_should_end()->{out};
    }

    $self->_run_on_cleanup();

    %SIG = %{$self->{_ORIG_SIG}};

    return $self->terminated // 0;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IPC::Manager::Role::Service - Role for implementing IPC services with message handling

=head1 DESCRIPTION

This role provides the core functionality for IPC services including:

=over 4

=item Message handling (requests/responses)

=item Peer management and delta detection

=item Signal handling

=item Worker process management

=item Main event loop via the C<run()> method

=back

It composes with L<IPC::Manager::Role::Service::Select> and
L<IPC::Manager::Role::Service::Requests> for I/O multiplexing and request/response
patterns.

=head1 SYNOPSIS

    package MyService;
    use Role::Tiny::With;
    with 'IPC::Manager::Role::Service';

    sub new { ... }

    sub orig_io { ... }

    sub name { ... }

    sub run { ... }

    sub ipcm_info { ... }

    sub pid { ... }

    sub set_pid { ... }

    sub watch_pids { ... }

    sub handle_request { ... }

    1;

=head1 REQUIRED METHODS

These methods must be implemented by the consuming class:

=over 4

=item $inst = $class->new(%params)

Constructor. Must accept parameters for initialization.

=item $io = $self->orig_io()

Returns a hashref with optional C<stdout>, C<stderr>, or C<stdin> filehandles.

=item $string = $self->name()

Returns the service name.

=item $exit = $self->run()

Runs the main event loop. Returns when the service is terminated. Should return
an exit code.

=item $info = $self->ipcm_info()

Returns connection information for the IPC system.

=item $pid = $self->pid()

Returns the process ID the service is supposed to be confined to.

=item $self->set_pid($pid)

Sets the process ID (used after fork).

=item $pids_arrayref = $self->watch_pids()

Returns an arrayref of PIDs to watch. If any terminates, the service exits.

=item ($resp) = $self->handle_request($request, $msg)

Handles an incoming request message.

Should return an empty list if the request is being processed, but no response
is ready.

Should return a single item (undef, scalar, or reference) for a response.

If this returns multiple items an exception will be thrown.

=back

=head1 METHODS

=over 4

=item $self->cycle()

Returns the select cycle time (default: 0.2 seconds).

=item $self->interval()

Returns the interval for C<run_on_interval> callbacks (default: 0.2 seconds).

=item $self->use_posix_exit()

Returns whether to use POSIX exit codes (default: 0).

=item $self->intercept_errors()

Returns whether to intercept and log errors (default: 0).

=item $val = $self->terminated()

Gets the termination status.

=item $self->is_terminated()

Returns true if the service is terminated.

=item $val = $self->terminate()

=item $val = $self->terminate($val)

Sets the termination status. If no value is provided then C<0> is used. Returns
the new value.

=item $class = $self->peer_class()

Returns the class to use for peer connections (default: C<IPC::Manager::Service::Peer>).

=item $class = $self->handle_class()

Returns the class to use for handles (default: C<IPC::Manager::Service::Handle>).

=item @signal_names = $self->signals_to_grab()

Returns a list of signals to intercept (default: empty).

=item $self->redirect()

Override to redirect I/O. Called during startup. Default implementation is a
no-op.

=item $self->pre_fork_hook()

Override to run code before forking workers. Default implementation is a no-op.

=item $self->run_on_all($activity)

Called for every iteration of the service's main loop.

See the L</"ACTIVITY HASH"> for a description of the C<$activity> input.

=item $self->run_on_cleanup()

Called when the service is shutting down.

=item $self->run_on_general_message($msg)

Called for messages that are not requests or responses.

=item $self->run_on_interval()

Called at regular intervals (controlled by C<interval()>).

=item $self->run_on_peer_delta($delta)

Called when peer connections change. C<$delta> is a hashref showing added/removed peers.

The L</"ACTIVITY HASH"> section shows the structure of the peer_delta as well.

=item $self->run_on_sig($sig)

Called when a signal is received. May be called multiple times in rapid
succession in a single loop iteration if a signal is recieved more than once.

=item $self->run_on_start()

Called on startup before the main loop.

=item $self->run_should_end()

Called to determine if the service should exit. Return true to terminate.

=item $self->run_on_unhandled($activity)

Called when activity remains unhandled after processing. Dies by default.

See the L</"ACTIVITY HASH"> for a description of the C<$activity> input.

=item $self->clear_service_fields()

Clears all internal state fields.

=item $self->register_worker($name, $pid)

Registers a worker process.

=item $self->workers()

Returns a hashref of worker PIDs to names.

=item $self->reap_workers()

Reaps terminated worker processes. Returns a hashref of results.

=item $self->send_response($peer, $id, $resp)

Sends a response message to a peer.

=item $client = $self->client()

Returns the client connection for this service.

=item $self->in_correct_pid()

Verifies we're running in the correct process. Dies if not.

=item $self->kill($sig)

Sends a signal to the service process.

=item $self->debug(@msg)

Outputs debug messages to the appropriate filehandle.

=item $self->handle(name => $name, %params)

Creates a new handle for connecting to this service.

=item $self->peer($name, %params)

Creates a peer connection to another service.

=item $res = $self->try($cb)

Executes a callback with optional error interception.

$res is a hashref:

    {
        ok => $bool,
        err => $string,
        out => ...,
    }

=item $delta = $self->peer_delta(%params)

Returns a hashref showing changes in peer connections.

=item @handles = $self->select_handles()

Returns a list of filehandles for select().

=item $activity = $self->watch($sig_seen)

Waits for activity and returns an activity hashref.

See the L</"ACTIVITY HASH"> for a description of the C<$activity> output.

=item $terminated = $self->run()

Runs the main event loop until terminated. Returns the termination value.

=back

=head1 ACTIVITY HASH

The methods that take an activity hash get this structure:

Note that all keys that are not applicable may be omitted.

    {
        # Set if the time interval has passed since the last iteration
        interval => $bool,

        # An arrayref of messages, if any
        messages => \@messages,

        # A hashref for peers that have been added or removed, -1 means removed, 1 means added.
        peer_delta => {peer1 => -1, peer3 => 1},

        # True if a wtached pid has exited
        pid_watch => $bool,

        # Hashref of all signals intercepted since the last iteration, plus a count of how many times they were recieved
        sigs => {sig => $count, sig2 => $count2},

        # Set if termination has occured, along with the termination value as a key on the hashref.
        terminated => { value => $value },
    }

=head1 SOURCE

The source code repository for IPC::Manager can be found at
L<https://github.com/exodist/IPC-Manager>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 COPYRIGHT

Copyright Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See L<https://dev.perl.org/licenses/>

=cut
