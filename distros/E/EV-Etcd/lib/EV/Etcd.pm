package EV::Etcd;
use 5.010;
use strict;
use warnings;
use Carp ();
use Scalar::Util ();

our $VERSION = '0.11';

use EV ();
require XSLoader;
XSLoader::load('EV::Etcd', $VERSION);

# A cloned ithread would DESTROY the same C structs a second time
sub CLONE_SKIP { 1 }
{
    no strict 'refs';
    *{"EV::Etcd::${_}::CLONE_SKIP"} = \&CLONE_SKIP for qw(Watch Keepalive Observe);
}

# Called from XS under G_EVAL: $EV::DIED, __WARN__ and stringification may all die
sub _warn_callback_died {
    my $err = $_[0];
    my $died = eval { my $text = "$err"; 1 } ? $err : ref($err) . ' object';
    return warn "EV::Etcd: callback died: $died" unless ref $EV::DIED;
    # eval clears $@ on entry, so it is set inside
    eval { $@ = $died; $EV::DIED->(); 1 }
        or warn "EV::Etcd: \$EV::DIED died on '$died': $@";
}

my $_xs_txn = \&txn;

# As the XS methods check them: blessed references pass
my $reftype = sub { Scalar::Util::reftype($_[0]) // '' };

no warnings 'redefine';
*txn = sub {
    my $self = shift;

    if (@_ == 4
        && $reftype->($_[0]) eq 'ARRAY'
        && $reftype->($_[1]) eq 'ARRAY'
        && $reftype->($_[2]) eq 'ARRAY'
        && $reftype->($_[3]) eq 'CODE') {
        return $_xs_txn->($self, @_);
    }
    if (@_ == 4
        && $reftype->($_[0]) eq 'ARRAY'
        && $reftype->($_[1]) eq 'ARRAY'
        && $reftype->($_[2]) eq 'ARRAY') {
        Carp::croak("txn: callback must be a code reference");
    }

    my $callback;
    if (@_ % 2 == 1) {
        $reftype->($_[-1]) eq 'CODE'
            or Carp::croak("txn: expected positional (compare, success, failure, callback) or name => value pairs");
        $callback = pop;
    }

    my %args = @_;
    for my $k (keys %args) {
        Carp::croak("Unknown option '$k' in \$client->txn")
            unless $k eq 'compare' || $k eq 'success' || $k eq 'failure' || $k eq 'callback';
    }
    $callback //= $args{callback};

    for my $k (qw(compare success failure)) {
        next unless defined $args{$k};
        $reftype->($args{$k}) eq 'ARRAY'
            or Carp::croak("txn '$k' must be an array reference");
    }

    my $compare = $args{compare} // [];
    my $success = $args{success} // [];
    my $failure = $args{failure} // [];

    return $_xs_txn->($self, $compare, $success, $failure, $callback);
};
use warnings 'redefine';

1;

__END__

=head1 NAME

EV::Etcd - Async etcd v3 client using native gRPC and EV/libev

=head1 SYNOPSIS

    use v5.10;
    use EV;
    use EV::Etcd;

    my $client = EV::Etcd->new(
        endpoints => ['127.0.0.1:2379'],
    );

    $client->put('/my/key', 'value', sub {
        my ($resp, $err) = @_;
        die $err->{message} if $err;
        say "Put succeeded, revision: $resp->{header}{revision}";
    });

    $client->get('/my/key', sub {
        my ($resp, $err) = @_;
        die $err->{message} if $err;
        say "Value: $resp->{kvs}[0]{value}";
    });

    $client->watch('/my/key', sub {
        my ($resp, $err) = @_;
        return warn "Watch error: $err->{message}\n" if $err;
        for my $event (@{$resp->{events}}) {
            say "Event: $event->{type} on $event->{kv}{key}";
        }
    });

    EV::run;

=head1 DESCRIPTION

An asynchronous etcd v3 client on the gRPC Core C API and the EV event
loop: a gRPC thread waits for completions and wakes the loop, and callbacks
run in the Perl thread. It needs etcd 3.4 or later (C<auth_status> needs
3.5).

Every method takes a callback last; methods with options take them as a
hash reference just before it. Invalid arguments croak. The callback
receives C<($response, $error)>: the response hash and C<undef>, or
C<undef> and an error hash (see L</ERRORS>). Responses carry a C<header>
with C<cluster_id>, C<member_id>, C<revision> and C<raft_term> unless noted
otherwise. A kv hash has C<key>, C<value>, C<create_revision>,
C<mod_revision>, C<version> and C<lease>.

=head1 CONSTRUCTOR

=head2 new

    my $client = EV::Etcd->new(%options);

=over 4

=item endpoints => [ 'host:port', ... ]

Default C<['127.0.0.1:2379']>; an empty list croaks. An endpoint may carry
the C<http://> or C<https://> scheme etcd prints; C<https://> turns on
C<tls>.

The client uses one endpoint at a time and moves to the next when it cannot
be reached: a unary call fails with UNAVAILABLE, or with DEADLINE_EXCEEDED
before a connection was made, a stream has to reconnect because its
connection is down, or a keepalive ping goes unanswered. The failing call
still reports its error; retrying it reaches the next endpoint. Several
failures on one endpoint move the client once.

A member that has lost its leader fails linearizable reads and writes
after etcd's request timeout (7 seconds by default), and these failures
move the client on too, though a shorter C<timeout> ends the call on the
client first and does not. Errors a working member returns during an election, such as
C<etcdserver: leader changed>, do not move it.

Streams need a leader as well: a member without one refuses new streams
and, after a few election timeouts, ends running watches and keepalives
with UNAVAILABLE C<etcdserver: no leader>. Streams retry such answers a
second apart until a leader is back, on the next endpoint when there are
several; each restarts the C<max_retries> count. Once a unary call, or a
stream that was running, reports C<etcdserver: no leader>, pending C<lock>
and C<election_campaign> calls sent over the same connection fail with
UNAVAILABLE, as they do when a connection that never became ready is
abandoned.

An endpoint may also be a gRPC target listing several addresses, such as
C<ipv4:10.0.0.1:2379,10.0.0.2:2379>. gRPC moves between them within one
connection, so a refused address fails no call, but never away from a
member that has lost its leader: list members as separate endpoints to
leave one.

gRPC connects through a proxy named in C<grpc_proxy>, C<https_proxy> or
C<http_proxy>, even to a loopback address; list etcd's hosts in
C<no_proxy> to connect directly.

=item timeout => $seconds

RPC timeout in whole seconds, at least 1; default 30. C<lock> and
C<election_campaign> wait without one, as a timeout could not tell whether
they succeeded.

=item max_retries => $count

Reconnection attempts for a stream (C<watch>, C<lease_keepalive>,
C<election_observe>) after a connection failure; default 30, 0 disables
reconnecting. Attempts are 0.5 seconds further apart each time, up to 5
seconds, so the default gives up about two minutes after the endpoints
start refusing connections, plus gRPC's 20-second connect timeout for one
that accepts them but stays silent. Lower it to learn sooner that the
endpoints are gone.

=item keepalive_time => $seconds

=item keepalive_timeout => $seconds

Seconds between pings while calls or streams are open (default 10,
fractions allowed, 0 disables them), and how long a ping may go unanswered
(default 10). An unanswered ping closes the connection: its calls fail with
UNAVAILABLE and the client moves to the next endpoint. Without pings, an
endpoint that goes silent (a hung host, a partition) goes unnoticed until
the operating system gives up on the connection. etcd closes connections
that ping more often than its C<--grpc-keepalive-min-time> (5 seconds by
default).

=item health_interval => $seconds

=item on_health_change => sub { my ($healthy, $endpoint) = @_; ... }

Every C<health_interval> seconds (fractions allowed; default 0, off) the
client checks its connection state without sending a request, and calls
C<on_health_change> when health changes. Only a failed connection attempt
counts as unhealthy; with several endpoints it also moves the client on.
Switching endpoints after a failed call is not reported.

=item auth_token => $token

A token from an earlier C<authenticate>, used without authenticating again.

=item tls => $bool

Connect with TLS; any C<tls_*> option or an C<https://> endpoint turns it
on too. Without C<tls_ca_file>, gRPC uses its default roots, or the PEM
bundle named by C<GRPC_DEFAULT_SSL_ROOTS_FILE_PATH>.

=item tls_ca_file => $path

PEM CA certificates to verify the servers with (etcd's
C<--trusted-ca-file>), in place of the default roots. Verification cannot
be turned off; for a self-signed server, give its certificate here.

=item tls_cert_file => $path

=item tls_key_file => $path

Client certificate and key, given together, for servers started with
C<--client-cert-auth>.

=item tls_server_name => $name

Name to verify the server certificate against and send as SNI, in place of
the endpoint's host.

=back

    my $client = EV::Etcd->new(
        endpoints     => ['https://10.0.0.1:2379', 'https://10.0.0.2:2379'],
        tls_ca_file   => '/etc/etcd/ca.crt',
        tls_cert_file => '/etc/etcd/client.crt',
        tls_key_file  => '/etc/etcd/client.key',
    );

=head1 ERRORS

    {
        code      => 14,                    # gRPC status code
        status    => 'UNAVAILABLE',
        message   => 'Connection refused',
        source    => 'range',               # the call that failed
        retryable => 1,
    }

C<source> is the method name, except C<range> for C<get>, C<lease_ttl> for
C<lease_time_to_live>, C<keepalive> for C<lease_keepalive>, C<campaign>,
C<proclaim>, C<leader>, C<resign> and C<observe> for the C<election_*>
calls, and C<internal> for a unary response the client could not read.

C<retryable> is set for UNAVAILABLE, ABORTED, DEADLINE_EXCEEDED and
RESOURCE_EXHAUSTED C<etcdserver: too many requests>, but never for a failed
C<lock> or C<election_campaign>. Other RESOURCE_EXHAUSTED errors last until
someone intervenes, such as C<etcdserver: mvcc: database space exceeded> (see
C<alarm>). Retryable means transient, not without effect: a write can be
applied after its deadline has passed, so retrying C<lease_grant>,
C<lease_revoke> or C<delete> can apply it twice or report what the first
attempt did.

Unary calls are not retried. Streams reconnect on their own (see
C<max_retries>), to the next endpoint once the current one has failed, and
the count restarts once a stream is working again. A stream reports an
error when reconnecting is disabled or exhausted, at once for a status a
new connection cannot fix (UNAUTHENTICATED, PERMISSION_DENIED,
INVALID_ARGUMENT, NOT_FOUND, ALREADY_EXISTS, FAILED_PRECONDITION,
OUT_OF_RANGE, UNIMPLEMENTED), and for an error the server sends on it, such
as a cancelled or compacted watch or an expired lease, which ends it.

The server can still clean up after a failed C<lock> or
C<election_campaign> has reported, deleting the key it made on the lease.
Retry with a fresh lease, and revoke the old one (which deletes all its
keys) or let it expire, as a stale candidate on it can block the new
attempt.

=head1 CALLBACKS AND HANDLES

A callback that dies stops neither the loop nor the client: the exception
goes to C<$EV::DIED>, a warning by default.

Callbacks live in C structures Perl cannot see, so a closure that captures
its client or stream handle keeps it alive until the stream is cancelled
or the client destroyed; capture a weakened copy instead. Dropping a handle
does not cancel its stream. Destroying a client cancels its calls and
streams without calling their callbacks. A client keeps C<EV::run> running
while it exists: destroy it or call C<EV::break> to leave the loop. Only
EV's default loop runs the callbacks, never a loop from
C<< EV::Loop->new >>.

    use Scalar::Util 'weaken';
    weaken(my $weak = $client);
    my $watch = $client->watch('/jobs', sub {
        my ($resp, $err) = @_;
        $weak->put('/seen', 1, sub {}) if $weak && !$err;
    });

=head2 cancel

    $handle->cancel($callback);

C<watch>, C<lease_keepalive> and C<election_observe> return a handle
(C<EV::Etcd::Watch>, C<EV::Etcd::Keepalive>, C<EV::Etcd::Observe>) whose
C<cancel> ends the stream. The callback runs before C<cancel> returns, with
an empty hash as the response, and the stream delivers nothing after it.
Cancelling again is safe and does the same.

=head1 ENCODING

etcd stores keys and values as bytes and the client does no encoding: a
string with the UTF-8 flag is stored as its UTF-8 bytes, and responses hold
byte strings. Use C<encode_utf8> and C<decode_utf8> from L<Encode> at the
boundary for character data.

A key or value over 1 MiB croaks before anything is sent. etcd refuses a
request over its C<--max-request-bytes> (1.5 MiB by default) with
INVALID_ARGUMENT C<etcdserver: request is too large>, and gRPC one 512 KiB
larger still with RESOURCE_EXHAUSTED.

=head1 KEY-VALUE

=head2 put

    $client->put($key, $value, [\%opts,] $callback);

=over 4

=item lease => $lease_id

Attach the key to a lease.

=item prev_kv => $bool

Return the previous kv as C<prev_kv>.

=item ignore_value => $bool

=item ignore_lease => $bool

Keep the current value, or lease, and update only the other.

=back

=head2 get

    $client->get($key, [\%opts,] $callback);

Response keys: C<kvs> (array of kv hashes), C<count> (all keys matched,
even beyond C<limit>) and C<more> (true when C<limit> cut the result).

=over 4

=item prefix => $bool

Every key with C<$key> as prefix; every key at all for an empty one.

=item range_end => $end

Keys from C<$key> up to C<$end>, exclusive.

=item limit => $n

At most C<$n> keys.

=item revision => $rev

Read at an older revision.

=item keys_only => $bool

=item count_only => $bool

Return keys without values, or only C<count>.

=item sort_order => 'ascend' | 'descend'

=item sort_target => 'key' | 'version' | 'create' | 'mod' | 'value'

Sort the result by C<sort_target>, in C<sort_order>.

=item serializable => $bool

Read from the member's local data: faster, possibly stale.

=item min_mod_revision, max_mod_revision, min_create_revision, max_create_revision => $rev

Filter by modification or creation revision.

=back

=head2 delete

    $client->delete($key, [\%opts,] $callback);

Options C<prefix> and C<range_end> as for C<get> (an empty prefix deletes
every key), and C<prev_kv> to return the deleted kvs. Response keys:
C<deleted> (count) and C<prev_kvs>.

=head1 WATCH

=head2 watch

    my $watch = $client->watch($key, [\%opts,] $callback);

Watch a key or range; returns a handle (see L</cancel>). The callback runs
for each message, whose C<events> hold hashes with C<type> (C<PUT> or
C<DELETE>), C<kv> and, with the C<prev_kv> option, C<prev_kv>. C<created>
is true on the first message of each stream, so again after a reconnect.

A watch the server cancels arrives as an error with C<status> CANCELLED
and C<source> C<watch>, whatever the cause its C<message> names: a
compaction, a permission denied or an expired token. After a compaction,
C<< $err->{compact_revision} >> holds the revision to resume from (0
otherwise).

=over 4

=item prefix => $bool

=item range_end => $end

As for C<get>.

=item start_revision => $rev

Start from an older revision instead of the current one.

=item prev_kv => $bool

Add the previous kv to each event.

=item progress_notify => $bool

Have the server send empty messages while idle, carrying the current
revision.

=item watch_id => $id

Choose the watch ID instead of letting the server assign one.

=item auto_reconnect => $bool

Reconnect after a connection failure, resuming from the last revision seen.
Default true.

=back

=head1 LEASE

=head2 lease_grant

    $client->lease_grant($ttl, $callback);

Grant a lease for C<$ttl> seconds. Response keys: C<id> and C<ttl> (as
granted).

=head2 lease_revoke

    $client->lease_revoke($lease_id, $callback);

Revoke a lease, deleting every key attached to it.

=head2 lease_keepalive

    my $keepalive = $client->lease_keepalive($lease_id, [\%opts,] $callback);

Keep a lease refreshed over a stream; returns a handle (see L</cancel>).
Each refresh calls back with C<id> and C<ttl>. An expired lease ends the
stream with a NOT_FOUND error. Option C<auto_reconnect> (default true)
reconnects after a connection failure.

=head2 lease_time_to_live

    $client->lease_time_to_live($lease_id, [\%opts,] $callback);

Response keys: C<id>, C<ttl> (remaining seconds, -1 once expired),
C<granted_ttl> and C<keys>, which with the C<keys> option lists the keys
attached to the lease.

=head2 lease_leases

    $client->lease_leases($callback);

Response key C<leases>: an array of hashes with an C<id>.

=head1 LOCK

=head2 lock

    $client->lock($name, $lease_id, $callback);

Acquire the lock C<$name>, held until C<unlock> or until the lease expires
or is revoked. The call waits until the lock is free, without the client
C<timeout>; destroying the client cancels it. The response C<key> is what
C<unlock> takes. On failure, see L</ERRORS>.

    $client->lease_grant(30, sub {
        my ($lease, $err) = @_;
        die $err->{message} if $err;
        $client->lock('my-resource', $lease->{id}, sub {
            my ($lock, $err) = @_;
            die $err->{message} if $err;
            # ... protected work ...
            $client->unlock($lock->{key}, sub {});
        });
    });

=head2 unlock

    $client->unlock($key, $callback);

=head1 AUTHENTICATION

=head2 authenticate

    $client->authenticate($user, $password, $callback);

On success the client keeps the token (response key C<token>) and sends it
with every later call.

Simple tokens expire after C<--auth-token-ttl> seconds unused (300 by
default), do not survive a restart, and are timed by each member
separately, so one may already have expired on the member the client
switches to. JWT tokens expire after the C<ttl> of C<--auth-token>, and
calls fail with INVALID_ARGUMENT C<etcdserver: revision of auth store is
old> after any user, role or permission change. With an expired or stale
token, calls and new streams fail, while running streams may continue for a
while; call C<authenticate> again and restart the streams.

=head2 auth_enable

    $client->auth_enable($callback);

etcd refuses it until a C<root> user with the C<root> role exists.

=head2 auth_disable

    $client->auth_disable($callback);

Needs root. The client drops its token. Other clients keep theirs, which
etcd before 3.4.28 and 3.5.10 rejects with C<etcdserver: invalid auth
token>; C<authenticate> on such a client fails with FAILED_PRECONDITION and
drops it.

=head2 auth_status

    $client->auth_status($callback);

Response keys: C<enabled> and C<auth_revision>.

=head2 user_add, user_delete, user_change_password, user_get, user_list

    $client->user_add($user, $password, $callback);
    $client->user_delete($user, $callback);
    $client->user_change_password($user, $password, $callback);
    $client->user_get($user, $callback);       # roles => [...]
    $client->user_list($callback);             # users => [...]

=head2 user_grant_role, user_revoke_role

    $client->user_grant_role($user, $role, $callback);
    $client->user_revoke_role($user, $role, $callback);

=head2 role_add, role_delete, role_get, role_list

    $client->role_add($role, $callback);
    $client->role_delete($role, $callback);
    $client->role_get($role, $callback);       # perm => [...]
    $client->role_list($callback);             # roles => [...]

C<role_get> lists permissions as hashes with C<perm_type> (C<READ>,
C<WRITE> or C<READWRITE>), C<key> and C<range_end>.

=head2 role_grant_permission, role_revoke_permission

    $client->role_grant_permission($role, $perm_type, $key, $range_end, $callback);
    $client->role_revoke_permission($role, $key, $range_end, $callback);

C<$range_end> is exclusive; C<undef> means the single key. For a prefix,
pass it with its last byte incremented: C</app/> gives C</app0>.
C<"\x00"> covers every key from C<$key> on, not only the prefix.

    $client->role_grant_permission('app', 'READWRITE', '/app/', '/app0', sub {
        my ($resp, $err) = @_;
        warn $err->{message} if $err;
    });

=head1 MAINTENANCE

=head2 status

    $client->status($callback);

Status of the member the client is connected to. Response keys:
C<version>, C<db_size>, C<db_size_in_use>, C<leader> (member ID),
C<raft_index>, C<raft_term>, C<raft_applied_index>, C<is_learner>, and
C<errors> when the member has any.

=head2 compact

    $client->compact($revision, [\%opts,] $callback);

Discard all revisions before C<$revision>, irreversibly. With
C<< physical => 1 >> the call returns once the data is removed from the
backend rather than once the compaction is committed.

=head2 alarm

    $client->alarm($action, [\%opts,] $callback);

C<$action> is C<GET>, C<ACTIVATE> or C<DEACTIVATE>. Option C<alarm> is
C<NOSPACE> or C<CORRUPT>; the default, C<NONE>, lists every alarm for
C<GET> and does nothing otherwise. Option C<member_id> names the member the
alarm is recorded for: pass a real one, from C<GET> or C<member_list>.
Response key C<alarms>: hashes with C<member_id>, C<alarm> (a number) and
C<alarm_type> (its name); etcd 3.4 sends no header.

    # After freeing space: clear every alarm
    $client->alarm('GET', sub {
        my ($resp, $err) = @_;
        return warn $err->{message} if $err;
        $client->alarm('DEACTIVATE', {
            alarm     => $_->{alarm_type},
            member_id => $_->{member_id},
        }, sub { warn $_[1]{message} if $_[1] }) for @{$resp->{alarms}};
    });

=head2 defragment

    $client->defragment($callback);

Defragment the backend of the member the client is connected to. It blocks
that member while running. etcd 3.4 and 3.5 send no header, so the
response is empty.

=head2 hash_kv

    $client->hash_kv([$revision,] $callback);

Hash of the store up to C<$revision> (default current), to compare
members. Response keys: C<hash> and C<compact_revision>.

=head2 move_leader

    $client->move_leader($member_id, $callback);

Hand leadership to another voting member. Only the leader accepts it, so
the client must be connected to the leader (C<status> then shows C<leader>
equal to C<< $resp->{header}{member_id} >>). etcd sends no header.

=head1 ELECTION

=head2 election_campaign

    $client->election_campaign($name, $lease_id, $value, $callback);

Wait to become leader of C<$name> with C<$value>; leadership lasts as long
as the lease. There is no client C<timeout>, and destroying the client
cancels the wait. The response C<leader> is a hash (C<name>, C<key>, C<rev>,
C<lease>) for C<election_proclaim> and C<election_resign>. On failure, see
L</ERRORS>.

=head2 election_leader

    $client->election_leader($name, $callback);

Response key C<kv>: the leader's kv. Without a leader, an error.

=head2 election_proclaim

    $client->election_proclaim($leader, $value, $callback);

Announce a new value as leader.

=head2 election_resign

    $client->election_resign($leader, $callback);

Give up leadership. Both this and C<election_proclaim> croak unless
C<$leader> has a non-empty C<key> and positive C<rev> and C<lease>.

=head2 election_observe

    my $observe = $client->election_observe($name, [\%opts,] $callback);

Call back with the leader's C<kv> on every change; returns a handle (see
L</cancel>). Option C<auto_reconnect> (default true) reconnects after a
connection failure.

=head1 CLUSTER

=head2 member_list

    $client->member_list([\%opts,] $callback);

Response key C<members>: hashes with C<id>, C<name>, C<peer_urls>,
C<client_urls> and C<is_learner>. Option C<linearizable> reads through the
leader instead of the member's local view; etcd 3.4 ignores it.

=head2 member_add

    $client->member_add(\@peer_urls, [\%opts,] $callback);

Option C<is_learner> adds a non-voting member. Response keys: C<member>
(the new one) and C<members>.

=head2 member_remove, member_update, member_promote

    $client->member_remove($member_id, $callback);
    $client->member_update($member_id, \@peer_urls, $callback);
    $client->member_promote($member_id, $callback);   # learner to voter

Response key C<members>.

=head1 TRANSACTIONS

=head2 txn

    $client->txn(
        compare  => \@compare,
        success  => \@success,
        failure  => \@failure,
        callback => $callback,
    );
    $client->txn(\@compare, \@success, \@failure, $callback);

Run C<success> if every comparison holds, otherwise C<failure>, atomically;
the response C<succeeded> says which. A comparison names a key and one
field, compared with C<result> C<=> (default), C<!=>, C<< < >> or
C<< > >>:

    { key => $key, value => $expected }
    { key => $key, version => $expected }
    { key => $key, create_revision => $expected }
    { key => $key, mod_revision => $expected, result => '<' }
    { key => $key, lease => $expected }

C<target> (C<value>, C<version>, C<create>, C<mod> or C<lease>) may name
the field too, and must agree with it; alone it compares against 0 or an
empty value, so C<< { key => $key, target => 'version' } >>, like
C<< { key => $key, version => 0 } >>, means the key does not exist.
Operations, which also take C<lease> (put) and C<range_end> (delete,
range):

    { put    => { key => $key, value => $value } }   # or request_put
    { delete => { key => $key } }                     # or request_delete_range
    { range  => { key => $key } }                     # or request_range

The response C<responses> holds one hash per operation run, under
C<response_put>, C<response_delete_range> (C<deleted>, C<prev_kvs>) or
C<response_range> (C<kvs>, C<count>, C<more>).

    $client->txn(
        compare  => [{ key => '/counter', value => '0' }],
        success  => [{ put => { key => '/counter', value => '1' } }],
        callback => sub {
            my ($resp, $err) = @_;
            say $resp->{succeeded} ? 'Incremented' : 'Already changed';
        },
    );

=head1 CAVEATS

B<Fork:> gRPC's threads do not survive C<fork()>. EV::Etcd starts gRPC
with the first client and shuts it down when the last is destroyed, so a
child forked while the process holds no client can create its own. The
first C<fork()> after shutdown waits up to two seconds for gRPC's threads
to finish. Destroying a client whose streams never ran can take seconds to
settle; cancel its streams, or run the loop, first. On macOS gRPC stays up
until the process exits. A child forked while gRPC is up (a client exists,
it is still settling, or on macOS ever since the first client) cannot use
etcd: C<new> croaks, as does any call on an inherited client or handle.
Inherited clients are inert in the child (they neither fire nor keep its
loop running), and destroying one there only frees its Perl side, with a
warning. In a server that forks workers, create
clients in the workers. A child forked inside an EV::Etcd callback must
exec or exit, not return from it.

B<Signals:> on a threaded perl before 5.42, a C<%SIG> handler that runs on
a gRPC thread crashes perl. EV::Etcd starts gRPC with all signals blocked,
which keeps them on the Perl thread in practice, but gRPC can start a
thread later; prefer C<EV::signal> watchers there.

=head1 INSTALLATION

Building needs the gRPC Core and protobuf-c C libraries and pkg-config:

    apt install libgrpc-dev libgrpc++-dev libprotobuf-c-dev pkg-config
    brew install grpc protobuf-c pkg-config
    pkg install grpc protobuf-c pkgconf

Most tests need an etcd on C<127.0.0.1:2379> and skip without one. They
write under their own prefixes and remove the leases, users and roles they
create; tests that compact history or add members run only with
C<EV_ETCD_TEST_ETCD=1>, for an etcd that exists for testing.

=head1 AUTHOR

vividsnow

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
