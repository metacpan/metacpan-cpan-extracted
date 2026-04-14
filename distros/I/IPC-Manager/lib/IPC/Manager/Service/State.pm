package IPC::Manager::Service::State;
use strict;
use warnings;

use Carp qw/croak/;
use Time::HiRes qw/sleep time/;
use IPC::Manager::Util qw/require_mod clone_io/;
use IPC::Manager::Serializer::JSON();

use POSIX();

my $base_0 = $0;
my $service_inst;

my $_post_exec_run = sub { 255 };

sub import {
    my $class = shift;

    my $json = shift @ARGV;

    my $params = IPC::Manager::Serializer::JSON->deserialize($json);
    my $exec = delete $params->{exec} // {};

    $params->{orig_io} = {
        stderr => clone_io('>&', \*STDERR),
        stdout => clone_io('>&', \*STDOUT),
        stdin  => clone_io('<&', \*STDIN),
    };

    my $svc_class = require_mod($params->{class} // 'IPC::Manager::Service');
    my $new_inst = $svc_class->new(%$params);

    my $exit;
    my $code = sub { _ipcm_service(%$params, new_inst => $new_inst); $exit = 0 };

    if ($exec->{stay_in_begin}) {
        $exit = 255;
        $_post_exec_run = sub { $exit };
        $code->();
    }
    else {
        $_post_exec_run = $code;
    }
}

sub ipcm_worker {
    my ($name, $cb) = @_;

    croak "ipcm_service_worker() can only be called from inside a service"
        unless $service_inst && ref($service_inst) ne 'CODE';

    my $pid = fork // die "Could not fork: $!";
    if ($pid) {
        $service_inst->register_worker($name => $pid);
        return $pid;
    }

    $0 = "$0 $name";

    $service_inst = $cb;
    no warnings 'exiting';
    redo SERVICE;
    die "This should not be reachable";
}

sub ipcm_service {
    my ($name, @args) = @_;

    my $return_handle = defined(wantarray) ? 1 : 0;

    my %params;
    if (@args == 1 && ref($args[0]) eq 'CODE') {
        $params{class}  = 'IPC::Manager::Service';
        $params{on_all} = $args[0];
    }
    elsif (@args == 2 && ref($args[0]) eq 'HASH' && ref($args[1]) eq 'CODE') {
        %params         = %{$args[0]};
        $params{class}  = 'IPC::Manager::Service';
        $params{on_all} = $args[1];
    }
    else {
        %params = @args;
    }

    my $skip_role_checks = delete $params{skip_role_checks};

    my $exec = delete $params{exec};

    $params{name} = $name;

    $params{orig_io} //= $service_inst ? $service_inst->orig_io : {
        stderr => clone_io('>&', \*STDERR),
        stdout => clone_io('>&', \*STDOUT),
        stdin  => clone_io('<&', \*STDIN),
    } unless $exec;

    if ($service_inst && !$params{redirect}) {
        if (my $redir = $service_inst->redirect) {
            $params{redirect} = $redir unless defined($redir->{inherit}) && !$redir->{inherit};
        }
    }

    my $new_ipcm = delete $params{new_ipcm};

    my $handle_params = delete $params{handle_params} // {};
    if ($params{ipcm_info}) {
        croak "'new_ipcm' and 'ipcm_info' may not be combined" if $new_ipcm;
    }
    else {
        if ($service_inst && !$new_ipcm) {
            $handle_params->{_peer} = 1;
            $params{ipcm_info} = $service_inst->ipcm_info;
        }
        elsif ($return_handle) {
            require IPC::Manager;
            $handle_params->{spawn} = IPC::Manager::ipcm_spawn();
            $params{ipcm_info}      = $handle_params->{spawn}->info;
            $params{watch_pids}     = [$$];
        }
        else {
            croak "Cannot be called in void context without providing 'ipcm_info'";
        }
    }

    my $class = require_mod($params{class} // 'IPC::Manager::Service');

    croak "'$class' does not implement the 'IPC::Manager::Role::Service' role"
        unless $skip_role_checks || Role::Tiny::does_role($class, 'IPC::Manager::Role::Service');

    my $new_inst = $class->new(%params);

    $new_inst->pre_fork_hook();

    $exec->{json} = IPC::Manager::Serializer::JSON->serialize(\%params)
        if $exec;

    my $pid = fork // die "Could not fork: $!";

    # In parent
    if ($pid) {
        return unless $return_handle || $exec;

        my $out;

        if (delete $handle_params->{_peer}) {
            $out = $service_inst->peer($params{name}, %$handle_params);
        }
        else {
            $out = $new_inst->handle(%$handle_params, name => "service_parent_$$");
        }

        my $timeout = $params{timeout} || 10;

        my $start = time;
        until ($out->ready) {
            my $delta = time - $start;
            last if $delta > $timeout;
            sleep 0.025;
        }

        croak "Timeout waiting for service to come up after ${timeout}s"
            unless $out->ready;

        return $out;
    }

    $new_inst->post_fork_hook();

    if ($exec) {
        my $cmd = $exec->{cmd} // [];
        my $json = $exec->{json};

        exec(
            $^X,
            @{$cmd},
            "-M${ \__PACKAGE__ }",
            "-e" => "exit(${ \__PACKAGE__ }\::_post_exec_run())",
            $json,
        );
    }

    @_ = (%params, new_inst => $new_inst);
    goto \&_ipcm_service;
}

sub _post_exec_run { $_post_exec_run->() }

sub _ipcm_service {
    my %params = @_;

    my $name = $params{name};

    my $new_inst = delete $params{new_inst};
    $new_inst->set_pid($$);

    $0 = delete($params{rebase_0}) ? "$base_0 $name" : "$0 $name";

    # Figure out if we already had a service
    my $prev_service = $service_inst ? 1 : 0;

    # Set the new instance as the current one
    $service_inst = $new_inst;

    # If we want the stack to unwind, use this to unwind it (nested services)
    if ($prev_service) {
        no warnings 'exiting';
        redo SERVICE;
        die "This should not be reachable";
    }

    # Run the service
    # We have this label here for the 'redo' above.
    SERVICE: {
        # Get a copy to work with, the $service_inst can be replaced before this block exits.
        my $using_service = $service_inst;

        my $do_posix_exit = ref($using_service) ne 'CODE' && $using_service->use_posix_exit;

        eval {
            if (ref($using_service) eq 'CODE') {
                my $exit = $using_service->();
                exit($exit);
            }
            else {
                my $exit = $using_service->run() // 0;
                $do_posix_exit ? POSIX::_exit($exit) : exit($exit);
            }
            1;
        } or warn $@;

        $do_posix_exit ? POSIX::_exit(255) : exit(255);
    }

    # This should not be reachable....
    eval { warn "Scope leak in service '$name' process $$" };
    POSIX::_exit(255);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IPC::Manager::Service::State - Internal implementation of ipcm_service and ipcm_worker

=head1 DESCRIPTION

This module is the implementation backing the C<ipcm_service> and
C<ipcm_worker> exports provided by L<IPC::Manager>.  It also acts as its
own C<-M> boot module when a service is started via C<exec>: in that case
Perl loads this module with C<-MIPC::Manager::Service::State>, which reads
the serialised service parameters from C<@ARGV> and arranges for the service
to start running once the Perl runtime exits C<BEGIN>.

Callers should interact with this module only through the exports of
L<IPC::Manager>; direct use is not part of the public API.

=head1 EXPORTS

These functions are re-exported through L<IPC::Manager>; see that module for
the primary documentation.

=over 4

=item $handle = ipcm_service($name, \&on_all_callback)

=item $handle = ipcm_service($name, \%params, \&on_all_callback)

=item $handle = ipcm_service($name, %params)

Fork a new service process.  The return value depends on calling context and
where the call is made:

=over 4

=item *

When called outside a service, returns an
L<IPC::Manager::Service::Handle> connected to a newly spawned IPC bus.
C<ipcm_service> blocks until the service signals that it is ready.

=item *

When called from B<inside> a running service (from a service callback), the
new service shares the existing IPC bus.  Returns an
L<IPC::Manager::Service::Peer> that the calling service can use to send
requests to the nested service.  C<ipcm_service> blocks until the nested
service is ready.

=item *

When called in B<void context> from inside a service, the nested service is
started but C<ipcm_service> returns immediately without waiting for the
service to be ready.  The caller is responsible for waiting before sending
messages; see L<IPC::Manager/ipcm_service> for details.

=back

=item $pid = ipcm_worker($name, \&callback)

Fork a worker process from inside a running service.  The worker runs
C<\&callback> in place of a normal service loop and is registered with the
parent service so that it is reaped when the service exits.  Dies if called
outside a service.

Returns the PID of the newly forked worker to the parent; in the worker
process the callback is invoked and the function never returns.

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
