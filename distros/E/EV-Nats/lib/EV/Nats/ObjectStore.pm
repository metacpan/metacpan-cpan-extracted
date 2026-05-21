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
    require JSON::PP;
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
        allow_rollup_hdrs => JSON::PP::true(),
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

    if ($size == 0) {
        $chunks = 1;
        $publish_chunk->('');
    } else {
        while ($offset < $size) {
            my $end = $offset + $self->{chunk_size};
            $end = $size if $end > $size;
            $publish_chunk->(substr($data, $offset, $end - $offset));
            $chunks++;
            $offset = $end;
        }
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

            my $msg = $resp->{message} or return $cb->(undef, undef);
            # Object was deleted: tombstone is on the metadata subject.
            return $cb->(undef, undef)
                if EV::Nats::JetStream::msg_is_tombstone($msg);

            require MIME::Base64;
            my $raw = $msg->{data} || '';
            my $meta_json = MIME::Base64::decode_base64($raw);
            my ($meta, $derr) = EV::Nats::JetStream::decode_json_or_error($meta_json);
            return $cb->(undef, "invalid metadata: $derr") if $derr;

            my $nuid = $meta->{nuid};
            my $expected = $meta->{chunks} || 0;
            my $chunk_subj = '$O.' . $self->{bucket} . '.C.' . $nuid;

            if ($expected == 0) {
                return $cb->('', undef, $meta);
            }

            # Fetch chunks sequentially via STREAM.MSG.GET.
            # next_by_subj returns first matching message with seq >= start_sequence,
            # so after each hit we must advance past the returned seq.
            my @chunks;
            my $seq = 1;

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
                        my $msg = $resp->{message} or
                            return $cb->(undef, "missing chunk message", $meta);
                        my $data = MIME::Base64::decode_base64($msg->{data} || '');
                        push @chunks, $data;
                        $seq = ($msg->{seq} || $seq) + 1;

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
    my $nats = $self->{js}{nats};

    my $tombstone = sub {
        my $purge_err = shift;
        my $headers = "NATS/1.0\r\nKV-Operation: PURGE\r\nNats-Rollup: sub\r\n\r\n";
        my $meta_subj = '$O.' . $self->{bucket} . '.M.' . _encode_name($name);
        $nats->hpublish($meta_subj, $headers, '');
        # Flush so the tombstone reaches the server before $cb fires; this
        # avoids a race with a subsequent info()/get() that would otherwise
        # see the pre-tombstone metadata.
        $nats->flush(sub {
            my ($flush_err) = @_;
            return unless $cb;
            my $err = $purge_err // $flush_err;
            $cb->($err ? undef : 1, $err);
        });
    };

    # Look up the object's nuid so we can purge its chunks.
    $self->info($name, sub {
        my ($meta, $err) = @_;
        if ($err || !$meta || !$meta->{nuid}) {
            return $tombstone->($err);
        }
        my $chunk_subj = '$O.' . $self->{bucket} . '.C.' . $meta->{nuid};
        $self->{js}->_json_api(
            'STREAM.PURGE.' . $self->{stream},
            { filter => $chunk_subj },
            sub {
                my ($resp, $purge_err) = @_;
                $tombstone->($purge_err);
            },
        );
    });
}

sub info {
    my ($self, $name, $cb) = @_;
    my $meta_subj = '$O.' . $self->{bucket} . '.M.' . _encode_name($name);
    $self->{js}->_json_api(
        'STREAM.MSG.GET.' . $self->{stream},
        { last_by_subj => $meta_subj },
        sub {
            my ($resp, $err) = @_;
            if ($err) {
                return $cb->(undef, undef) if $err =~ /no message found|10037/;
                return $cb->(undef, $err);
            }
            my $msg = $resp->{message} or return $cb->(undef, undef);
            # Tombstone: PURGE/DEL on the metadata subject -> object is gone.
            return $cb->(undef, undef)
                if EV::Nats::JetStream::msg_is_tombstone($msg);

            require MIME::Base64;
            my $raw = $msg->{data} || '';
            my $meta_json = MIME::Base64::decode_base64($raw);
            my ($meta, $derr) = EV::Nats::JetStream::decode_json_or_error($meta_json);
            $cb->($meta, $derr ? "invalid metadata: $derr" : undef);
        },
    );
}

sub list {
    my ($self, $cb) = @_;
    my $prefix = '$O.' . $self->{bucket} . '.M.';
    $self->{js}->stream_info(
        $self->{stream},
        { subjects_filter => $prefix . '>' },
        sub {
            my ($info, $err) = @_;
            return $cb->(undef, $err) if $err;
            my $subjects = $info->{state}{subjects} || {};
            my $plen = length $prefix;
            my @names = map { _decode_name(substr($_, $plen)) }
                        grep { substr($_, 0, $plen) eq $prefix }
                        keys %$subjects;
            $cb->(\@names, undef);
        },
    );
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

EV::Nats::ObjectStore - Chunked object store on top of NATS JetStream

=head1 SYNOPSIS

    use EV;
    use EV::Nats;
    use EV::Nats::JetStream;
    use EV::Nats::ObjectStore;

    my $nats = EV::Nats->new(host => '127.0.0.1');
    my $js   = EV::Nats::JetStream->new(nats => $nats);
    my $os   = EV::Nats::ObjectStore->new(js => $js, bucket => 'files');

    $os->create_bucket({}, sub {
        $os->put('report.pdf', $pdf_data, sub {
            my ($info, $err) = @_;
            print "stored: $info->{size} bytes in $info->{chunks} chunks\n";
            $os->get('report.pdf', sub {
                my ($data, $err, $meta) = @_;
                print "got $meta->{size} bytes back\n";
            });
        });
    });

    EV::run;

=head1 DESCRIPTION

An object-store bucket is a JetStream stream named C<OBJ_E<lt>bucketE<gt>>
with two subject groups:

=over

=item * C<$O.E<lt>bucketE<gt>.C.E<lt>nuidE<gt>> - opaque chunks for one
object (one chunk per stream message; the nuid is generated per object).

=item * C<$O.E<lt>bucketE<gt>.M.E<lt>encoded-nameE<gt>> - last-write-wins
metadata describing an object (name, size, chunk count, SHA-256 digest).

=back

C<put> chunks the input, publishes each chunk via C<js_publish> for
durability, then writes a metadata entry. C<get> fetches the metadata,
walks the chunks back via C<STREAM.MSG.GET>, and verifies the digest.

=head1 METHODS

All callbacks fire on the L<EV> loop, not synchronously.

=head2 new(js => $js, bucket => $name, [chunk_size => $bytes])

Default C<chunk_size> is 128 KiB. C<timeout> defaults to the timeout
of C<$js>.

=head2 create_bucket(\%opts, $cb)

Provision the underlying stream. Recognised C<\%opts>:

=over

=item * C<max_bytes> - bucket-wide storage cap.

=item * C<max_age> - per-message TTL in nanoseconds.

=item * C<replicas> - cluster replication factor.

=back

Callback: C<($info, $err)>.

=head2 delete_bucket($cb)

Tear down the underlying stream. Callback: C<($info, $err)>.

=head2 put($name, $data, $cb)

Store C<$data> under C<$name>, automatically chunked. Each chunk is
published with JetStream ack; the metadata entry is written last so
a partial upload doesn't surface a half-stored object. Callback:
C<($info, $err)> where C<$info> is C<{ name, size, chunks, seq }>.

=head2 get($name, $cb)

Retrieve a previously-stored object. Callback: C<($data, $err, $meta)>.
C<$data> is C<undef> if the object does not exist or has been deleted
(the tombstone is recognised). On digest mismatch, C<$data> is C<undef>
and C<$err> is C<"digest mismatch">.

=head2 delete($name, [$cb])

Looks up the object's nuid via metadata, purges all chunks under
C<$O.E<lt>bucketE<gt>.C.E<lt>nuidE<gt>> via C<STREAM.PURGE>, then
publishes a C<KV-Operation: PURGE> tombstone on the metadata subject
followed by a C<flush> fence. Callback: C<($ok, $err)>; C<$err> is
set if the chunk purge or flush failed.

=head2 info($name, $cb)

Fetch only the metadata entry for an object, without downloading
chunks. Callback: C<(\%meta, $err)>; C<\%meta> is C<undef> if the
object does not exist or was deleted (the tombstone is recognised).
This is the recommended way to filter live objects out of a
L</list> result.

=head2 list($cb)

List names of all live objects in the bucket. Callback:
C<(\@names, $err)>. Tombstoned entries appear in the listing -- call
C<info> to filter.

=head2 status($cb)

Returns a snapshot hashref:

    { bucket => $name, bytes => $n, sealed => 0|1 }

C<sealed> reflects the underlying stream's C<config.sealed> flag;
this client never seals on its own, so unless someone manually
sealed the stream out-of-band the value is always 0.

Callback: C<(\%status, $err)>.

=head1 SEE ALSO

L<EV::Nats>, L<EV::Nats::JetStream>, L<EV::Nats::KV>,
L<NATS Object Store|https://docs.nats.io/using-nats/developer/develop_jetstream/object>.

=cut
