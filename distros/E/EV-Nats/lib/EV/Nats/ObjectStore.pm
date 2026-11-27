package EV::Nats::ObjectStore;
use strict;
use warnings;
our $VERSION = '0.09';
use Digest::SHA qw(sha256 sha256_hex);
use JSON::PP ();
use MIME::Base64 ();
use EV::Nats::JetStream;

my $CHUNK_SIZE = 128 * 1024;
my $PUT_WINDOW = 16;   # chunks in flight; each one's timeout runs from its own send
my @NUID_CHARS = ('A'..'Z', 'a'..'z', '0'..'9');

sub new {
    my ($class, %opts) = @_;
    my $js      = delete $opts{js}      || die "js (JetStream) required";
    my $bucket  = delete $opts{bucket}  || die "bucket name required";
    die "invalid ObjectStore bucket name '$bucket'"
        unless $bucket =~ /\A[a-zA-Z0-9_-]+\z/;
    my $timeout = delete $opts{timeout};
    my $chunk_size = delete $opts{chunk_size} || $CHUNK_SIZE;
    die "invalid chunk_size '$chunk_size'"
        unless $chunk_size =~ /\A\d+\z/ && $chunk_size > 0;
    warn "EV::Nats::ObjectStore::new: unknown option '$_'" for keys %opts;
    bless {
        js           => $js->with_timeout($timeout),
        bucket       => $bucket,
        stream       => "OBJ_$bucket",
        chunk_prefix => "\$O.$bucket.C.",
        meta_prefix  => "\$O.$bucket.M.",
        chunk_size   => $chunk_size,
    }, $class;
}

sub create_bucket {
    my ($self, $opts, $cb) = @_;
    $opts //= {};
    my $config = {
        name     => $self->{stream},
        subjects => [ $self->{chunk_prefix} . '>', $self->{meta_prefix} . '>' ],
        retention    => 'limits',
        ($opts->{max_bytes}    ? (max_bytes    => 0 + $opts->{max_bytes})    : ()),
        ($opts->{max_age}      ? (max_age      => 0 + $opts->{max_age})     : ()),
        ($opts->{replicas}     ? (num_replicas => 0 + $opts->{replicas})    : ()),
        discard      => 'new',
        allow_rollup_hdrs => JSON::PP::true(),
        allow_direct => JSON::PP::true(),
    };
    $self->{js}->create_bucket_stream($config, sub { $cb->(@_[0, 1]) });
}

sub delete_bucket {
    my ($self, $cb) = @_;
    $self->{js}->stream_delete($self->{stream}, sub { $cb->(@_[0, 1]) });
}

# Survives a dead connection: a sync croak (not connected, nothing
# queued) skips the purge and runs $cb now.
sub purge_best_effort {
    my ($self, $filter, $cb) = @_;
    my $ok = eval {
        $self->{js}->json_api('STREAM.PURGE.' . $self->{stream},
            { filter => $filter }, $cb);
        1;
    };
    $cb->() unless $ok;
}

sub purge_each {
    my ($self, $done, @filters) = @_;
    return $done->() unless @filters;
    my $filter = shift @filters;
    $self->purge_best_effort($filter, sub { $self->purge_each($done, @filters) });
}

sub put {
    my ($self, $name, $data, $cb) = @_;
    # the chunks, the size and the digest must all see the same bytes
    utf8::downgrade($data, 1) or die "ObjectStore put: wide character in data\n";
    my $nats = $self->{js}{nats};
    # fail here rather than in a chunk publish; before the first INFO
    # max_payload is only the default
    if ($nats->is_connected) {
        my $max = $nats->max_payload;
        die "chunk_size ($self->{chunk_size}) exceeds max_payload ($max)"
            if $max > 0 && $self->{chunk_size} > $max;
    }
    # the previous object's chunks and legacy meta go once the new meta is stored
    $self->raw_meta($name, sub {
        my ($old_meta, $old_subj, $old_gone, $err) = @_;
        return $cb->(undef, $err) if $err;

        my $nuid = nuid();
        my $size = length $data;
        my $cs   = $self->{chunk_size};
        my $chunks = $size ? int(($size + $cs - 1) / $cs) : 1;
        my $chunk_subj = $self->{chunk_prefix} . $nuid;

        my $store_meta = sub {
            my ($failed) = @_;
            return $self->purge_best_effort($chunk_subj,
                sub { $cb->(undef, "$failed chunk(s) failed to publish") }) if $failed;
            my $meta = JSON::PP::encode_json({
                name   => meta_name($name),
                size   => $size,
                chunks => $chunks,
                nuid   => $nuid,
                # ADR-20: padded base64url of the raw SHA-256, as nats.go writes it
                digest => 'SHA-256=' . b64url(sha256($data)),
                bucket => $self->{bucket},
            });
            my $on_meta = sub {
                my ($ack, $err) = @_;
                return $self->purge_best_effort($chunk_subj, sub { $cb->(undef, $err) })
                    if $err;
                my @stale;
                push @stale, $self->{chunk_prefix} . $old_meta->{nuid}
                    if $old_meta && !$old_gone && length($old_meta->{nuid} // '')
                        && $old_meta->{nuid} ne $nuid;
                my $legacy = $self->{meta_prefix} . encode_name_legacy($name);
                push @stale, $legacy if $old_subj && $old_subj eq $legacy;
                $self->purge_each(sub {
                    $cb->({ name => $name, size => $size, chunks => $chunks, seq => $ack->{seq} }, undef);
                }, @stale);
            };
            # the rollup keeps exactly one message on the meta subject
            eval {
                $self->{js}->js_publish_h($self->{meta_prefix} . encode_name($name),
                    "NATS/1.0\r\nNats-Rollup: sub\r\n\r\n", $meta, $on_meta);
                1;
            } or do {
                my $err = $@;
                $self->purge_best_effort($chunk_subj, sub { $cb->(undef, $err) });
            };
        };
        $self->put_chunks({ data => $data, subj => $chunk_subj, chunks => $chunks,
                            sent => 0, acked => 0, failed => 0, done => $store_meta });
    });
}

# a failure stops further sends; done fires once every sent chunk is answered
sub put_chunks {
    my ($self, $st) = @_;
    my $cs = $self->{chunk_size};
    while ($st->{sent} < $st->{chunks} && !$st->{failed}
           && $st->{sent} - $st->{acked} < $PUT_WINDOW) {
        my $chunk = substr $st->{data}, $st->{sent}++ * $cs, $cs;
        next if eval {
            $self->{js}->js_publish($st->{subj}, $chunk, sub {
                $st->{failed}++ if $_[1];
                $st->{acked}++;
                $self->put_chunks($st);
            });
            1;
        };
        $st->{failed}++;
        $st->{acked}++;
    }
    return unless $st->{acked} == $st->{sent}
        && ($st->{sent} == $st->{chunks} || $st->{failed});
    my $done = delete $st->{done} or return;
    $done->($st->{failed});
}

sub get {
    my ($self, $name, $cb) = @_;
    $self->raw_meta($name, sub {
        my ($meta, undef, $gone, $err) = @_;
        return $cb->(undef, $err) if $err;
        # a missing or deleted object is a clean miss, as in KV::get
        return $cb->(undef, undef) if !$meta || $gone;
        return $cb->('', undef, $meta) unless $meta->{chunks};
        $self->fetch_chunks($meta, 1, [], $cb);
    });
}

# next_by_subj answers the first match at or after seq. A replica that has
# not caught up misses a chunk the leader has: ask the leader before failing.
sub fetch_chunks {
    my ($self, $meta, $seq, $chunks, $cb, $leader) = @_;
    $self->{js}->get_msg($self->{stream},
        { next_by_subj => $self->{chunk_prefix} . $meta->{nuid}, seq => $seq }, sub {
            my ($msg, $err) = @_;
            return $cb->(undef, "chunk fetch error: $err", $meta) if $err;
            return $self->fetch_chunks($meta, $seq, $chunks, $cb, 1) if !$msg && !$leader;
            return $cb->(undef, "missing chunk message", $meta) unless $msg;
            push @$chunks, $msg->{data};
            return $self->fetch_chunks($meta, ($msg->{seq} || $seq) + 1, $chunks, $cb)
                if @$chunks < $meta->{chunks};
            my $data = join '', @$chunks;
            return $cb->(undef, "digest mismatch", $meta) unless digest_ok($meta->{digest}, $data);
            $cb->($data, undef, $meta);
        }, $leader);
}

# hex and unpadded base64url digests come from older writers
sub digest_ok {
    my ($digest, $data) = @_;
    return 1 unless $digest && $digest =~ /^SHA-256=(.+)\z/;
    my $stored = $1;
    return sha256_hex($data) eq $stored if $stored =~ /\A[0-9a-f]{64}\z/;
    (my $s = $stored) =~ s/=+\z//;
    (my $g = b64url(sha256($data))) =~ s/=+\z//;
    return $g eq $s;
}

sub delete {
    my ($self, $name, $cb) = @_;
    $cb //= sub {};
    # nats.go marks a delete with the full metadata carrying "deleted":true
    # under a rollup, not with an empty KV-Operation tombstone
    $self->raw_meta($name, sub {
        my ($meta, $found_subj, $gone, $err) = @_;
        return $cb->(undef, $err) if $err;
        # nothing live: success, and no spurious marker
        return $cb->(1, undef) if !$meta || $gone;
        my $marker = JSON::PP::encode_json({
            name    => meta_name($name),
            bucket  => $self->{bucket},
            nuid    => '',
            size    => 0,
            chunks  => 0,
            digest  => '',
            deleted => JSON::PP::true(),
        });
        my $legacy = $self->{meta_prefix} . encode_name_legacy($name);
        # marked first, as nats.go does, so a failed purge cannot leave it readable
        $self->{js}->js_publish_h($self->{meta_prefix} . encode_name($name),
            "NATS/1.0\r\nNats-Rollup: sub\r\n\r\n", $marker, sub {
                my (undef, $perr) = @_;
                return $cb->(undef, $perr) if $perr;
                my @cleanup;
                push @cleanup, $self->{chunk_prefix} . $meta->{nuid} if length($meta->{nuid} // '');
                # a live legacy meta would resurface through the dual read and list()
                push @cleanup, $legacy if $found_subj && $found_subj eq $legacy;
                $self->purge_each(sub { $cb->(1, undef) }, @cleanup);
            });
    });
}

sub info {
    my ($self, $name, $cb) = @_;
    $self->raw_meta($name, sub {
        my ($meta, undef, $gone, $err) = @_;
        return $cb->(undef, $err) if $err;
        $cb->($meta && !$gone ? $meta : undef, undef);
    });
}

sub list {
    my ($self, $cb) = @_;
    $self->{js}->subjects_under($self->{stream}, $self->{meta_prefix}, sub {
        my ($tokens, $err) = @_;
        return $cb->(undef, $err) if $err;
        $cb->([ map { decode_name_best($_) } @$tokens ], undef);
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

# ($meta, $found_subject, $is_gone, $err) -> $cb. The base64url subject is
# read first, then the legacy %XX one. $is_gone covers a KV-Operation
# tombstone and a "deleted":true meta; $meta still comes back when gone,
# so delete() can read its nuid.
sub raw_meta {
    my ($self, $name, $cb) = @_;
    my @try = ($self->{meta_prefix} . encode_name($name));
    my $legacy = $self->{meta_prefix} . encode_name_legacy($name);
    push @try, $legacy if $legacy ne $try[0];
    $self->meta_at($cb, @try);
}

sub meta_at {
    my ($self, $cb, $subj, @rest) = @_;
    return $cb->(undef, undef, 0, undef) unless defined $subj;
    $self->{js}->get_msg($self->{stream}, { last_by_subj => $subj }, sub {
        my ($msg, $err) = @_;
        return $cb->(undef, undef, 0, $err) if $err;
        return $self->meta_at($cb, @rest) unless $msg;
        my ($meta, $derr);
        # a tombstone's payload is empty
        if (length($msg->{data} // '')) {
            ($meta, $derr) = EV::Nats::JetStream::decode_json_or_error($msg->{data});
            return $cb->(undef, $subj, 0, "invalid metadata: $derr") if $derr;
        }
        my $gone = EV::Nats::JetStream::msg_is_tombstone($msg) || ($meta && $meta->{deleted}) ? 1 : 0;
        $cb->($meta, $subj, $gone, undef);
    }, 1);   # put and delete act on it: a replica's lagging copy would mislead them
}

# concurrent writers' chunk subjects must never collide
sub nuid {
    my $bytes = '';
    if (open my $fh, '<:raw', '/dev/urandom') {
        read $fh, $bytes, 22;
    }
    $bytes .= chr int rand 256 while length $bytes < 22;
    return join '', map { $NUID_CHARS[ord($_) % @NUID_CHARS] } split //, $bytes;
}

# padded base64url of bytes, as Go's URLEncoding
sub b64url {
    (my $e = MIME::Base64::encode_base64($_[0], '')) =~ tr{+/}{-_};
    return $e;
}

# padded or unpadded base64url to a UTF-8-decoded string
sub b64url_dec {
    my $s = shift;
    $s =~ tr{-_}{+/};
    my $b = MIME::Base64::decode_base64($s);
    utf8::decode($b);
    return $b;
}

# ADR-20 names are padded base64url of the name's bytes (a character string
# as UTF-8); *_legacy is the older %XX form
sub encode_name {
    my $n = shift;
    utf8::encode($n) if utf8::is_utf8($n);
    return b64url($n);
}

# the metadata's name is text: UTF-8 bytes are decoded so it names the same
# subject for every client, not encoded a second time by the JSON encoder
sub meta_name {
    my $n = shift;
    return $n if utf8::is_utf8($n);
    my $text = $n;
    return utf8::decode($text) ? $text : $n;
}
sub encode_name_legacy { my $n = $_[0]; $n =~ s/([^A-Za-z0-9._-])/sprintf("%%%02X", ord($1))/ge; $n }
sub decode_name_legacy { my $n = $_[0]; $n =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/ge; $n }

# the base64url form wins when re-encoding round-trips
sub decode_name_best {
    my $tok = shift;
    my $dec = b64url_dec($tok);
    return $dec if encode_name($dec) eq $tok;
    return decode_name_legacy($tok);
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
    my $pdf_data = '...';  # your file bytes here

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
reads the chunks back with Direct Get (C<STREAM.MSG.GET> for a bucket
without C<allow_direct>), and verifies the digest.

=head1 METHODS

All callbacks fire on the L<EV> loop, not synchronously.

=head2 new

    new(js => $js, bucket => $name, [chunk_size => $bytes], [timeout => $ms])

Default C<chunk_size> is 128 KiB. C<timeout> defaults to the timeout
of C<$js>. The bucket name must match C<[a-zA-Z0-9_-]+> and
C<chunk_size> must be a positive integer; both are validated up
front. C<chunk_size> must also not exceed the server's
C<max_payload> (checked on L</put> once connected).

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
is C<undef> and C<$err> is C<"digest mismatch">.

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
Deleted entries still appear in the listing -- filtering them would
cost a per-name metadata round-trip, so call C<info> to filter.

=head2 status

    status($cb)

Returns a snapshot hashref:

    { bucket => $name, bytes => $n, sealed => 0|1 }

C<sealed> reflects the stream's C<config.sealed> flag.

Callback: C<(\%status, $err)>.

=head1 SEE ALSO

L<EV::Nats>, L<EV::Nats::JetStream>, L<EV::Nats::KV>,
L<NATS Object Store|https://docs.nats.io/using-nats/developer/develop_jetstream/object>.

=cut
