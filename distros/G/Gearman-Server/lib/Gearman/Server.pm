package Gearman::Server;
use version;
$Gearman::Server::VERSION = qv("v1.130.1");

use strict;
use warnings;

=head1 NAME

Gearman::Server - function call "router" and load balancer

=head1 DESCRIPTION

You run a Gearman server (or more likely, many of them for both
high-availability and load balancing), then have workers (using
L<Gearman::Worker> from the Gearman module, or libraries for other
languages) register their ability to do certain functions to all of
them, and then clients (using L<Gearman::Client>,
L<Gearman::Client::Async>, etc) request work to be done from one of
the Gearman servers.

The servers connect them, routing function call requests to the
appropriate workers, multiplexing responses to duplicate requests as
requested, etc.

More than likely, you want to use the provided L<bin/gearmand> wrapper
script, and not use Gearman::Server directly.

=cut

use Carp qw(croak);
use Gearman::Server::Client;
use Gearman::Server::Listener;
use Gearman::Server::Job;
use IO::Handle ();
use Socket qw/
    IPPROTO_TCP
    SOL_SOCKET
    SOCK_STREAM
    AF_UNIX
    SOCK_STREAM
    PF_UNSPEC
    /;
use Sys::Hostname ();

use fields (
    'client_map',      # fd -> Client
    'sleepers',        # func -> { "Client=HASH(0xdeadbeef)" => Client }
    'sleepers_list',   # func -> [ Client, ... ], ...
    'job_queue',       # job_name -> [Job, Job*]  (key only exists if non-empty)
    'job_of_handle',   # handle -> Job
    'max_queue',       # func -> configured max jobqueue size
    'job_of_uniq',     # func -> uniq -> Job
    'handle_ct',       # atomic counter
    'handle_base',     # atomic counter
    'listeners',       # arrayref of listener objects
    'wakeup',          # number of workers to wake
    'wakeup_delay',    # seconds to wait before waking more workers
    'wakeup_timers',   # func -> timer, timer to be canceled or adjusted
                       # when job grab/inject is called
);

=head1 METHODS

=head2 new

  $server_object = Gearman::Server->new( %options )

Creates and returns a new Gearman::Server object, which attaches itself to the Danga::Socket event loop. The server will begin operating when the Danga::Socket runloop is started. This means you need to start up the runloop before anything will happen.

Options:

=over

=item port

Specify a port which you would like the Gearman::Server to listen on for TCP connections (not necessary, but useful)

=back

=cut

sub new {
    my ($class, %opts) = @_;
    my $self = ref $class ? $class : fields::new($class);

    $self->{client_map}    = {};
    $self->{sleepers}      = {};
    $self->{sleepers_list} = {};
    $self->{job_queue}     = {};
    $self->{job_of_handle} = {};
    $self->{max_queue}     = {};
    $self->{job_of_uniq}   = {};
    $self->{listeners}     = [];
    $self->{wakeup}        = 3;
    $self->{wakeup_delay}  = .1;
    $self->{wakeup_timers} = {};

    $self->{handle_ct}   = 0;
    $self->{handle_base} = "H:" . Sys::Hostname::hostname() . ":";

    my $port = delete $opts{port};

    my $wakeup = delete $opts{wakeup};

    if (defined $wakeup) {
        die "Invalid value passed in wakeup option"
            if $wakeup < 0 && $wakeup != -1;
        $self->{wakeup} = $wakeup;
    }

    my $wakeup_delay = delete $opts{wakeup_delay};

    if (defined $wakeup_delay) {
        die "Invalid value passed in wakeup_delay option"
            if $wakeup_delay < 0 && $wakeup_delay != -1;
        $self->{wakeup_delay} = $wakeup_delay;
    }

    croak("Unknown options") if %opts;
    $self->create_listening_sock($port);

    return $self;
} ## end sub new

sub debug {
    my ($self, $msg) = @_;

    #warn "$msg\n";
}

=head2 create_listening_sock

  $server_object->create_listening_sock( $portnum, \%options )

Add a TCP port listener for incoming Gearman worker and client connections.  Options:

=over 4

=item accept_per_loop

=item local_addr

Bind socket to only this address.

=back

=cut

sub create_listening_sock {
    my ($self, $portnum, %opts) = @_;

    my $accept_per_loop = delete $opts{accept_per_loop};
    my $local_addr      = delete $opts{local_addr};

    warn "Extra options passed into create_listening_sock: "
        . join(', ', keys %opts) . "\n"
        if keys %opts;

    my $ssock = IO::Socket::INET->new(
        LocalPort => $portnum,
        Type      => SOCK_STREAM,
        Proto     => IPPROTO_TCP,
        Blocking  => 0,
        Reuse     => 1,
        Listen    => 1024,
        ($local_addr ? (LocalAddr => $local_addr) : ())
    ) or die "Error creating socket: $@\n";

    my $listeners = $self->{listeners};
    push @$listeners,
        Gearman::Server::Listener->new($ssock, $self,
        accept_per_loop => $accept_per_loop);

    return $ssock;
} ## end sub create_listening_sock

sub new_client {
    my ($self, $sock) = @_;
    my $client = Gearman::Server::Client->new($sock, $self);
    $client->watch_read(1);
    $self->{client_map}{ $client->{fd} } = $client;
} ## end sub new_client

sub note_disconnected_client {
    my ($self, $client) = @_;
    delete $self->{client_map}{ $client->{fd} };
}

sub clients {
    my $self = shift;
    return values %{ $self->{client_map} };
}

# Returns a socket that is connected to the server, we can then use this
# socket with a Gearman::Client::Async object to run clients and servers in the
# same thread.
sub to_inprocess_server {
    my $self = shift;

    my ($psock, $csock);
    socketpair($csock, $psock, AF_UNIX, SOCK_STREAM, PF_UNSPEC)
        or die "socketpair: $!";

    $csock->autoflush(1);
    $psock->autoflush(1);

    IO::Handle::blocking($csock, 0);
    IO::Handle::blocking($psock, 0);

    my $client = Gearman::Server::Client->new($csock, $self);

    my ($package, $file, $line) = caller;
    $client->{peer_ip} = "[$package|$file|$line]";
    $client->watch_read(1);
    $self->{client_map}{ $client->{fd} } = $client;

    return $psock;
} ## end sub to_inprocess_server

=head2 start_worker

  $pid = $server_object->start_worker( $prog )

  ($pid, $client) = $server_object->start_worker( $prog )

Fork and start a worker process named by C<$prog> and returns the pid (or pid and client object).

=cut

sub start_worker {
    my ($self, $prog) = @_;

    my ($psock, $csock);
    socketpair($csock, $psock, AF_UNIX, SOCK_STREAM, PF_UNSPEC)
        or die "socketpair: $!";

    $csock->autoflush(1);
    $psock->autoflush(1);

    my $pid = fork;
    unless (defined $pid) {
        warn "fork failed: $!\n";
        return undef;
    }

    # child process
    unless ($pid) {
        local $ENV{'GEARMAN_WORKER_USE_STDIO'} = 1;
        close(STDIN);
        close(STDOUT);
        open(STDIN, '<&', $psock)
            or die "Unable to dup socketpair to STDIN: $!";
        open(STDOUT, '>&', $psock)
            or die "Unable to dup socketpair to STDOUT: $!";
        if (UNIVERSAL::isa($prog, "CODE")) {
            $prog->();
            exit 0;    # shouldn't get here.  subref should exec.
        }
        exec $prog;
        die "Exec failed: $!";
    } ## end unless ($pid)

    close($psock);

    IO::Handle::blocking($csock, 0);
    my $sock = $csock;

    my $client = Gearman::Server::Client->new($sock, $self);

    $client->{peer_ip} = "[gearman_child]";
    $client->watch_read(1);
    $self->{client_map}{ $client->{fd} } = $client;
    return wantarray ? ($pid, $client) : $pid;
} ## end sub start_worker

sub enqueue_job {
    my ($self, $job, $highpri) = @_;
    my $jq = ($self->{job_queue}{ $job->{func} } ||= []);

    if (defined(my $max_queue_size = $self->{max_queue}{ $job->{func} })) {
        $max_queue_size
            --;    # Subtract one, because we're about to add one more below.
        while (@$jq > $max_queue_size) {
            my $delete_job = pop @$jq;
            my $msg        = Gearman::Util::pack_res_command("work_fail",
                $delete_job->handle);
            $delete_job->relay_to_listeners($msg);
            $delete_job->note_finished;
        } ## end while (@$jq > $max_queue_size)
    } ## end if (defined(my $max_queue_size...))

    if ($highpri) {
        unshift @$jq, $job;
    }
    else {
        push @$jq, $job;
    }

    $self->{job_of_handle}{ $job->{'handle'} } = $job;
} ## end sub enqueue_job

sub wake_up_sleepers {
    my ($self, $func) = @_;

    if (my $existing_timer = delete($self->{wakeup_timers}->{$func})) {
        $existing_timer->cancel();
    }

    return unless $self->_wake_up_some($func);

    my $delay = $self->{wakeup_delay};

    # -1 means don't setup a timer. 0 actually means go as fast as we can, cooperatively.
    return if $delay == -1;

    # If we're only going to wakeup 0 workers anyways, don't set up a timer.
    return if $self->{wakeup} == 0;

    my $timer = Danga::Socket->AddTimer(
        $delay,
        sub {
            # Be sure to not wake up more sleepers if we have no jobs in the queue.
            # I know the object definition above says I can trust the func element to determine
            # if there are items in the list, but I'm just gonna be safe, rather than sorry.
            return unless @{ $self->{job_queue}{$func} || [] };
            $self->wake_up_sleepers($func);
        }
    );
    $self->{wakeup_timers}->{$func} = $timer;
} ## end sub wake_up_sleepers

# Returns true when there are still more workers to wake up
# False if there are no sleepers
sub _wake_up_some {
    my ($self, $func) = @_;
    my $sleepmap   = $self->{sleepers}{$func}      or return;
    my $sleeporder = $self->{sleepers_list}{$func} or return;

    # TODO SYNC UP STATE HERE IN CASE TWO LISTS END UP OUT OF SYNC

    my $max = $self->{wakeup};

    while (@$sleeporder) {
        my Gearman::Server::Client $c = shift @$sleeporder;
        next if $c->{closed} || !$c->{sleeping};
        if ($max-- <= 0) {
            unshift @$sleeporder, $c;
            return 1;
        }
        delete $sleepmap->{"$c"};
        $c->res_packet("noop");
        $c->{sleeping} = 0;
    } ## end while (@$sleeporder)

    delete $self->{sleepers}{$func};
    delete $self->{sleepers_list}{$func};
    return;
} ## end sub _wake_up_some

sub on_client_sleep {
    my $self = shift;
    my Gearman::Server::Client $cl = shift;

    foreach my $cd (@{ $cl->{can_do_list} }) {

        # immediately wake the sleeper up if there are things to be done
        if ($self->{job_queue}{$cd}) {
            $cl->res_packet("noop");
            $cl->{sleeping} = 0;
            return;
        }

        my $sleepmap = ($self->{sleepers}{$cd} ||= {});
        my $count = $sleepmap->{"$cl"}++;

        next if $count >= 2;

        my $sleeporder = ($self->{sleepers_list}{$cd} ||= []);

        # The idea here is to keep workers at the head of the list if they are doing work, hopefully
        # this will allow extra workers that aren't needed to actually go 'idle' safely.
        my $jobs_done = $cl->{jobs_done_since_sleep};

        if ($jobs_done) {
            unshift @$sleeporder, $cl;
        }
        else {
            push @$sleeporder, $cl;
        }

        $cl->{jobs_done_since_sleep} = 0;

    } ## end foreach my $cd (@{ $cl->{can_do_list...}})
} ## end sub on_client_sleep

sub jobs_outstanding {
    my Gearman::Server $self = shift;
    return scalar keys %{ $self->{job_queue} };
}

sub jobs {
    my Gearman::Server $self = shift;
    return values %{ $self->{job_of_handle} };
}

sub job_by_handle {
    my ($self, $handle) = @_;
    return $self->{job_of_handle}{$handle};
}

sub note_job_finished {
    my Gearman::Server $self     = shift;
    my Gearman::Server::Job $job = shift;

    if (my Gearman::Server::Client $worker = $job->worker) {
        $worker->{jobs_done_since_sleep}++;
    }

    if (length($job->{uniq})) {
        delete $self->{job_of_uniq}{ $job->{func} }{ $job->{uniq} };
    }
    delete $self->{job_of_handle}{ $job->{handle} };
} ## end sub note_job_finished

# <0/undef/"" to reset.  else integer max depth.
sub set_max_queue {
    my ($self, $func, $max) = @_;
    if (defined $max && length $max && $max >= 0) {
        $self->{max_queue}{$func} = int($max);
    }
    else {
        delete $self->{max_queue}{$func};
    }
} ## end sub set_max_queue

sub new_job_handle {
    my $self = shift;
    return $self->{handle_base} . (++$self->{handle_ct});
}

sub job_of_unique {
    my ($self, $func, $uniq) = @_;
    return undef unless $self->{job_of_uniq}{$func};
    return $self->{job_of_uniq}{$func}{$uniq};
}

sub set_unique_job {
    my ($self, $func, $uniq, $job) = @_;
    $self->{job_of_uniq}{$func} ||= {};
    $self->{job_of_uniq}{$func}{$uniq} = $job;
}

sub grab_job {
    my ($self, $func) = @_;
    return undef unless $self->{job_queue}{$func};

    my $empty = sub {
        delete $self->{job_queue}{$func};
        return undef;
    };

    my Gearman::Server::Job $job;
    while (1) {
        $job = shift @{ $self->{job_queue}{$func} };
        return $empty->() unless $job;
        return $job unless $job->require_listener;

        foreach my Gearman::Server::Client $c (@{ $job->{listeners} }) {
            return $job if $c && !$c->{closed};
        }
        $job->note_finished(0);
    } ## end while (1)
} ## end sub grab_job

1;
__END__

=head1 SEE ALSO

L<bin/gearmand>

=cut
