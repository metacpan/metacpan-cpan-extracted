package EV::Gearman::Job;
use strict;
use warnings;

# A job is a blessed hashref { handle, function, unique, workload,
# _client_ptr => raw ev_gm_t* (IV) }, built by EV::Gearman XS when a
# JOB_ASSIGN[_UNIQ] arrives. Job methods read the pointer back and
# guard against use-after-free via the C struct's magic word.

sub handle   { $_[0]{handle}   }
sub function { $_[0]{function} }
sub unique   { $_[0]{unique}   }
sub workload { $_[0]{workload} }
sub data     { $_[0]{workload} }   # alias

sub complete  { $_[0]->_send_event(0, $_[1]) }
sub fail      { $_[0]->_send_event(1) }
sub exception { $_[0]->_send_event(2, $_[1]) }
sub send_data { $_[0]->_send_event(3, $_[1]) }
sub warning   { $_[0]->_send_event(4, $_[1]) }

sub status {
    my ($self, $num, $denom) = @_;
    $self->_send_status($num, $denom);
}

1;

=encoding utf8

=head1 NAME

EV::Gearman::Job - a job dispatched to a worker callback

=head1 SYNOPSIS

    $g->register_function(slow_compute => { async => 1 }, sub {
        my ($job) = @_;

        # introspect
        my $h = $job->handle;       # 'H:host:42'
        my $f = $job->function;     # 'slow_compute'
        my $u = $job->unique;       # set if grab_unique => 1
        my $w = $job->workload;     # request bytes

        # progress / partial-result events delivered to the client
        $job->status(50, 100);
        $job->send_data("partial chunk");
        $job->warning("non-fatal warning");
        $job->exception("rich error info");  # if exceptions option set

        # terminal
        $job->complete($result);    # success (sends WORK_COMPLETE)
        $job->fail;                 # failure (sends WORK_FAIL)
    });

=head1 DESCRIPTION

A job object is created by L<EV::Gearman> when a C<JOB_ASSIGN> /
C<JOB_ASSIGN_UNIQ> packet arrives, and passed as the sole argument
to the function callback registered with C<register_function>.

In B<sync> mode (default), you typically just C<return> a result
from your callback — the worker translates that into
C<WORK_COMPLETE>. C<die> becomes C<WORK_FAIL>. The job methods
below are still available for sending intermediate events.

In B<async> mode, the callback returns immediately; you must
explicitly call C<complete>, C<fail>, or C<exception> later. The
job object can be stashed in a closure or any other long-lived
container — it carries the connection pointer plus a magic word
that's checked on every send.

If the underlying L<EV::Gearman> connection has been destroyed by
the time you call a job method, the call C<croak>s with
C<"client destroyed">; this prevents use-after-free.

=head1 ACCESSORS

=head2 handle

Server-assigned job handle (e.g. C<H:host:42>).

=head2 function

Function name as registered.

=head2 unique

Submitter-supplied unique key. Empty string if the worker did not
opt into C<grab_unique =E<gt> 1> (the server only sends the unique
key with C<JOB_ASSIGN_UNIQ>).

=head2 workload

The job payload bytes.

=head2 data

Alias for C<workload>.

=head1 EVENT METHODS

These methods send packets back to the job server; the foreground
client (if any) receives the corresponding C<WORK_*> events
demultiplexed by handle.

=head2 send_data($bytes)

Send a partial C<WORK_DATA> chunk. The client's C<on_data> fires.

=head2 warning($bytes)

Send C<WORK_WARNING>. The client's C<on_warning> fires.

=head2 status($numerator, $denominator)

Send progress as C<WORK_STATUS>. Both values are sent as strings,
so any printable form is accepted (C<"42">, C<"3.14">, ...). The
client's C<on_status> fires with the same two values.

=head1 TERMINAL METHODS

Exactly one of these should be called per job in async mode; in
sync mode the worker calls one for you based on your callback's
return value or thrown exception. Sending a second terminal
packet produces a C<JOB_NOT_FOUND> error from gearmand (which
arrives as a connection-level error), so don't follow
C<exception> with C<fail>.

=head2 complete([$result])

Send C<WORK_COMPLETE>. C<$result> defaults to the empty string.

=head2 fail

Send C<WORK_FAIL>.

=head2 exception($bytes)

Send C<WORK_EXCEPTION>. Terminal at the server: gearmand
forwards the data to the foreground client and then marks the
job as failed, so do not also call C<fail>. Only delivered to
clients that requested the C<exceptions> option (either via the
constructor's C<exceptions =E<gt> 1> or via
C<< $cli->option('exceptions') >>); other clients see a plain
C<WORK_FAIL>.

=head1 SEE ALSO

L<EV::Gearman>

=cut
