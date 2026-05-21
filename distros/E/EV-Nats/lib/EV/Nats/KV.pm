package EV::Nats::KV;
use strict;
use warnings;
use EV::Nats::JetStream;

sub new {
    my ($class, %opts) = @_;
    my $js      = delete $opts{js}      || die "js (JetStream) required";
    my $bucket  = delete $opts{bucket}  || die "bucket name required";
    my $timeout = delete $opts{timeout} || $js->{timeout};
    bless {
        js      => $js,
        bucket  => $bucket,
        stream  => "KV_$bucket",
        timeout => $timeout,
    }, $class;
}

sub get {
    my ($self, $key, $cb) = @_;
    my $subj = '$KV.' . $self->{bucket} . '.' . $key;
    $self->{js}->_json_api(
        'STREAM.MSG.GET.' . $self->{stream},
        { last_by_subj => $subj },
        sub {
            my ($resp, $err) = @_;
            if ($err) {
                # 10037 = "no message found" -- treat as missing key
                return $cb->(undef, undef) if $err =~ /no message found|10037/;
                return $cb->(undef, $err);
            }
            my $msg = $resp->{message};
            return $cb->(undef, undef) unless $msg;
            # DEL/PURGE tombstones surface as missing
            return $cb->(undef, undef)
                if EV::Nats::JetStream::msg_is_tombstone($msg);

            require MIME::Base64;
            my $value = MIME::Base64::decode_base64($msg->{data} || '');
            $cb->($value, undef);
        },
    );
}

sub put {
    my ($self, $key, $value, $cb) = @_;
    my $subj = '$KV.' . $self->{bucket} . '.' . $key;
    $self->{js}->js_publish($subj, $value, sub {
        my ($ack, $err) = @_;
        return $cb->(undef, $err) if $err;
        $cb->($ack->{seq}, undef);
    });
}

sub create {
    my ($self, $key, $value, $cb) = @_;
    my $nats = $self->{js}{nats};
    my $headers = "NATS/1.0\r\nNats-Expected-Last-Subject-Sequence: 0\r\n\r\n";
    my $subj = '$KV.' . $self->{bucket} . '.' . $key;

    if ($cb) {
        my $inbox = $nats->new_inbox;
        my ($sid, $timer);
        $sid = $nats->subscribe_max($inbox, sub {
            my ($s, $payload) = @_;
            if ($timer) { $timer->stop; undef $timer; }
            my ($ack, $derr) = EV::Nats::JetStream::decode_json_or_error($payload);
            return $cb->(undef, $derr) if $derr;
            return $cb->(undef, $ack->{error}{description}) if $ack->{error};
            $cb->($ack->{seq}, undef);
        }, 1);
        $timer = EV::timer($self->{timeout} / 1000.0, 0, sub {
            $nats->unsubscribe($sid);
            $cb->(undef, "create timeout");
        });
        $nats->hpublish($subj, $headers, $value, $inbox);
    } else {
        $nats->hpublish($subj, $headers, $value);
    }
}

sub delete {
    my ($self, $key, $cb) = @_;
    # KV delete = publish empty with KV-Operation: DEL header.
    # flush() ensures the tombstone reaches the server before $cb fires
    # so a subsequent get() doesn't race the publish.
    my $headers = "NATS/1.0\r\nKV-Operation: DEL\r\n\r\n";
    my $subj = '$KV.' . $self->{bucket} . '.' . $key;
    my $nats = $self->{js}{nats};
    $nats->hpublish($subj, $headers, '');
    $nats->flush(sub { $cb->(defined $_[0] ? undef : 1, $_[0]) }) if $cb;
}

sub purge {
    my ($self, $key, $cb) = @_;
    my $headers = "NATS/1.0\r\nKV-Operation: PURGE\r\nNats-Rollup: sub\r\n\r\n";
    my $subj = '$KV.' . $self->{bucket} . '.' . $key;
    my $nats = $self->{js}{nats};
    $nats->hpublish($subj, $headers, '');
    $nats->flush(sub { $cb->(defined $_[0] ? undef : 1, $_[0]) }) if $cb;
}

sub keys {
    my ($self, $cb) = @_;
    my $prefix = '$KV.' . $self->{bucket} . '.';
    $self->{js}->stream_info(
        $self->{stream},
        { subjects_filter => $prefix . '>' },
        sub {
            my ($info, $err) = @_;
            return $cb->(undef, $err) if $err;
            my $subjects = $info->{state}{subjects} || {};
            my $plen = length $prefix;
            my @keys = map { substr($_, $plen) }
                       grep { substr($_, 0, $plen) eq $prefix }
                       CORE::keys %$subjects;
            $cb->(\@keys, undef);
        },
    );
}

sub watch {
    my ($self, $key_pattern, $cb) = @_;
    $key_pattern //= '>';
    my $subj = '$KV.' . $self->{bucket} . '.' . $key_pattern;
    return $self->{js}{nats}->subscribe($subj, sub {
        my ($subject, $payload, $reply, $headers) = @_;
        my $prefix = '$KV.' . $self->{bucket} . '.';
        my $key = substr($subject, length $prefix);
        my $op = 'PUT';
        if ($headers && $headers =~ /KV-Operation:\s*(\S+)/i) {
            $op = uc $1;
        }
        $cb->($key, $payload, $op);
    });
}

sub create_bucket {
    my ($self, $opts, $cb) = @_;
    $opts //= {};
    require JSON::PP;
    my $config = {
        name      => $self->{stream},
        subjects  => ['$KV.' . $self->{bucket} . '.>'],
        retention => 'limits',
        max_msgs_per_subject => $opts->{max_history} || 1,
        ($opts->{max_bytes}   ? (max_bytes    => $opts->{max_bytes})   : ()),
        ($opts->{max_age}     ? (max_age      => $opts->{max_age})     : ()),
        ($opts->{replicas}    ? (num_replicas => $opts->{replicas})    : ()),
        discard   => 'new',
        allow_rollup_hdrs => JSON::PP::true(),
        deny_delete       => JSON::PP::true(),
        deny_purge        => JSON::PP::false(),
    };
    $self->{js}->stream_create($config, $cb);
}

sub delete_bucket {
    my ($self, $cb) = @_;
    $self->{js}->stream_delete($self->{stream}, $cb);
}

sub status {
    my ($self, $cb) = @_;
    $self->{js}->stream_info($self->{stream}, sub {
        my ($info, $err) = @_;
        return $cb->(undef, $err) if $err;
        $cb->({
            bucket  => $self->{bucket},
            values  => $info->{state}{messages},
            bytes   => $info->{state}{bytes},
            history => $info->{config}{max_msgs_per_subject},
        }, undef);
    });
}

1;

=head1 NAME

EV::Nats::KV - Key-Value store on top of NATS JetStream

=head1 SYNOPSIS

    use EV;
    use EV::Nats;
    use EV::Nats::JetStream;
    use EV::Nats::KV;

    my $nats = EV::Nats->new(host => '127.0.0.1');
    my $js   = EV::Nats::JetStream->new(nats => $nats);
    my $kv   = EV::Nats::KV->new(js => $js, bucket => 'config');

    $kv->create_bucket({}, sub {
        $kv->put('app.setting', 'on', sub {
            $kv->get('app.setting', sub {
                my ($val, $err) = @_;
                print "got: $val\n";
            });
        });
    });

    # Live updates
    $kv->watch('app.>', sub {
        my ($key, $value, $op) = @_;
        print "$op $key = $value\n";
    });

    EV::run;

=head1 DESCRIPTION

A KV bucket is a JetStream stream named C<KV_E<lt>bucketE<gt>> with
subjects C<$KV.E<lt>bucketE<gt>.E<gt>>, history of 1, rollup headers
allowed, and deletes denied (purge tombstones are used instead).
This module wraps that convention: C<put>/C<get> become single calls
that hide the underlying C<js_publish> + C<STREAM.MSG.GET> dance.

=head1 METHODS

All callbacks fire on the L<EV> loop, not synchronously.

=head2 new(js => $js, bucket => $name, [timeout => $ms])

The bucket need not exist yet; call L</create_bucket> first to
provision it. C<timeout> defaults to the timeout of C<$js>.

=head2 get($key, $cb)

Fetch the latest value for C<$key>. Callback: C<($value, $err)>.
C<$value> is C<undef> if the key does not exist, or has been deleted
or purged (the tombstone is recognised and surfaces as a clean miss).

=head2 put($key, $value, $cb)

Set C<$key> to C<$value>. Callback: C<($seq, $err)>, where C<$seq> is
the JetStream sequence number assigned by the server.

=head2 create($key, $value, $cb)

Like C<put>, but only succeeds if C<$key> does not yet exist. Uses
C<Nats-Expected-Last-Subject-Sequence: 0>; concurrent creators see
a wrong-last-sequence error from the server. Callback: C<($seq, $err)>.

=head2 delete($key, [$cb])

Mark C<$key> as deleted by publishing a C<KV-Operation: DEL> tombstone,
followed by a C<flush> fence so a subsequent C<get> won't race the
publish. Callback: C<($ok, $err)>; C<$err> is set if the connection
dropped before the PONG arrived.

=head2 purge($key, [$cb])

Like C<delete>, but emits C<Nats-Rollup: sub> too -- the prior history
of C<$key> is rolled up and replaced by the tombstone, freeing storage.
Callback: C<($ok, $err)>.

=head2 keys($cb)

List all keys currently stored in the bucket. Callback: C<(\@keys, $err)>.
Tombstoned keys are not filtered out -- check with C<get> if needed.

=head2 watch($pattern, $cb)

Subscribe to live changes. C<$pattern> is a NATS subject suffix relative
to the bucket (e.g. C<E<gt>> for all keys, C<app.E<gt>> for everything
under C<app.>). Callback receives C<($key, $value, $op)> where C<$op>
is C<PUT>, C<DEL>, or C<PURGE>. Returns the underlying subscription
id; pass to L<EV::Nats/unsubscribe> to stop.

=head2 create_bucket(\%opts, $cb)

Provision the underlying stream. Recognised C<\%opts>:

=over

=item * C<max_history> - default 1; how many revisions to keep per key.

=item * C<max_bytes> - bucket-wide storage cap.

=item * C<max_age> - per-message TTL in nanoseconds.

=item * C<replicas> - cluster replication factor.

=back

Callback: C<($info, $err)>.

=head2 delete_bucket($cb)

Tear down the underlying stream. Callback: C<($info, $err)>.

=head2 status($cb)

Returns a snapshot hashref:

    { bucket => $name, values => $count, bytes => $n, history => $h }

Callback: C<(\%status, $err)>.

=head1 SEE ALSO

L<EV::Nats>, L<EV::Nats::JetStream>, L<EV::Nats::ObjectStore>,
L<NATS KV documentation|https://docs.nats.io/nats-concepts/jetstream/key-value-store>.

=cut
