package Gearman::Worker;
use version;
$Gearman::Worker::VERSION = version->declare("2.004.015");

use strict;
use warnings;

use base "Gearman::Objects";

=head1 NAME

Gearman::Worker - Worker for gearman distributed job system

=head1 SYNOPSIS

    use Gearman::Worker;
    my $worker = Gearman::Worker->new;
    $worker->job_servers(
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

    $worker->register_function($funcname => sub {
        ...
      }
    );

    $worker->work(
      on_start => sub {
        my ($jobhandle) = @_;
        ...
      },
      on_complete => sub {
        my ($jobhandle, $result) = @_;
        ...
      },
      on_fail => sub {
        my ($jobhandle, $err) = @_;
        ..
      },
      stop_if => sub {
        my ($is_idle, $last_job_time) = @_;
        # stop idle worker
        return $is_idle;
      },
    );


=head1 DESCRIPTION

I<Gearman::Worker> is a worker class for the Gearman distributed job system,
providing a framework for receiving and serving jobs from a Gearman server.

Callers instantiate a I<Gearman::Worker> object, register a list of functions
and capabilities that they can handle, then enter an event loop, waiting
for the server to send jobs.

The worker can send a return value back to the server, which then gets
sent back to the client that requested the job; or it can simply execute
silently.

=head1 USAGE

=head2 Gearman::Worker->new(%options)

Creates a new I<Gearman::Worker> object, and returns the object.

If I<%options> is provided, initializes the new worker object with the
settings in I<%options>, which can contain:

I<Gearman::Worker> is derived from L<Gearman::Objects>

=over 4

=item * job_servers

List of job servers. Value should be an array reference, hash reference
or scalar.
It will be ignored if this worker is running as a child
process of a gearman server.

=item * prefix

Calls I<prefix> (see below) to set the prefix / namespace.

=item * client_id

Unique worker identifier for C<job_servers>.

=back

=head2 $worker-E<gt>prefix($prefix)

Sets the namespace / prefix for the function names.  This is useful
for sharing job servers between different applications or different
instances of the same application (different development sandboxes for
example).

The namespace is currently implemented as a simple tab separated
concatenation of the prefix and the function name.

=head1 EXAMPLES

=head2 Summation

This is an example worker that receives a request to sum up a list of
integers.

    use Gearman::Worker;
    use Storable qw( thaw );
    use List::Util qw( sum );
    my $worker = Gearman::Worker->new;
    $worker->job_servers('127.0.0.1');
    $worker->register_function(sum => sub { sum @{ thaw($_[0]->arg) } });
    $worker->work while 1;

See the L<Gearman::Client> documentation for a sample client sending the
I<sum> job.

=head1 NOTE

If you intend to send or receive UTF-8 data over SSL connections,
beware that there is no UTF-8 support in the underlying L<Net::SSLeay>.
L<perlunicode/"Forcing-Unicode-in-Perl-(Or-Unforcing-Unicode-in-Perl)"> describes proper workarounds.

=head1 METHODS

=cut

use Carp          ();
use Gearman::Util ();
use Gearman::Job;
use Storable ();

use fields (
    'last_connect_fail',    # host:port -> unixtime
    'down_since',           # host:port -> unixtime
    'connecting',           # host:port -> unixtime connect started at
    'can',        # ability -> subref     (ability is func with optional prefix)
    'timeouts',   # ability -> timeouts
    'client_id',  # random identifier string, no whitespace
    'parent_pipe',  # bool/obj:  if we're a child process of a gearman server,
                    #   this is socket to our parent process.  also means parent
                    #   sock can never disconnect or timeout, etc..
);

sub new {
    my ($class, %opts) = @_;
    my $self = $class;
    $self = fields::new($class) unless ref $self;

    if ($ENV{GEARMAN_WORKER_USE_STDIO}) {
        if ($opts{job_servers}) {
            warn join ' ', __PACKAGE__,
                'ignores job_servers if $ENV{GEARMAN_WORKER_USE_STDIO} is set';

            # delete job_servers to insure Gearman::Objects
            # does not treat correspondent object property
            delete($opts{job_servers});
        } ## end if ($opts{job_servers})
    } ## end if ($ENV{GEARMAN_WORKER_USE_STDIO...})

    $self->SUPER::new(%opts);

    $self->{last_connect_fail} = {};
    $self->{down_since}        = {};
    $self->{can}               = {};
    $self->{timeouts}          = {};
    $self->{client_id}         = $opts{client_id}
        || join('', map { chr(int(rand(26)) + 97) } (1 .. 30));

    if ($ENV{GEARMAN_WORKER_USE_STDIO}) {
        open my $sock, '+<&', \*STDIN
            or die "Unable to dup STDIN to socket for worker to use.";
        $self->{job_servers} = [$sock];
        $self->{parent_pipe} = $sock;

        die "Unable to initialize connection to gearmand"
            unless $self->_set_client_id($sock);
    } ## end if ($ENV{GEARMAN_WORKER_USE_STDIO...})

    return $self;
} ## end sub new

=head2 reset_abilities

This tells all the job servers that this worker can no longer do any tasks.

B<return> true if C<reset_abilities> request successfully transmitted to C<job_servers>

=cut

sub reset_abilities {
    my $self = shift;
    my $req  = _rc("reset_abilities");

    $self->{can}      = {};
    $self->{timeouts} = {};

    return $self->_register_all($req);
} ## end sub reset_abilities

=head2 work(%opts)

This endlessly loops. It takes an applicable job, if available, does the job, and then waits for the next one.
You can pass "stop_if", "on_start", "on_complete" and "on_fail" callbacks in I<%opts>.
See L</SYNOPSIS>

=cut

my %job_done;

sub work {
    my ($self, %opts) = @_;
    my $stop_if     = delete($opts{stop_if}) || sub {0};
    my $complete_cb = delete $opts{on_complete};
    my $fail_cb     = delete $opts{on_fail};
    my $start_cb    = delete $opts{on_start};
    die "Unknown opts" if %opts;

    my $grab_req     = _rc("grab_job");
    my $presleep_req = _rc("pre_sleep");

    my $last_job_time;

    my $on_connect = sub {
        return _send($_[0], \$presleep_req);
    };

    my %js_map = map { $self->_js_str($_) => $_ } $self->job_servers;

    # "Active" job servers are servers that have woken us up and should be
    # queried to see if they have jobs for us to handle. On our first pass
    # in the loop we contact all servers.
    my %active_js = map { $_ => 1 } keys(%js_map);

    # ( js => last_update_time, ... )
    my %last_update_time;

    while (1) {

        # "Jobby" job servers are the set of server which we will contact
        # on this pass through the loop, because we need to clear and use
        # the "Active" set to plan for our next pass through the loop.
        my @jobby_js = keys %active_js;

        %active_js = ();

        my $js_count  = @jobby_js;
        my $js_offset = int(rand($js_count));

        for (my $i = 0; $i < $js_count; $i++) {
            my $js_index = ($i + $js_offset) % $js_count;
            my $js_str   = $jobby_js[$js_index];
            my $js       = $js_map{$js_str};
            my $jss      = $self->_get_js_sock(
                $js,
                on_connect            => $on_connect,
                register_on_reconnect => 1
            ) or next;

            # TODO: add an optional sleep in here for the test suite
            # to test gearmand server going away here.  (SIGPIPE on
            # send_req, etc) this testing has been done manually, at
            # least.
            unless (_send($jss, \$grab_req)) {
                if ($!{EPIPE} && $self->{parent_pipe}) {

                    # our parent process died, so let's just quit
                    # gracefully.
                    exit(0);
                } ## end if ($!{EPIPE} && $self...)

                $self->_uncache_sock($js, "grab_job_timeout");
                delete $last_update_time{$js_str};
                next;
            } ## end unless (_send($jss, \$grab_req...))

            # if we're a child process talking over a unix pipe, give more
            # time, since we know there are no network issues, and also
            # because on failure, we can't "reconnect".  all we can do is
            # die and hope our parent process respawns us.
            my $timeout = $self->{parent_pipe} ? 5 : 0.50;
            unless (Gearman::Util::wait_for_readability($jss->fileno, $timeout))
            {
                $self->_uncache_sock($js, "grab_job_timeout");
                delete $last_update_time{$js_str};
                next;
            } ## end unless (Gearman::Util::wait_for_readability...)

            my $res;
            do {
                my $err;
                $res = Gearman::Util::read_res_packet($jss, \$err);
                unless ($res) {
                    $self->_uncache_sock($js, "read_res_error");
                    delete $last_update_time{$js_str};
                    next;
                }
            } while ($res->{type} eq "noop");

            if ($res->{type} eq "no_job") {
                unless (_send($jss, \$presleep_req)) {
                    delete $last_update_time{$js_str};
                    $self->_uncache_sock($js, "write_presleep_error");
                }
                $last_update_time{$js_str} = time;
                next;
            } ## end if ($res->{type} eq "no_job")

            unless ($res->{type} eq "job_assign") {
                my $msg = "unexpected packet type: $res->{type}";

                if ($res->{type} eq "error") {
                    $msg .= " [${$res->{blobref}}]\n";
                    $msg =~ s/\0/ -- /g;
                }
                die $msg;
            } ## end unless ($res->{type} eq "job_assign")

            ${ $res->{blobref} } =~ s/^(.+?)\0(.+?)\0//
                or die "regexp on job_assign failed";
            my ($handle, $ability) = ($1, $2);
            my $job = Gearman::Job->new(
                func   => $ability,
                argref => $res->{blobref},
                handle => $handle,
                jss    => $jss,
                js     => $js
            );

            my $jobhandle = join("//", $js_str, $job->handle);
            $start_cb->($jobhandle) if $start_cb;

            my $handler = $self->{can}{$ability};
            my $ret     = eval { $handler->($job); };
            my $err     = $@;
            warn "Job '$ability' died: $err" if $err;

            $last_update_time{$js_str} = $last_job_time = time();
            if ($err) {
                my $exception_req
                    = _rc("work_exception",
                    _join0($handle, Storable::nfreeze(\$err)));
                unless (_send($jss, \$exception_req)) {
                    $self->_uncache_sock($js, "write_res_error");
                    next;
                }
            } ## end if ($err)

            if (!defined $job_done{ $job->handle }) {
                if (defined $ret) {
                    $self->send_work_complete($job, $ret);
                }
                else {
                    $self->send_work_fail($job);
                }
            } ## end if (!defined $job_done...)

            my $done = delete $job_done{ $job->handle };
            if ($done->{command} eq "work_complete") {
                $complete_cb->($jobhandle, $ret) if $complete_cb;
            }
            else {
                $fail_cb->($jobhandle, $err) if $fail_cb;
            }

            unless ($done->{result}) {
                $self->_uncache_sock($js, "write_res_error");
                next;
            }

            $active_js{$js_str} = 1;
        } ## end for (my $i = 0; $i < $js_count...)

        my @jss;

        foreach my $js_str (keys(%js_map)) {
            my $jss = $self->_get_js_sock(
                $js_map{$js_str},
                on_connect            => $on_connect,
                register_on_reconnect => 1
            ) or next;
            push @jss, [$js_str, $jss];
        } ## end foreach my $js_str (keys(%js_map...))

        my $wake_vec = '';

        foreach my $j (@jss) {
            (undef, my $_jss) = @{$j};
            my $fd = $_jss->fileno;
            vec($wake_vec, $fd, 1) = 1;
        }

        my $timeout = keys(%active_js) ? 0 : (10 + rand(2));

        # chill for some arbitrary time until we're woken up again
        my $nready = select(my $wout = $wake_vec, undef, undef, $timeout);

        if ($nready) {
            foreach my $j (@jss) {
                my ($js_str, $jss) = @{$j};
                my $fd = $jss->fileno;
                $active_js{$js_str} = 1
                    if vec($wout, $fd, 1);
            } ## end foreach my $j (@jss)
        } ## end if ($nready)

        my $is_idle = scalar(keys %active_js) > 0 ? 0 : 1;

        return if $stop_if->($is_idle, $last_job_time);

        my $update_since = time - (15 + rand 60);

        while (my ($js_str, $last_update) = each %last_update_time) {
            $active_js{$js_str} = 1 if $last_update < $update_since;
        }
    } ## end while (1)

} ## end sub work

=head2 $worker->register_function($funcname, $subref)

=head2 $worker->register_function($funcname, $timeout, $subref)

Registers the function C<$funcname> as being provided by the worker
C<$worker>, and advertises these capabilities to all of the job servers
defined in this worker.

C<$subref> must be a subroutine reference that will be invoked when the
worker receives a request for this function. It will be passed a
L<Gearman::Job> object representing the job that has been received by the
worker.

C<$timeout> is an optional parameter specifying how long the jobserver will
wait for your subroutine to give an answer. Exceeding this time will result
in the jobserver reassigning the task and ignoring your result. This prevents
a gimpy worker from ruining the 'user experience' in many situations.

B<return> true if C<$funcname> registration successfully transmitted to C<job_servers>

=cut

sub register_function {
    my $self = shift;
    my $func = shift;
    $func || return;

    my $timeout;
    if (ref($_[0]) ne 'CODE') {
        $timeout = shift;
    }

    my $subref  = shift;
    my $ability = $self->func($func);
    $self->{can}{$ability} = $subref;

    if (defined $timeout) {
        $self->{timeouts}{$ability} = $timeout;
    }

    my @job_servers = $self->job_servers();
    @job_servers || return;

    my $done = 0;
    foreach my $js (@job_servers) {
        $self->_register_function($ability, $js) && $done++;
    }

    return $done == scalar @job_servers;
} ## end sub register_function

=head2 unregister_function($funcname)

send cant_do C<$funcname> request to L<job_servers>

B<return> true if CANT_DO C<$funcname> request successfully transmitted to C<job_servers>

=cut

sub unregister_function {
    my ($self, $func) = @_;
    my $ability = $self->func($func);
    delete $self->{can}{$ability};

    my $req = _rc("cant_do", $ability);
    return $self->_register_all($req);
} ## end sub unregister_function

=head2 job_servers(@servers)

Override L<Gearman::Objects> method to skip job server initialization if
working with L<Gearman::Server>.

Calling this method will do nothing in a worker that is running as a child
process of a gearman server.

=cut

sub job_servers {
    my $self = shift;
    $ENV{GEARMAN_WORKER_USE_STDIO} && return $self->{job_servers};

    return $self->SUPER::job_servers(@_);
} ## end sub job_servers

=head2 send_work_complete($job, $v)

notify the server (and listening clients) that job completed successfully

=cut

sub send_work_complete {
    return shift->_finish_job_request("work_complete", @_);
}

=head2 send_work_data($job, $data)

Use this method to update the client with data from a running job.

=cut

sub send_work_data {
    my ($self, $job, $data) = @_;
    return $self->_job_request("work_data", $job,
        ref($data) ? ${$data} : $data);
}

=head2 send_work_warning($job, $message)

Use this method to send a warning C<$message> to the server (and any listening clients) with regard to the running C<job>.

=cut

sub send_work_warning {
    my ($self, $job, $msg) = @_;
    return $self->_job_request("work_warning", $job, $msg);
}

=head2 send_work_exception($job, $exception)

Use this method to notify the server (and any listening clients) that the C<job> failed with the given C<$exception>.

If you are using L<Gearman::Client>, you have to set parameter exceptions properly to get worker exception notifications.

=cut

sub send_work_exception {
    my ($self) = shift;
    return $self->_finish_job_request("work_exception", @_);
}

=head2 send_work_fail($job)

Use this method to notify the server (and any listening clients) that the job failed.

=cut

sub send_work_fail {
    return shift->_finish_job_request("work_fail", shift);
}

=head2 send_work_status($job, $numerator, $denominator)

Use this method to send periodically to the server status update for long running jobs to update the percentage
complete.

=cut

sub send_work_status {
    my ($self, $job, $numerator, $denominator) = @_;
    return $self->_job_request("work_status", $job, $numerator, $denominator);
}

# _finish_job_request($cmd, $job, [$v])
#
# send some data or message to the client for finished job
# $cmd = work_complete || work_fail
#
sub _finish_job_request {
    my ($self, $cmd, $job, $v) = @_;
    my $res = $self->_job_request($cmd, $job, ref($v) ? ${$v} : $v);

    # set job done flag because work method check it
    $job_done{ $job->handle } = { command => $cmd, result => $res };

    return $res;
} ## end sub _finish_job_request

# _job_request($cmd, $job, [$v])
#
# send some data to the client for the running job
#
sub _job_request {
    my ($self, $cmd, $job, $v) = @_;
    my $req = _rc($cmd, $v ? _join0($job->handle, $v) : $job->handle);

    return _send($job->{jss}, \$req);
} ## end sub _job_request

#
# _register_all($req)
#
sub _register_all {
    my ($self, $req) = @_;
    my @job_servers = $self->job_servers();
    my $done        = 0;
    foreach my $js (@job_servers) {
        my $jss = $self->_get_js_sock($js);

        ($jss && $req) || next;

        unless (_send($jss, \$req)) {
            $self->_uncache_sock($js, "$req request failed");
            next;
        }

        $done++;
    } ## end foreach my $js (@job_servers)

    return $done == scalar @job_servers;
} ## end sub _register_all

#
# _get_js_sock($js, %opts)
#
sub _get_js_sock {
    my ($self, $js, %opts) = @_;
    $js || return;

    my $js_str     = $self->_js_str($js);
    my $on_connect = delete $opts{on_connect};

    # Someday should warn when called with extra opts.

    warn "getting job server socket: $js_str" if $self->debug;

    # special case, if we're a child process of a gearman::server
    # parent process, talking over a unix pipe...
    return $self->{parent_pipe} if $self->{parent_pipe};

    if (my $sock = $self->_sock_cache($js)) {
        return $sock if getpeername($sock);

        $self->_uncache_sock($js, "getpeername failed");
    }

    my $now        = time;
    my $down_since = $self->{down_since}{$js_str};
    if ($down_since) {
        my $down_for = $now - $down_since;
        warn "$js_str down for $down_for" if $self->debug;

        my $retry_period = $down_for > 60 ? 30 : (int($down_for / 2) + 1);
        if ($self->{last_connect_fail}{$js_str} > $now - $retry_period) {
            return;
        }
    } ## end if ($down_since)

    warn "connecting to '$js_str'" if $self->debug;

    my $sock = $self->socket($js, 1);
    unless ($sock) {
        $self->{down_since}{$js_str} ||= $now;
        $self->{last_connect_fail}{$js_str} = $now;

        return;
    } ## end unless ($sock)

    $sock->autoflush(1);
    $self->sock_nodelay($sock);

    delete $self->{last_connect_fail}{$js_str};
    delete $self->{down_since}{$js_str};

    if ($opts{register_on_reconnect}) {
        my @fail = ();
        foreach (keys %{ $self->{can} }) {
            $self->_register_function($_, $js, $sock) || push @fail, $_;
        }

        if (@fail) {
            $self->_uncache_sock($js, join ' ', "failed registration of",
                @fail);
            return;
        }
    } ## end if ($opts{register_on_reconnect...})

    $self->_sock_cache($js, $sock);

    if ($on_connect && !$on_connect->($sock)) {
        $self->_uncache_sock($js, "on connect callback failed");
        return;
    }

    return $sock;
} ## end sub _get_js_sock

=head2 _uncache_sock($js, $reason)

close TCP connection

=cut

sub _uncache_sock {
    my ($self, $js, $reason) = @_;

    # we can't reconnect as a child process, so all we can do is die and hope our
    # parent process respawns us...
    die "Error/timeout talking to gearman parent process: [$reason]"
        if $self->{parent_pipe};

    $self->debug && warn join ' ', "close connection to", $self->_js_str($js),
        $reason || '';

    # normal case, we just close this TCP connection and we'll reconnect later.
    # delete cached sock
    $self->_sock_cache($js, undef, 1);
} ## end sub _uncache_sock

#
# _set_client_id($sock)
#
sub _set_client_id {
    my ($self, $sock) = @_;
    my $req = _rc("set_client_id", $self->{client_id});
    return _send($sock, \$req);
}

#
# _set_ability($sock, $ability, [$timeout])
#
sub _set_ability {
    my ($self, $sock, $ability, $timeout) = @_;
    my $req;
    if (defined $timeout) {
        $req = _rc("can_do_timeout", _join0($ability, $timeout));
    }
    else {
        $req = _rc("can_do", $ability);
    }
    return _send($sock, \$req);
} ## end sub _set_ability

#
# _register_function($ability, $js, [$sock])
# set client id
# can do
#
sub _register_function {
    my ($self, $ability, $js, $sock) = @_;
    $sock ||= $self->_get_js_sock($js);
    $sock || return;

    unless ($self->_set_client_id($sock)) {
        $self->_uncache_sock($js, "set client id request failed");
        return;
    }

    unless ($self->_set_ability($sock, $ability, $self->{timeouts}{$ability})) {
        $self->_uncache_sock($js, "can do request failed");
        return;
    }

    return 1;
} ## end sub _register_function

#
# _send($jss, $req_ref)
#
# send C<$req> to C<$jss>
#
*_send = \&Gearman::Util::send_req;

#
# _rc($cmd, [@val])
#
*_rc = \&Gearman::Util::pack_req_command;

#
# _join0(@v)
#
sub _join0 {
    return join("\0", @_);
}

1;
__END__

=head1 WORKERS AS CHILD PROCESSES

Gearman workers can be run as child processes of a parent process
which embeds L<Gearman::Server>.  When such a parent process
fork/execs a worker, it sets the environment variable
GEARMAN_WORKER_USE_STDIO to true before launching the worker. If this
variable is set to true, then the L<job_servers|job_servers(@servers)> function and option for
new() are ignored and the unix socket bound to STDIN/OUT are used
instead as the IO path to the gearman server.

