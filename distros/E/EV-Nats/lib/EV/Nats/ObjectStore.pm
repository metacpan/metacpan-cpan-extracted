package EV::Nats::ObjectStore;
use strict;
use warnings;
use Digest::SHA qw(sha256 sha256_hex);
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
    # Look up any existing object first so its old chunks / legacy %XX meta
    # can be purged after the new meta is rolled up. A real error aborts.
    $self->_raw_meta($name, sub {
        my ($old_meta, $old_subj, $old_gone, $err) = @_;
        return $cb->(undef, $err) if $err;

        my $nuid   = _nuid();
        # ADR-20 digest: padded base64url of the raw SHA-256 (nats.go form).
        my $sha    = _b64url(sha256($data));
        my $size   = length $data;
        my $chunks = 0;
        my $offset = 0;
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
            # Nats-Rollup: sub keeps exactly one message on the meta subject.
            my $headers = "NATS/1.0\r\nNats-Rollup: sub\r\n\r\n";
            $self->{js}->js_publish_h($meta_subj, $headers, $meta, sub {
                my ($ack, $err) = @_;
                return $cb->(undef, $err) if $err;

                # Purge the previous object's chunks, and its legacy %XX
                # meta subject when found there (migrate to base64url).
                my @purges;
                if ($old_meta && !$old_gone
                    && length($old_meta->{nuid} // '')
                    && $old_meta->{nuid} ne $nuid) {
                    push @purges, '$O.' . $self->{bucket} . '.C.' . $old_meta->{nuid};
                }
                my $legacy_subj = '$O.' . $self->{bucket} . '.M.' . _encode_name_legacy($name);
                if ($old_subj && $old_subj eq $legacy_subj) {
                    push @purges, $legacy_subj;
                }
                # The put already succeeded (meta rolled up); old-chunk
                # cleanup is best-effort.
                my $run_purge;
                $run_purge = sub {
                    my $filter = shift @purges;
                    if (!defined $filter) {
                        # Break the $run_purge self-cycle before firing $cb.
                        undef $run_purge;
                        return $cb->({ name => $name, size => $size, chunks => $chunks, seq => $ack->{seq} }, undef);
                    }
                    $self->{js}->_json_api(
                        'STREAM.PURGE.' . $self->{stream},
                        { filter => $filter },
                        sub { $run_purge->() },   # ignore purge errors
                    );
                };
                $run_purge->();
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
            # Fix the total first: an ack arriving before the loop ends would
            # otherwise complete the object with a short count.
            $chunks = int(($size + $self->{chunk_size} - 1) / $self->{chunk_size});
            while ($offset < $size) {
                my $end = $offset + $self->{chunk_size};
                $end = $size if $end > $size;
                $publish_chunk->(substr($data, $offset, $end - $offset));
                $offset = $end;
            }
        }
    });
}

sub get {
    my ($self, $name, $cb) = @_;

    $self->_raw_meta($name, sub {
        my ($meta, $meta_subj, $gone, $err) = @_;
        return $cb->(undef, $err) if $err;
        # Missing object or deleted marker: a clean miss, same as KV::get.
        return $cb->(undef, undef) if !$meta || $gone;

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
                        # Break the $fetch_next self-cycle before firing
                        # $cb, or the closure pins $self forever.
                        undef $fetch_next;
                        return $cb->(undef, "chunk fetch error: $err", $meta);
                    }
                    my $msg = $resp->{message};
                    if (!$msg) {
                        undef $fetch_next;
                        return $cb->(undef, "missing chunk message", $meta);
                    }
                    require MIME::Base64;
                    my $data = MIME::Base64::decode_base64($msg->{data} || '');
                    push @chunks, $data;
                    $seq = ($msg->{seq} || $seq) + 1;

                    if (scalar @chunks >= $expected) {
                        my $assembled = join('', @chunks);
                        if ($meta->{digest} && $meta->{digest} =~ /^SHA-256=(.+)\z/) {
                            # Accept all three writers: 0.03/0.04 hex, 0.05
                            # unpadded base64url, and 0.06+/nats.go padded.
                            my $stored = $1;
                            my $ok;
                            if ($stored =~ /\A[0-9a-f]{64}\z/) {
                                $ok = sha256_hex($assembled) eq $stored;
                            } else {
                                (my $s = $stored) =~ s/=+\z//;
                                (my $g = _b64url(sha256($assembled))) =~ s/=+\z//;
                                $ok = $g eq $s;
                            }
                            unless ($ok) {
                                undef $fetch_next;
                                return $cb->(undef, "digest mismatch", $meta);
                            }
                        }
                        undef $fetch_next;
                        $cb->($assembled, undef, $meta);
                    } else {
                        $fetch_next->();
                    }
                }
            );
        };
        $fetch_next->();
    });
}

sub delete {
    my ($self, $name, $cb) = @_;
    # nats.go marks a delete with the full metadata JSON carrying
    # "deleted":true and a rollup header, not an empty KV-Operation tombstone.
    $self->_raw_meta($name, sub {
        my ($meta, $found_subj, $gone, $err) = @_;
        return $cb ? $cb->(undef, $err) : undef if $err;
        # Idempotent: nothing live to delete -> success, no spurious marker.
        return $cb ? $cb->(1, undef) : undef if !$meta || $gone;

        my $prefix = '$O.' . $self->{bucket} . '.M.';
        my $meta_subj   = $prefix . _encode_name($name);
        my $legacy_subj = $prefix . _encode_name_legacy($name);
        my $nuid        = length($meta->{nuid} // '') ? $meta->{nuid} : undef;

        require JSON::PP;
        my $marker = JSON::PP::encode_json({
            name    => $name,
            bucket  => $self->{bucket},
            nuid    => '',
            size    => 0,
            chunks  => 0,
            digest  => '',
            deleted => JSON::PP::true(),
        });
        my $headers = "NATS/1.0\r\nNats-Rollup: sub\r\n\r\n";

        # Mark deleted first (nats.go order) so a best-effort cleanup purge
        # can't leave a "deleted" object still readable.
        $self->{js}->js_publish_h($meta_subj, $headers, $marker, sub {
            my ($ack, $perr) = @_;
            return $cb ? $cb->(undef, $perr) : undef if $perr;

            my @cleanup;
            push @cleanup, '$O.' . $self->{bucket} . '.C.' . $nuid if $nuid;
            # A live meta at the legacy %XX subject would resurface via the
            # dual-read fallback / list(); purge it too.
            push @cleanup, $legacy_subj if $found_subj && $found_subj eq $legacy_subj;

            my $step; $step = sub {
                my $subj = shift @cleanup;
                if (!defined $subj) { undef $step; return $cb ? $cb->(1, undef) : undef }
                $self->{js}->_json_api(
                    'STREAM.PURGE.' . $self->{stream},
                    { filter => $subj },
                    sub { $step->() },   # best-effort: ignore purge errors
                );
            };
            $step->();
        });
    });
}

sub info {
    my ($self, $name, $cb) = @_;
    $self->_raw_meta($name, sub {
        my ($meta, $meta_subj, $gone, $err) = @_;
        return $cb->(undef, $err) if $err;
        # Missing or deleted (tombstone or "deleted":true): a clean miss.
        return $cb->(undef, undef) if !$meta || $gone;
        $cb->($meta, undef);
    });
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
            # Best-effort decode: base64url names (0.06+/nats.go) and
            # legacy %XX names (0.03-0.05) can share a bucket.
            my @names = map { _decode_name_best(substr($_, $plen)) }
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

# ($meta, $found_subject, $is_gone, $err) -> $cb. Dual-read: base64url meta
# subject first, then legacy %XX (0.03-0.05 buckets stay readable). $is_gone
# covers a KV-Operation tombstone and a "deleted":true meta; $meta is still
# returned when gone so delete() can read its nuid.
sub _raw_meta {
    my ($self, $name, $cb) = @_;
    my $prefix = '$O.' . $self->{bucket} . '.M.';
    my @try = $prefix . _encode_name($name);
    my $legacy = $prefix . _encode_name_legacy($name);
    push @try, $legacy if $legacy ne $try[0];

    my $attempt;
    $attempt = sub {
        my $meta_subj = shift @try;
        if (!defined $meta_subj) {
            # Break the $attempt self-cycle before firing $cb.
            undef $attempt;
            return $cb->(undef, undef, 0, undef);
        }
        $self->{js}->_json_api(
            'STREAM.MSG.GET.' . $self->{stream},
            { last_by_subj => $meta_subj },
            sub {
                my ($resp, $err) = @_;
                if ($err) {
                    # Clean miss on this subject -> try the fallback form.
                    return $attempt->() if $err =~ /no message found|10037/;
                    undef $attempt;
                    return $cb->(undef, undef, 0, $err);
                }
                my $msg = $resp->{message};
                return $attempt->() if !$msg;
                my $tombstone = EV::Nats::JetStream::msg_is_tombstone($msg);
                require MIME::Base64;
                my $meta_json = MIME::Base64::decode_base64($msg->{data} || '');
                my ($meta, $derr);
                # A tombstone's payload is empty; only parse real data.
                if (length $meta_json) {
                    ($meta, $derr) = EV::Nats::JetStream::decode_json_or_error($meta_json);
                    if ($derr) {
                        undef $attempt;
                        return $cb->(undef, $meta_subj, 0, "invalid metadata: $derr");
                    }
                }
                my $gone = ($tombstone || ($meta && $meta->{deleted})) ? 1 : 0;
                undef $attempt;
                $cb->($meta, $meta_subj, $gone, undef);
            }
        );
    };
    $attempt->();
}

sub _nuid {
    my @chars = ('A'..'Z', 'a'..'z', '0'..'9');
    join '', map { $chars[rand @chars] } 1..22;
}

# padded base64url of a byte/most-strings value, matching Go URLEncoding
sub _b64url {
    my $bytes = shift;
    utf8::encode($bytes) if utf8::is_utf8($bytes);   # names may be wide
    require MIME::Base64;
    (my $e = MIME::Base64::encode_base64($bytes, '')) =~ tr{+/}{-_};
    return $e;                                        # keeps '=' padding
}
# inverse: padded-or-unpadded base64url -> UTF-8-decoded string
sub _b64url_dec {
    my $s = shift;
    $s =~ tr{-_}{+/};
    require MIME::Base64;
    my $b = MIME::Base64::decode_base64($s);          # tolerant of padding
    utf8::decode($b);
    return $b;
}

# ADR-20 name encoding: padded base64url (nats.go). The 0.03-0.05 %XX
# percent form is kept as *_legacy for the dual-read fallback.
sub _encode_name { _b64url($_[0]) }
sub _decode_name { _b64url_dec($_[0]) }
sub _encode_name_legacy { my $n = $_[0]; $n =~ s/([^A-Za-z0-9._-])/sprintf("%%%02X", ord($1))/ge; $n }
sub _decode_name_legacy { my $n = $_[0]; $n =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/ge; $n }

# Best-effort name decode for list(): the base64url form wins when
# re-encoding round-trips, otherwise fall back to the legacy %XX form.
sub _decode_name_best {
    my $tok = shift;
    my $dec = _b64url_dec($tok);
    return $dec if _encode_name($dec) eq $tok;
    return _decode_name_legacy($tok);
}

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

=head2 new

    new(js => $js, bucket => $name, [chunk_size => $bytes])

Default C<chunk_size> is 128 KiB. C<timeout> defaults to the timeout
of C<$js>.

=head2 create_bucket

    create_bucket(\%opts, $cb)

Provision the underlying stream. Recognised C<\%opts>:

=over

=item * C<max_bytes> - bucket-wide storage cap.

=item * C<max_age> - per-message TTL in nanoseconds.

=item * C<replicas> - cluster replication factor.

=back

Callback: C<($info, $err)>.

=head2 delete_bucket

    delete_bucket($cb)

Tear down the underlying stream. Callback: C<($info, $err)>.

=head2 put

    put($name, $data, $cb)

Store C<$data> under C<$name>, automatically chunked. Each chunk is
published with JetStream ack; the metadata entry is written last
(with a C<Nats-Rollup: sub> header, so the meta subject holds exactly
one message) so a partial upload doesn't surface a half-stored object.
Overwriting an existing name purges the previous object's chunks after
the new metadata is acknowledged. Callback: C<($info, $err)> where
C<$info> is C<{ name, size, chunks, seq }>.

=head2 get

    get($name, $cb)

Retrieve a previously-stored object. Callback: C<($data, $err, $meta)>.
C<$data> is C<undef> if the object does not exist or has been deleted
(both the old C<KV-Operation> tombstone and the nats.go
C<"deleted":true> marker are recognised). On digest mismatch, C<$data>
is C<undef> and C<$err> is C<"digest mismatch">. Digests written by
0.03/0.04 (hex), 0.05 (unpadded base64url) and 0.06+/nats.go (padded
base64url) all verify.

=head2 delete

    delete($name, [$cb])

Publishes a C<"deleted":true> metadata marker with a C<Nats-Rollup:
sub> header (the nats.go form; the PubAck doubles as the flush fence),
then best-effort purges the object's chunks under
C<$O.E<lt>bucketE<gt>.C.E<lt>nuidE<gt>>. Marking is done first, so a
purge hiccup cannot leave a "deleted" object still readable. Idempotent:
deleting a missing or already-deleted object is a no-op success and
writes no marker. Callback: C<($ok, $err)>.

=head2 info

    info($name, $cb)

Fetch only the metadata entry for an object, without downloading
chunks. Callback: C<(\%meta, $err)>; C<\%meta> is C<undef> if the
object does not exist or was deleted (the deletion marker is
recognised). This is the recommended way to filter live objects out
of a L</list> result.

=head2 list

    list($cb)

List object names in the bucket. Callback: C<(\@names, $err)>.
Names written by 0.03-0.05 (legacy %XX encoding) and by 0.06+/nats.go
(base64url) are both decoded. Deleted entries still appear in the
listing -- filtering them would cost a per-name metadata round-trip,
so call C<info> to filter.

=head2 status

    status($cb)

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
