package EV::Nats::JetStream;
use strict;
use warnings;
our $VERSION = '0.09';
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

# the same client with another request timeout; the direct-get cache is shared
sub with_timeout {
    my ($self, $ms) = @_;
    return $self if !$ms || $ms == $self->{timeout};
    return bless { %$self, direct => ($self->{direct} //= {}), timeout => $ms }, ref $self;
}

my $JSON = eval { require Cpanel::JSON::XS; Cpanel::JSON::XS->new }
        || eval { require JSON::XS; JSON::XS->new }
        || JSON::PP->new;
$JSON->utf8->allow_nonref;

sub decode_json_or_error {
    my ($json) = @_;
    local $@;
    my $r = eval { $JSON->decode($json) };
    return ($r, undef) unless $@;
    return (undef, "JSON decode error: $@");
}

sub msg_is_tombstone {
    my ($msg) = @_;
    return 0 unless $msg && defined $msg->{headers};
    # or a server TTL marker (nats-server 2.11+), as nats.go reads it
    return $msg->{headers} =~ /KV-Operation:\s*(?:DEL|PURGE)|Nats-Marker-Reason:\s*(?:MaxAge|Purge|Remove)/i
        ? 1 : 0;
}

sub json_api {
    my ($self, $subj, $data, $cb) = @_;
    my $payload = defined $data ? JSON::PP::encode_json($data) : '';
    $self->{nats}->request("$self->{prefix}.$subj", $payload, $self->decoded($cb), $self->{timeout});
}

# a request callback decoding the reply for $cb; API errors become strings
sub decoded {
    my ($self, $cb) = @_;
    return sub {
        my ($resp, $err) = @_;
        return $cb->(undef, $err, $self->err_status($err)) if $err;
        my ($decoded, $derr) = decode_json_or_error($resp);
        return $cb->(undef, $derr) if $derr;
        my $e = ref $decoded eq 'HASH' ? $decoded->{error} : undef;
        return $cb->(undef, "$e->{description} (code $e->{code})", $self->{with_status} ? $e : ())
            if $e;
        $cb->($decoded, undef);
    };
}

sub err_status {
    my ($self, $err) = @_;
    return $self->{with_status} && $err eq 'no responders' ? ({ code => 503, description => '' }) : ();
}

sub later {
    my ($nats, $code) = @_;
    my $t;
    $t = $nats->timer(0, 0, sub { undef $t; $code->() });
    return;
}

# report a croak through $cb on the next loop iteration
sub fail_later {
    my ($nats, $cb, $err) = @_;
    $err = 'not connected' unless defined $err && length $err;
    $err =~ s/ at \S+ line \d+.*//s;
    $err =~ s/\n\z//;
    later($nats, sub { $cb->(undef, $err) });
}

# the subjects under $prefix that hold messages, without the prefix; the
# server pages them, 100k per reply
sub subjects_under {
    my ($self, $stream, $prefix, $cb) = @_;
    my $plen = length $prefix;
    $self->offset_pages(sub {
        my ($offset, $done) = @_;
        $self->stream_info($stream, { subjects_filter => "$prefix>", ($offset ? (offset => $offset) : ()) }, sub {
            my ($info, $err) = @_;
            return $cb->(undef, $err) if $err;
            $done->($info, $info->{total},
                map { [ $_, substr $_, $plen ] } grep { substr($_, 0, $plen) eq $prefix }
                sort keys %{ $info->{state}{subjects} || {} });
        });
    }, sub { $cb->($_[0], undef) });
}

my $RELIST = 3;   # list again from the start at most this often, then settle

# The API pages a name-sorted list by offset, so an entry created or deleted
# ahead of the offset between two requests shifts the next page. Each later
# page is asked one entry early: when it does not start with the last entry
# held, the list moved and is read again. Past $RELIST, plain offsets finish
# it without duplicates. $fetch->($offset, $done) answers
# $done->($resp, $total, [$name, $item]...) in server order, or reports an
# error itself; $cb gets ([$item...], $last_resp).
sub offset_pages {
    my ($self, $fetch, $cb, $st) = @_;
    $st //= { items => [], seen => {}, relists => 0, offset => undef };
    my $items = $st->{items};
    my $offset = $st->{offset} // (@$items ? @$items - 1 : 0);
    $fetch->($offset, sub {
        my ($resp, $total, @page) = @_;
        my $had = @$items;
        if ($had && !defined $st->{offset}) {
            if (@page && $page[0][0] eq $items->[-1][0]) {
                shift @page;
            } elsif ($st->{relists}++ < $RELIST) {
                @$items = ();
                %{ $st->{seen} } = ();
                return $self->offset_pages($fetch, $cb, $st);
            } else {
                $st->{offset} = $offset;
            }
        }
        $st->{offset} += @page if defined $st->{offset};
        push @$items, grep { !$st->{seen}{ $_->[0] }++ } @page;
        my $more = defined $st->{offset} ? @page && $st->{offset} < ($total // 0)
                                         : @$items > $had && @$items < ($total // 0);
        return $self->offset_pages($fetch, $cb, $st) if $more;
        $cb->([ map { $_->[1] } @$items ], $resp);
    });
}

# remember a stream's allow_direct from any reply carrying its config
sub noting_direct {
    my ($self, $name, $cb) = @_;
    return sub {
        $self->{direct}{$name} = $_[0]{config}{allow_direct} ? 1 : 0
            if ref $_[0] eq 'HASH' && $_[0]{config};
        $cb->(@_);
    };
}

sub stream_create {
    my ($self, $config, $cb) = @_;
    my $name = $config->{name} || die "stream name required";
    $self->json_api("STREAM.CREATE.$name", $config, $self->noting_direct($name, $cb));
}

sub stream_update {
    my ($self, $config, $cb) = @_;
    my $name = $config->{name} || die "stream name required";
    $self->json_api("STREAM.UPDATE.$name", $config, $self->noting_direct($name, $cb));
}

# A KV or ObjectStore bucket made before allow_direct differs from $config
# only there: turn it on, keeping the stream's other settings, as nats.go
# does. A difference in a field the bucket sets is still refused. The
# server leaves false booleans out of the config it reports, and these
# limits when unset.
my %BUCKET_DEFAULT = (max_bytes => -1, max_age => 0, num_replicas => 1);

sub create_bucket_stream {
    my ($self, $config, $cb) = @_;
    $self->stream_create($config, sub {
        my ($info, $err) = @_;
        return $cb->($info, $err) unless $err && $err =~ /already in use with a different configuration/i;
        $self->stream_info($config->{name}, sub {
            my $have = $_[0] && $_[0]{config} or return $cb->(undef, $err);
            for my $k (grep { $_ ne 'allow_direct' } keys %$config, keys %BUCKET_DEFAULT) {
                my ($x, $y) = map {
                    ref($_) eq 'ARRAY' ? join("\0", @$_) : ref($_) || !defined($_) ? ($_ ? 1 : 0) : "$_"
                } map { $_->{$k} // $BUCKET_DEFAULT{$k} } $have, $config;
                return $cb->(undef, $err) if $x ne $y;
            }
            $self->stream_update({ %$have, allow_direct => JSON::PP::true() }, sub { $cb->(@_[0, 1]) });
        });
    });
}

sub stream_delete {
    my ($self, $name, $cb) = @_;
    delete $self->{direct}{$name};
    $self->json_api("STREAM.DELETE.$name", undef, $cb);
}

sub stream_info {
    my ($self, $name, @rest) = @_;
    my $cb   = pop @rest;
    my $opts = $rest[0];
    $self->json_api("STREAM.INFO.$name", $opts, $self->noting_direct($name, $cb));
}

# $leader: read through the stream leader. A Direct Get may be answered by
# a replica that has not applied the latest write yet.
sub get_msg {
    my ($self, $stream, $opts, $cb, $leader) = @_;
    return $self->get_msg_using($stream, $opts, 0, $cb) if $leader;
    my $direct = $self->{direct}{$stream};
    return $self->get_msg_using($stream, $opts, $direct, $cb) if defined $direct;
    my $waiting = $self->{direct_wait}{$stream} //= [];
    push @$waiting, [$opts, $cb];
    return if @$waiting > 1;
    my $asked = eval {
        $self->stream_info($stream, sub {
            my ($info, $err) = @_;
            for (@{ delete $self->{direct_wait}{$stream} }) {
                my ($o, $c) = @$_;
                $err ? $c->(undef, $err) : $self->get_msg_using($stream, $o, $self->{direct}{$stream}, $c);
            }
        });
        1;
    };
    return if $asked;
    delete $self->{direct_wait}{$stream};
    die $@;
}

sub get_msg_using {
    my ($self, $stream, $opts, $direct, $cb) = @_;
    if ($direct) {
        return $self->direct_get($stream, $opts, sub {
            my ($msg, $err) = @_;
            return $cb->($msg, $err) unless defined $err && $err eq 'no responders';
            $self->{direct}{$stream} = 0;
            $self->get_msg_using($stream, $opts, 0, $cb);
        });
    }
    $self->json_api("STREAM.MSG.GET.$stream", $opts, sub {
        my ($resp, $err) = @_;
        if ($err) {
            return $cb->(undef, undef) if $err =~ /no message found|\(code 10037\)/;
            return $cb->(undef, $err);
        }
        my $m = $resp->{message} or return $cb->(undef, undef);
        require MIME::Base64;
        $cb->({
            subject => $m->{subject},
            seq     => $m->{seq},
            time    => $m->{time},
            data    => MIME::Base64::decode_base64($m->{data} // ''),
            headers => defined $m->{hdrs} ? MIME::Base64::decode_base64($m->{hdrs}) : undef,
        }, undef);
    });
}

sub direct_get {
    my ($self, $stream, $opts, $cb) = @_;
    $self->{nats}->request("$self->{prefix}.DIRECT.GET.$stream", JSON::PP::encode_json($opts), sub {
        my ($data, $err, $hdr) = @_;
        return $cb->(undef, $err, $self->err_status($err)) if $err;
        $hdr //= '';
        if ($hdr =~ m{\ANATS/1\.0 (\d{3})(?: ([^\r\n]*))?}) {
            my ($code, $desc) = ($1, $2 // '');
            return $cb->(undef, undef) if $code == 404;
            return $cb->(undef, "direct get failed: NATS/1.0 $code" . (length $desc ? " $desc" : ''),
                $self->{with_status} ? ({ code => 0 + $code, description => $desc }) : ());
        }
        my %nats_hdr = map { /\ANats-([\w-]+):\s*(.*)\z/i ? (lc $1 => $2) : () } split /\r\n/, $hdr;
        $cb->({
            subject => $nats_hdr{subject},
            seq     => defined $nats_hdr{sequence} ? 0 + $nats_hdr{sequence} : undef,
            time    => $nats_hdr{'time-stamp'},
            data    => $data,
            headers => $hdr,
        }, undef);
    }, $self->{timeout});
}

sub stream_list {
    my ($self, $cb) = @_;
    $self->all_pages("STREAM.LIST", 'streams', $cb);
}

# the API pages its lists (256 per reply): one reply with every page merged
sub all_pages {
    my ($self, $subj, $key, $cb) = @_;
    $self->offset_pages(sub {
        my ($offset, $done) = @_;
        $self->json_api($subj, $offset ? { offset => $offset } : undef, sub {
            my ($resp, $err) = @_;
            return $cb->(@_) if $err;
            $done->($resp, $resp->{total},
                map { [ $_->{name} // $_->{config}{name} // '', $_ ] } @{ $resp->{$key} || [] });
        });
    }, sub {
        my ($items, $resp) = @_;
        $cb->({ %$resp, $key => $items, offset => 0, limit => scalar @$items }, undef);
    });
}

sub stream_purge {
    my ($self, $name, $cb) = @_;
    $self->json_api("STREAM.PURGE.$name", undef, $cb);
}

sub stream_msg_get {
    my ($self, $stream, $opts, $cb) = @_;
    $self->json_api("STREAM.MSG.GET.$stream", $opts, $cb);
}

sub consumer_create {
    my ($self, $stream, $config, $cb) = @_;
    my $name = $config->{durable_name} || $config->{name};
    my $subj = $name
        ? "CONSUMER.CREATE.$stream.$name"
        : "CONSUMER.CREATE.$stream";
    $self->json_api($subj, { stream_name => $stream, config => $config }, $cb);
}

sub consumer_delete {
    my ($self, $stream, $consumer, $cb) = @_;
    $self->json_api("CONSUMER.DELETE.$stream.$consumer", undef, $cb);
}

sub consumer_info {
    my ($self, $stream, $consumer, $cb) = @_;
    $self->json_api("CONSUMER.INFO.$stream.$consumer", undef, $cb);
}

sub consumer_list {
    my ($self, $stream, $cb) = @_;
    $self->all_pages("CONSUMER.LIST.$stream", 'consumers', $cb);
}

sub js_publish {
    my ($self, $subject, $payload, $cb) = @_;
    $self->{nats}->request($subject, $payload, $self->decoded($cb), $self->{timeout});
}

sub js_publish_h {
    my ($self, $subject, $headers, $payload, $cb) = @_;
    $self->{nats}->hrequest($subject, $headers, $payload, $self->decoded($cb), $self->{timeout});
}

# The server serves a pull until it expires even after a cancel or a
# reconnect, so the inbox stays open until then and late messages are -NAKed.
sub fetch {
    my ($self, $stream, $consumer, $opts, $cb) = @_;
    $opts //= {};
    # numified: JSON::PP sends a string the server rejects for an integer
    my $batch      = 0 + ($opts->{batch}   || 1);
    my $expires_ns = 0 + ($opts->{expires} || 5_000_000_000);
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
        $nats->unwatch_disconnect($watch) if defined $watch;
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

    $timer = $nats->timer($wait, 0, sub {
        $close->();
        $answer->([splice @messages]);
    });
    $watch = $nats->watch_disconnect(sub {
        undef $watch;
        return if $answered++;
        my @undelivered = splice @messages;
        later($nats, sub {
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

sub ack         { $_[0]->ack_reply($_[1], '+ACK') }
sub in_progress { $_[0]->ack_reply($_[1], '+WPI') }

sub nak {
    my ($self, $msg, $delay) = @_;
    return $self->ack_reply($msg, '-NAK') unless defined $delay;
    die "invalid nak delay '$delay'" unless $delay =~ /\A[0-9]+\z/;
    $self->ack_reply($msg, qq{-NAK {"delay":$delay}});
}

sub term {
    my ($self, $msg, $reason) = @_;
    $self->ack_reply($msg, defined $reason && length $reason ? "+TERM $reason" : '+TERM');
}

sub ack_sync {
    my ($self, $msg, $cb, $timeout_ms) = @_;
    my $reply = reply_of($msg);
    my $sent = eval {
        $self->{nats}->request($reply, '+ACK', sub { $cb->($_[1] ? (undef, $_[1]) : (1, undef)) },
            $timeout_ms // $self->{timeout});
        1;
    };
    return 1 if $sent;
    fail_later($self->{nats}, $cb, $@);
    return 0;
}

sub reply_of {
    my ($msg) = @_;
    my $reply = ref $msg ? $msg->{reply} : $msg;
    die "message has no reply subject" unless defined $reply && length $reply;
    return $reply;
}

sub ack_reply {
    my ($self, $msg, $body) = @_;
    my $reply = reply_of($msg);
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
C<< { code => 503, description => '' } >> for C<"no responders">, or the status that ended
a L</fetch>.

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

List all streams' info, every page of the API's reply merged.

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
under C<< $resp->{message}{data} >> and C<< $resp->{message}{hdrs} >>,
so a message larger than about 3/4 of C<max_payload> cannot be read
this way; see L</direct_get>.

=head3 direct_get

    direct_get($stream, \%opts, $cb)

Fetch a single message with Direct Get, from a stream created with
C<< allow_direct => true >>. Any replica may answer, so on a replicated
stream the result can trail a write that came just before.
C<\%opts> selects the message as for L</stream_msg_get>. Callback:
C<($msg, $err)>, with C<$msg>

    {
        subject => 'orders.new',
        seq     => 42,
        time    => '2026-11-26T11:36:54.412Z',
        data    => '...',     # raw bytes
        headers => "...",     # raw NATS/1.0 block, Nats-* headers included
    }

or C<undef> for a missing message.

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

Every page of the API's reply merged, as for L</stream_list>.

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
C<$cb>; messages that still arrive for the pull before it expires are
C<-NAK>ed.

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

=head3 ack_sync

    ack_sync($msg, $cb, [$timeout_ms])

Acknowledge and wait for the server to confirm it applied the ack.
Callback: C<($ok, $err)>; C<$err> is C<"request timeout"> when nothing
answers (e.g. a server in lame duck mode, or a consumer that is gone),
C<"no responders"> for a gone consumer when the connection has
C<no_responders> enabled, or C<"disconnected">. C<$timeout_ms> defaults
to the JetStream C<timeout>.

=head1 SEE ALSO

L<EV::Nats>, L<EV::Nats::KV>, L<EV::Nats::ObjectStore>,
L<JetStream API reference|https://docs.nats.io/reference/reference-protocols/nats_api_reference>.

=cut
