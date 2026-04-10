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
    $self->{js}{nats}->request($subj, '', sub {
        my ($resp, $err) = @_;
        return $cb->(undef, $err) if $err;
        $cb->($resp, undef);
    }, $self->{timeout});
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
            undef $timer;
            require JSON::PP;
            my $ack = eval { JSON::PP::decode_json($payload) };
            if ($@ || !$ack) { return $cb->(undef, "decode error: $@") }
            if ($ack->{error}) { return $cb->(undef, $ack->{error}{description}) }
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
    # KV delete = publish empty with KV-Operation: DEL header
    my $headers = "NATS/1.0\r\nKV-Operation: DEL\r\n\r\n";
    my $subj = '$KV.' . $self->{bucket} . '.' . $key;
    $self->{js}{nats}->hpublish($subj, $headers, '');
    $cb->(1, undef) if $cb;
}

sub purge {
    my ($self, $key, $cb) = @_;
    my $headers = "NATS/1.0\r\nKV-Operation: PURGE\r\nNats-Rollup: sub\r\n\r\n";
    my $subj = '$KV.' . $self->{bucket} . '.' . $key;
    $self->{js}{nats}->hpublish($subj, $headers, '');
    $cb->(1, undef) if $cb;
}

sub keys {
    my ($self, $cb) = @_;
    $self->{js}->stream_info($self->{stream}, sub {
        my ($info, $err) = @_;
        return $cb->(undef, $err) if $err;
        # Return subjects from stream state
        my $subjects = $info->{state}{subjects} || {};
        my $prefix = '$KV.' . $self->{bucket} . '.';
        my $plen = length $prefix;
        my @keys = map { substr($_, $plen) }
                   grep { substr($_, 0, $plen) eq $prefix }
                   CORE::keys %$subjects;
        $cb->(\@keys, undef);
    });
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
    my $config = {
        name      => $self->{stream},
        subjects  => ['$KV.' . $self->{bucket} . '.>'],
        retention => 'limits',
        max_msgs_per_subject => $opts->{max_history} || 1,
        ($opts->{max_bytes}   ? (max_bytes    => $opts->{max_bytes})   : ()),
        ($opts->{max_age}     ? (max_age      => $opts->{max_age})     : ()),
        ($opts->{replicas}    ? (num_replicas => $opts->{replicas})    : ()),
        discard   => 'new',
        allow_rollup_hdrs => 1,
        deny_delete       => 1,
        deny_purge        => 0,
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

EV::Nats::KV - Key-Value store API for NATS JetStream

=head1 SYNOPSIS

    use EV::Nats;
    use EV::Nats::JetStream;
    use EV::Nats::KV;

    my $nats = EV::Nats->new(host => '127.0.0.1');
    my $js = EV::Nats::JetStream->new(nats => $nats);
    my $kv = EV::Nats::KV->new(js => $js, bucket => 'config');

    # Create bucket (stream)
    $kv->create_bucket({}, sub { ... });

    # Put / Get / Delete
    $kv->put('app.setting', 'value', sub { ... });
    $kv->get('app.setting', sub { my ($val, $err) = @_; ... });
    $kv->delete('app.setting', sub { ... });

    # Watch for changes
    my $sid = $kv->watch('app.>', sub {
        my ($key, $value, $op) = @_;
        print "$op: $key = $value\n";
    });

    # List keys
    $kv->keys(sub { my ($keys, $err) = @_; ... });

=head1 METHODS

=head2 new(js => $js, bucket => $name, [timeout => $ms])

=head2 get($key, $cb)

=head2 put($key, $value, $cb)

=head2 create($key, $value, $cb) - put only if key doesn't exist

=head2 delete($key, [$cb])

=head2 purge($key, [$cb]) - remove all revisions

=head2 keys($cb) - list all keys

=head2 watch($pattern, $cb) - watch for changes

=head2 create_bucket(\%opts, $cb) - create underlying stream

=head2 delete_bucket($cb)

=head2 status($cb)

=cut
