package IPC::Manager::Service;
use strict;
use warnings;

our $VERSION = '0.000022';

use Carp qw/croak confess/;
use List::Util qw/max/;

my @ACTIONS;
BEGIN {
    @ACTIONS = qw{
        on_all
        on_cleanup
        on_general_message
        on_interval
        on_peer_delta
        on_pid
        on_start
        on_unhandled
        should_end
    };
}

use Object::HashBase(
    qw{
        <name
        <orig_io
        <ipcm_info
        <redirect

        pid
        use_posix_exit
        intercept_errors
        expose_error_details
        watch_pids

        <interval
        <cycle
        +on_sig
        +handle_request
        +handle_response
        <post_fork
    },

    map { "<$_" } @ACTIONS,
);

use Role::Tiny::With;
with 'IPC::Manager::Role::Service';

sub signals_to_grab { keys %{$_[0]->{+ON_SIG}} }
sub handle_request  { $_[0]->{+HANDLE_REQUEST}->(@_) }
sub handle_response { $_[0]->{+HANDLE_RESPONSE}->(@_) }

sub post_fork_hook {
    my $self = shift;
    my $cb = $self->{+POST_FORK} or return;
    $cb->($self);
}

sub init {
    my $self = shift;

    $self->clear_service_fields();

    $self->{+CYCLE}            //= $self->IPC::Manager::Role::Service::cycle();
    $self->{+INTERVAL}         //= $self->IPC::Manager::Role::Service::interval();
    $self->{+USE_POSIX_EXIT}   //= $self->IPC::Manager::Role::Service::use_posix_exit();
    $self->{+INTERCEPT_ERRORS}      //= $self->IPC::Manager::Role::Service::intercept_errors();
    $self->{+EXPOSE_ERROR_DETAILS}  //= $self->IPC::Manager::Role::Service::expose_error_details();

    croak "'post_fork' must be a coderef" if $self->{+POST_FORK} && ref($self->{+POST_FORK}) ne 'CODE';

    if ($self->{+ON_ALL}) {
        $self->{+HANDLE_REQUEST}  //= sub { return () };
        $self->{+HANDLE_RESPONSE} //= sub { return () };
    }
    else {
        my $req_handler  = $self->{+HANDLE_REQUEST} or croak "Either 'on_all' or 'handle_request' callback is required";
        my $resp_handler = $self->{+HANDLE_RESPONSE} //= sub { confess "Got a response, but no response handler set" };

        croak "'handle_request' must be a coderef"  unless ref($req_handler) eq 'CODE';
        croak "'handle_response' must be a coderef" unless ref($resp_handler) eq 'CODE';
    }

    for my $action (@ACTIONS) {
        my $in = delete $self->{$action};
        my $do = $in ? (ref($in) eq 'ARRAY' ? $in : [$in]) : [];

        my @bad = grep { ref($_) ne 'CODE' } @$do;
        croak "All '$action' callbacks must be coderefs, got: " . join(', ' => @bad) if @bad;

        $self->{$action} = $do;
    }

    if (my $sigs = delete $self->{+ON_SIG}) {
        croak "'on_sig' must be a hashref" unless ref($sigs) eq 'HASH';

        my $new = {};
        for my $sig (keys %$sigs) {
            my $do = $sigs->{$sig} or next;
            $do = [$do] unless ref($do) eq 'ARRAY';
            my @bad = grep { ref($_) ne 'CODE' } @$do;
            croak "All signal handlers must be coderefs, got: " . join(', ' => @bad) if @bad;
            $new->{$sig} = $do;
        }

        $self->{+ON_SIG} = $new;
    }
    else {
        $self->{+ON_SIG} = {};
    }
}

#<<<    Do not tidy this
sub clear_on_sig   { delete $_[0]->{+ON_SIG}->{$_[1]} }
sub push_on_sig    { push @{$_[0]->{+ON_SIG}->{$_[1]}}    => $_[2] }
sub unshift_on_sig { unshift @{$_[0]->{+ON_SIG}->{$_[1]}} => $_[2] }
sub run_on_sig     { my @args = @_; [map { $_->(@args) } @{$_[0]->{+ON_SIG}->{$_[1]}}] }
sub remove_on_sig  { my $cb = $_[2]; @{$_[0]->{+ON_SIG}->{$_[1]}} = grep { $_ != $cb } @{$_[0]->{+ON_SIG}->{$_[1]}} }
#>>>

BEGIN {
    my %inject;

    # Should end needs to return true/false
    $inject{'run_should_end'} = sub { my @args = @_; my $count = grep { $_->(@args) } @{$_[0]->{should_end}}; $count ? 1 : 0 };

    for my $action (@ACTIONS) {
        my $key = $action;

        #<<<    Do not tidy this
        $inject{"clear_$key"}   //= sub { delete $_[0]->{$key} };
        $inject{"push_$key"}    //= sub { push @{$_[0]->{$key}}    => $_[1] };
        $inject{"unshift_$key"} //= sub { unshift @{$_[0]->{$key}} => $_[1] };
        $inject{"run_$key"}     //= sub { my @args = @_; [map { $_->(@args) } @{$_[0]->{$key}}] };
        $inject{"remove_$key"}  //= sub { my $cb = $_[1]; @{$_[0]->{$key}} = grep { $_ != $cb } @{$_[0]->{$key}} };
        #>>>
    }

    no strict 'refs';
    *{$_} = $inject{$_} for keys %inject;
}

sub DESTROY {
    my $self = shift;
    local $?;
    $self->terminate_workers;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IPC::Manager::Service - Base class for creating IPC services

=head1 DESCRIPTION

This class provides a concrete implementation of the
L<IPC::Manager::Role::Service> role for creating IPC services. It handles
message handling, peer management, signal handling, and the main event loop.

=head1 SYNOPSIS

    use IPC::Manager::Service;

    my $service = IPC::Manager::Service->new(
        name           => 'my-service',
        ipcm_info      => $ipcm_info,
        handle_request => sub {
            my ($self, $request, $msg) = @_;
            return {result => 'ok'};
        },
    );

    $service->run;

=head1 CONSTRUCTOR ARGUMENTS

=over 4

=item name

The service name (required).

=item orig_io

Hashref with optional C<stdout> and C<stderr> filehandles for debug output.

=item ipcm_info

Connection information for the IPC system.

=item redirect

Boolean indicating whether to redirect I/O.

=item pid

The process ID.

=item use_posix_exit

Boolean indicating whether to use POSIX exit codes.

=item intercept_errors

Boolean indicating whether to intercept and log errors.

=item expose_error_details

Boolean indicating whether exception text from C<handle_request> should be
included verbatim in error responses.  When false (the default), a generic
C<"Internal service error"> message is sent.  When true, the stringified
exception is sent as the C<ipcm_error> value in the response.

=item watch_pids

Arrayref of PIDs to watch. If any terminates, the service exits.

=item interval

Interval for C<run_on_interval> callbacks (default: 0.2 seconds).

=item cycle

Select cycle time (default: 0.2 seconds).

=item on_sig => {\%hash}

Hash of signal names to callback(s) for signal handling.

=item handle_request => \&callback

Callback for handling requests. Required unless C<on_all> is provided.

=item handle_response => \&callback

Callback for handling responses. Defaults to confessing if not provided.

=item post_fork => \&callback

Callback called in the child process after C<ipcm_service> forks but before
the service takes over. Use this to implement a double-fork pattern: fork
inside the callback, have the middle process do its work and exit, and let the
grandchild return to become the service. The callback receives the service
instance as its argument.

=item on_all => \&callback

Callback called for every activity cycle. If provided, C<handle_request> and
C<handle_response> default to no-ops.

=item on_cleanup => \&callback

Callback called when the service is shutting down.

=item on_general_message => \&callback

Callback for messages that are not requests or responses.

=item on_interval => \&callback

Callback called at regular intervals.

=item on_peer_delta => \&callback

Callback called when peer connections change.

=item on_pid => \&callback

Callback called (with C<$pid> and C<$exit>) for each non-worker child process
reaped by the service loop.  Worker processes registered with
C<ipcm_worker> are handled internally and do not trigger this callback.

=item on_start => \&callback

Callback called on startup before the main loop.

=item on_unhandled => \&callback

Callback called when activity remains unhandled. Dies by default.

=item should_end => \&callback

Callback called to determine if the service should exit.

=back

=head1 METHODS

=over 4

=item @signal_names = $self->signals_to_grab()

Returns a list of signals to intercept.

=item ($resp) = $self->handle_request($request, $msg)

Calls the configured request handler. The handler should return a single item
(scalar, undef, reference) when if the response is ready. Should return an
empty list if the request needs further processing.

=item $self->handle_response($resp, $msg)

Calls the configured response handler.

=item $self->clear_on_sig($sig)

Clears all handlers for a signal.

=item $self->push_on_sig($sig, $cb)

Adds a callback to the signal handlers.

=item $self->unshift_on_sig($sig, $cb)

Prepends a callback to the signal handlers.

=item $self->run_on_sig($sig, @args)

Runs all callbacks for a signal.

=item $self->remove_on_sig($sig, $cb)

Removes a specific callback from signal handlers.

=item $self->clear_on_all()

Clears the array of callbacks for C<on_all>.

=item $self->push_on_all($cb)

Adds a callback to the C<on_all> callback array.

=item $self->unshift_on_all($cb)

Prepends a callback to the C<on_all> callback array.

=item $self->run_on_all(@args)

Runs all callbacks for C<on_all>.

=item $self->remove_on_all($cb)

Removes a specific callback from the C<on_all> callback array.

=item $self->clear_on_cleanup()

Clears the array of callbacks for C<on_cleanup>.

=item $self->push_on_cleanup($cb)

Adds a callback to the C<on_cleanup> callback array.

=item $self->unshift_on_cleanup($cb)

Prepends a callback to the C<on_cleanup> callback array.

=item $self->run_on_cleanup(@args)

Runs all callbacks for C<on_cleanup>.

=item $self->remove_on_cleanup($cb)

Removes a specific callback from the C<on_cleanup> callback array.

=item $self->clear_on_general_message()

Clears the array of callbacks for C<on_general_message>.

=item $self->push_on_general_message($cb)

Adds a callback to the C<on_general_message> callback array.

=item $self->unshift_on_general_message($cb)

Prepends a callback to the C<on_general_message> callback array.

=item $self->run_on_general_message(@args)

Runs all callbacks for C<on_general_message>.

=item $self->remove_on_general_message($cb)

Removes a specific callback from the C<on_general_message> callback array.

=item $self->clear_on_interval()

Clears the array of callbacks for C<on_interval>.

=item $self->push_on_interval($cb)

Adds a callback to the C<on_interval> callback array.

=item $self->unshift_on_interval($cb)

Prepends a callback to the C<on_interval> callback array.

=item $self->run_on_interval(@args)

Runs all callbacks for C<on_interval>.

=item $self->remove_on_interval($cb)

Removes a specific callback from the C<on_interval> callback array.

=item $self->clear_on_peer_delta()

Clears the array of callbacks for C<on_peer_delta>.

=item $self->push_on_peer_delta($cb)

Adds a callback to the C<on_peer_delta> callback array.

=item $self->unshift_on_peer_delta($cb)

Prepends a callback to the C<on_peer_delta> callback array.

=item $self->run_on_peer_delta(@args)

Runs all callbacks for C<on_peer_delta>.

=item $self->remove_on_peer_delta($cb)

Removes a specific callback from the C<on_peer_delta> callback array.

=item $self->clear_on_pid()

Clears the array of callbacks for C<on_pid>.

=item $self->push_on_pid($cb)

Adds a callback to the C<on_pid> callback array.

=item $self->unshift_on_pid($cb)

Prepends a callback to the C<on_pid> callback array.

=item $self->run_on_pid($pid, $exit)

Runs all callbacks for C<on_pid>, passing the reaped child's PID and raw C<$?>
exit value.

=item $self->remove_on_pid($cb)

Removes a specific callback from the C<on_pid> callback array.

=item $self->clear_on_start()

Clears the array of callbacks for C<on_start>.

=item $self->push_on_start($cb)

Adds a callback to the C<on_start> callback array.

=item $self->unshift_on_start($cb)

Prepends a callback to the C<on_start> callback array.

=item $self->run_on_start(@args)

Runs all callbacks for C<on_start>.

=item $self->remove_on_start($cb)

Removes a specific callback from the C<on_start> callback array.

=item $self->clear_on_unhandled()

Clears the array of callbacks for C<on_unhandled>.

=item $self->push_on_unhandled($cb)

Adds a callback to the C<on_unhandled> callback array.

=item $self->unshift_on_unhandled($cb)

Prepends a callback to the C<on_unhandled> callback array.

=item $self->run_on_unhandled(@args)

Runs all callbacks for C<on_unhandled>.

=item $self->remove_on_unhandled($cb)

Removes a specific callback from the C<on_unhandled> callback array.

=item $self->clear_should_end()

Clears the array of callbacks for C<should_end>.

=item $self->push_should_end($cb)

Adds a callback to the C<should_end> callback array.

=item $self->unshift_should_end($cb)

Prepends a callback to the C<should_end> callback array.

=item $self->run_should_end(@args)

Runs all callbacks for C<should_end>. Returns true if any callback returns true.

=item $self->remove_should_end($cb)

Removes a specific callback from the C<should_end> callback array.

=back

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
