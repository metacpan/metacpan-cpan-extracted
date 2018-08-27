package Gearman::Taskset;
use version ();
$Gearman::Taskset::VERSION = version->declare("2.004.015");

use strict;
use warnings;

=head1 NAME

Gearman::Taskset - a taskset in Gearman, from the point of view of a L<Gearman::Client>

=head1 SYNOPSIS

    use Gearman::Client;
    my $client = Gearman::Client->new;

    # waiting on a set of tasks in parallel
    my $ts = $client->new_task_set;
    $ts->add_task( "add" => "1+2", {...});
    $ts->wait();


=head1 DESCRIPTION

Gearman::Taskset is a L<Gearman::Client>'s representation of tasks queue

=head1 METHODS

=cut

use fields (
    qw/
        waiting
        client
        need_handle
        default_sock
        default_sockaddr
        loaned_sock
        cancelled
        hooks
        /
);

use Carp          ();
use Gearman::Util ();
use Gearman::ResponseParser::Taskset;
use IO::Select;

# i thought about weakening taskset's client, but might be too weak.
use Scalar::Util ();
use Socket       ();
use Storable     ();
use Time::HiRes  ();

=head2 new($client)

=cut

sub new {
    my ($self, $client) = @_;
    (Scalar::Util::blessed($client) && $client->isa("Gearman::Client"))
        || Carp::croak
        "provided client argument is not a Gearman::Client reference";

    unless (ref $self) {
        $self = fields::new($self);
    }

    # { handle => [Task, ...] }
    $self->{waiting}     = {};
    $self->{need_handle} = [];
    $self->{client}      = $client;

    # { hostport => socket }
    $self->{loaned_sock} = {};

    # bool, if taskset has been cancelled mid-processing
    $self->{cancelled} = 0;

    # { hookname => coderef }
    $self->{hooks} = {};

    # default socket (non-merged requests)
    $self->{default_sock} = undef;

    # $self->client()->_js_str($self->{default_sock});
    $self->{default_sockaddr} = undef;

    return $self;
} ## end sub new

sub DESTROY {
    my $self = shift;

    # During global cleanup this may be called out of order, and the client my not exist in the taskset.
    return unless $self->client;

    if ($self->{default_sock}) {
        $self->client->_sock_cache($self->{default_sockaddr},
            $self->{default_sock});
    }

    keys %{ $self->{loaned_sock} };
    while (my ($hp, $sock) = each %{ $self->{loaned_sock} }) {
        $self->client->_sock_cache($hp, $sock);
    }
} ## end sub DESTROY

#=head2 run_hook($name)
#
#run a hook callback if defined
#
#=cut

sub run_hook {
    my ($self, $name) = (shift, shift);
    ($name && $self->{hooks}->{$name}) || return;

    eval { $self->{hooks}->{$name}->(@_) };

    warn "Gearman::Taskset hook '$name' threw error: $@\n" if $@;
} ## end sub run_hook

#=head2 add_hook($name, [$cb])
#
#add a hook
#
#=cut

sub add_hook {
    my ($self, $name, $cb) = @_;
    $name || return;

    if ($cb) {
        $self->{hooks}->{$name} = $cb;
    }
    else {
        delete $self->{hooks}->{$name};
    }
} ## end sub add_hook

#=head2 client ()
#
#B<return> L<Gearman::Client>
#
#=cut

# this method is part of the "Taskset" interface, also implemented by
# Gearman::Client::Async, where no tasksets make sense, so instead the
# Gearman::Client::Async object itself is also its taskset.  (the
# client tracks all tasks).  so don't change this, without being aware
# of Gearman::Client::Async.  similarly, don't access $ts->{client} without
# going via this accessor.

sub client {
    return shift->{client};
}

#=head2 cancel()
#
#Close sockets, cleanup internals.
#
#=cut

sub cancel {
    my $self = shift;

    $self->{cancelled} = 1;

    if ($self->{default_sock}) {
        close($self->{default_sock});
        $self->{default_sock} = undef;
    }

    foreach my $sock (values %{ $self->{loaned_sock} }) {
        $sock->close;
    }

    $self->{client}      = undef;
    $self->{loaned_sock} = {};
    $self->{need_handle} = [];
    $self->{waiting}     = {};
} ## end sub cancel

#
# _get_loaned_sock($js)
#

sub _get_loaned_sock {
    my ($self, $js) = @_;
    my $js_str = $self->client()->_js_str($js);

    if (my $sock = $self->{loaned_sock}{$js_str}) {
        return $sock if $sock->connected;
        delete $self->{loaned_sock}{$js_str};
    }

    my $sock = $self->client()->_get_js_sock($js);

    return $self->{loaned_sock}{$js_str} = $sock;
} ## end sub _get_loaned_sock

=head2 wait(%opts)

Waits for a response from the job server for any of the tasks listed
in the taskset. Will call the I<on_*> handlers for each of the tasks
that have been completed, updated, etc.  Doesn't return until
everything has finished running or failing.

=cut

sub wait {
    my ($self, %opts) = @_;
    my ($timeout, $given_timeout_s);
    if (exists $opts{timeout}) {
        $timeout = delete $opts{timeout};
        if (defined $timeout) {
            ## keep the given timeout value for the failure reason
            #  Handles issue #35
            #  https://github.com/p-alik/perl-Gearman/issues/35
            $given_timeout_s = $timeout;
            $timeout += Time::HiRes::time();
        }
    }

    Carp::carp "Unknown options: "
        . join(',', keys %opts)
        . " passed to Taskset->wait."
        if keys %opts;

    # fd -> Gearman::ResponseParser object
    my %parser;

    my $cb = sub {
        my ($fd) = shift;

        my $parser = $parser{$fd} ||= Gearman::ResponseParser::Taskset->new(
            source  => $fd,
            taskset => $self
        );
        eval {
            $parser->parse_sock($fd);
            1;
        } or do {

            # TODO this should remove the fd from the list, and reassign any tasks to other jobserver, or bail.
            # We're not in an accessible place here, so if all job servers fail we must die to prevent hanging.
            Carp::croak("Job server failure: $@");
            } ## end do
    };

    my $io = IO::Select->new($self->{default_sock},
        values %{ $self->{loaned_sock} });

    my $pending_sock;
    foreach ($io->handles) {
        (ref($_) eq "IO::Socket::SSL" && $_->pending()) || next;

        $pending_sock = $_;
        last;
    }

    if ($pending_sock) {
        return $cb->($pending_sock);
    }

    while (!$self->{cancelled} && keys %{ $self->{waiting} }) {
        my $time_left = $timeout ? $timeout - Time::HiRes::time() : 0.5;
        my $nfound = select($io->bits(), undef, undef, $time_left);
        if ($timeout && $time_left <= 0) {
            ## Attempt to fix
            #  https://github.com/p-alik/perl-Gearman/issues/33
            #  Mark all tasks of that taskset failed.
            #  Get all waiting tasks and call their "fail" method one by one
            #  with the failure reason.
            for (values %{ $self->{waiting} }) {
                for (@$_) {
                    my $func = $_->func;
                    ## use the given timeout here
                    #  Handles issue #35
                    #  https://github.com/p-alik/perl-Gearman/issues/35
                    $_->fail("Task $func elapsed timeout [${given_timeout_s}s]");
                }
            } ## end for (values %{ $self->{...}})
            $self->cancel;
            return;
        } ## end if ($timeout && $time_left...)

        next if !$nfound;
        foreach my $fd ($io->can_read()) {
            $cb->($fd);
        }
    } ## end while (!$self->{cancelled...})
} ## end sub wait

=head2 add_task(Gearman::Task)

=head2 add_task($func, <$scalar | $scalarref>, <$uniq | $opts_hr>

Adds a task to the taskset.  Three different calling conventions are available.

C<$opts_hr> see L<Gearman::Task>

=cut

sub add_task {
    my $self = shift;
    my $task = $self->client()->_get_task_from_args(@_);

    $task->taskset($self);

    $self->run_hook('add_task', $self, $task);

    my $jssock = $task->{jssock};

    return $task->fail("undefined jssock") unless ($jssock);

    my $req = $task->pack_submit_packet($self->client);
    Gearman::Util::send_req($jssock, \$req)
        || Carp::croak "Error sending data to job server";

    push @{ $self->{need_handle} }, $task;
    while (@{ $self->{need_handle} }) {
        my $rv
            = $self->_wait_for_packet($jssock,
            $self->client()->{command_timeout});
        if (!$rv) {

            # ditch it, it failed.
            # this will resubmit it if it failed.
            shift @{ $self->{need_handle} };
            return $task->fail(
                join(' ',
                    "no rv on waiting for packet",
                    defined($rv) ? $rv : $!)
            );
        } ## end if (!$rv)
    } ## end while (@{ $self->{need_handle...}})

    return $task->handle;
} ## end sub add_task

#
# _get_default_sock()
# used in Gearman::Task->taskset only
#
sub _get_default_sock {
    my $self = shift;
    return $self->{default_sock} if $self->{default_sock};

    my $getter = sub {
        my $js = shift;
        return $self->{loaned_sock}{$js}
            || $self->client()->_get_js_sock($js);
    };

    my ($js, $jss) = $self->client()->_get_random_js_sock($getter);
    return unless $jss;

    my $js_str = $self->client()->_js_str($js);
    $self->{loaned_sock}{$js_str} ||= $jss;

    $self->{default_sock}     = $jss;
    $self->{default_sockaddr} = $js_str;

    return $jss;
} ## end sub _get_default_sock

#
#  _get_hashed_sock($hv)
#
# only used in Gearman::Task->taskset only
#
# return a socket
sub _get_hashed_sock {
    my $self = shift;
    my $hv   = shift;
    my ($js_count, @job_servers)
        = ($self->client()->{js_count}, $self->client()->job_servers());
    my $sock;
    for (my $off = 0; $off < $js_count; $off++) {
        my $idx = ($hv + $off) % ($js_count);
        $sock = $self->_get_loaned_sock($job_servers[$idx]);
        last;
    }

    return $sock;
} ## end sub _get_hashed_sock

#
#  _wait_for_packet($sock, $timeout)
#
# $sock socket to singularly read from
#
# returns boolean when given a sock to wait on.
# otherwise, return value is undefined.
sub _wait_for_packet {
    my ($self, $sock, $timeout) = @_;
    my $res = Gearman::Util::read_res_packet($sock, \my $err, $timeout);
    $err && Carp::croak("reading response packet failed: $err");

    return $res ? $self->process_packet($res, $sock) : 0;
} ## end sub _wait_for_packet

#
# _is_port($sock)
#
# return hostport || ipport
#
sub _ip_port {
    my ($self, $sock) = @_;
    $sock || return;

    my $pn = getpeername($sock);
    $pn || return;

    # look for a hostport in loaned_sock
    my $hostport;
    my @k = keys %{ $self->{loaned_sock} };
    while (!$hostport && (my $hp = shift @k)) {
        my $s = $self->{loaned_sock}->{$hp};
        $s || next;
        if ($sock == $s) {
            $hostport = $hp;

            # last;
        }
    } ## end while (!$hostport && (my ...))

    # hopefully it solves client->get_status mismatch
    $hostport && return $hostport;

    my $fam = Socket::sockaddr_family($pn);
    my ($port, $iaddr)
        = ($fam == Socket::AF_INET6)
        ? Socket::sockaddr_in6($pn)
        : Socket::sockaddr_in($pn);

    my $addr = Socket::inet_ntop($fam, $iaddr);

    return join ':', $addr, $port;
} ## end sub _ip_port

#
# _fail_jshandle($shandle, $type, [$message])
#
# note the failure of a task given by its jobserver-specific handle
#
sub _fail_jshandle {
    my ($self, $shandle, $type, $msg) = @_;
    $shandle
        or Carp::croak "_fail_jshandle() called without shandle parameter";

    my $task_list = $self->{waiting}{$shandle}
        or Carp::croak "Got $type for unknown handle: $shandle";

    my $task = shift @{$task_list};
    (Scalar::Util::blessed($task) && $task->isa("Gearman::Task"))
        || Carp::croak "task_list is empty on $type for handle $shandle\n";

    $task->fail($msg || "jshandle fail");

    delete $self->{waiting}{$shandle} unless @{$task_list};
} ## end sub _fail_jshandle

#=head2 process_packet($res, $sock)
#
# process response packet
#
#=cut

sub process_packet {
    my ($self, $res, $sock) = @_;

    my $qr     = qr/(.+?)\0/;
    my %assert = (
        task => sub {
            my ($task, $msg) = @_;
            (Scalar::Util::blessed($task) && $task->isa("Gearman::Task"))
                || Carp::croak $msg;
        }
    );
    my %type = (
        job_created => sub {
            my ($blob) = shift;
            my $task = shift @{ $self->{need_handle} };
            $assert{task}
                ->($task, "Got an unexpected job_created notification");
            my $shandle = $blob;
            my $ipport  = $self->_ip_port($sock);

            # did sock become disconnected in the meantime?
            if (!$ipport) {
                $self->_fail_jshandle($shandle, "job_created");
                return 1;
            }

            $task->handle("$ipport//$shandle");
            return 1 if $task->{background};
            push @{ $self->{waiting}{$shandle} ||= [] }, $task;
            return 1;
        },
        work_complete => sub {
            my ($blob) = shift;
            ($blob =~ /^$qr/)
                or Carp::croak "Bogus work_complete from server";
            $blob =~ s/^$qr//;
            my $shandle = $1;

            my $task_list = $self->{waiting}{$shandle};
            my $task      = shift @{$task_list};
            $assert{task}->(
                $task,
                "task_list is empty on work_complete for handle $shandle"
            );

            $task->complete(\$blob);
            delete $self->{waiting}{$shandle} unless @{$task_list};

            return 1;
        },
        work_data => sub {
            my ($blob) = shift;
            $blob =~ s/^(.+?)\0//
                or Carp::croak "Bogus work_data from server";
            my $shandle = $1;

            my $task_list = $self->{waiting}{$shandle};
            my $task      = $task_list->[0];
            $assert{task}->($task,
                "task_list is empty on work_data for handle $shandle");

            $task->data(\$blob);

            return 1;
        },
        work_warning => sub {
            my ($blob) = shift;
            $blob =~ s/^(.+?)\0//
                or Carp::croak "Bogus work_warning from server";
            my $shandle = $1;

            my $task_list = $self->{waiting}{$shandle};
            my $task      = $task_list->[0];
            $assert{task}->(
                $task, "task_list is empty on work_warning for handle $shandle"
            );

            $task->warning(\$blob);

            return 1;
        },
        work_exception => sub {
            my ($blob) = shift;
            ($blob =~ /^$qr/)
                or Carp::croak "Bogus work_exception from server";
            $blob =~ s/^$qr//;
            my $shandle   = $1;
            my $task_list = $self->{waiting}{$shandle};
            my $task      = shift @{$task_list};
            $assert{task}->(
                $task,
                "task_list is empty on work_exception for handle $shandle"
            );

            #FIXME we have to freeze $blob because Task->exception expected it in this form.
            # The only reason I see to do it so, is Worker->work implementation. With Gearman::Server it uses nfreeze for exception value.
            $task->exception(\Storable::freeze(\$blob));

            delete $self->{waiting}{$shandle} unless @{$task_list};

            return 1;
        },
        work_fail => sub {
            $self->_fail_jshandle(shift, "work_fail");
            return 1;
        },
        work_status => sub {
            my ($blob) = shift;
            my ($shandle, $nu, $de) = split(/\0/, $blob);
            my $task_list = $self->{waiting}{$shandle};
            ref($task_list) eq "ARRAY" && scalar(@{$task_list})
                or Carp::croak "Got work_status for unknown handle: $shandle";

            # FIXME: the server is (probably) sending a work_status packet for each
            # interested client, even if the clients are the same, so probably need
            # to fix the server not to do that.  just put this FIXME here for now,
            # though really it's a server issue.
            foreach my $task (@{$task_list}) {
                $task->status($nu, $de);
            }

            return 1;
        },
    );

    defined($type{ $res->{type} })
        || Carp::croak
        "Unimplemented packet type: $res->{type} [${$res->{blobref}}]";

    return $type{ $res->{type} }->(${ $res->{blobref} });
} ## end sub process_packet

1;
