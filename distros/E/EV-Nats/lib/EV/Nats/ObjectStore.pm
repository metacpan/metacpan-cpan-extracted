package EV::Nats::ObjectStore;
use strict;
use warnings;
use Digest::SHA qw(sha256_hex);
use EV::Nats::JetStream;

my $CHUNK_SIZE = 128 * 1024; # 128KB default

sub new {
    my ($class, %opts) = @_;
    my $js      = delete $opts{js}      || die "js (JetStream) required";
    my $bucket  = delete $opts{bucket}  || die "bucket name required";
    my $timeout = delete $opts{timeout} || $js->{timeout};
    bless {
        js         => $js,
        bucket     => $bucket,
        stream     => "OBJ_$bucket",
        chunk_size => $opts{chunk_size} || $CHUNK_SIZE,
        timeout    => $timeout,
    }, $class;
}

sub create_bucket {
    my ($self, $opts, $cb) = @_;
    $opts //= {};
    my $config = {
        name     => $self->{stream},
        subjects => [
            '$O.' . $self->{bucket} . '.C.>',  # chunks
            '$O.' . $self->{bucket} . '.M.>',  # metadata
        ],
        retention    => 'limits',
        ($opts->{max_bytes}    ? (max_bytes    => $opts->{max_bytes})    : ()),
        ($opts->{max_age}      ? (max_age      => $opts->{max_age})     : ()),
        ($opts->{replicas}     ? (num_replicas => $opts->{replicas})    : ()),
        discard      => 'new',
        allow_rollup_hdrs => 1,
    };
    $self->{js}->stream_create($config, $cb);
}

sub delete_bucket {
    my ($self, $cb) = @_;
    $self->{js}->stream_delete($self->{stream}, $cb);
}

sub put {
    my ($self, $name, $data, $cb) = @_;
    my $nuid   = _nuid();
    my $sha    = sha256_hex($data);
    my $size   = length $data;
    my $chunks = 0;
    my $offset = 0;
    my $nats   = $self->{js}{nats};
    my $chunk_subj = '$O.' . $self->{bucket} . '.C.' . $nuid;

    # Publish chunks via JetStream (with ack for durability)
    my $chunk_errors = 0;
    my $chunks_acked = 0;

    # Define completion handler before starting any publishes
    my $on_all_chunks = sub {
        if ($chunk_errors) {
            return $cb->(undef, "$chunk_errors chunk(s) failed to publish");
        }
        require JSON::PP;
        my $meta = JSON::PP::encode_json({
            name    => $name,
            size    => $size,
            chunks  => $chunks,
            nuid    => $nuid,
            digest  => "SHA-256=$sha",
            bucket  => $self->{bucket},
        });
        my $meta_subj = '$O.' . $self->{bucket} . '.M.' . _encode_name($name);
        $self->{js}->js_publish($meta_subj, $meta, sub {
            my ($ack, $err) = @_;
            return $cb->(undef, $err) if $err;
            $cb->({ name => $name, size => $size, chunks => $chunks, seq => $ack->{seq} }, undef);
        });
    };

    my $publish_chunk = sub {
        my $chunk = shift;
        $self->{js}->js_publish($chunk_subj, $chunk, sub {
            my ($ack, $err) = @_;
            $chunk_errors++ if $err;
            $chunks_acked++;
            $on_all_chunks->() if $chunks_acked >= $chunks;
        });
    };

    while ($offset < $size) {
        my $end = $offset + $self->{chunk_size};
        $end = $size if $end > $size;
        $publish_chunk->(substr($data, $offset, $end - $offset));
        $chunks++;
        $offset = $end;
    }

    if ($size == 0) {
        $publish_chunk->('');
        $chunks = 1;
    }
}

sub get {
    my ($self, $name, $cb) = @_;

    # Get metadata via JetStream STREAM.MSG.GET
    my $meta_subj = '$O.' . $self->{bucket} . '.M.' . _encode_name($name);
    $self->{js}->_json_api(
        'STREAM.MSG.GET.' . $self->{stream},
        { last_by_subj => $meta_subj },
        sub {
            my ($resp, $err) = @_;
            return $cb->(undef, $err) if $err;

            require JSON::PP;
            require MIME::Base64;
            my $raw = $resp->{message}{data} || '';
            my $meta_json = MIME::Base64::decode_base64($raw);
            my $meta = eval { JSON::PP::decode_json($meta_json) };
            if ($@ || !$meta) {
                return $cb->(undef, "invalid metadata: $@");
            }

            my $nuid = $meta->{nuid};
            my $expected = $meta->{chunks} || 0;
            my $chunk_subj = '$O.' . $self->{bucket} . '.C.' . $nuid;

            if ($expected == 0) {
                return $cb->('', undef, $meta);
            }

            # Fetch chunks sequentially via STREAM.MSG.GET
            my @chunks;
            my $seq = 0; # next_by_subj starts from seq+1

            my $fetch_next;
            $fetch_next = sub {
                $self->{js}->_json_api(
                    'STREAM.MSG.GET.' . $self->{stream},
                    { next_by_subj => $chunk_subj, seq => $seq },
                    sub {
                        my ($resp, $err) = @_;
                        if ($err) {
                            return $cb->(undef, "chunk fetch error: $err", $meta);
                        }
                        my $data = MIME::Base64::decode_base64($resp->{message}{data} || '');
                        push @chunks, $data;
                        $seq = $resp->{message}{seq} || ($seq + 1);

                        if (scalar @chunks >= $expected) {
                            my $assembled = join('', @chunks);
                            if ($meta->{digest} && $meta->{digest} =~ /^SHA-256=(.+)/) {
                                if (sha256_hex($assembled) ne $1) {
                                    return $cb->(undef, "digest mismatch", $meta);
                                }
                            }
                            $cb->($assembled, undef, $meta);
                        } else {
                            $fetch_next->();
                        }
                    }
                );
            };
            $fetch_next->();
        }
    );
}

sub delete {
    my ($self, $name, $cb) = @_;
    # Purge metadata entry
    my $headers = "NATS/1.0\r\nKV-Operation: PURGE\r\nNats-Rollup: sub\r\n\r\n";
    my $meta_subj = '$O.' . $self->{bucket} . '.M.' . _encode_name($name);
    $self->{js}{nats}->hpublish($meta_subj, $headers, '');
    $cb->(1, undef) if $cb;
}

sub info {
    my ($self, $name, $cb) = @_;
    my $meta_subj = '$O.' . $self->{bucket} . '.M.' . _encode_name($name);
    $self->{js}{nats}->request($meta_subj, '', sub {
        my ($resp, $err) = @_;
        return $cb->(undef, $err) if $err;
        require JSON::PP;
        my $meta = eval { JSON::PP::decode_json($resp) };
        $cb->($meta, $@ ? "JSON error: $@" : undef);
    }, $self->{timeout});
}

sub list {
    my ($self, $cb) = @_;
    $self->{js}->stream_info($self->{stream}, sub {
        my ($info, $err) = @_;
        return $cb->(undef, $err) if $err;
        my $subjects = $info->{state}{subjects} || {};
        my $prefix = '$O.' . $self->{bucket} . '.M.';
        my $plen = length $prefix;
        my @names = map { _decode_name(substr($_, $plen)) }
                    grep { substr($_, 0, $plen) eq $prefix }
                    keys %$subjects;
        $cb->(\@names, undef);
    });
}

sub status {
    my ($self, $cb) = @_;
    $self->{js}->stream_info($self->{stream}, sub {
        my ($info, $err) = @_;
        return $cb->(undef, $err) if $err;
        $cb->({
            bucket => $self->{bucket},
            bytes  => $info->{state}{bytes},
            sealed => $info->{config}{sealed} ? 1 : 0,
        }, undef);
    });
}

sub _nuid {
    my @chars = ('A'..'Z', 'a'..'z', '0'..'9');
    join '', map { $chars[rand @chars] } 1..22;
}

sub _encode_name { my $n = $_[0]; $n =~ s/([^A-Za-z0-9._-])/sprintf("%%%02X", ord($1))/ge; $n }
sub _decode_name { my $n = $_[0]; $n =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/ge; $n }

1;

=head1 NAME

EV::Nats::ObjectStore - Object store API for NATS JetStream

=head1 SYNOPSIS

    use EV::Nats;
    use EV::Nats::JetStream;
    use EV::Nats::ObjectStore;

    my $nats = EV::Nats->new(host => '127.0.0.1');
    my $js = EV::Nats::JetStream->new(nats => $nats);
    my $os = EV::Nats::ObjectStore->new(js => $js, bucket => 'files');

    $os->create_bucket({}, sub { ... });

    # Store object (automatically chunked)
    $os->put('report.pdf', $pdf_data, sub {
        my ($info, $err) = @_;
        print "stored: $info->{size} bytes in $info->{chunks} chunks\n";
    });

    # Retrieve
    $os->get('report.pdf', sub {
        my ($data, $err, $meta) = @_;
        print "got $meta->{size} bytes\n";
    });

=head1 METHODS

=head2 new(js => $js, bucket => $name, [chunk_size => $bytes])

Default chunk size: 128KB.

=head2 create_bucket(\%opts, $cb)

=head2 delete_bucket($cb)

=head2 put($name, $data, $cb)

=head2 get($name, $cb)

Callback: C<($data, $err, $meta)>.

=head2 delete($name, [$cb])

=head2 info($name, $cb)

=head2 list($cb)

=head2 status($cb)

=cut
