package Gearman::WorkerSpawner;

=head1 NAME

Gearman::WorkerSpawner - Subprocess manager for Gearman workers in a
Danga::Socket environment

=head1 SYNOPSIS

    # write client code in some Danga::Socket environment, e.g. Perlbal:

    my $worker_manager = Gearman::WorkerSpawner->new;

    # add one or more workers
    $worker_manager->add_worker(
        class        => 'AdditionWorker',
        num_workers  => 4,
        config       => {
            left_hand => 3,
        },
    );
    $worker_manager->run_method(adder => { right_hand => 3 }, sub {
        my $return = shift;
        print $return->{sum};
    });
    Danga::Socket->EventLoop;

    # and in the worker:

    package MethodWorker;
    use base 'Gearman::WorkerSpawner::BaseWorker';

    sub new {
        my MethodWorker $self = fields::new(shift);
        $self->SUPER::new(@_);

        $self->register_method(adder => \&add);
        return $self;
    }

    sub add {
        my MethodWorker $self = shift;
        my $args = shift;
        return { sum => $self->{config}{left_hand} + $args->{right_hand} };
    }

=head1 DESCRIPTION

Launches subclasses of L<Gearman::Worker> in their own processes for
communication with a gearmand. External Gearman servers may be used, or one can
be created for the lifetime of the spawner.

=cut

use strict;
use warnings;

our $VERSION = '2.17';

use Carp qw/ croak /;
use Danga::Socket ();
use Fcntl qw/ F_GETFD F_SETFD FD_CLOEXEC /;
use Gearman::Client ();
use Gearman::Client::Async ();
use Gearman::Server ();
use IO::Handle ();
use IO::Socket::INET qw/ SOCK_STREAM /;
use POSIX qw/ :sys_wait_h /;
use Storable qw/ nfreeze thaw /;

=head1 CLASS METHODS

=over 4

=item * Gearman::WorkerSpawner->new(%params)

Constructor, can take the following parameters:

=over 4

=item * gearmand

Specifies the location of the Gearman server to use. This may either be an
array reference of host:port specs ; or a comma separated list of host:port
specs; or I<auto>, which specifies that the WorkerSpawner should spawn a
separate process to contain a Gearman server. The advantage of using this over
running gearmand externally is that the Gearman server process will halt itself
in the event of the calling process' demise; the disadvantage is that you give
up gearmand redundancy. Defaults to I<auto>.

=item * check_period

Time in seconds between live-worker checks. Any zombie children are reaped with
C<waitpid> during the check, and enough workers are spawned to make the total
C<num_workers> again.

=item * perl

Path to the C<perl(1)> binary with which to execute workers. Defaults to
C<$^X>.

=item * reaper

WorkerSpawner periodically reaps any dead children of its running process. If
there are non-WorkerSpawner child processes in your program, you won't know
when they die. To be notified of such events, you can provide a subref as the
C<reaper> parameter which will be called with the PID and exit code of any
reaped children which don't belong to WorkerSpawner.

Along that line, only a single WorkerSpawner may be created in a process
(otherwise multiple spawners would race to reap each others' children, making
worker accounting impossible). As such, new() will croak if called more than
once.

=item * sigchld

If true, a SIGCHLD handler is installed which immediately schedules a child
check, rather than waiting upwards of C<check_period> seconds. Defaults to
true.

=back

=cut

our $gearmand_spec;
our $singleton;
my $num_workers = 0;
my @open_slots;
my $started = 0;
my $quitting = 0;

sub new {
    croak 'only one WorkerSpawner allowed per process' if $started;

    my $class = shift;
    my $ref = ref $class || $class;

    my %params = (
        check_period    => 1,
        perl            => $^X,
        quitting        => 0,
        gearmand        => 'auto',
        sigchld         => 1,
        method_suffix   => '_m',
        @_
    );

    $gearmand_spec = $params{gearmand};
    gearman_servers(); # init the server singleton if necessary

    croak 'gearmand location not specified' unless @{ gearman_servers() };

    # NB: this structure must be Storable-serializable for all bits used by
    # _supervise. see special handling in add_worker
    my $self = bless \%params, $class;

    $params{initial_pid} = $$;

    # clean up any dead supervisors. will also catch non-WorkerSpawner processes,
    # so fire the callback for those if provided
    my $child_handler = sub {
        my %reaped = $self->_reap();
        while (my ($pid, $thing) = each %reaped) {
            if ($thing->{action}) {
                # spawner
                $thing->{action}->($thing->{exit_code});
            }
            elsif ($self->{reaper}) {
                # unowned child
                $self->{reaper}->($pid, $thing->{exit_code});
            }
        }
    };

    # restart children immediately if installing sigchld handler
    $SIG{CHLD} = sub {
        Danga::Socket->AddTimer(0, $child_handler);
    } if $params{sigchld};

    # ... and/or check periodically
    _run_periodically($child_handler, $self->{check_period});

    $started = 1;

    return $singleton = $self;
}

=item * Gearman::WorkerSpawner->old

Returns the Gearman::WorkerSpawner object created by a previous call to ->new.
Use this if you need a WorkerSpawner in multiple places in your code within the
same process and passing the object is tricky.

=cut

sub old {
    return $singleton;
}

=item Gearman::WorkerSpawner->gearmand_pid()

Returns the PID of the gearmand which was started up if I<auto> was given
as the C<gearmand> parameter to C<new>, or undef otherwise.

=head1 OBJECT METHODS

=over 4

=item $spawner->add_worker(%options)

Add a new worker set to the manager. A new supervisor process will be created
to manage it if one does not already exist for the worker class. Can take the
following parameters:

=over 4

=item * class

(Required) The package name of the L<Gearman::Worker> subclass which will
register itself for work when instantiated. This need not be distinct across
different calls.

=item * source

(Optional) The path to the file containing the definition of 'class'; only
necessary if the module can't be use'd for some reason.

=item * caller_source

(Optional) If true, assume that the source for 'class' is the calling module or
script. This will generally fail if the working directory has changed since
program startup. This overrides I<source> if both are provided.

=item * num_workers

The number of worker children to spawn. If any child processes die they will be
respawned. Defaults to 1.

=item * config

An opaque data structure to pass to the child process, generally used to keep
configuration that is specific to the worker but not any one job. Must be
serializable via Storable.

=back

=cut

use constant SLOT_NUM    => 0;
use constant SLOT_ID     => 1;
use constant SLOT_PARAMS => 2;

sub add_worker {
    my Gearman::WorkerSpawner $self = shift;
    my %params = (
        num_workers => 1,
        @_
    );

    my $class = $params{class};
    croak 'no class provided' unless $class;

    # exec this .pm file
    (my $package_spec = __PACKAGE__ . '.pm') =~ s{::}{/}g;
    my $package_file = $INC{$package_spec};
    die "couldn't determine location of myself" unless $package_file;


    # "slots" are the set of jobs that each supervisor is managing. each worker
    # slot gets different parameters  so they can differentiate themselves
    # (like an MPI rank). @open_slots contains the slot# and startup params for
    # any slot without a live worker child. the originating process has only
    # open slots; supervisors in child processes fill the slots by spawning
    # workers. parent assigns the slots so that it knows how to contact them
    # in wait_until_all_ready.
    my @slots;
    for my $slot_num ($num_workers..$num_workers+$params{num_workers}-1) {
        my $worker_id = sprintf '%d:%s/%s', $slot_num, $class, substr rand() . '0'x16, 2, 16;
        push @slots, [$slot_num, $worker_id, \%params];
    }
    push @open_slots, @slots;
    $num_workers += $params{num_workers};

    my $success = 1;
    local $SIG{CHLD} = 'IGNORE';
    for (1 .. 10) {
        my $cmd = '';

        my $writer = $self->{supervisors}{$class};
        if (!defined $writer) {
            # don't have an existing child for this worker class

            # logically, we want to call $self->_supervise, except in a separate
            # process which has a reduced memory footprint after exec'ing. therefore we
            # need to recreate $self and parameters in the "remote" _supervise
            # procedure. create a pipe over which to do that.
            pipe(my $reader, $writer) or die "pipe failed: $!\n";
            $writer->autoflush(1);
            $reader->autoflush(1);

            # so exec doesn't close it
            fcntl($reader, F_GETFD, my $flags = '');
            vec($flags, FD_CLOEXEC, 1) = 0;
            fcntl($reader, F_SETFD, $flags);

            my $parent_pid = $$;

            my $pid = fork;
            die "failed to fork: $!\n" unless defined $pid;

            if ($pid) {
                # parent
                $self->{supervisors}{$class} = $writer;
                close $reader;

                $self->{kids}{$pid}{action} = sub {
                    # supervisor shouldn't exit; compilation of worker class probably failed
                    my $code = shift;
                    if ($code != 0) {
                        die "supervisor died ($code)\n";
                    }

                    # invalidate cmd pipe "cache" when kid dies
                    delete $self->{supervisors}{$class};
                };

                # make a serializable copy of $self
                my $storable_self = bless {
                    map { $_ => $self->{$_} }
                    grep {
                        $_ ne 'supervisors' && # globs aren't serializable
                        $_ ne 'kids' # so DESTROY doesn't kill them
                    }
                    keys %$self
                }, __PACKAGE__;

                $params{source} = (caller)[1] if $params{caller_source};

                # first command is startup parameters
                $cmd = _serialize({
                    spawner     => $storable_self,
                    class       => $class,
                    ppid        => $parent_pid,
                    gearmand    => gearman_servers(),
                    source      => $params{source},
                    inc         => \@INC,
                });
            }
            else {
                # child: start supervisor in a distinct process to manage the new jobs
                exec $self->{perl}, $package_file, fileno $reader; # $self->_supervise
                die "exec failed: $!\n";
            }
        }

        # subsequent commands start new workers
        $cmd .= _serialize(\@slots);

        local $SIG{PIPE} = 'IGNORE';
        return if print $writer $cmd;

        # print failed, try again
        delete $self->{supervisors}{$class} unless $success;
        sleep 1;
    }
    die "failed to spawn workers";
}

=item $spawner->wait_until_all_ready()

Returns only once all worker are ready to accept jobs. This will only wait on
workers which have been started since the last call to wait_until_all_ready.

=cut

sub wait_until_all_ready {
    my Gearman::WorkerSpawner $self = shift;
    my $timeout = shift || 0.1;

    my $client = Gearman::Client->new(job_servers => gearman_servers());
    my $task_set = $client->new_task_set;

    while (my $slot = shift @open_slots) {
        $task_set->add_task(
            _ping_name($slot->[SLOT_ID]),
            undef,
            {
                timeout     => $timeout,
                retry_count => 1_000_000,
            }
        );
    }

    $task_set->wait;
}

=item $spawner->add_task($task)

=item $spawner->add_task($funcname, $arg, \%options)

Asynchronously submits a task to a configured Gearman server. May either
take a L<Gearman::Task> object, or the 3 arguments that the Gearman::Task
constructor takes.

=cut

sub add_task {
    my Gearman::WorkerSpawner $self = shift;
    my $task = shift;

    croak "task object or Gearman::Task->new parameters required)"
        unless $task;

    if (ref $task && $task->isa('Gearman::Task')) {
        _gearman_client()->add_task($task);
    }
    else {
        _gearman_client()->add_task(Gearman::Task->new($task, @_));
    }
}

=item $spawner->run_method($funcname, $arg, \%options)

=item $spawner->run_method($funcname, $arg, $callback)

Submits a task but with less boilerplate than add_task. %options is the same as
for add_task. Marshaling of $arg is done for you in a manner compatible with
methods created with Gearman::WorkerSpawner::BaseWorker::register_method. The
on_fail handler will be called if marshalling fails for some reason.

If the second form is used, an empty %options is created and $callback is used
as the on_complete handler.

=cut

sub run_method {
    my Gearman::WorkerSpawner $self = shift;
    my ($methodname, $arg, $options) = @_;

    $methodname .= $self->{method_suffix};

    if (ref $options eq 'CODE') {
        $options = { on_complete => $options };
    }

    # wrap callback with Storable marshaling of arguments
    if (my $cb = delete $options->{on_complete}) {
        $options->{on_complete} = sub {
            my $ref_to_frozen_retval = shift;

            if (!$ref_to_frozen_retval || ref $ref_to_frozen_retval ne 'SCALAR') {
                $options->{on_fail}->('marshaling error') if exists $options->{on_fail};
                return;
            }

            my $rets = eval { thaw($$ref_to_frozen_retval) };
            if ($@) {
                $options->{on_fail}->($@) if exists $options->{on_fail};
                return;
            }
            elsif (ref $rets ne 'ARRAY') {
                $options->{on_fail}->('marshaling error') if exists $options->{on_fail};
                return;
            }

            $cb->(@$rets);
        };
    }

    # serialize parameter
    _gearman_client()->add_task(Gearman::Task->new($methodname, \nfreeze([$arg]), $options));
}

=item method_suffix([$suffix])

Accessor for the suffix which is appended to the method name. Defaults to '_m'.

=cut

sub method_suffix {
    my Gearman::WorkerSpawner $self = shift;
    $self->{method_suffix} = shift if @_;;
    return $self->{method_suffix};
}

=item $spawner->stop_workers([$sig])

Tell all spawned processes to quit (by default, with SIGINT).

=cut

sub stop_workers {
    my Gearman::WorkerSpawner $self = shift;
    my $signal = shift || 'INT';
    $self->{quitting}++;
    kill $signal, keys %{ $self->{kids} };
}

=item DESTROY

Upon destruction, stop_workers is called unless you've already called it.

=cut

sub DESTROY {
    my Gearman::WorkerSpawner $self = shift;
    $self->stop_workers unless $self->{quitting} || $self->{initial_pid} != $$;
}

=item $spawner->gearman_servers()

Returns an arrayref of server host:port specs. If an 'auto' server was
requested, its hostspec is included.

=cut

# singleton server list
my $gearman_servers;
my $gearmand_pid;
sub gearman_servers {
    unless ($gearman_servers) {
        use Carp; Carp::cluck("bad server list") unless defined $gearmand_spec;
        if (ref $gearmand_spec eq 'ARRAY') {
            $gearman_servers = [@$gearmand_spec];
        }
        elsif ($gearmand_spec eq 'auto' || $gearmand_spec eq 'external') {
            # ask OS for open listening port
            my $gearmand_port;
            eval {
                my $sock = IO::Socket::INET->new(
                    Type      => SOCK_STREAM,
                    Proto     => 'tcp',
                    Reuse     => 1,
                    Listen    => 1,
                );
                $gearmand_port = $sock->sockport;
                $sock->close;
            };
            die "failed to create listening socket: $@" if $@;

            die "couldn't find an open port for gearmand" unless $gearmand_port;

            # fork a clingy gearmand
            my $parent_pid = $$;
            my $pid = fork;
            die "fork failed: $!" unless defined $pid;
            if ($pid) {
                $gearman_servers = ["127.0.0.1:$gearmand_port"];
                $gearmand_pid = $pid;
                # don't return until the server is contactable
                while (1) {
                    last if IO::Socket::INET->new(
                        PeerAddr => $gearman_servers->[0],
                    );
                    select undef, undef, undef, 0.1;
                }
            }
            else {
                $0 = 'gearmand-WorkerSpawner';
                Danga::Socket->Reset();
                my $server = Gearman::Server->new;
                $server->create_listening_sock($gearmand_port);
                _run_periodically(sub { exit if getppid != $parent_pid }, 5);
                Danga::Socket->EventLoop();
                exit 0;
            }
        }
        else {
            $gearman_servers = [split /[ ,]+/, $gearmand_spec];
        }
    }
    return $gearman_servers;
}

# historical alias
no warnings 'once';
*gearman_server = \&gearman_servers;

sub gearmand_pid {
    return $gearmand_pid || undef;
}

=back

=head1 INTERNAL METHODS

=over 4

=cut

=item $spawner->_gearman_client()

Returns the L<Gearman::Client::Async> object used by the spawner.

=cut

my $gearman_client;
sub _gearman_client {
    return $gearman_client ||= Gearman::Client::Async->new(job_servers => gearman_servers());
}

=item Gearman::WorkerSpawner->_supervise('My::WorkerClass', @ARGV)

Loads the given L<Gearman::Worker> subclass, then parses additional arguments
as specified by the return value of the worker class' C<options()> class method
via L<Getopt::Long>. These options are passed to the worker object's
constructor and the C<work> method of the worker object is called repeatedly
until either SIG_INT is received or the ppid changes (parent went away).

This class method is automatically executed if Gearman/WorkerSpawner.pm has no
C<caller()>, i.e. if it is run as a script rather than loaded as a module. This
should only be done by other internal methods of this package (add_worker).

=back

=cut

sub _supervise {
    my $spawner_class = shift;

    die "modulino invoked incorrectly, see documentation\n" unless @_;

    my $fileno = shift;
    open my $reader, '<&=', $fileno or die "failed to open pipe: $!\n";

    chomp(my $startup_data = <$reader>); # need this now, so allow blocking read
    my $startup_params = _unserialize($startup_data);

    @INC = @{ $startup_params->{inc} };

    my $worker_class = $startup_params->{class};
    $0 = sprintf "%s supervisor", $worker_class;

    die "no worker class provided" unless $worker_class;
    die "parent went away before I started" if getppid != $startup_params->{ppid};

    if (my $source_file = $startup_params->{source}) {
        unless (eval "require '$source_file'; 1") {
            die "failed to load worker class $worker_class from $source_file: $@";
        }
    }
    else {
        unless (eval "use $worker_class; 1") {
            die "failed to load worker class $worker_class: $@";
        }
    }

    my $self = $startup_params->{spawner};

    $gearman_servers = $self->{gearmand} = $startup_params->{gearmand};
    $self->{supervisor_pid} = $$;

    # set nonblocking since these commands come any time
    IO::Handle::blocking($reader, 0);
    my $read_buf = '';
    my $handler = sub {
        while (my $line = <$reader>) {
            $read_buf .= $line;
            last unless $line =~ /\n$/;
            chomp($read_buf);
            my $slots = _unserialize($read_buf);
            $read_buf = '';
            push @open_slots, @$slots;
        }
    };
    $handler->();

    # spin up initial workers
    $self->_check_workers;

    # watch for parent going away
    _run_periodically(sub { $self->_cleanup() if getppid != $startup_params->{ppid} }, 5);
    $SIG{INT} = $SIG{TERM} = sub { $self->_cleanup };

    # install handler for parent asking to start more workers
    Danga::Socket->AddOtherFds(fileno $reader, $handler);

    # periodically check for children needing replacement
    _run_periodically(sub { $self->_check_workers }, $self->{check_period});

    Danga::Socket->EventLoop;
    exit 1;
}

# try to reap any worker processes, and start up any that are missing. also
# starts up workers for the first time after they're added
sub _check_workers {
    my Gearman::WorkerSpawner $self = shift;

    # reap slots from dead kids
    my %reaped = $self->_reap();

    for my $pid (keys %reaped) {
        my $open_slot = $reaped{$pid}{slot};
        if (defined $open_slot) {
            push @open_slots, $open_slot;
        }
        else {
            warn "dead child $pid didn't own a slot";
        }
    }

    return if $self->{quitting};

    return unless @open_slots;

    # refill lowest slots first
    @open_slots = sort {$a->[SLOT_NUM]<=>$b->[SLOT_NUM]} @open_slots;

    while (my $slot = shift @open_slots) {
        my $pid = fork;
        die "fork failed: $!\n" unless defined $pid;

        unless ($pid) {
            # child is a worker
            $SIG{INT} = $SIG{TERM} = sub { $self->_cleanup };
            $self->_do_work($slot);
            exit 1;
        }

        # parent is still supervisor
        $self->{kids}{$pid}{slot} = $slot;
    }
}

# create a worker and run it forever
sub _do_work {
    my Gearman::WorkerSpawner $self = shift;
    my $slot = shift;

    my $params = $slot->[SLOT_PARAMS];
    my $worker_class = $params->{class};
    $0 = sprintf "%s #%d", $worker_class, $slot->[SLOT_NUM];

    my $worker = $worker_class->new($slot->[SLOT_NUM], $params->{config}, gearman_servers());

    die "failed to create $worker_class object" unless $worker;

    $worker->job_servers(@{ $self->{gearmand} });

    # each worker gets a unique function so we can ping it in wait_until_all_ready
    $worker->register_function(_ping_name($slot->[SLOT_ID]) => sub {
        if ($worker->can('unregister_function')) {
            # remove the function so it doesn't pollute server "status" command
            $worker->unregister_function(_ping_name($slot->[SLOT_ID]));
        }
        return 1;
    });

    $SIG{INT} = sub { $quitting = 1 };
    while (!$quitting) {
        {
            eval {
                $worker->work(stop_if => sub {1});
            };
            $@ && warn "$worker_class [$$] failed: $@";
        }

        $worker->post_work if $worker->can('post_work');

        # bail if supervisor went away
        $quitting++ if getppid != $self->{supervisor_pid};
    }
    exit 0;
}

# takes a subref and a number of seconds, and runs the sub that often
sub _run_periodically {
    my $sub    = shift;
    my $period = shift;
    my $recycler;
    $recycler = sub {
        $sub->();
        Danga::Socket->AddTimer($period, $recycler);
    };
    Danga::Socket->AddTimer(0, $recycler);
}

sub _serialize {
    return join '', unpack('h*', nfreeze shift), "\n";
}

sub _unserialize {
    my $frozen = shift;
    return thaw pack 'h*', $frozen;
}

sub _ping_name {
    my $id = shift;
    return "ping_$id";
}

# consume kids and returns a hash $self->{kids} contents for reaped pids, or
# undef for unknown kids
sub _reap {
    my Gearman::WorkerSpawner $self = shift;
    my %reaped;
    while ((my $pid = waitpid(-1, WNOHANG)) > 0) {
        $reaped{$pid} = delete $self->{kids}{$pid};
        $reaped{$pid}{exit_code} = $?;
    }
    return %reaped;
}

sub _cleanup {
    my $self = shift;
    return if $quitting++;
    my @kids = keys %{ $self->{kids} };
    push @kids, $gearmand_pid if $gearmand_pid;
    kill 'INT', @kids;
    exit 0;
}

if (!caller()) {
    # we're being called as a script, not a module, presumably from exec in _spawn_workers.
    __PACKAGE__->_supervise(@ARGV);
}

1;

__END__

=head1 BUGS

=item * add_worker may sleep in attempt to recontact an unreachable supervisor
process. This is detrimental if a worker is added after the Danga::Socket event
loop is running.

=head1 SEE ALSO

L<Gearman::Server>

L<Gearman::Worker>

L<Gearman::Task>

L<Gearman::Client::Async>

L<Getopt::Long>

brian d foy's modulino article: L<http://www.ddj.com/dept/debug/184416165>

=head1 AUTHOR

Adam Thomason, E<lt>athomason@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007-2011 by Say Media Inc, E<lt>cpan@sixapart.comE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
