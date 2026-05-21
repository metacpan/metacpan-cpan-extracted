package EV::Nats::JetStream;
use strict;
use warnings;
use EV;
use JSON::PP ();

sub new {
    my ($class, %opts) = @_;
    my $nats    = delete $opts{nats}    || die "nats connection required";
    my $prefix  = delete $opts{prefix}  || '$JS.API';
    my $timeout = delete $opts{timeout} || 5000;
    bless {
        nats    => $nats,
        prefix  => $prefix,
        timeout => $timeout,
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
    $self->_api($subj, $payload, sub {
        my ($resp, $err) = @_;
        return $cb->(undef, $err) if $err;
        my ($decoded, $derr) = decode_json_or_error($resp);
        return $cb->(undef, $derr) if $derr;
        if ($decoded->{error}) {
            return $cb->(undef, "$decoded->{error}{description} (code $decoded->{error}{code})");
        }
        $cb->($decoded, undef);
    });
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
    $self->{nats}->request($subject, $payload, sub {
        my ($resp, $err) = @_;
        return $cb->(undef, $err) if $err;
        my ($ack, $derr) = decode_json_or_error($resp);
        return $cb->(undef, $derr) if $derr;
        return $cb->(undef, "$ack->{error}{description}") if $ack->{error};
        $cb->($ack, undef);
    }, $self->{timeout});
}

# Fetch messages (pull consumer).
#
# A pull-consumer NEXT request returns up to N messages on a reply inbox,
# not a single JSON API response. We subscribe to a fresh inbox, publish
# the fetch request, and collect messages until $batch is reached, the
# server emits a status message (404/408/503), or the local safety timer
# fires.

sub fetch {
    my ($self, $stream, $consumer, $opts, $cb) = @_;
    $opts //= {};
    my $batch       = $opts->{batch}   || 1;
    my $expires_ns  = $opts->{expires} || 5_000_000_000; # 5s default
    my $no_wait     = $opts->{no_wait} ? 1 : 0;
    my $expires_sec = $expires_ns / 1_000_000_000;

    my $nats  = $self->{nats};
    my $inbox = $nats->new_inbox;

    my @messages;
    my ($sid, $timer);
    my $finished = 0;

    my $finish = sub {
        my $err = shift;
        return if $finished;
        $finished = 1;
        if ($timer) { $timer->stop; undef $timer; }
        $nats->unsubscribe($sid) if defined $sid;
        $err ? $cb->(undef, $err) : $cb->(\@messages, undef);
    };

    $sid = $nats->subscribe($inbox, sub {
        my ($subject, $payload, $reply, $headers) = @_;
        if ($headers && $headers =~ m{^NATS/1\.0\s+(\d+)}) {
            my $code = $1;
            # 404 = no messages, 408 = expires elapsed, 503 = no responders
            if ($code == 404 || $code == 408 || $code == 503) {
                return $finish->();
            }
        }
        push @messages, {
            subject => $subject,
            payload => $payload,
            reply   => $reply,
            headers => $headers,
        };
        $finish->() if @messages >= $batch;
    });

    my %req = (batch => $batch, expires => $expires_ns);
    $req{no_wait} = JSON::PP::true() if $no_wait;
    my $req_body = JSON::PP::encode_json(\%req);
    my $subj = "$self->{prefix}.CONSUMER.MSG.NEXT.$stream.$consumer";
    $nats->publish($subj, $req_body, $inbox);

    $timer = EV::timer($expires_sec + 1, 0, sub {
        $finish->();
    });
    return;
}

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

=head2 new(%opts)

    my $js = EV::Nats::JetStream->new(
        nats    => $nats,
        prefix  => '$JS.API',   # default API subject prefix
        timeout => 5000,        # ms; default 5000
    );

=head2 Stream management

=head3 stream_create($config, $cb)

Create a stream. C<$config> is passed verbatim as the
C<StreamConfig> request body. Callback: C<($info, $err)>.

=head3 stream_update($config, $cb)

Update an existing stream. Same shape as C<stream_create>.

=head3 stream_delete($name, $cb)

Delete the stream by name.

=head3 stream_info($name, [\%opts], $cb)

Fetch stream config + state. Optional C<\%opts> may include
C<subjects_filter> (e.g. C<E<gt>>) to populate C<state.subjects>;
without it the server omits that field for performance.

=head3 stream_list($cb)

List all streams' info.

=head3 stream_purge($name, $cb)

Purge all messages from the stream.

=head3 stream_msg_get($stream, \%opts, $cb)

Fetch a single message from C<$stream>. C<\%opts> selects the message:

    { seq => $n }                                # by sequence number
    { last_by_subj => $subject }                 # latest matching subject
    { next_by_subj => $subject, seq => $start }  # next at-or-after $start

The message body and headers in the response are base64-encoded
under C<< $resp->{message}{data} >> and C<< $resp->{message}{hdrs} >>.

=head2 Consumer management

=head3 consumer_create($stream, $config, $cb)

Create a consumer (push or pull). C<$config> is the consumer config
hashref; C<durable_name> makes it durable, C<ack_policy> controls
ack semantics.

=head3 consumer_delete($stream, $consumer, $cb)

=head3 consumer_info($stream, $consumer, $cb)

=head3 consumer_list($stream, $cb)

=head2 Publishing and fetching

=head3 js_publish($subject, $payload, $cb)

Publish with JetStream acknowledgment. Callback: C<($ack, $err)>
where C<$ack> is C<{ stream, seq, duplicate }>.

=head3 fetch($stream, $consumer, \%opts, $cb)

Pull messages from a pull-mode consumer. Options:

=over

=item C<batch>

Maximum number of messages to fetch (default 1).

=item C<expires>

Server-side wait time in nanoseconds (default 5_000_000_000 = 5s).

=item C<no_wait>

If true, return immediately if no messages are currently available.

=back

Callback: C<(\@messages, $err)>. Each message is a hashref:

    {
        subject => 'orders.new',
        payload => '...',
        reply   => '$JS.ACK....',  # for explicit ack/nak/wpi
        headers => "...",          # raw NATS/1.0 header block, or undef
    }

To acknowledge a message:

    $nats->publish($msg->{reply}, '+ACK');   # success
    $nats->publish($msg->{reply}, '-NAK');   # negative --redeliver after ack_wait
    $nats->publish($msg->{reply}, '+WPI');   # work-in-progress --extend ack_wait

=head1 INTERNAL

These are exposed for sibling modules (L<EV::Nats::KV>,
L<EV::Nats::ObjectStore>) -- not part of the end-user API and subject
to change.

=head2 decode_json_or_error($json)

Decode C<$json>. Returns C<($decoded, $error_or_undef)>; the error
string already includes a C<"JSON decode error: "> prefix when set.
Gates on C<$@> so falsy-but-valid JSON (C<null>, C<0>, C<false>,
empty string) is reported as a clean decode rather than a failure.

=head2 msg_is_tombstone($msg)

True if a C<STREAM.MSG.GET> response message carries a
C<KV-Operation: DEL> or C<KV-Operation: PURGE> header. C<$msg> is the
decoded C<message> hash from the response. Used by L<EV::Nats::KV>
and L<EV::Nats::ObjectStore> to surface deleted/purged entries as
clean misses rather than as malformed payloads.

=head1 SEE ALSO

L<EV::Nats>, L<EV::Nats::KV>, L<EV::Nats::ObjectStore>,
L<JetStream API reference|https://docs.nats.io/reference/reference-protocols/nats_api_reference>.

=cut
