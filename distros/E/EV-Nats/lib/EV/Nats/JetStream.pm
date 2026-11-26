package EV::Nats::JetStream;
use strict;
use warnings;
our $VERSION = '0.07';
use EV;
use JSON::PP ();

sub new {
    my ($class, %opts) = @_;
    my $nats    = delete $opts{nats}    || die "nats connection required";
    my $prefix  = delete $opts{prefix}  || '$JS.API';
    my $timeout = delete $opts{timeout} || 5000;
    my $with_status = delete $opts{with_status} ? 1 : 0;
    warn "EV::Nats::JetStream::new: unknown option '$_'" for keys %opts;
    bless {
        nats        => $nats,
        prefix      => $prefix,
        timeout     => $timeout,
        with_status => $with_status,
    }, $class;
}

sub _api {
    my ($self, $subj, $payload, $cb) = @_;
    $payload //= '';
    $self->{nats}->request(
        "$self->{prefix}.$subj",
        $payload, $cb, $self->{timeout},
    );
}

## Public to sibling modules (KV, ObjectStore, ...) -- not part of the user
## API. Decode a JSON string; returns ($decoded, $error_or_undef) where
## $error already includes a "JSON decode error: ..." prefix when set.
## Gates on $@ so falsy-but-valid JSON (null/0/false/empty-string) doesn't
## get misreported as a decode failure.
sub decode_json_or_error {
    my ($json) = @_;
    local $@;
    my $r = eval { JSON::PP::decode_json($json) };
    return ($r, undef) unless $@;
    return (undef, "JSON decode error: $@");
}

## Public to sibling modules. True if a STREAM.MSG.GET response message
## carries a KV-Operation: DEL or PURGE tombstone header. $msg is the
## decoded {message} hash; its {hdrs} field is base64-encoded by the server.
sub msg_is_tombstone {
    my ($msg) = @_;
    return 0 unless $msg && $msg->{hdrs};
    require MIME::Base64;
    my $hdrs = MIME::Base64::decode_base64($msg->{hdrs});
    return $hdrs =~ /KV-Operation:\s*(?:DEL|PURGE)/i ? 1 : 0;
}

sub _json_api {
    my ($self, $subj, $data, $cb) = @_;
    my $payload = defined $data ? JSON::PP::encode_json($data) : '';
    $self->_api($subj, $payload, $self->_decoded($cb));
}

## Public to sibling modules. A request callback that decodes the JSON
## reply for $cb and turns an API error object into an error string.
sub _decoded {
    my ($self, $cb) = @_;
    return sub {
        my ($resp, $err) = @_;
        return $cb->(undef, $err) if $err;
        my ($decoded, $derr) = decode_json_or_error($resp);
        return $cb->(undef, $derr) if $derr;
        my $e = $decoded->{error};
        return $cb->(undef, "$e->{description} (code $e->{code})", $self->{with_status} ? $e : ())
            if $e;
        $cb->($decoded, undef);
    };
}

sub _defer {
    my ($nats, $code) = @_;
    my $t;
    $t = $nats->_timer(0, 0, sub { undef $t; $code->() });
    return;
}

# Stream management

sub stream_create {
    my ($self, $config, $cb) = @_;
    my $name = $config->{name} || die "stream name required";
    $self->_json_api("STREAM.CREATE.$name", $config, $cb);
}

sub stream_update {
    my ($self, $config, $cb) = @_;
    my $name = $config->{name} || die "stream name required";
    $self->_json_api("STREAM.UPDATE.$name", $config, $cb);
}

sub stream_delete {
    my ($self, $name, $cb) = @_;
    $self->_json_api("STREAM.DELETE.$name", undef, $cb);
}

sub stream_info {
    my ($self, $name, @rest) = @_;
    my $cb   = pop @rest;
    my $opts = $rest[0];
    $self->_json_api("STREAM.INFO.$name", $opts, $cb);
}

sub stream_list {
    my ($self, $cb) = @_;
    $self->_json_api("STREAM.LIST", undef, $cb);
}

sub stream_purge {
    my ($self, $name, $cb) = @_;
    $self->_json_api("STREAM.PURGE.$name", undef, $cb);
}

# Fetch a single message from a stream by sequence, last-by-subject, or
# next-by-subject. \%opts is passed verbatim as the request body
# (server accepts: seq, last_by_subj, next_by_subj).
sub stream_msg_get {
    my ($self, $stream, $opts, $cb) = @_;
    $self->_json_api("STREAM.MSG.GET.$stream", $opts, $cb);
}

# Consumer management

sub consumer_create {
    my ($self, $stream, $config, $cb) = @_;
    my $name = $config->{durable_name} || $config->{name};
    my $subj = $name
        ? "CONSUMER.CREATE.$stream.$name"
        : "CONSUMER.CREATE.$stream";
    $self->_json_api($subj, { stream_name => $stream, config => $config }, $cb);
}

sub consumer_delete {
    my ($self, $stream, $consumer, $cb) = @_;
    $self->_json_api("CONSUMER.DELETE.$stream.$consumer", undef, $cb);
}

sub consumer_info {
    my ($self, $stream, $consumer, $cb) = @_;
    $self->_json_api("CONSUMER.INFO.$stream.$consumer", undef, $cb);
}

sub consumer_list {
    my ($self, $stream, $cb) = @_;
    $self->_json_api("CONSUMER.LIST.$stream", undef, $cb);
}

# Publishing with ack

sub js_publish {
    my ($self, $subject, $payload, $cb) = @_;
    $self->{nats}->request($subject, $payload, $self->_decoded($cb), $self->{timeout});
}

sub js_publish_h {
    my ($self, $subject, $headers, $payload, $cb) = @_;
    $self->{nats}->hrequest($subject, $headers, $payload, $self->_decoded($cb), $self->{timeout});
}

# The server serves a pull until it expires even after a cancel or a
# reconnect, so the inbox stays open until then and late messages are -NAKed.
sub fetch {
    my ($self, $stream, $consumer, $opts, $cb) = @_;
    $opts //= {};
    my $batch      = $opts->{batch}   || 1;
    my $expires_ns = $opts->{expires} || 5_000_000_000;
    my $no_wait    = $opts->{no_wait} ? 1 : 0;
    my $wait = $no_wait ? $self->{timeout} / 1000 : $expires_ns / 1e9 + 1;

    my $nats  = $self->{nats};
    my $inbox = $nats->new_inbox;

    my (@messages, $sid, $timer, $watch, $answered, $cancelled);
    my $seen = 0;

    my $nak = sub { $self->nak($_) for grep { defined $_->{reply} } @_ };
    my $close = sub {
        return unless $timer;
        $timer->stop;
        undef $timer;
        $nats->_unwatch_disconnect($watch) if defined $watch;
        undef $watch;
        eval { $nats->unsubscribe($sid) };
    };
    my $answer = sub {
        return if $answered++;
        $cb->(@_);
    };

    $sid = $nats->subscribe($inbox, sub {
        my ($subject, $payload, $reply, $headers) = @_;
        # Status lines are exactly "NATS/1.0 <3 digits>"; a loose \s+ would
        # swallow a headered DATA message's first header as a status frame.
        if ($headers && $headers =~ m{\A(NATS/1\.0 (\d{3})(?: ([^\r\n]*))?)(?:[\r\n]|\z)}) {
            my ($line, $code, $desc) = ($1, $2, $3 // '');
            # 100 is a heartbeat; 404/408 end the batch; anything else
            # (409, 503, 400) is a failure the caller must see.
            return if $code == 100;
            $close->();
            return if $answered;
            my @status = $self->{with_status}
                ? ({ code => 0 + $code, description => $desc }) : ();
            return $answer->([splice @messages], undef, @status)
                if $code == 404 || $code == 408;
            $nak->(splice @messages);
            return $answer->(undef, "fetch failed: $line", @status);
        }
        my $msg = {
            subject => $subject,
            payload => $payload,
            reply   => $reply,
            headers => $headers,
        };
        if ($answered) { $nak->($msg) } else { push @messages, $msg }
        return if ++$seen < $batch;
        $close->();
        $answer->([splice @messages]);
    });

    my %req = (batch => $batch);
    # no_wait with an expires is pointless: the server waits the expires
    # out instead of answering immediately.
    $req{expires} = $expires_ns unless $no_wait;
    $req{no_wait} = JSON::PP::true() if $no_wait;
    my $req_body = JSON::PP::encode_json(\%req);
    my $subj = "$self->{prefix}.CONSUMER.MSG.NEXT.$stream.$consumer";
    if (!eval { $nats->publish($subj, $req_body, $inbox); 1 }) {
        my $err = $@;
        eval { $nats->unsubscribe($sid) };
        die $err;
    }

    $timer = $nats->_timer($wait, 0, sub {
        $close->();
        $answer->([splice @messages]);
    });
    $watch = $nats->_watch_disconnect(sub {
        undef $watch;
        return if $answered++;
        my @undelivered = splice @messages;
        _defer($nats, sub {
            $nak->(@undelivered);
            $cb->(undef, 'disconnected') unless $cancelled;
        });
    });

    return bless sub {
        $cancelled = 1;
        return if $answered++;
        $nak->(splice @messages);
    }, 'EV::Nats::JetStream::Fetch';
}

sub ack         { $_[0]->_ack_reply($_[1], '+ACK') }
sub in_progress { $_[0]->_ack_reply($_[1], '+WPI') }

sub nak {
    my ($self, $msg, $delay) = @_;
    return $self->_ack_reply($msg, '-NAK') unless defined $delay;
    die "invalid nak delay '$delay'" unless $delay =~ /\A[0-9]+\z/;
    $self->_ack_reply($msg, qq{-NAK {"delay":$delay}});
}

sub term {
    my ($self, $msg, $reason) = @_;
    $self->_ack_reply($msg, defined $reason && length $reason ? "+TERM $reason" : '+TERM');
}

sub _ack_reply {
    my ($self, $msg, $body) = @_;
    my $reply = ref $msg ? $msg->{reply} : $msg;
    die "message has no reply subject" unless defined $reply && length $reply;
    return eval { $self->{nats}->publish($reply, $body); 1 } ? 1 : 0;
}

package EV::Nats::JetStream::Fetch;

sub cancel { $_[0]->(); return }

1;

=head1 NAME

EV::Nats::JetStream - JetStream API client for L<EV::Nats>

=head1 SYNOPSIS

    use EV;
    use EV::Nats;
    use EV::Nats::JetStream;

    my $nats = EV::Nats->new(host => '127.0.0.1');
    my $js   = EV::Nats::JetStream->new(nats => $nats);

    $js->stream_create({ name => 'ORDERS', subjects => ['orders.>'] },
                       sub {
        my ($info, $err) = @_;
        die $err if $err;
        $js->js_publish('orders.new', '{"item":"widget"}', sub {
            my ($ack, $err) = @_;
            print "stored at seq=$ack->{seq}\n";
        });
    });

    EV::run;

=head1 DESCRIPTION

Thin async wrapper over the JetStream C<$JS.API.*> request/reply
endpoints. Each method is a single request whose callback is invoked
with the decoded JSON response (or an error string). The C<$nats>
connection passed to L</new> handles all the actual I/O.

L<EV::Nats::KV> and L<EV::Nats::ObjectStore> build on top of this
module -- see those for higher-level KV / blob APIs.

=head1 METHODS

All methods are async. Callbacks fire on the L<EV> loop.

=head2 new

    new(%opts)

    my $js = EV::Nats::JetStream->new(
        nats        => $nats,
        prefix      => '$JS.API',   # default API subject prefix
        timeout     => 5000,        # ms; default 5000
        with_status => 0,           # see below
    );

With C<with_status>, callbacks receive a third argument when the server
reported a status: a JetStream API error's object,
C<< { code => 404, err_code => 10014, description => 'consumer not found' } >>,
or the status that ended a L</fetch>.

=head2 Stream management

=head3 stream_create

    stream_create($config, $cb)

Create a stream. C<$config> is passed verbatim as the
C<StreamConfig> request body. Callback: C<($info, $err)>.

=head3 stream_update

    stream_update($config, $cb)

Update an existing stream. Same shape as C<stream_create>.

=head3 stream_delete

    stream_delete($name, $cb)

Delete the stream by name.

=head3 stream_info

    stream_info($name, [\%opts], $cb)

Fetch stream config + state. Optional C<\%opts> may include
C<subjects_filter> (e.g. C<E<gt>>) to populate C<state.subjects>;
without it the server omits that field for performance.

=head3 stream_list

    stream_list($cb)

List all streams' info.

=head3 stream_purge

    stream_purge($name, $cb)

Purge all messages from the stream.

=head3 stream_msg_get

    stream_msg_get($stream, \%opts, $cb)

Fetch a single message from C<$stream>. C<\%opts> selects the message:

    { seq => $n }                                # by sequence number
    { last_by_subj => $subject }                 # latest matching subject
    { next_by_subj => $subject, seq => $start }  # next at-or-after $start

The message body and headers in the response are base64-encoded
under C<< $resp->{message}{data} >> and C<< $resp->{message}{hdrs} >>.

=head2 Consumer management

=head3 consumer_create

    consumer_create($stream, $config, $cb)

Create a consumer (push or pull). C<$config> is the consumer config
hashref; C<durable_name> makes it durable, C<ack_policy> controls
ack semantics.

=head3 consumer_delete

    consumer_delete($stream, $consumer, $cb)

=head3 consumer_info

    consumer_info($stream, $consumer, $cb)

=head3 consumer_list

    consumer_list($stream, $cb)

=head2 Publishing and fetching

=head3 js_publish

    js_publish($subject, $payload, $cb)

Publish with JetStream acknowledgment. Callback: C<($ack, $err)>
where C<$ack> is C<{ stream, seq, duplicate }>.

=head3 js_publish_h

    js_publish_h($subject, $headers, $payload, $cb)

Like L</js_publish> but sends C<$headers> (a full C<NATS/1.0> header
block, e.g. C<"NATS/1.0\r\nNats-Rollup: sub\r\n\r\n">) with the
message, waiting for the PubAck on a one-shot reply inbox. Used for
rollup publishes where the acknowledged sequence still matters
(L<EV::Nats::ObjectStore> metadata). Callback: C<($ack, $err)>.

=head3 fetch

    my $fetch = fetch($stream, $consumer, \%opts, $cb)

Pull messages from a pull-mode consumer. Options:

=over

=item C<batch>

Maximum number of messages to fetch (default 1).

=item C<expires>

Server-side wait time in nanoseconds (default 5_000_000_000 = 5s).
Ignored with C<no_wait>.

=item C<no_wait>

If true, the server answers at once with what is available; a fetch
nobody answers ends after C<timeout>.

=back

Callback: C<(\@messages, $err)>. Each message is a hashref:

    {
        subject => 'orders.new',
        payload => '...',
        reply   => '$JS.ACK....',  # for ack/nak/in_progress/term
        headers => "...",          # raw NATS/1.0 header block, or undef
    }

A 404 (no messages) or 408 (expired) status ends the batch; any other
status fails the fetch (C<"fetch failed: NATS/1.0 409 Server Shutdown">)
and C<-NAK>s the messages received so far. A dropped connection fails it
with C<"disconnected">. With C<with_status> the ending status is passed
as C<< { code => 409, description => 'Server Shutdown' } >>. An unknown
stream or consumer may get no answer at all: the fetch then ends with an
empty batch.

Returns a handle: C<< $fetch->cancel >> ends the fetch without calling
C<$cb>; messages that still arrive for the pull are C<-NAK>ed.

=head3 ack

    ack($msg)

=head3 nak

    nak($msg, [$delay_ns])

Redeliver, after C<$delay_ns> nanoseconds if given.

=head3 in_progress

    in_progress($msg)

Extend the message's C<ack_wait>.

=head3 term

    term($msg, [$reason])

Never redeliver the message.

These take a fetched message hashref or its reply subject, and return
true once the acknowledgement is sent or queued, or false when it
cannot be (C<$@> holds why). They die on a message without a reply
subject.

=head1 INTERNAL

These are exposed for sibling modules (L<EV::Nats::KV>,
L<EV::Nats::ObjectStore>) -- not part of the end-user API and subject
to change.

=head2 decode_json_or_error

    decode_json_or_error($json)

Decode C<$json>. Returns C<($decoded, $error_or_undef)>; the error
string already includes a C<"JSON decode error: "> prefix when set.
Gates on C<$@> so falsy-but-valid JSON (C<null>, C<0>, C<false>,
empty string) is reported as a clean decode rather than a failure.

=head2 msg_is_tombstone

    msg_is_tombstone($msg)

True if a C<STREAM.MSG.GET> response message carries a
C<KV-Operation: DEL> or C<KV-Operation: PURGE> header. C<$msg> is the
decoded C<message> hash from the response. Used by L<EV::Nats::KV>
and L<EV::Nats::ObjectStore> to surface deleted/purged entries as
clean misses rather than as malformed payloads.

=head1 SEE ALSO

L<EV::Nats>, L<EV::Nats::KV>, L<EV::Nats::ObjectStore>,
L<JetStream API reference|https://docs.nats.io/reference/reference-protocols/nats_api_reference>.

=cut
