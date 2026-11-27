package EV::Nats::KV;
use strict;
use warnings;
our $VERSION = '0.09';
use JSON::PP ();
use EV::Nats::JetStream;

sub new {
    my ($class, %opts) = @_;
    my $js      = delete $opts{js}      || die "js (JetStream) required";
    my $bucket  = delete $opts{bucket}  || die "bucket name required";
    # interpolated into subjects verbatim; the nats.go rule
    die "invalid KV bucket name '$bucket'" unless $bucket =~ /\A[a-zA-Z0-9_-]+\z/;
    my $timeout = delete $opts{timeout};
    warn "EV::Nats::KV::new: unknown option '$_'" for keys %opts;
    bless {
        js      => $js->with_timeout($timeout),
        bucket  => $bucket,
        stream  => "KV_$bucket",
        prefix  => "\$KV.$bucket.",
        # through a JetStream domain the server takes writes under the API
        # prefix, as nats.go sends them
        put_prefix => ($js->{prefix} eq '$JS.API' ? '' : "$js->{prefix}.") . "\$KV.$bucket.",
    }, $class;
}

# Keys go into subjects verbatim: a space is a fatal protocol error, and
# * or > would turn a lookup into a wildcard. The nats.go rule.
sub subject {
    my ($self, $key) = @_;
    die "invalid KV key '" . ($key // '') . "'"
        unless defined $key
            && $key =~ /\A[-\/_=.a-zA-Z0-9]+\z/
            && $key !~ /\A\./ && $key !~ /\.\z/;
    return $self->{prefix} . $key;
}

sub put_subject {
    my ($self, $key) = @_;
    $self->subject($key);
    return $self->{put_prefix} . $key;
}

sub get {
    my ($self, $key, $cb) = @_;
    $self->get_entry($key, sub {
        my ($entry, $err) = @_;
        $cb->($entry ? $entry->{value} : undef, $err);
    });
}

sub get_entry {
    my ($self, $key, $cb) = @_;
    my $subj = $self->subject($key);
    $self->{js}->get_msg($self->{stream}, { last_by_subj => $subj }, sub {
        my ($msg, $err) = @_;
        return $cb->(undef, $err) if $err;
        return $cb->(undef, undef) if !$msg || EV::Nats::JetStream::msg_is_tombstone($msg);
        $cb->({ value => $msg->{data}, revision => $msg->{seq} }, undef);
    });
}

sub put {
    my ($self, $key, $value, $cb) = @_;
    $self->{js}->js_publish($self->put_subject($key), $value, sub {
        my ($ack, $err) = @_;
        $cb->($ack && $ack->{seq}, $err);
    });
}

sub expect_publish {
    my ($self, $subj, $headers, $value, $cb) = @_;
    return $self->{js}{nats}->hpublish($subj, $headers, $value) unless $cb;
    $self->{js}->js_publish_h($subj, $headers, $value, sub {
        my ($ack, $err) = @_;
        $cb->($ack && $ack->{seq}, $err);
    });
}

sub create {
    my ($self, $key, $value, $cb) = @_;
    my $subj = $self->subject($key);
    my $put = $self->put_subject($key);
    $self->expect_publish($put,
        "NATS/1.0\r\nNats-Expected-Last-Subject-Sequence: 0\r\n\r\n",
        $value, $cb ? sub {
            my ($seq, $err) = @_;
            return $cb->($seq, $err) unless $err && $err =~ /wrong last sequence/i;
            $self->{js}->get_msg($self->{stream},
                { last_by_subj => $subj }, sub {
                    my ($msg, $read_err) = @_;
                    return $cb->(undef, $read_err) if $read_err;
                    return $cb->(undef, $err)
                        unless EV::Nats::JetStream::msg_is_tombstone($msg);
                    $self->expect_publish($put,
                        "NATS/1.0\r\nNats-Expected-Last-Subject-Sequence: $msg->{seq}\r\n\r\n",
                        $value, $cb);
                });
        } : undef);
}

sub update {
    my ($self, $key, $value, $rev, $cb) = @_;
    my $subj = $self->put_subject($key);
    die "invalid KV revision '" . ($rev // '') . "'"
        unless defined $rev && $rev =~ /\A[1-9][0-9]*\z/;
    $self->expect_publish($subj,
        "NATS/1.0\r\nNats-Expected-Last-Subject-Sequence: $rev\r\n\r\n",
        $value, $cb);
}

sub delete {
    my ($self, $key, $cb) = @_;
    $self->tombstone($key, "NATS/1.0\r\nKV-Operation: DEL\r\n\r\n", $cb);
}

sub purge {
    my ($self, $key, $cb) = @_;
    $self->tombstone($key, "NATS/1.0\r\nKV-Operation: PURGE\r\nNats-Rollup: sub\r\n\r\n", $cb);
}

# the PubAck fences the tombstone ahead of a following get
sub tombstone {
    my ($self, $key, $headers, $cb) = @_;
    my $subj = $self->put_subject($key);
    return $self->expect_publish($subj, $headers, '') unless $cb;
    my $ok = eval {
        $self->expect_publish($subj, $headers, '', sub { $cb->($_[1] ? (undef, $_[1]) : (1, undef)) });
        1;
    };
    EV::Nats::JetStream::fail_later($self->{js}{nats}, $cb, $@) unless $ok;
}

sub keys {
    my ($self, $cb) = @_;
    $self->{js}->subjects_under($self->{stream}, $self->{prefix}, $cb);
}

sub watch {
    my ($self, $key_pattern, $cb, $opts) = @_;
    $key_pattern //= '>';
    die "invalid KV watch pattern '$key_pattern'"
        if !length $key_pattern || $key_pattern =~ /\s/;
    $opts //= {};
    return EV::Nats::KV::Watch->new(
        kv       => $self,
        cb       => $cb,
        filter   => $self->{prefix} . $key_pattern,
        initial  => $opts->{initial} ? 1 : 0,
        ready    => $opts->{ready},
        on_error => $opts->{on_error},
    )->{sid};
}

sub create_bucket {
    my ($self, $opts, $cb) = @_;
    $opts //= {};
    my $config = {
        name      => $self->{stream},
        subjects  => [ $self->{prefix} . '>' ],
        retention => 'limits',
        max_msgs_per_subject => 0 + ($opts->{max_history} || 1),
        ($opts->{max_bytes}   ? (max_bytes    => 0 + $opts->{max_bytes})   : ()),
        ($opts->{max_age}     ? (max_age      => 0 + $opts->{max_age})     : ()),
        ($opts->{replicas}    ? (num_replicas => 0 + $opts->{replicas})    : ()),
        discard   => 'new',
        allow_rollup_hdrs => JSON::PP::true(),
        allow_direct      => JSON::PP::true(),
        deny_delete       => JSON::PP::true(),
        deny_purge        => JSON::PP::false(),
    };
    $self->{js}->create_bucket_stream($config, sub { $cb->(@_[0, 1]) });
}

sub delete_bucket {
    my ($self, $cb) = @_;
    $self->{js}->stream_delete($self->{stream}, sub { $cb->(@_[0, 1]) });
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

# An ordered view of the bucket through an ephemeral pull consumer. After a
# drop the consumer is replaced by one starting right past the last revision
# delivered; each incarnation pulls into its own inbox token, so what a
# replaced one still sends is told apart. Only the subscription holds the
# watch strongly: unsubscribing frees it, and DESTROY deletes the consumer.
package EV::Nats::KV::Watch;
use Scalar::Util ();

my $BATCH    = 256;
my $EXPIRES  = 30;   # s per pull
my $DEADLINE = 40;   # s by which a pull has ended, or its consumer is gone

sub new {
    my ($class, %w) = @_;
    my $w = bless { %w, last => 0, gen => 0 }, $class;
    my $nats = $w->nats;
    $w->{inbox} = $nats->new_inbox;
    $w->{sid} = $nats->subscribe("$w->{inbox}.*", sub { $w->deliver(@_) });
    $w->start;
    return $w;
}

sub nats { $_[0]{kv}{js}{nats} }

# held weakly, and never what keeps EV::run going
sub later {
    my ($w, $slot, $delay, $method) = @_;
    Scalar::Util::weaken(my $weak = $w);
    my $t = $w->nats->timer($delay, 0, sub {
        return unless $weak;
        delete $weak->{$slot};
        $weak->$method;
    });
    $t->keepalive(0);
    $w->{$slot} = $t;
}

sub retry {
    my ($w) = @_;
    $w->{backoff} = $w->{backoff} ? ($w->{backoff} * 2 > 30 ? 30 : $w->{backoff} * 2) : 1;
    $w->later(retry => $w->{backoff}, 'start');
}

sub start {
    my ($w) = @_;
    return if $w->{stopped} || !$w->nats->is_subscribed($w->{sid});
    my $gen = ++$w->{gen};
    my $old = delete $w->{consumer};
    delete $w->{deadline};
    $w->arm_disconnect;
    my $kv = $w->{kv};
    my $ok = eval {
        $kv->{js}->stream_info($kv->{stream}, sub {
            my ($info, $err) = @_;
            return unless $gen == $w->{gen};
            return $w->failed($err) if $err;
            # a bucket deleted and made again restarts its sequence
            my $created = $info->{created} // '';
            @$w{qw(last recreated)} = (0, 1)
                if defined $w->{created} && $w->{created} ne $created;
            $w->{created} = $created;
            $w->create_consumer($gen, $old);
        });
        1;
    };
    $w->retry unless $ok;
}

sub create_consumer {
    my ($w, $gen, $old) = @_;
    my $kv = $w->{kv};
    my %cfg = (ack_policy => 'none', filter_subject => $w->{filter},
               inactive_threshold => 60_000_000_000, num_replicas => 1,
               mem_storage => JSON::PP::true());
    if ($w->{recreated}) {
        $cfg{deliver_policy} = $w->{initial} ? 'last_per_subject' : 'all';
    } elsif ($w->{started} && ($w->{last} || !$w->{initial})) {
        @cfg{qw(deliver_policy opt_start_seq)} = ('by_start_sequence', $w->{last} + 1);
    } else {
        $cfg{deliver_policy} = $w->{initial} ? 'last_per_subject' : 'new';
    }
    my $ok = eval {
        $kv->{js}->consumer_create($kv->{stream}, \%cfg, sub {
            my ($info, $err) = @_;
            return unless $gen == $w->{gen};
            return $w->failed($err) if $err;
            delete @$w{qw(backoff recreated)};
            $w->{consumer} = $info->{name};
            $w->drop_consumer($old) if defined $old;
            # these report the revision before their first delivery
            $w->{last} = $info->{delivered}{stream_seq} || 0
                if $cfg{deliver_policy} =~ /\A(?:new|by_start_sequence)\z/;
            if (!$w->{started}++) {
                $w->{to_ready} = $info->{num_pending} || 0;
                $w->fire_ready unless $w->{to_ready};
            }
            $w->pull;
        });
        1;
    };
    $w->retry unless $ok;
}

sub drop_consumer {
    my ($w, $name) = @_;
    my $kv = $w->{kv};
    eval { $kv->{js}->consumer_delete($kv->{stream}, $name, sub {}); 1 };
}

sub fire_ready {
    my ($w) = @_;
    my $ready = delete $w->{ready} or return;
    $ready->();
}

sub pull {
    my ($w) = @_;
    return unless defined $w->{consumer};
    my $kv = $w->{kv};
    $w->{pending} = $BATCH;
    my $ok = eval {
        $w->nats->publish("$kv->{js}{prefix}.CONSUMER.MSG.NEXT.$kv->{stream}.$w->{consumer}",
            sprintf('{"batch":%d,"expires":%d}', $BATCH, $EXPIRES * 1_000_000_000),
            "$w->{inbox}.$w->{gen}");
        1;
    };
    return $w->retry unless $ok;
    $w->later(deadline => $DEADLINE, 'check');
}

# a pull ended unanswered or with a status: is its consumer still there?
sub check {
    my ($w, $delay) = @_;
    my ($gen, $kv) = ($w->{gen}, $w->{kv});
    return unless defined $w->{consumer};
    my $ok = eval {
        $kv->{js}->consumer_info($kv->{stream}, $w->{consumer}, sub {
            my (undef, $err) = @_;
            return unless $gen == $w->{gen};
            return if defined $err && $err eq 'disconnected';
            return $w->start if $err;
            $delay ? $w->later(retry => $delay, 'pull') : $w->pull;
        });
        1;
    };
    $w->retry unless $ok;
}

# a drop loses the pull in flight; starting over on the next loop pass
# finds the reconnect armed, so the new consumer is made once reconnected
sub arm_disconnect {
    my ($w) = @_;
    return if defined $w->{watch_id};
    Scalar::Util::weaken(my $weak = $w);
    $w->{watch_id} = $w->nats->watch_disconnect(sub {
        return unless $weak;
        delete $weak->{watch_id};
        $weak->later(retry => 0, 'start');
    });
}

sub failed {
    my ($w, $err) = @_;
    return if $err eq 'disconnected';   # the disconnect hook starts over
    # superseded consumers not yet expired fill the stream's limit for a while
    return $w->retry
        if $err =~ /\A(?:request timeout|no responders)\z|maximum consumers limit reached/i;
    $w->stop;
    my $report = $w->{on_error} || sub { warn "EV::Nats::KV watch: $_[0]\n" };
    $report->($err);
}

sub stop {
    my ($w) = @_;
    $w->{stopped} = 1;
    delete @$w{qw(retry deadline)};
    $w->nats->unwatch_disconnect(delete $w->{watch_id}) if defined $w->{watch_id};
}

sub DESTROY {
    my ($w) = @_;
    return if ${^GLOBAL_PHASE} eq 'DESTRUCT' || !$w->{kv};
    local $@;   # it runs inside the caller's unsubscribe
    eval { $w->nats->unwatch_disconnect($w->{watch_id}) } if defined $w->{watch_id};
    $w->drop_consumer($w->{consumer}) if defined $w->{consumer};
}

sub op_of {
    my ($headers) = @_;
    return 'PUT' unless defined $headers;
    return uc $1 if $headers =~ /^KV-Operation:\s*(\S+)/im;
    # a server TTL marker (nats-server 2.11+), as nats.go reads it
    return $1 eq 'Remove' ? 'DEL' : 'PURGE'
        if $headers =~ /^Nats-Marker-Reason:\s*(MaxAge|Purge|Remove)/im;
    return 'PUT';
}

sub deliver {
    my ($w, $subject, $payload, $reply, $headers) = @_;
    if (defined $headers && $headers =~ m{\ANATS/1\.0 (\d{3})}) {
        my $code = $1;
        my ($gen) = $subject =~ /\.(\d+)\z/;
        return unless $gen && $gen == $w->{gen};   # a replaced consumer's pull
        return if $code == 100;
        return $w->pull if $code == 404 || $code == 408;
        return $w->check(1);
    }
    # $JS.ACK.<stream>.<consumer>.<delivered>.<stream seq>..., with a
    # domain and account hash ahead of the stream in the 12-token form
    my @t = split /\./, $reply // '';
    my ($consumer, $seq) = @t == 9 ? @t[3, 5] : @t >= 12 ? @t[5, 7] : return;
    return unless defined $w->{consumer} && $consumer eq $w->{consumer} && $seq > $w->{last};
    $w->{last} = $seq;
    $w->pull unless --$w->{pending};
    my $ok = eval { $w->{cb}->(substr($subject, length $w->{kv}{prefix}), $payload, op_of($headers)); 1 };
    my $err = $@;
    $w->fire_ready if $w->{ready} && !--$w->{to_ready};
    die $err unless $ok;
}

package EV::Nats::KV;

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
that hide the underlying JetStream requests. Reads use Direct Get when
the bucket allows it (new buckets do, and C<create_bucket> turns it on
for an older one): on a replicated bucket a read can briefly trail a
write it follows, as with nats.go.

Keys must match C<[-/_=.a-zA-Z0-9]+> without leading or trailing
dots, and are validated up front.

=head1 METHODS

All callbacks fire on the L<EV> loop, not synchronously.

=head2 new

    new(js => $js, bucket => $name, [timeout => $ms])

The bucket need not exist yet; call L</create_bucket> first to
provision it. C<timeout> defaults to the timeout of C<$js>. The
bucket name must match C<[a-zA-Z0-9_-]+>.

=head2 get

    get($key, $cb)

Fetch the latest value for C<$key>. Callback: C<($value, $err)>.
C<$value> is C<undef> if the key does not exist, or has been deleted
or purged (the tombstone is recognised and surfaces as a clean miss).

=head2 get_entry

    get_entry($key, $cb)

Like L</get>, but the callback receives
C<< { value => $value, revision => $rev } >>, or C<undef> for a missing
key; C<revision> is what L</update> expects.

=head2 put

    put($key, $value, $cb)

Set C<$key> to C<$value>. Callback: C<($seq, $err)>, where C<$seq> is
the JetStream sequence number assigned by the server.

=head2 create

    create($key, $value, [$cb])

Like C<put>, but only succeeds if C<$key> is missing. With a callback,
deleted/purged keys can be recreated using the tombstone's revision;
concurrent creators see a wrong-last-sequence error. Callback: C<($seq, $err)>.
Without C<$cb> the headered publish is fire-and-forget.

=head2 update

    update($key, $value, $rev, [$cb])

Like C<put>, but only succeeds if C<$key>'s current revision is
C<$rev> (compare-and-swap). Callback: C<($seq, $err)>.

=head2 delete

    delete($key, [$cb])

Mark C<$key> as deleted by publishing a C<KV-Operation: DEL> tombstone.
Callback: C<($ok, $err)>, once the server has stored the tombstone.
Without C<$cb> the publish is fire-and-forget.

=head2 purge

    purge($key, [$cb])

Like C<delete>, but emits C<Nats-Rollup: sub> too -- the prior history
of C<$key> is rolled up and replaced by the tombstone, freeing storage.
Callback: C<($ok, $err)>.

=head2 keys

    keys($cb)

List all keys currently stored in the bucket. Callback: C<(\@keys, $err)>.
Tombstoned keys are not filtered out -- check with C<get> if needed.

=head2 watch

    watch($pattern, $cb, [\%opts])

Follow the changes the bucket stores, in order, through an ephemeral
JetStream consumer: a write the bucket rejects (a lost C<create> or
C<update>) is never reported, and after a reconnect the watch resumes
from the last revision it delivered. C<$pattern> is a NATS subject
suffix relative to the bucket (e.g. C<E<gt>> for all keys, C<app.E<gt>>
for everything under C<app.>); it must be non-empty and contain no
whitespace. Callback receives C<($key, $value, $op)> where C<$op> is
C<PUT>, C<DEL>, or C<PURGE>. Recognised C<\%opts>:

=over

=item * C<initial> - deliver each matching key's current value first.

=item * C<ready> - called once the watch is live and, with C<initial>,
the current values are delivered; changes from then on are reported.

=item * C<on_error> - called with the error when the bucket refuses the
watch, e.g. a missing bucket; the default warns.

=back

Returns a subscription id; pass it to L<EV::Nats/unsubscribe> to stop.

=head2 create_bucket

    create_bucket(\%opts, $cb)

Provision the underlying stream. Recognised C<\%opts>:

=over

=item * C<max_history> - default 1; how many revisions to keep per key.

=item * C<max_bytes> - bucket-wide storage cap.

=item * C<max_age> - per-message TTL in nanoseconds.

=item * C<replicas> - cluster replication factor.

=back

Callback: C<($info, $err)>.

=head2 delete_bucket

    delete_bucket($cb)

Tear down the underlying stream. Callback: C<($info, $err)>.

=head2 status

    status($cb)

Returns a snapshot hashref:

    { bucket => $name, values => $count, bytes => $n, history => $h }

Callback: C<(\%status, $err)>.

=head1 SEE ALSO

L<EV::Nats>, L<EV::Nats::JetStream>, L<EV::Nats::ObjectStore>,
L<NATS KV documentation|https://docs.nats.io/nats-concepts/jetstream/key-value-store>.

=cut
