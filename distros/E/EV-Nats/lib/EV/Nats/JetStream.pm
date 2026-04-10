package EV::Nats::JetStream;
use strict;
use warnings;

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

sub _json_api {
    my ($self, $subj, $data, $cb) = @_;
    require JSON::PP;
    my $payload = defined $data ? JSON::PP::encode_json($data) : '';
    $self->_api($subj, $payload, sub {
        my ($resp, $err) = @_;
        return $cb->(undef, $err) if $err;
        my $decoded = eval { JSON::PP::decode_json($resp) };
        if ($@) {
            return $cb->(undef, "JSON decode error: $@");
        }
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
    my ($self, $name, $cb) = @_;
    $self->_json_api("STREAM.INFO.$name", undef, $cb);
}

sub stream_list {
    my ($self, $cb) = @_;
    $self->_json_api("STREAM.LIST", undef, $cb);
}

sub stream_purge {
    my ($self, $name, $cb) = @_;
    $self->_json_api("STREAM.PURGE.$name", undef, $cb);
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
        require JSON::PP;
        my $ack = eval { JSON::PP::decode_json($resp) };
        if ($@) {
            return $cb->(undef, "JSON decode error: $@");
        }
        if ($ack->{error}) {
            return $cb->(undef, "$ack->{error}{description}");
        }
        $cb->($ack, undef);
    }, $self->{timeout});
}

# Fetch messages (pull consumer)

sub fetch {
    my ($self, $stream, $consumer, $opts, $cb) = @_;
    $opts //= {};
    my $batch   = $opts->{batch}   || 1;
    my $expires = $opts->{expires} || 5_000_000_000; # 5s in nanoseconds
    $self->_json_api(
        "CONSUMER.MSG.NEXT.$stream.$consumer",
        { batch => $batch, expires => $expires },
        $cb,
    );
}

1;

=head1 NAME

EV::Nats::JetStream - JetStream API for EV::Nats

=head1 SYNOPSIS

    use EV::Nats;
    use EV::Nats::JetStream;

    my $nats = EV::Nats->new(host => '127.0.0.1', ...);
    my $js = EV::Nats::JetStream->new(nats => $nats);

    # Create stream
    $js->stream_create({
        name     => 'ORDERS',
        subjects => ['orders.>'],
    }, sub {
        my ($info, $err) = @_;
        die $err if $err;
        print "stream created: $info->{config}{name}\n";
    });

    # Publish with ack
    $js->js_publish('orders.new', '{"item":"widget"}', sub {
        my ($ack, $err) = @_;
        die $err if $err;
        print "published: seq=$ack->{seq}\n";
    });

=head1 METHODS

=head2 new(%opts)

    my $js = EV::Nats::JetStream->new(
        nats    => $nats,
        prefix  => '$JS.API',   # default
        timeout => 5000,         # ms
    );

=head2 stream_create($config, $cb)

=head2 stream_update($config, $cb)

=head2 stream_delete($name, $cb)

=head2 stream_info($name, $cb)

=head2 stream_list($cb)

=head2 stream_purge($name, $cb)

=head2 consumer_create($stream, $config, $cb)

=head2 consumer_delete($stream, $consumer, $cb)

=head2 consumer_info($stream, $consumer, $cb)

=head2 consumer_list($stream, $cb)

=head2 js_publish($subject, $payload, $cb)

Publish with JetStream acknowledgment.

=head2 fetch($stream, $consumer, \%opts, $cb)

Pull messages from a consumer. Options: C<batch>, C<expires>.

=cut
