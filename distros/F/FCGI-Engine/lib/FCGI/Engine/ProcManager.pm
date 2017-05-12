package FCGI::Engine::ProcManager;
use Moose;

use constant DEBUG => 0;

use POSIX qw(SA_RESTART SIGTERM SIGHUP);

use FCGI::Engine::Types;
use MooseX::Daemonize::Pid::File;

our $VERSION   = '0.22';
our $AUTHORITY = 'cpan:STEVAN';

has 'role' => (
    is      => 'rw',
    isa     => 'FCGI::Engine::ProcManager::Role',
    default => sub { 'manager' }
);

has 'start_delay' => (
    is      => 'rw',
    isa     => 'Int',
    default => sub { 0 }
);

has 'die_timeout' => (
    is      => 'rw',
    isa     => 'Int',
    default => sub { 60 }
);

has 'n_processes' => (
    is       => 'rw',
    isa      => 'Int',
    default  => sub { 0 }
);

has 'pidfile' => (
    is       => 'rw',
    isa      => 'MooseX::Daemonize::Pid::File',
#    coerce   => 1,
);

has 'no_signals' => (
    is      => 'rw',
    isa     => 'Bool',
    default => sub { 0 }
);

has 'sigaction_no_sa_restart' => (is => 'rw', isa => 'POSIX::SigAction');
has 'sigaction_sa_restart'    => (is => 'rw', isa => 'POSIX::SigAction');

has 'signals_received' => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub { +{} }
);

has 'manager_pid' => (
    is  => 'rw',
    isa => 'Int',
);

has 'server_pids' => (
    traits  => [ 'Hash' ],
    is      => 'rw',
    isa     => 'HashRef',
    clearer => 'forget_all_pids',
    default => sub { +{} },
    handles => {
        '_add_pid'     => 'set',
        'get_all_pids' => 'keys',
        'remove_pid'   => 'delete',
        'has_pids'     => 'count',
        'pid_count'    => 'count',
    }
);

sub add_pid { (shift)->_add_pid( @_, 1 ) }

has 'process_name'         => (is => 'ro', isa => 'Str', default => sub { 'perl-fcgi'    });
has 'manager_process_name' => (is => 'ro', isa => 'Str', default => sub { 'perl-fcgi-pm' });

## methods ...

sub BUILD {
    my $self = shift;
    unless ($self->no_signals()) {
        $self->sigaction_no_sa_restart(
            POSIX::SigAction->new(
                'FCGI::Engine::ProcManager::sig_sub'
            )
        );
        $self->sigaction_sa_restart(
            POSIX::SigAction->new(
                'FCGI::Engine::ProcManager::sig_sub',
                undef,
                POSIX::SA_RESTART
            )
        );
    }
}

# this is the signal handler ...
{
    my $SIG_CODEREF;

    sub sig_sub { $SIG_CODEREF->(@_) if ref $SIG_CODEREF }

    sub clear_signal_handler { undef $SIG_CODEREF }

    sub setup_signal_handler {
        my $self = shift;
        $SIG_CODEREF = $self->role eq 'manager'
            ? sub { defined $self && $self->manager_sig_handler(@_) }
            : sub { defined $self && $self->server_sig_handler(@_)  };
    }
}

## main loop ...

sub manage {
    my $self = shift;

    # skip to handling now if we won't be managing any processes.
    $self->n_processes or return;

    # call the (possibly overloaded) management initialization hook.
    $self->role("manager");
    $self->manager_init;
    $self->notify("initialized");

    my $manager_pid = $$;

    MANAGING_LOOP: while (1) {

        # FIXME
        # we should tell the process that it is being
        # run under some kind of daemon, which will mean
        # that getppid will usually then return 1
        # - SL
        #getppid() == 1 and
        #  return $self->die("calling process has died");

        $self->n_processes > 0 or
            return $self->die;

        # while we have fewer servers than we want.
        PIDS: while ($self->pid_count < $self->n_processes) {

            if (my $pid = fork) {
               # the manager remembers the server.
               $self->add_pid($pid);
               $self->notify("server (pid $pid) started");

            }
            elsif (! defined $pid) {
                return $self->abort("fork: $!");
            }
            else {
                $self->manager_pid($manager_pid);
                # the server exits the managing loop.
                last MANAGING_LOOP;
            }

            for (my $s = $self->start_delay; $s; $s = sleep $s) {};
        }

        # this should block until the next server dies.
        $self->wait;

    }# while 1

    SERVER:

    # forget any children we had been collecting.
    $self->forget_all_pids;

    # call the (possibly overloaded) handling init hook
    $self->role("server");
    $self->server_init;
    $self->notify("initialized");

    # server returns
    return 1;
}

## initializers ...

sub manager_init {
    my $self = shift;

    unless ($self->no_signals) {
        $self->setup_signal_actions(with_sa_restart => 0);
        $self->setup_signal_handler;
    }

    $self->change_process_name;

    eval { $self->pidfile->write };
    $self->notify("Could not write the PID file because: $@") if $@;

    inner();
}

sub server_init {
    my $self = shift;

    unless ($self->no_signals) {
        $self->setup_signal_actions(with_sa_restart => 0);
        $self->setup_signal_handler;
    }

    $self->change_process_name;

    inner();
}


## hooks ...

sub pre_dispatch {
    my $self = shift;

    $self->setup_signal_actions(with_sa_restart => 1)
        unless $self->no_signals;

    inner();
}

sub post_dispatch {
    my $self = shift;

    $self->exit("safe exit after SIGTERM")
        if $self->received_signal("TERM");

    $self->exit("safe exit after SIGHUP")
        if $self->received_signal("HUP");

    if ($self->manager_pid and getppid() != $self->manager_pid) {
        $self->exit("safe exit: manager has died");
    }

    $self->setup_signal_actions(with_sa_restart => 0)
        unless $self->no_signals;

    inner();
}

## utils ...

# sig-handlers

sub manager_sig_handler {
    my ($self, $name) = @_;
    if ($name eq "TERM") {
        $self->notify("received signal $name");
        $self->die("safe exit from signal $name");
    }
    elsif ($name eq "HUP") {
        # send a TERM to each of the servers,
        # and pretend like nothing happened..
        if (my @pids = $self->get_all_pids) {
            $self->notify("sending TERM to PIDs, @pids");
            kill TERM => @pids;
        }
    }
    else {
        $self->notify("ignoring signal $name");
    }
}

sub server_sig_handler {
    my ($self, $name) = @_;
    $self->received_signal($name, 1);
}

sub received_signal {
    my ($self, $sig, $received) = @_;
    return $self->signals_received unless $sig;
    $self->signals_received->{$sig}++ if $received;
    return $self->signals_received->{$sig};
}

sub change_process_name {
    my $self = shift;
    $0 = ($self->role eq 'manager' ? $self->manager_process_name : $self->process_name);
}

sub wait : method {
    my $self = shift;

    # wait for the next server to die.
    return if (my $pid = CORE::wait()) < 0;

    # notify when one of our servers have died.
    $self->remove_pid($pid)
        and $self->notify("server (pid $pid) exited with status $?");

    return $pid;
}

## signal handling stuff ...

sub setup_signal_actions {
    my $self = shift;
    my %args = @_;

    my $sig_action = (exists $args{with_sa_restart} && $args{with_sa_restart})
        ? $self->sigaction_sa_restart
        : $self->sigaction_no_sa_restart;

    POSIX::sigaction(POSIX::SIGTERM, $sig_action)
        || $self->notify("sigaction: SIGTERM: $!");
    POSIX::sigaction(POSIX::SIGHUP,  $sig_action)
        || $self->notify("sigaction: SIGHUP: $!");
}

## notification ...

sub notify {
    my ($self, $msg) = @_;
    $msg =~ s/\s*$/\n/;
    print STDERR "FastCGI: " . $self->role() . " (pid $$): " . $msg;
}

## error/exit handlers ...

sub die : method {
    my ($self, $msg, $n) = @_;

    # stop handling signals.
    $self->clear_signal_handler;
    $SIG{HUP}  = 'DEFAULT';
    $SIG{TERM} = 'DEFAULT';

    $self->pidfile->remove
        || $self->notify("Could not remove PID file: $!");

    # prepare to die no matter what.
    if (defined $self->die_timeout) {
        $SIG{ALRM} = sub { $self->abort("wait timeout") };
        alarm $self->die_timeout;
    }

    # send a TERM to each of the servers.
    if (my @pids = $self->get_all_pids) {
        $self->notify("sending TERM to PIDs, @pids");
        kill TERM => @pids;
    }

    # wait for the servers to die.
    while ($self->has_pids) {
        $self->wait;
    }

    # die already.
    $self->exit("dying: $msg", $n);
}

sub abort {
    my ($self, $msg, $n) = @_;
    $n ||= 1;
    $self->exit($msg, 1);
}

sub exit : method {
    my ($self, $msg, $n) = @_;
    $n ||= 0;

    # if we still have children at this point,
    # something went wrong. SIGKILL them now.
    kill KILL => $self->get_all_pids
        if $self->has_pids;

    $self->notify($msg);
    $@ = $msg;
    CORE::exit $n;
}

1;

__END__

=pod

=head1 NAME

FCGI::Engine::ProcManager - module for managing FastCGI applications.

=head1 DESCRIPTION

This module is a refactoring of L<FCGI::ProcManager>, it behaves exactly the
same, but the API is a little different. The function-oriented API has been
removed in favor of object-oriented API. The C<pm_> prefix has been removed
from  the hook routines and instead they now use the C<augment> and C<inner>
functionality from L<Moose>. More docs will come eventually.

=head2 Signal Handling

FCGI::Engine::ProcManager attempts to do the right thing for proper shutdowns.

When it receives a SIGHUP, it sends a SIGTERM to each of its children, and
then resumes its normal operations.

When it receives a SIGTERM, it sends a SIGTERM to each of its children, sets
an alarm(3) "die timeout" handler, and waits for each of its children to
die.  If all children die before this timeout, process manager exits with
return status 0.  If all children do not die by the time the "die timeout"
occurs, the process manager sends a SIGKILL to each of the remaining
children, and exists with return status 1.

FCGI::Engine::ProcManager uses POSIX::sigaction() to override the default
SA_RESTART policy used for perl's %SIG behavior.  Specifically, the process
manager never uses SA_RESTART, while the child FastCGI servers turn off
SA_RESTART around the accept loop, but re-enstate it otherwise.

The desired (and implemented) effect is to give a request as big a chance as
possible to succeed and to delay their exits until after their request,
while allowing the FastCGI servers waiting for new requests to die right
away.

=head1 METHODS

I will fill this in more eventually, but for now if you really wanna know,
read the source.

=head1 SEE ALSO

=over 4

=item L<FCGI::ProcManager>

This module is a fork of the FCGI::ProcManager code, with lots of
code cleanup as well as general Moosificaition.

=back

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 AUTHOR

Stevan Little E<lt>stevan@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2007-2010 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
