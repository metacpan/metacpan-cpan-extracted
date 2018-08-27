package Gearman::Client;
use version ();
$Gearman::Client::VERSION = version->declare("2.004.015");

use strict;
use warnings;

=head1 NAME

Gearman::Client - Client for gearman distributed job system

=head1 SYNOPSIS

    use Gearman::Client;
    my $client = Gearman::Client->new;
    $client->job_servers(
      '127.0.0.1',
      {
        host      => '10.0.0.1',
        port      => 4730,
        socket_cb => sub {...},
        use_ssl   => 1,
        ca_file   => ...,
        cert_file => ...,
        key_file  => ...,
      }
    );

    # running a single task
    my $result_ref = $client->do_task("add", "1+2", {
      on_fail => sub {...},
      on_complete => sub {...}
    });
    print "1 + 2 = $$result_ref\n";

    # waiting on a set of tasks in parallel
    my $taskset = $client->new_task_set;
    $taskset->add_task( "add" => "1+2", {
       on_complete => sub { ... }
    });
    $taskset->add_task( "divide" => "5/0", {
       on_fail => sub { print "divide by zero error!\n"; },
    });
    $taskset->wait;


=head1 DESCRIPTION

I<Gearman::Client> is a client class for the Gearman distributed job
system, providing a framework for sending jobs to one or more Gearman
servers. These jobs are then distributed out to a farm of workers.

Callers instantiate a I<Gearman::Client> object and from it dispatch
single tasks, sets of tasks, or check on the status of tasks.

I<Gearman::Client> is derived from L<Gearman::Objects>

=head1 USAGE

=head2 Gearman::Client->new(%options)

Creates a new I<Gearman::Client> object, and returns the object.

If I<%options> is provided, initializes the new client object with the
settings in I<%options>, which can contain:

=over 4

=item

exceptions

If true, the client sends an L<OPTION_REQ exceptions|http://gearman.org/protocol/> request for each connection to the job server.
This causes job server to forward WORK_EXCEPTION packets to the client.

=item

job_servers

List of job servers. Value should be an array reference, hash reference
or scalar.

Calls L<Gearman::Objects> to set I<job_servers>

=item

prefix

Calls I<prefix> (see L<Gearman::Objects>) to set the prefix / namespace.

=item

command_timeout

Maximum time a gearman command should take to get a result (not a job timeout)

default: 30 seconds

=item

backoff_max

Max number of failed connection attempts before an job server will be temporary disabled

default: 90

=back

=head1 EXAMPLES

=head2 Summation

This is an example client that sends off a request to sum up a list of
integers.

    use Gearman::Client;
    use Storable qw( freeze );
    my $client = Gearman::Client->new;
    $client->job_servers('127.0.0.1');
    my $tasks = $client->new_task_set;
    my $handle = $tasks->add_task(sum => freeze([ 3, 5 ]), {
        on_complete => sub { print ${ $_[0] }, "\n" }
    });
    $tasks->wait;

See the L<Gearman::Worker> documentation for the worker for the I<sum>
function.

=head1 NOTE

If you intend using UTF-8 data with SSL based connection,
beware there is no UTF-8 support in underlying L<Net::SSLeay>.
L<perlunicode/"Forcing-Unicode-in-Perl-(Or-Unforcing-Unicode-in-Perl)"> describes proper workarounds.

=cut

use base 'Gearman::Objects';

use fields (
    'sock_info',    # hostport -> hashref
    'hooks',        # hookname -> coderef
    'exceptions',
    'backoff_max',

    # maximum time a gearman command should take to get a result (not a job timeout)
    'command_timeout',
);

use Carp;
use Gearman::Task;
use Gearman::Taskset;
use Gearman::JobStatus;
use Time::HiRes;

sub new {
    my ($self, %opts) = @_;
    unless (ref $self) {
        $self = fields::new($self);
    }

    $self->SUPER::new(%opts);

    $self->{hooks}           = {};
    $self->{exceptions}      = 0;
    $self->{backoff_max}     = 90;
    $self->{command_timeout} = 30;

    $self->{exceptions} = delete $opts{exceptions}
        if exists $opts{exceptions};

    $self->{backoff_max} = $opts{backoff_max}
        if defined $opts{backoff_max};

    $self->{command_timeout} = $opts{command_timeout}
        if defined $opts{command_timeout};

    return $self;
} ## end sub new

=head1 METHODS

=head2 new_task_set()

Creates and returns a new L<Gearman::Taskset> object.

=cut

sub new_task_set {
    my $self    = shift;
    my $taskset = Gearman::Taskset->new($self);
    $self->run_hook('new_task_set', $self, $taskset);
    return $taskset;
} ## end sub new_task_set

#
# _job_server_status_command($command, $each_line_sub)
# $command e.g. "status\n".
# $each_line_sub A sub to be called on each line of response;
#                takes $hostport and the $line as args.
#
sub _job_server_status_command {
    my ($self, $command, $each_line_sub) = (shift, shift, shift);

    my $list
        = scalar(@_)
        ? $self->canonicalize_job_servers(@_)
        : $self->job_servers();
    my %js_map = map { $self->_js_str($_) => 1 } $self->job_servers();

    foreach my $js (@{$list}) {
        defined($js_map{ $self->_js_str($js) }) || next;

        my $sock = $self->_get_js_sock($js)
            or next;

        my $rv = $sock->write($command);

        my $err;
        my @lines = Gearman::Util::read_text_status($sock, \$err);
        if ($err) {

            $self->debug() && warn $err;
            next;
        }

        foreach my $l (@lines) {
            $each_line_sub->($js, $l);
        }

        $self->_sock_cache($js, $sock);
    } ## end foreach my $js (@{$list})
} ## end sub _job_server_status_command

=head2 get_job_server_status()

B<return> C<< {job_server => {job => {capable, queued, running}}} >>

=cut

sub get_job_server_status {
    my $self = shift;

    my $js_status = {};
    $self->_job_server_status_command(
        "status\n",
        sub {
            my ($js, $line) = @_;
            unless ($line =~ /^(\S+)\s+(\d+)\s+(\d+)\s+(\d+)$/) {
                return;
            }

            my ($job, $queued, $running, $capable) = ($1, $2, $3, $4);
            $js_status->{ $self->_js_str($js) }->{$job} = {
                queued  => $queued,
                running => $running,
                capable => $capable,
            };
        },
        @_
    );
    return $js_status;
} ## end sub get_job_server_status

=head2 get_job_server_jobs()

supported only by L<Gearman::Server>

B<return> C<< {job-server => {job => {address, listeners, key}}} >>

=cut

sub get_job_server_jobs {
    my $self    = shift;
    my $js_jobs = {};
    $self->_job_server_status_command(
        "jobs\n",
        sub {
            my ($js, $line) = @_;

            # Yes, the unique key is sometimes omitted.
            return unless $line =~ /^(\S+)\s+(\S*)\s+(\S+)\s+(\d+)$/;

            my ($job, $key, $address, $listeners) = ($1, $2, $3, $4);
            $js_jobs->{ $self->_js_str($js) }->{$job} = {
                key       => $key,
                address   => $address,
                listeners => $listeners,
            };
        },
        @_
    );
    return $js_jobs;
} ## end sub get_job_server_jobs

=head2 get_job_server_clients()

supported only by L<Gearman::Server>

=cut

sub get_job_server_clients {
    my $self = shift;

    my $js_clients = {};
    my $client;
    $self->_job_server_status_command(
        "clients\n",
        sub {
            my ($js, $line) = @_;
            my $js_str = $self->_js_str($js);
            if ($line =~ /^(\S+)$/) {
                $client = $1;
                $js_clients->{$js_str}->{$client} ||= {};
            }
            elsif ($client && $line =~ /^\s+(\S+)\s+(\S*)\s+(\S+)$/) {
                my ($job, $key, $address) = ($1, $2, $3);
                $js_clients->{$js_str}->{$client}->{$job} = {
                    key     => $key,
                    address => $address,
                };
            } ## end elsif ($client && $line =~...)
        },
        @_
    );

    return $js_clients;
} ## end sub get_job_server_clients

#
# _get_task_from_args
#
sub _get_task_from_args {
    my $self = shift;
    my $task;
    if (ref $_[0]) {
        $task = shift;
        $task->isa("Gearman::Task")
            || Carp::croak("Argument isn't a Gearman::Task");
    }
    else {
        my $func   = shift;
        my $arg_p  = shift;
        my $opts   = shift;
        my $argref = ref $arg_p ? $arg_p : \$arg_p;
        Carp::croak("Function argument must be scalar or scalarref")
            unless ref $argref eq "SCALAR";

        $task = Gearman::Task->new($func, $argref, $opts);
    } ## end else [ if (ref $_[0]) ]
    return $task;

} ## end sub _get_task_from_args

=head2 do_task($task)

=head2 do_task($funcname, $arg, \%options)

Dispatches a task and waits on the results.  May either provide a
L<Gearman::Task> object, or the 3 arguments that the L<Gearman::Task>
constructor takes.

B<return> scalarref of WORK_COMPLETE result, or undef on failure.

=cut

sub do_task {
    my $self = shift;
    my $task = $self->_get_task_from_args(@_);
    my ($ret, $sub) = (undef, $task->{on_complete});
    $task->{on_complete} = sub {
        ($ret) = @_;
        $sub && $sub->(@_);
    };

    my $ts = $self->new_task_set;
    $ts->add_task($task);
    $ts->wait(timeout => $task->timeout);

    return $ret;
} ## end sub do_task

=head2 dispatch_background($func, $arg_p, $options_hr)

=head2 dispatch_background($task)

Dispatches a C<task> and doesn't wait for the result. Return value
is an opaque scalar that can be used to refer to the task with L<get_status>.

B<It is strongly recommended to set> L<Gearman::Task> C<uniq> B<option>
to insure gearmand does not squash jobs if it store background jobs in a persistence backend.
See the issue L<#87|https://github.com/gearman/gearmand/issues/87#issuecomment-291119785>

B<return> the handle from the jobserver, or undef on failure

=cut

sub dispatch_background {
    my $self = shift;
    my $task = $self->_get_task_from_args(@_);

    $task->{background} = 1;

    my $ts = $self->new_task_set;
    return $ts->add_task($task);
} ## end sub dispatch_background

=head2 run_hook($name)

run a hook callback if defined

=cut

sub run_hook {
    my ($self, $hookname) = @_;
    $hookname || return;

    my $hook = $self->{hooks}->{$hookname};
    return unless $hook;

    eval { $hook->(@_) };

    warn "Gearman::Client hook '$hookname' threw error: $@\n" if $@;
} ## end sub run_hook

=head2 add_hook($name, $cb)

add a hook

=cut

sub add_hook {
    my ($self, $hookname) = (shift, shift);
    $hookname || return;

    if (@_) {
        $self->{hooks}->{$hookname} = shift;
    }
    else {
        delete $self->{hooks}->{$hookname};
    }
} ## end sub add_hook

=head2 get_status($handle)

The Gearman Server will assign a scalar job handle when you request a
background job with L<dispatch_background>. Save this scalar, and use it later
in order to request the status of this job.

B<return> L<Gearman::JobStatus> on success

=cut

sub get_status {
    my ($self, $handle) = @_;
    $handle || return;

    my ($js_str, $shandle) = split(m!//!, $handle);

    #TODO simple check for $js_str in job_server doesn't work if
    # $js_str is not contained in job_servers
    # job_servers = ["localhost:4730"]
    # handle = 127.0.0.1:4730//H:...
    #
    # hopefully commit 58e2aa5 solves this TODO

    my $js = $self->_js($js_str);
    $js || return;

    my $sock = $self->_get_js_sock($js);
    $sock || return;

    my $req = Gearman::Util::pack_req_command("get_status", $shandle);
    my $len = length($req);
    my $rv  = $sock->write($req, $len);
    my $err;
    my $res = Gearman::Util::read_res_packet($sock, \$err);

    if ($res && $res->{type} eq "error") {
        Carp::croak
            "Error packet from server after get_status: ${$res->{blobref}}\n";
    }

    return undef unless $res && $res->{type} eq "status_res";

    my @args = split(/\0/, ${ $res->{blobref} });

    #FIXME returns on '', 0
    $args[0] || return;

    shift @args;
    $self->_sock_cache($js_str, $sock);

    return Gearman::JobStatus->new(@args);
} ## end sub get_status

#
# _option_request($sock, $option)
#
sub _option_request {
    my ($self, $sock, $option) = @_;

    my $req = Gearman::Util::pack_req_command("option_req", $option);
    my $len = length($req);
    my $rv  = $sock->write($req, $len);

    my $err;
    my $res = Gearman::Util::read_res_packet($sock, \$err,
        $self->{command_timeout});

    return unless $res;

    return 0 if $res->{type} eq "error";
    return 1 if $res->{type} eq "option_res";

    warn "Got unknown response to option request: $res->{type}\n";
    return;
} ## end sub _option_request

#
# _get_js_sock($js)
#
# returns a socket from the cache. it should be returned to the
# cache with _sock_cache($js, $sock).
# The hostport isn't verified. the caller
# should verify that $js is in the set of jobservers.
sub _get_js_sock {
    my ($self, $js) = @_;
    if (my $sock = $self->_sock_cache($js, undef, 1)) {
        return $sock if $sock->connected;
    }

    my $sockinfo = $self->{sock_info}{ $self->_js_str($js) } ||= {};
    my $disabled_until = $sockinfo->{disabled_until};
    return if defined $disabled_until && $disabled_until > Time::HiRes::time();

    my $sock = $self->socket($js, 1);
    unless ($sock) {
        my $count       = ++$sockinfo->{failed_connects};
        my $disable_for = $count**2;
        my $max         = $self->{backoff_max};
        $disable_for = $disable_for > $max ? $max : $disable_for;
        $sockinfo->{disabled_until} = $disable_for + Time::HiRes::time();
        return;
    } ## end unless ($sock)

    $self->sock_nodelay($sock);
    $sock->autoflush(1);

    # If exceptions support is to be requested, and the request fails, disable
    # exceptions for this client.
    if ($self->{exceptions} && !$self->_option_request($sock, 'exceptions')) {
        warn "Exceptions support denied by server, disabling.\n";
        $self->{exceptions} = 0;
    }

    delete $sockinfo->{failed_connects};    # Success, mark the socket as such.
    delete $sockinfo->{disabled_until};

    return $sock;
} ## end sub _get_js_sock

sub _get_random_js_sock {
    my ($self, $getter) = @_;

    $self->{js_count} || return;

    $getter ||= sub {
        my $js = shift;
        return $self->_get_js_sock($js);
    };

    my $ridx = int(rand($self->{js_count}));
    for (my $try = 0; $try < $self->{js_count}; $try++) {
        my $aidx = ($ridx + $try) % $self->{js_count};
        my $js   = $self->{job_servers}[$aidx];
        my $sock = $getter->($js) or next;
        return ($js, $sock);
    } ## end for (my $try = 0; $try ...)
    return ();
} ## end sub _get_random_js_sock

1;
__END__


=head1 COPYRIGHT

Copyright 2006-2007 Six Apart, Ltd.

License granted to use/distribute under the same terms as Perl itself.

=head1 WARRANTY

This is free software. This comes with no warranty whatsoever.

=head1 AUTHORS

 Brad Fitzpatrick (<brad at danga dot com>)
 Jonathan Steinert (<hachi at cpan dot org>)
 Alexei Pastuchov (<palik at cpan dot org>) co-maintainer

=head1 REPOSITORY

L<https://github.com/p-alik/perl-Gearman.git>


