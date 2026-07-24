use strict;
use warnings;
use Test::More;
use lib 'xt/lib';
use EVNatsHelpers qw(nats_bin_or_skip free_port spawn_nats);
use File::Temp qw(tempdir);
use MIME::Base64 qw(encode_base64 decode_base64);
use Digest::SHA qw(sha256 sha256_hex);
use JSON::PP ();
use EV;
use EV::Nats;
use EV::Nats::JetStream;
use EV::Nats::ObjectStore;

# Authoritative interop test: run the real nats-server, and check that
# ObjectStore's ON-THE-WIRE format matches ADR-20 / nats.go (padded base64url
# names + digest, deleted:true delete markers, chunk purge + meta rollup on
# overwrite), and that EV::Nats can READ objects laid down in the reference
# format and in the pre-0.06 EV::Nats format.

my $bin = nats_bin_or_skip();
my $port = free_port();
my $dir  = tempdir(CLEANUP => 1);
my $pid  = spawn_nats($bin, '-js', '-p', $port, '-sd', $dir);

# local $?: reaping the server must not leak its exit status into the
# test's own exit code (Test::Builder reads $? when deciding pass/fail).
END { if ($pid) { local $?; kill 'TERM', $pid; waitpid $pid, 0 } }

# padded base64url, exactly like Go's base64.URLEncoding
sub b64url { (my $e = encode_base64($_[0], '')) =~ tr{+/}{-_}; $e }

my $nats = EV::Nats->new(host => '127.0.0.1', port => $port, connect_timeout => 3000);
my $js   = EV::Nats::JetStream->new(nats => $nats, timeout => 3000);
my $bucket = "IT$$";
my $stream = "OBJ_$bucket";
my $os = EV::Nats::ObjectStore->new(js => $js, bucket => $bucket);

# tiny synchronous run-until helper
my $result;
sub await {
    my ($arm, $secs) = @_;
    undef $result;
    my $done = 0;
    my $go; $go = EV::timer 0.02, 0.02, sub {
        return unless $nats->is_connected;
        undef $go;
        $arm->(sub { $result = [@_]; $done = 1; EV::break });
    };
    my $guard = EV::timer($secs || 8, 0, sub { EV::break });
    EV::run;
    return $done ? $result : undef;
}

# bring the bucket up or skip the whole file (no JetStream => nothing to test)
my $created = await(sub { my $cb = shift; $os->create_bucket({}, sub { $cb->($_[1]) }) });
unless ($created && !$created->[0]) {
    plan skip_all => "JetStream/object bucket unavailable: "
        . (defined $created->[0] ? $created->[0] : 'no response');
}

plan tests => 16;

my $NAME = 'dir/report.txt';         # has a '/', an old %XX case
my $NAME_ENC = b64url($NAME);
my $DATA = 'x' x (300 * 1024);       # 3 chunks at the 128KiB default
my $DIGEST = 'SHA-256=' . b64url(sha256($DATA));

# ---- FORWARD: EV::Nats writes; assert the wire matches nats.go --------------
my $put = await(sub { my $cb = shift; $os->put($NAME, $DATA, $cb) });
ok($put && !$put->[1], 'put succeeded') or diag $put->[1];

my $subj_state = await(sub {
    my $cb = shift;
    $js->stream_info($stream, { subjects_filter => "\$O.$bucket.M.>" },
                     sub { $cb->($_[0], $_[1]) });
});
my @meta_subjects = keys %{ $subj_state->[0]{state}{subjects} || {} };
is scalar(@meta_subjects), 1, 'exactly one meta subject';
is $meta_subjects[0], "\$O.$bucket.M.$NAME_ENC",
   'meta subject is padded base64url of the name';

my $meta_msg = await(sub {
    my $cb = shift;
    $js->stream_msg_get($stream, { last_by_subj => "\$O.$bucket.M.$NAME_ENC" },
                        sub { $cb->($_[0], $_[1]) });
});
my $meta = JSON::PP::decode_json(decode_base64($meta_msg->[0]{message}{data}));
like $meta->{digest}, qr/\ASHA-256=[A-Za-z0-9\-_]+=*\z/, 'digest is base64url form';
is $meta->{digest}, $DIGEST, 'digest bytes match a padded-base64url SHA-256';
is $meta->{chunks}, 3, 'chunk count recorded';
my $nuid1 = $meta->{nuid};

# round-trip read of our own object
my $got = await(sub { my $cb = shift; $os->get($NAME, $cb) });
is $got->[0], $DATA, 'get() round-trips the object it wrote';

# ---- OVERWRITE: old chunks purged, meta rolled up to one message -----------
my $put2 = await(sub { my $cb = shift; $os->put($NAME, $DATA . 'more', $cb) });
ok($put2 && !$put2->[1], 'overwrite put succeeded') or diag $put2->[1];

my $old_chunks = await(sub {
    my $cb = shift;
    $js->stream_msg_get($stream, { last_by_subj => "\$O.$bucket.C.$nuid1" },
                        sub { $cb->($_[0], $_[1]) });
});
ok(defined $old_chunks->[1] && $old_chunks->[1] =~ /no message found|10037/,
   'previous object\'s chunks were purged on overwrite') or diag "err=$old_chunks->[1]";

my $meta_state2 = await(sub {
    my $cb = shift;
    $js->stream_info($stream, { subjects_filter => "\$O.$bucket.M.>" },
                     sub { $cb->($_[0], $_[1]) });
});
is $meta_state2->[0]{state}{subjects}{"\$O.$bucket.M.$NAME_ENC"}, 1,
   'meta subject still holds exactly one message (rolled up)';

# ---- DELETE: deleted:true meta with a rollup header ------------------------
my $del = await(sub { my $cb = shift; $os->delete($NAME, $cb) });
ok($del && !$del->[1], 'delete succeeded') or diag $del->[1];

my $tomb = await(sub {
    my $cb = shift;
    $js->stream_msg_get($stream, { last_by_subj => "\$O.$bucket.M.$NAME_ENC" },
                        sub { $cb->($_[0], $_[1]) });
});
my $tomb_meta = JSON::PP::decode_json(decode_base64($tomb->[0]{message}{data}));
my $tomb_hdrs = defined $tomb->[0]{message}{hdrs}
    ? decode_base64($tomb->[0]{message}{hdrs}) : '';
ok($tomb_meta->{deleted} && $tomb_hdrs =~ /Nats-Rollup:\s*sub/i,
   'delete writes a deleted:true meta carrying Nats-Rollup: sub')
   or diag "deleted=$tomb_meta->{deleted} hdrs=$tomb_hdrs";

my $got_del = await(sub { my $cb = shift; $os->get($NAME, $cb) });
ok(!defined $got_del->[0] && !defined $got_del->[1],
   'get() on the deleted object is a clean miss');

# ---- REVERSE: EV::Nats reads a foreign (nats.go-style) object --------------
# Lay one down by hand at the reference subjects, then read it with get().
my $fname = 'from-natsgo.bin';
my $fenc  = b64url($fname);
my $fnuid = 'ABCDEFGHIJKLMNOPQRSTUV';
my $fdata = 'hello from another client' x 100;
await(sub {
    my $cb = shift;
    $js->js_publish("\$O.$bucket.C.$fnuid", $fdata, sub { $cb->($_[1]) });
});
my $fmeta = JSON::PP::encode_json({
    name => $fname, bucket => $bucket, nuid => $fnuid,
    size => length($fdata), chunks => 1,
    digest => 'SHA-256=' . b64url(sha256($fdata)),   # padded, like nats.go
});
await(sub {
    my $cb = shift;
    $js->js_publish("\$O.$bucket.M.$fenc", $fmeta, sub { $cb->($_[1]) });
});
my $fgot = await(sub { my $cb = shift; $os->get($fname, $cb) });
is $fgot->[0], $fdata, 'get() reads a nats.go-format object (base64url subj + padded digest)';

# ---- COMPAT: EV::Nats reads an object in the pre-0.06 EV::Nats format -------
# Old scheme: %XX meta subject, UNPADDED base64url digest.
my $oname = 'legacy file.txt';                       # space -> %20 in old scheme
(my $oenc = $oname) =~ s/([^A-Za-z0-9._-])/sprintf("%%%02X", ord($1))/ge;
my $onuid = 'ZYXWVUTSRQPONMLKJIHGFE';
my $odata = 'written by EV-Nats 0.05' x 50;
(my $udig = b64url(sha256($odata))) =~ s/=+\z//;      # unpadded, 0.05 style
await(sub {
    my $cb = shift;
    $js->js_publish("\$O.$bucket.C.$onuid", $odata, sub { $cb->($_[1]) });
});
my $ometa = JSON::PP::encode_json({
    name => $oname, bucket => $bucket, nuid => $onuid,
    size => length($odata), chunks => 1, digest => "SHA-256=$udig",
});
await(sub {
    my $cb = shift;
    $js->js_publish("\$O.$bucket.M.$oenc", $ometa, sub { $cb->($_[1]) });
});
my $ogot = await(sub { my $cb = shift; $os->get($oname, $cb) });
is $ogot->[0], $odata,
   'get() reads a pre-0.06 EV::Nats object (%XX subject + unpadded digest) via dual-read';

# ---- list() decodes both a base64url and a legacy %XX subject --------------
my $listed = await(sub { my $cb = shift; $os->list($cb) });
my %names = map { $_ => 1 } @{ $listed->[0] || [] };
ok($names{$fname} && $names{$oname},
   'list() decodes both base64url and legacy %XX subjects to their real names')
   or diag 'listed: ' . join(', ', sort keys %names);

$nats->disconnect;
