use strict;
use warnings;
use Test::More;
use MIME::Base64 qw(encode_base64 encode_base64url decode_base64);
use Digest::SHA qw(sha256 sha256_hex);
use JSON::PP ();
use EV::Nats::ObjectStore;
use EV::Nats::KV;

# Pure-Perl layer regressions (ObjectStore digest format, get() lifetime,
# clean misses, KV validation, ADR-20/nats.go wire compat) against a mock
# JetStream. No socket at all.

# ---- mock JetStream: a tiny in-memory stream keyed by subject ----
# Acks are DEFERRED, like a real connection: on the live client js_publish
# goes through $nats->request and the ack arrives from the event loop, so
# put()'s publish loop always finishes before the first ack lands. A
# synchronous mock hides the real ordering bug this exercises.
{
    package MockJS;
    sub new {
        bless { store => {}, seq => 0, nats => MockConn->new, timeout => 100 }, shift;
    }
    sub js_publish {
        my ($self, $subj, $payload, $cb) = @_;
        $self->{store}{$subj} = { data => MIME::Base64::encode_base64($payload, ''),
                                  seq  => ++$self->{seq} };
        push @{ $self->{order} }, $subj;
        my $seq = $self->{seq};
        push @{ $self->{pending} }, sub { $cb->({ seq => $seq }, undef) };
    }
    # Headered publish with PubAck (Nats-Rollup meta/marker writes).
    sub js_publish_h {
        my ($self, $subj, $headers, $payload, $cb) = @_;
        my %m = (data => MIME::Base64::encode_base64($payload, ''),
                 seq  => ++$self->{seq});
        $m{hdrs} = MIME::Base64::encode_base64($headers, '') if defined $headers;
        $self->{store}{$subj} = \%m;
        push @{ $self->{order} }, $subj;
        push @{ $self->{hpubs} },
            { subject => $subj, headers => $headers, payload => $payload };
        my $seq = $self->{seq};
        push @{ $self->{pending} }, sub { $cb->({ seq => $seq }, undef) };
    }
    sub drain {   # stand-in for the event loop
        my ($self) = @_;
        while (my $t = shift @{ $self->{pending} || [] }) { $t->() }
    }
    sub stream_info {
        my ($self, $name, @rest) = @_;
        my $cb = pop @rest;
        my %subs = map { $_ => 1 } keys %{ $self->{store} };
        $cb->({ state => { subjects => \%subs } }, undef);
    }
    sub _json_api {
        my ($self, $subj, $body, $cb) = @_;
        if ($subj =~ /^STREAM\.MSG\.GET\./) {
            $self->{msg_gets}++;
            if (my $s = $body->{last_by_subj}) {
                my $m = $self->{store}{$s}
                    or return $cb->(undef, 'no message found (code 404)');
                return $cb->({ message => { %$m, subject => $s } }, undef);
            }
            if (my $s = $body->{next_by_subj}) {
                my $start = $body->{seq} || 1;
                for my $sub (@{ $self->{order} || [] }) {
                    next unless $sub eq $s;
                    my $m = $self->{store}{$sub};
                    next if $m->{seq} < $start;
                    return $cb->({ message => { %$m, subject => $sub } }, undef);
                }
                return $cb->(undef, 'no message found (code 404)');
            }
        }
        if ($subj =~ /^STREAM\.PURGE\./) {
            my $filter = $body ? $body->{filter} : undef;
            push @{ $self->{purges} }, $filter;
            if (defined $filter) {
                delete $self->{store}{$filter};
                @{ $self->{order} } = grep { $_ ne $filter } @{ $self->{order} || [] };
            } else {
                $self->{store} = {};
                $self->{order} = [];
            }
            return $cb->({ purged => 1, success => JSON::PP::true() }, undef);
        }
        $cb->({}, undef);
    }
}
{
    package MockConn;
    sub new { bless {}, shift }
    sub new_inbox { '_INBOX.x.1' }
    sub subscribe { 1 }
    sub subscribe_max { 1 }
    sub unsubscribe { }
    sub hpublish { }
    sub flush { $_[1]->(undef) if $_[1] }
}
{
    # DESTROY runs the callback it holds: proves the ObjectStore it rode in
    # on was really freed. (Note it must own a fresh referent -- blessing a
    # ref to the caller's flag would bless the FLAG, whose lifetime has
    # nothing to do with the ObjectStore's.)
    package Guard;
    sub new { my ($class, $cb) = @_; bless { cb => $cb }, $class }
    sub DESTROY { $_[0]{cb}->() }
}

sub rewrite_digest {
    my ($js, $meta_subj, $replacement) = @_;
    my $j = decode_base64($js->{store}{$meta_subj}{data});
    $j =~ s/SHA-256=[^"]+/$replacement/;
    $js->{store}{$meta_subj}{data} = encode_base64($j, '');
}

# padded base64url of raw bytes, computed independently of the module
sub padded_b64url { (my $e = encode_base64($_[0], '')) =~ tr{+/}{-_}; $e }

subtest 'name encoding is padded base64url, legacy percent form kept' => sub {
    plan tests => 5;
    is EV::Nats::ObjectStore::_encode_name('report.txt'), 'cmVwb3J0LnR4dA==',
       'encode_name is padded base64url (nats.go form)';
    is EV::Nats::ObjectStore::_decode_name('cmVwb3J0LnR4dA=='), 'report.txt',
       'decode_name round-trips';
    my $uni = "r\x{e9}sum\x{e9}.txt";
    is EV::Nats::ObjectStore::_decode_name(EV::Nats::ObjectStore::_encode_name($uni)),
       $uni, 'unicode name round-trips';
  SKIP: {
        skip 'legacy encoders not present (pre-0.06 ObjectStore)', 2
            unless defined &EV::Nats::ObjectStore::_encode_name_legacy;
        is EV::Nats::ObjectStore::_encode_name_legacy('a b.txt'), 'a%20b.txt',
           'legacy percent encoder kept';
        is EV::Nats::ObjectStore::_decode_name_legacy('a%20b.txt'), 'a b.txt',
           'legacy percent decoder kept';
    }
};

subtest 'ObjectStore digest is padded base64url, all legacy digests verify, corrupt rejected' => sub {
    plan tests => 10;
    my $js = MockJS->new;
    my $os = EV::Nats::ObjectStore->new(js => $js, bucket => 'B');
    my $data = 'hello object store' x 10;
    $os->put('thing', $data, sub { });
    $js->drain;
    my ($meta_subj) = grep { /\.M\./ } keys %{ $js->{store} };
    my $meta = JSON::PP::decode_json(decode_base64($js->{store}{$meta_subj}{data}));

    is $meta->{digest}, 'SHA-256=' . padded_b64url(sha256($data)),
       'put writes SHA-256=<padded base64url of raw digest>';
    like $meta->{digest}, qr/=\z/, 'digest keeps the = padding (nats.go form)';
    unlike $meta->{digest}, qr/\ASHA-256=[0-9a-f]{64}\z/, 'digest is not legacy hex';

    my $got;
    $os->get('thing', sub { $got = [ @_ ] });
    is $got->[0], $data, 'round-trip get returns the data';
    is $got->[1], undef, 'new digest verifies (no error)';

    # Buckets written by 0.03/0.04 carry hex; they must still verify.
    rewrite_digest($js, $meta_subj, 'SHA-256=' . sha256_hex($data));
    undef $got;
    $os->get('thing', sub { $got = [ @_ ] });
    is $got->[0], $data, 'legacy hex digest returns the data';
    is $got->[1], undef, 'legacy hex digest verifies (no error)';

    # Buckets written by 0.05 carry unpadded base64url; also accepted.
    rewrite_digest($js, $meta_subj, 'SHA-256=' . encode_base64url(sha256($data)));
    undef $got;
    $os->get('thing', sub { $got = [ @_ ] });
    is $got->[0], $data, '0.05 unpadded base64url digest returns the data';
    is $got->[1], undef, '0.05 unpadded base64url digest verifies (no error)';

    # A genuinely corrupt digest must still be caught.
    rewrite_digest($js, $meta_subj, 'SHA-256=deadbeef');
    undef $got;
    $os->get('thing', sub { $got = [ @_ ] });
    like $got->[1], qr/digest mismatch/, 'corrupt digest still rejected';
};

subtest 'put rolls up the meta subject' => sub {
    plan tests => 4;
    my $js = MockJS->new;
    my $os = EV::Nats::ObjectStore->new(js => $js, bucket => 'B');
    my $info;
    $os->put('report.txt', 'x' x 100, sub { $info = [ @_ ] });
    $js->drain;
    is $info->[1], undef, 'put succeeded';
    ok $info->[0]{seq}, 'put returns the PubAck seq';
    my ($hp) = grep { $_->{subject} eq '$O.B.M.cmVwb3J0LnR4dA==' } @{ $js->{hpubs} || [] };
    ok $hp, 'meta published at the base64url meta subject';
    ok $hp && $hp->{headers} =~ /Nats-Rollup: sub/, 'meta publish carried Nats-Rollup: sub';
};

subtest 'dual-read: legacy %XX meta subject still found' => sub {
    plan tests => 7;
    my $js = MockJS->new;
    my $os = EV::Nats::ObjectStore->new(js => $js, bucket => 'B');
    my $data = 'legacy object';
    my $nuid = 'LEGACYNUID000000000001';
    # Seed the store as 0.05 would have written it: %XX meta subject,
    # unpadded base64url digest, plain js_publish meta.
    my $chunk_subj = '$O.B.C.' . $nuid;
    $js->{store}{$chunk_subj} = { data => encode_base64($data, ''), seq => ++$js->{seq} };
    push @{ $js->{order} }, $chunk_subj;
    my $meta = {
        name => 'a b.txt', bucket => 'B', nuid => $nuid,
        size => length($data), chunks => 1,
        digest => 'SHA-256=' . encode_base64url(sha256($data)),
    };
    my $legacy_subj = '$O.B.M.a%20b.txt';
    $js->{store}{$legacy_subj} =
        { data => encode_base64(JSON::PP::encode_json($meta), ''), seq => ++$js->{seq} };
    push @{ $js->{order} }, $legacy_subj;

    my ($got, $inf);
    $os->get('a b.txt', sub { $got = [ @_ ] });
    is $got->[0], $data, 'get finds the object at the legacy subject';
    is $got->[1], undef, 'get: no error';
    $os->info('a b.txt', sub { $inf = [ @_ ] });
    is $inf->[0]{nuid}, $nuid, 'info finds the object at the legacy subject';

    # delete() must purge the legacy meta subject so it can't resurface.
    my $ok;
    $os->delete('a b.txt', sub { $ok = [ @_ ] });
    $js->drain;
    is $ok->[0], 1, 'delete of legacy-subject object succeeded';
    ok((grep { $_ eq $legacy_subj } @{ $js->{purges} || [] }),
       'legacy meta subject purged on delete');
    undef $got;
    $os->get('a b.txt', sub { $got = [ @_ ] });
    is $got->[0], undef, 'object gone after delete';
    is $got->[1], undef, 'gone is a clean miss';
};

subtest 'delete writes a deleted:true marker with rollup, no KV-Operation tombstone' => sub {
    plan tests => 10;
    my $js = MockJS->new;
    my $os = EV::Nats::ObjectStore->new(js => $js, bucket => 'B');
    $os->put('victim', 'some data', sub { });
    $js->drain;
    my ($meta_subj) = grep { /\.M\./ } keys %{ $js->{store} };
    my $live = JSON::PP::decode_json(decode_base64($js->{store}{$meta_subj}{data}));
    $js->{hpubs} = [];   # ignore the put's own meta publish

    my $ok;
    $os->delete('victim', sub { $ok = [ @_ ] });
    $js->drain;
    is $ok->[0], 1, 'delete reports success';
    is $ok->[1], undef, 'delete: no error';

    my ($hp) = grep { $_->{subject} eq $meta_subj } @{ $js->{hpubs} || [] };
    ok $hp, 'delete marker published at the meta subject';
    # $hp may be undef against a broken implementation; don't autovivify it.
    ok $hp && $hp->{headers} =~ /Nats-Rollup: sub/, 'marker carried Nats-Rollup: sub';
    ok $hp && $hp->{headers} !~ /KV-Operation/, 'marker is not a KV-Operation tombstone';
    my $marker = ($hp && $hp->{payload}) ? JSON::PP::decode_json($hp->{payload}) : {};
    ok $marker->{deleted}, 'marker JSON has deleted:true';
    is $marker->{size}, 0, 'marker size zeroed';
    is $marker->{chunks}, 0, 'marker chunks zeroed';
    is $marker->{digest}, '', 'marker digest emptied';

    my ($got, $inf);
    $os->get('victim', sub { $got = [ @_ ] });
    $os->info('victim', sub { $inf = [ @_ ] });
    ok !defined $got->[0] && !defined $inf->[0],
       'get/info report the object missing after delete'
        or diag "get err: ", $got->[1] // '(none)';
};

subtest 'delete on a missing or already-deleted object is a no-op success' => sub {
    plan tests => 4;
    my $js = MockJS->new;
    my $os = EV::Nats::ObjectStore->new(js => $js, bucket => 'B');

    # Never existed: success, and no spurious deleted:true marker written.
    my $ok;
    $os->delete('ghost', sub { $ok = [ @_ ] });
    $js->drain;
    is $ok->[0], 1, 'delete(missing) reports success';
    is scalar(@{ $js->{hpubs} || [] }), 0, 'no marker published for a missing name';

    # Already deleted: idempotent, still success.
    $os->put('twice', 'data', sub { });
    $js->drain;
    $os->delete('twice', sub { });   # first delete writes the marker
    $js->drain;
    $js->{hpubs} = [];
    my $ok2;
    $os->delete('twice', sub { $ok2 = [ @_ ] });   # second delete
    $js->drain;
    is $ok2->[0], 1, 'delete(already-deleted) reports success';
    is scalar(@{ $js->{hpubs} || [] }), 0, 'no second marker written';
};

subtest 'nats.go-style delete marker reads as missing (no KV-Operation header)' => sub {
    plan tests => 4;
    my $js = MockJS->new;
    my $os = EV::Nats::ObjectStore->new(js => $js, bucket => 'B');
    # A marker exactly as nats.go writes it: deleted:true meta, no headers.
    my $marker = {
        name => 'gone.txt', bucket => 'B', nuid => '',
        size => 0, chunks => 0, digest => '', deleted => JSON::PP::true(),
    };
    my $meta_subj = '$O.B.M.' . EV::Nats::ObjectStore::_encode_name('gone.txt');
    $js->{store}{$meta_subj} =
        { data => encode_base64(JSON::PP::encode_json($marker), ''), seq => ++$js->{seq} };
    push @{ $js->{order} }, $meta_subj;

    my ($got, $inf);
    $os->get('gone.txt', sub { $got = [ @_ ] });
    is $got->[0], undef, 'get returns no data for a deleted:true marker';
    is $got->[1], undef, 'get returns no error';
    $os->info('gone.txt', sub { $inf = [ @_ ] });
    is $inf->[0], undef, 'info returns no meta';
    is $inf->[1], undef, 'info returns no error';
};

subtest 'overwrite purges the previous object chunks' => sub {
    plan tests => 5;
    my $js = MockJS->new;
    my $os = EV::Nats::ObjectStore->new(js => $js, bucket => 'B');
    $os->put('file', 'first', sub { });
    $js->drain;
    my ($meta_subj) = grep { /\.M\./ } keys %{ $js->{store} };
    my $nuid1 = (JSON::PP::decode_json(decode_base64($js->{store}{$meta_subj}{data})))->{nuid};

    $js->{msg_gets} = 0;
    my $info;
    $os->put('file', 'second', sub { $info = [ @_ ] });
    $js->drain;
    is $info->[1], undef, 'second put succeeded';
    ok $js->{msg_gets} >= 1, 'second put looked up the existing meta first';
    my $nuid2 = (JSON::PP::decode_json(decode_base64($js->{store}{$meta_subj}{data})))->{nuid};
    isnt $nuid2, $nuid1, 'overwrite used a fresh nuid';
    ok((grep { $_ eq '$O.B.C.' . $nuid1 } @{ $js->{purges} || [] }),
       'previous nuid chunk subject purged');
    ok !exists $js->{store}{ '$O.B.C.' . $nuid1 }, 'old chunks gone from the store';
};

subtest 'list decodes base64url and legacy names' => sub {
    plan tests => 2;
    my $js = MockJS->new;
    my $os = EV::Nats::ObjectStore->new(js => $js, bucket => 'B');
    $os->put('report.txt', 'x', sub { });
    $js->drain;
    # plus a legacy-encoded name, as 0.05 would have written it
    my $legacy_meta = { name => 'a b.txt', bucket => 'B', nuid => 'N',
                        size => 0, chunks => 0, digest => '' };
    $js->{store}{'$O.B.M.a%20b.txt'} =
        { data => encode_base64(JSON::PP::encode_json($legacy_meta), ''), seq => ++$js->{seq} };
    push @{ $js->{order} }, '$O.B.M.a%20b.txt';
    my $names;
    $os->list(sub { $names = $_[0] });
    ok((grep { $_ eq 'report.txt' } @$names), 'base64url name decoded in list');
    ok((grep { $_ eq 'a b.txt' } @$names), 'legacy %XX name decoded in list');
};

subtest 'get() does not pin the connection' => sub {
    plan tests => 2;
    my $destroyed = 0;
    my $r;
    {
        my $js = MockJS->new;
        my $os = EV::Nats::ObjectStore->new(js => $js, bucket => 'B');
        # rides along inside the $self that get()'s closure captures
        $os->{_guard} = Guard->new(sub { $destroyed = 1 });
        $os->put('g', 'payload', sub { });
        $js->drain;
        $os->get('g', sub { $r = [ @_ ] });
        is $r->[0], 'payload', 'get returned data';
    }
    ok $destroyed, 'ObjectStore freed after get() (callback cycle broken)';
};

subtest 'missing object is a clean miss' => sub {
    plan tests => 2;
    my $js = MockJS->new;
    my $os = EV::Nats::ObjectStore->new(js => $js, bucket => 'B');
    my $got;
    $os->get('nope', sub { $got = [ @_ ] });
    is $got->[0], undef, 'get(missing) returns no data';
    is $got->[1], undef, 'get(missing) returns no error';
};

subtest 'KV key and bucket validation' => sub {
    plan tests => 12;
    my $js = MockJS->new;
    ok !eval { EV::Nats::KV->new(js => $js, bucket => 'bad bucket'); 1 },
       'bucket with a space rejected';
    my $kv = eval { EV::Nats::KV->new(js => $js, bucket => 'good-bucket_1') };
    ok $kv, 'valid bucket accepted';
    for my $bad ('a b', 'a>b', 'a*b', '.lead', 'trail.', "nl\nkey") {
        (my $show = $bad) =~ s/\n/\\n/;
        ok !eval { $kv->get($bad, sub { }); 1 }, "key '$show' rejected";
    }
    for my $good ('a.b.c', 'A_b-c', 'x=1', 'path/to/key') {
        ok eval { $kv->get($good, sub { }); 1 }, "key '$good' accepted"
            or diag $@;
    }
};

done_testing;
