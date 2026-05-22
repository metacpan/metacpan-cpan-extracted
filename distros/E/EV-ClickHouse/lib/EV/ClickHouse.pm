package EV::ClickHouse;
use strict;
use warnings;

use EV;
use Scalar::Util qw(refaddr weaken);

# Identifier validation regexes — single source of truth for the table
# / column / function names that get spliced into SQL via the helpers.
my $RE_IDENT = qr/\A[A-Za-z_][A-Za-z0-9_]*\z/;
my $RE_TABLE = qr/\A[A-Za-z_][A-Za-z0-9_]*(?:\.[A-Za-z_][A-Za-z0-9_]*)?\z/;

BEGIN {
    our $VERSION = '0.03';
    use XSLoader;
    XSLoader::load __PACKAGE__, $VERSION;
}

# Holds in-flight EV::cares resolvers so they aren't garbage-collected
# before their callback fires. Keyed by refaddr of the resolver itself
# (not the connection) — see new() for the rationale. Each entry is
# deleted from inside its own resolved callback via a deferred timer.
# Plain package hash (not Hash::Util::FieldHash) so module load doesn't
# add tied/magic SVs that Test::LeakTrace would flag.
our %_failover;

*q          = \&query;
*reconnect  = \&reset;
*disconnect = \&finish;
*ddl        = \&query;  # readability at call sites for DDL/DML

sub _uri_unescape { my $s = $_[0]; $s =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/ge; $s }

# Parse a URI query string into a hash. Bare keys (no `=`) are stored
# as 1 (standard URL flag convention); existing keys in $h are preserved
# (path-derived host/port/etc win over query-string overrides).
sub _uri_qs_into {
    my ($qs, $h) = @_;
    return unless defined $qs && length $qs;
    for my $pair (split /&/, $qs) {
        my ($k, $v) = split /=/, $pair, 2;
        next unless defined $k && length $k;
        $h->{$k} //= defined $v ? _uri_unescape($v) : 1;
    }
}

sub new {
    my ($class, %args) = @_;

    # Connection URI: clickhouse://user:pass@host:port/database
    # host accepts a bracketed IPv6 literal (e.g. clickhouse://[::1]:9000/db)
    if (my $uri = delete $args{uri}) {
        if ($uri =~ m{^clickhouse(?:\+(\w+))?://(?:([^:@]*?)(?::([^@]*))?\@)?(\[[^\]]+\]|[^/:?]+)(?::(\d+))?(?:/([^?]*))?(?:\?(.*))?$}) {
            my ($proto, $u, $pw, $h, $p, $db, $qs) = ($1, $2, $3, $4, $5, $6, $7);
            $h =~ s/^\[(.*)\]$/$1/;
            $args{protocol} //= $proto if $proto;
            $args{user}     //= _uri_unescape($u)  if defined $u && $u ne '';
            $args{password} //= _uri_unescape($pw) if defined $pw;
            $args{host}     //= $h;
            $args{port}     //= $p     if defined $p;
            $args{database} //= _uri_unescape($db) if defined $db && $db ne '';
            _uri_qs_into($qs, \%args);
        } else {
            die "EV::ClickHouse: invalid URI '$uri'\n";
        }
    }

    my $loop = delete $args{loop} || EV::default_loop;
    my $self = $class->_new($loop);

    # Multi-host failover: hosts => ['a', 'b', 'c'] or ['a:9000', 'b:9001'].
    # On a connect-phase failure, advance to the next host and reconnect
    # via auto_reconnect (or the user calling reset). Falls back to single
    # host => '...' when not provided.
    my $hosts_list;
    if (my $h = delete $args{hosts}) {
        die "hosts must be a non-empty arrayref"
            unless ref($h) eq 'ARRAY' && @$h;
        $hosts_list = $h;
        if (!defined $args{host}) {
            my ($h0, $p0) = _split_host_port($h->[0], $args{port});
            $args{host} = $h0;
            $args{port} //= $p0;
        }
    }

    # Failover state + on_failover both live in the connection's C struct
    # now: emit_error advances the host ring before firing on_error,
    # which keeps the hot error path off the Perl stack.
    my $user_on_error = exists $args{on_error}
        ? delete $args{on_error} : sub { die @_ };
    $self->on_error($user_on_error);
    if (my $cb = delete $args{on_failover}) { $self->on_failover($cb) }
    for my $h (qw(on_connect on_progress on_disconnect on_trace on_query_complete on_query_start on_log)) {
        $self->$h(delete $args{$h}) if exists $args{$h};
    }

    my $host     = delete $args{host}     // '127.0.0.1';
    my $port     = delete $args{port};
    my $protocol = delete $args{protocol} // 'http';
    my $user     = delete $args{user}     // 'default';
    my $password = delete $args{password} // '';
    my $database = delete $args{database} // delete $args{db} // 'default';

    die "EV::ClickHouse: unknown protocol '$protocol' (expected 'http' or 'native')\n"
        unless $protocol eq 'http' || $protocol eq 'native';

    $port //= ($protocol eq 'native') ? 9000 : 8123;

    $self->_set_protocol($protocol eq 'native' ? 1 : 0);

    # Pass-through setters. Skip only when the key was absent — explicit
    # 0/'' must reach the setter so e.g. `compress => 0` is honored, not
    # ignored. (Use `exists` rather than `defined` so a deliberate undef
    # is also passed through and rejected by the setter if invalid.)
    for my $opt (qw(compress tls tls_skip_verify auto_reconnect
                    keepalive reconnect_delay reconnect_max_delay
                    reconnect_jitter reconnect_max_attempts
                    progress_period http_basic_auth
                    connect_timeout query_timeout
                    max_query_size max_recv_buffer)) {
        next unless exists $args{$opt};
        my $val = delete $args{$opt};
        my $setter = "_set_$opt";
        $self->$setter($val);
    }
    for my $opt (qw(session_id tls_ca_file tls_cert_file tls_key_file)) {
        defined(my $val = delete $args{$opt}) or next;
        my $setter = "_set_$opt";
        $self->$setter($val);
    }

    # query_log_comment: 1 = auto-generate "ev_ch user=$ENV{USER} pid=$$"; any
    # other defined non-empty string (including "0") is taken literally;
    # undef / not present / empty string is disabled.
    {
        my $qlc = delete $args{query_log_comment};
        if (defined $qlc && length $qlc) {
            my $cmt = (!ref($qlc) && "$qlc" ne '1')
                    ? $qlc
                    : sprintf 'ev_ch user=%s pid=%d', $ENV{USER} // 'na', $$;
            $cmt =~ s{\*/}{*\\/}g;
            $self->_set_query_log_comment($cmt);
        }
    }

    # decode_flags bitmask (DT_STR=1, DEC_SCALE=2, ENUM_STR=4, NAMED_ROWS=8)
    my $decode_flags = (delete $args{decode_datetime} ? 1 : 0)
                     | (delete $args{decode_decimal}  ? 2 : 0)
                     | (delete $args{decode_enum}     ? 4 : 0)
                     | (delete $args{named_rows}      ? 8 : 0);
    $self->_set_decode_flags($decode_flags) if $decode_flags;

    if (my $settings = delete $args{settings}) { $self->_set_settings($settings) }

    warn "EV::ClickHouse->new: unknown parameter(s): " . join(', ', sort keys %args) . "\n"
        if %args;

    if ($hosts_list) {
        $self->_set_failover($hosts_list, $port);
    }

    # Async DNS via EV::cares when available — non-IP hostnames are
    # resolved off-loop so the constructor returns immediately and the
    # main EV loop never blocks on getaddrinfo. Pre-connect-queued
    # queries fire once the resolved-address connect completes. Falls
    # back to the XS blocking resolver if EV::cares isn't installed
    # or the host is already an IP literal.
    if ($host !~ /^[\d.]+$|^\[?[0-9a-fA-F:]+\]?$/
        && eval { require EV::cares; 1 }) {
        # Stash the resolver in %_failover, keyed by refaddr of the
        # resolver itself (NOT of $self). Two reasons:
        #   - never delete the resolver from inside its own callback —
        #     ares_destroy from a c-ares cb corrupts the channel heap.
        #     We defer the delete via EV::timer(0,...) so it runs from
        #     a clean stack frame.
        #   - keying by refaddr($self) was racy: A's deferred-delete
        #     could fire after A's struct was freed and B got the same
        #     refaddr, dropping B's resolver. refaddr($r) is unique
        #     while $r is alive in %_failover.
        my $r = EV::cares->new;
        my $key = refaddr($r);
        $_failover{$key} = $r;
        my $weak2 = $self; weaken $weak2;
        $self->_set_dns_pending(1);
        $r->resolve($host, sub {
            my ($status, @addrs) = @_;
            my $w; $w = EV::timer(0, 0, sub { undef $w; delete $_failover{$key} });
            # Skip if the connection has been DESTROYed or the user
            # finished it while DNS was in flight (cleanup_connection
            # clears dns_pending; if it's 0 here, finish ran already).
            return unless $weak2 && $weak2->_take_dns_pending;
            if ($status != 0 || !@addrs) {
                $weak2->skip_pending;
                # Warn if the handler itself throws — matches the XS
                # emit_error path (WARN_AND_CLEAR_ERRSV); a bare eval here
                # would make a DNS failure vanish under the default
                # `on_error => sub { die @_ }`.
                eval { $weak2->on_error->("DNS resolution failed for '$host'"); 1 }
                    or warn "EV::ClickHouse: exception in error handler: $@";
                return;
            }
            my ($v4) = grep /^[\d.]+$/, @addrs;
            $weak2->connect($v4 // $addrs[0], $port, $user, $password, $database);
        });
    } else {
        $self->connect($host, $port, $user, $password, $database);
    }

    $self;
}

sub _split_host_port {
    my ($entry, $default_port) = @_;
    if ($entry =~ /^\[([^\]]+)\](?::(\d+))?$/) {
        return ($1, $2 // $default_port);   # IPv6 literal in brackets
    }
    if ($entry =~ /^([^:]+):(\d+)$/) {
        return ($1, $2);
    }
    return ($entry, $default_port);
}

# Pull-based result iterator: $it = $ch->iterate($sql, [\%settings])
#   while (my $batch = $it->next($timeout)) { ... }
# Wraps the native on_data per-block callback in a synchronous-feeling
# pull interface for procedural code. The iterator drives the EV loop
# from inside ->next until the next block arrives, the query completes,
# or the optional timeout (seconds) expires.
sub iterate {
    my ($self, $sql, $settings) = @_;
    my $it = bless {
        ch       => $self,
        batches  => [],
        done     => 0,
        err      => undef,
    }, 'EV::ClickHouse::Iterator';
    my $on_data = sub {
        push @{ $it->{batches} }, $_[0];
        EV::break;
    };
    my %s = $settings ? %$settings : ();
    $s{on_data} = $on_data;
    $self->query($sql, \%s, sub {
        my (undef, $err) = @_;
        $it->{done} = 1;
        $it->{err}  = $err if $err;
        EV::break;
    });
    $it;
}

# Streaming insert: $s = $ch->insert_streamer($table, %opts)
#   $s->push_row([...]); ...; $s->finish(sub { my (undef, $err) = @_ });
# Buffers rows in batches of `batch_size` (default 10_000) and dispatches
# each batch as an insert(). Dispatches are serialised (the native protocol
# cannot pipeline INSERTs); push_row keeps buffering while a batch is in
# flight and the next batch fires from the in-flight callback.
sub insert_streamer {
    my ($self, $table, %opts) = @_;
    return EV::ClickHouse::Streamer->_new($self, $table, %opts);
}

# Generator-driven insert. $producer is a code ref returning one row
# per call (arrayref or hashref) and undef when exhausted. Rows pump
# into an insert_streamer with backpressure: when buffered_count
# crosses high_water (default 50_000) the producer is paused until
# the streamer drains below the watermark. $cb fires once with
# (undef) on success or (undef, $err) on first failure (same shape
# as Streamer::finish).
sub insert_iter {
    my ($self, $table, $producer, $cb, %opts) = @_;
    die "Usage: \$ch->insert_iter(\$table, \$producer, \$cb, [\%opts])"
        unless defined $table && ref($producer) eq 'CODE' && ref($cb) eq 'CODE';
    my $hi = $opts{high_water} //= 50_000;
    my $s  = $self->insert_streamer($table, %opts);
    my $pump; $pump = EV::idle(sub {
        # Abort early on sticky error so we don't keep pumping rows into
        # a streamer that will never accept them (and that would otherwise
        # accumulate the buffer indefinitely if the producer is fast).
        if (my $err = $s->sticky_error) {
            $pump->stop; undef $pump;
            $s->finish($cb);
            return;
        }
        # Backpressure: skip this tick if the buffer is at the watermark.
        # In-flight batches are handled inside the streamer (push_row keeps
        # buffering while one is on the wire), so we only gate on buffer
        # size here. $hi == 0 means the caller disabled backpressure — the
        # gate must then never fire (>= 0 would be permanently true).
        return if $hi && $s->buffered_count >= $hi;
        my $row = $producer->();
        if (defined $row) {
            $s->push_row($row);
        } else {
            $pump->stop;
            undef $pump;
            $s->finish($cb);
        }
    });
    return;
}

# Ergonomic wrapper around server-side async_insert. Defaults to
# wait_for_flush => 1 so the callback fires after the asynchronous batch
# has been committed, matching the wait_for_async_insert=1 semantics in
# clickhouse-server. Set wait_for_flush => 0 for fire-and-forget (the
# callback then resolves as soon as the server has accepted the row
# into the in-memory async batch).
#
#   $ch->insert_async('events', \@rows, sub {
#       my (undef, $err) = @_;
#       die "async insert: $err" if $err;
#   });
sub insert_async {
    my ($self, $table, $data, $cb, %opts) = @_;
    die "Usage: \$ch->insert_async(\$table, \$data, \$cb, [%opts])"
        unless defined $table && defined $data && ref($cb) eq 'CODE';
    my $wait     = exists $opts{wait_for_flush} ? delete($opts{wait_for_flush}) : 1;
    my %extra    = %{ delete($opts{settings}) // {} };
    my %settings = (
        async_insert          => 1,
        wait_for_async_insert => $wait ? 1 : 0,
        %extra,
    );
    $self->insert($table, $data, \%settings, $cb);
}

# Server-side insert into AggregateFunction columns. Per-aggregator
# state binary format isn't replicable client-side, so each per-row
# value is wrapped in the ${func}State combinator inside a single-row
# select, all union all'd into one insert.
sub insert_aggregated {
    my ($self, $table, %opts) = @_;
    my $cb       = delete $opts{cb}   // die "insert_aggregated: cb required";
    my $rows     = delete $opts{rows} // die "insert_aggregated: rows required";
    die "insert_aggregated: cb must be a coderef" if ref($cb) ne 'CODE';
    die "insert_aggregated: rows must be a non-empty arrayref"
        if ref($rows) ne 'ARRAY' || !@$rows;
    my $key_cols = delete $opts{key_cols} || [];
    die "insert_aggregated: key_cols must be an arrayref"
        if ref($key_cols) ne 'ARRAY';
    my @agg = grep { ref $opts{$_} eq 'HASH' } sort keys %opts;
    die "insert_aggregated: no aggregate columns specified" unless @agg;
    die "insert_aggregated: invalid table '$table'"
        unless $table =~ $RE_TABLE;
    for my $c (@$key_cols, @agg) {
        die "insert_aggregated: invalid column '$c'"
            unless $c =~ $RE_IDENT;
    }
    my @agg_meta;
    for my $ac (@agg) {
        my $spec = $opts{$ac};
        my $func = $spec->{func} // die "insert_aggregated: $ac.func required";
        my $args = $spec->{args} // die "insert_aggregated: $ac.args required";
        die "insert_aggregated: $ac.func must be a simple identifier"
            unless $func =~ $RE_IDENT;
        for my $t (@$args) {
            die "insert_aggregated: $ac arg type contains illegal chars"
                unless $t =~ /\A[A-Za-z0-9_(),\s]+\z/;
        }
        push @agg_meta, { col => $ac, func => $func, types => [@$args] };
    }
    my $expected_cols = @$key_cols;
    $expected_cols += @{ $_->{types} } for @agg_meta;
    for my $r (@$rows) {
        die sprintf("insert_aggregated: row width mismatch (got %d, want %d)",
                    scalar @$r, $expected_cols)
            if @$r != $expected_cols;
    }
    my $col_list = join ', ', @$key_cols, @agg;
    # VALUES doesn't permit aggregate combinators (treated as non-constant),
    # so build a UNION ALL of single-row SELECTs.
    my @selects;
    for my $r (@$rows) {
        my $offset = 0;
        my @parts;
        for my $kc (@$key_cols) {
            push @parts, _sql_quote_value($r->[$offset++]) . " as $kc";
        }
        for my $m (@agg_meta) {
            my @args;
            for my $t (@{ $m->{types} }) {
                push @args, "cast(" . _sql_quote_value($r->[$offset++]) . " as $t)";
            }
            push @parts, "$m->{func}State(" . join(', ', @args) . ") as $m->{col}";
        }
        push @selects, "select " . join(', ', @parts);
    }
    my $sql = "insert into $table ($col_list) " . join(' union all ', @selects);
    $self->query($sql, $cb);
}

# Minimal SQL literal quoter for insert_aggregated. Numbers go raw,
# strings get single-quoted with embedded ' and \ escaped, undef → NULL.
sub _sql_quote_value {
    my ($v) = @_;
    return 'null' unless defined $v;
    die "insert_aggregated: cannot quote a reference (got " . ref($v) . ")"
        if ref $v;
    return $v if $v =~ /\A-?(?:0|[1-9][0-9]*)(?:\.[0-9]+)?(?:[eE][-+]?[0-9]+)?\z/;
    my $s = $v;
    $s =~ s/\\/\\\\/g;
    $s =~ s/'/\\'/g;
    return "'$s'";
}

sub kill_query {
    my ($self, $query_id, $cb, %opts) = @_;
    die "Usage: \$ch->kill_query(\$query_id, \$cb, [%opts])"
        unless defined $query_id && ref($cb) eq 'CODE';
    die "kill_query: invalid query_id '$query_id'"
        unless $query_id =~ /\A[A-Za-z0-9_\-]+\z/;
    my $mode = $opts{async} ? 'async' : 'sync';
    $self->query("kill query where query_id = '$query_id' $mode", $cb);
}

# Per-connection latency tracking. EV::ClickHouse is a blessed scalar
# (XS struct pointer) so we can't stash hash slots on it. We keep a
# lexical refaddr-keyed map and hold the entry's lifetime via a guard
# object stored inside the wrapper closure: when the user replaces
# on_query_complete (or XS DESTROY clears it), the closure is freed,
# the guard goes out of scope, and the %DUR_STATE entry is reaped.
my %DUR_STATE;
{
    package EV::ClickHouse::_DurGuard;
    # During global destruction %DUR_STATE may have already been
    # reaped; touching it then is undefined.
    sub DESTROY {
        return if ${^GLOBAL_PHASE} eq 'DESTRUCT';
        delete $DUR_STATE{ ${ $_[0] } };
    }
}

sub track_query_durations {
    my ($self, $size) = @_;
    $size //= 1024;
    my $key = refaddr($self);
    if ($size == 0) {
        if (my $st = delete $DUR_STATE{$key}) {
            $self->on_query_complete($st->{prev});  # undef restores no-handler
        }
        return $self;
    }
    my $st = $DUR_STATE{$key};
    if (!$st) {
        $st = $DUR_STATE{$key} = {
            size => $size,
            buf  => [],
            pos  => 0,
            prev => $self->on_query_complete,
        };
        my $guard = bless \(my $k = $key), 'EV::ClickHouse::_DurGuard';
        my $prev  = $st->{prev};
        $self->on_query_complete(sub {
            # Use captured $key (not refaddr at fire time) so we still
            # reach the right ring after DESTROY zeroed the SV.
            my $ring = $DUR_STATE{$key};
            if ($ring) {
                my $dur = $_[4];
                if (defined $dur && $dur >= 0) {
                    if (@{ $ring->{buf} } < $ring->{size}) {
                        push @{ $ring->{buf} }, $dur;
                    } else {
                        $ring->{buf}[ $ring->{pos} ] = $dur;
                        $ring->{pos} = ($ring->{pos} + 1) % $ring->{size};
                    }
                }
            }
            $prev->(@_) if $prev;
            $guard;     # keep the guard alive for the closure's lifetime
        });
    } else {
        # Resize: linearize chronological order (oldest at $st->{pos}
        # once the ring is full), keep the newest min(N, $size) samples.
        # Plain shift would drop by physical index instead of by age.
        my $buf = $st->{buf};
        if (@$buf >= $st->{size}) {
            # Ring full: chronological is buf[pos..end] then buf[0..pos-1].
            my $pos = $st->{pos} % $st->{size};
            @$buf = (@{$buf}[$pos .. $#$buf], @{$buf}[0 .. $pos - 1]);
        }
        # Insertion order is now buf[0..n-1] — already chronological.
        shift @$buf while @$buf > $size;
        $st->{size} = $size;
        # After linearization the oldest item is at index 0. While the
        # ring is still filling, push appends and pos is ignored; once
        # full, the next overwrite must target the oldest (index 0).
        $st->{pos}  = 0;
    }
    return $self;
}

sub query_duration_p {
    my ($self, $p) = @_;
    my $st = $DUR_STATE{ refaddr($self) } or return undef;
    my @s = sort { $a <=> $b } @{ $st->{buf} };
    return undef unless @s;
    $p = 0 if $p < 0;
    $p = 1 if $p > 1;
    $s[ int($p * (@s - 1) + 0.5) ];
}

sub query_duration_count {
    my $st = $DUR_STATE{ refaddr($_[0]) } or return 0;
    scalar @{ $st->{buf} };
}

# Local in-flight cancel guarded by query_id match. Only triggers
# cancel() if the connection's current in-flight query (last_query_id)
# matches $query_id, so a race where the intended query has already
# finished and a different one is now running can't silently kill the
# wrong query. Returns 1 if it cancelled, 0 if the id didn't match.
sub cancel_by_query_id {
    my ($self, $query_id) = @_;
    die "cancel_by_query_id: query_id required" unless defined $query_id && length $query_id;
    my $cur = $self->last_query_id;
    return 0 unless defined $cur && $cur eq $query_id;
    $self->cancel;
    return 1;
}

# Retry a query over the same connection with exponential backoff,
# only on retryable server errors. Falls through to the user's $cb
# with the final result (success or last error) — never invokes $cb
# more than once. Per-attempt $settings are honored; pass via the
# settings => \%hash key.
#
#   $ch->retry("select * from t",
#       retries => 3, backoff => 0.5, jitter => 0.25,
#       cb => sub { my ($rows, $err) = @_; ... });
sub retry {
    my ($self, $sql, %opts) = @_;
    my $cb       = delete $opts{cb}       // die "retry: cb required";
    my $tries    = delete $opts{retries}  // 3;
    my $delay    = delete $opts{backoff}  // 0.25;
    my $jitter   = delete $opts{jitter}   // 0;
    my $settings = delete $opts{settings};
    die "retry: cb must be a coderef" if ref($cb) ne 'CODE';

    my $attempt = 0;
    my $timer;
    my $dispatch;
    $dispatch = sub {
        $attempt++;
        my $on_done = sub {
            my ($rows, $err) = @_;
            if (!$err || $attempt > $tries
                || !EV::ClickHouse->is_retryable_error($self->last_error_code)) {
                undef $dispatch;     # collapse the cycle on terminal call
                return $cb->($rows, $err);
            }
            my $wait = $delay * (2 ** ($attempt - 1));
            $wait += rand($wait * $jitter) if $jitter > 0;
            $timer = EV::timer($wait, 0, sub { undef $timer; $dispatch->() });
        };
        # Synchronous query() can croak (e.g. "not connected" if the
        # connection was finish()d between attempts). Catch and route to
        # the user cb instead of letting it escape into the event loop.
        my $ok = eval {
            if ($settings) { $self->query($sql, $settings, $on_done) }
            else           { $self->query($sql, $on_done) }
            1;
        };
        if (!$ok) {
            my $e = $@ || 'unknown error';
            undef $dispatch;
            $cb->(undef, $e);
        }
    };
    $dispatch->();
    return;
}

# Schema introspection: $ch->for_table('db.t', sub { my ($info, $err) = @_; ... })
# Delivers { columns => [{name=>..., type=>...}, ...] } or (undef, $err).
sub for_table {
    my ($self, $table, $cb) = @_;
    die "Usage: \$ch->for_table(\$table, \$cb)" unless defined $table && ref($cb) eq 'CODE';
    die "for_table: invalid table name '$table'"
        unless $table =~ $RE_TABLE;
    # HTTP needs an explicit FORMAT; native ignores it and returns
    # typed rows that respect the connection's named_rows setting.
    my $sql = "describe table $table";
    $sql .= " format TabSeparated" if !$self->server_revision;
    $self->query($sql, sub {
        my ($rows, $err) = @_;
        return $cb->(undef, $err) if $err;
        # Connection may be in named_rows mode, in which case each row
        # is a hashref keyed by the DESCRIBE column names. Handle both.
        my @cols = map {
            ref $_ eq 'HASH'
                ? { name => $_->{name}, type => $_->{type} }
                : { name => $_->[0],    type => $_->[1] };
        } @{ $rows // [] };
        $cb->({ columns => \@cols });
    });
}

# Discover the dynamic JSON path layout for a JSON/Object('json') column.
# Walks the Map(String, String) returned by JSONAllPathsWithTypes, deduped
# across the table.
sub for_json_paths {
    my ($self, $table, $column, $cb) = @_;
    die "Usage: \$ch->for_json_paths(\$table, \$column, \$cb)"
        unless defined $table && defined $column && ref($cb) eq 'CODE';
    die "for_json_paths: invalid table '$table'"
        unless $table  =~ $RE_TABLE;
    die "for_json_paths: invalid column '$column'"
        unless $column =~ $RE_IDENT;
    # Single arrayJoin to avoid Cartesian; reference the alias to look
    # up the type so each (path, type) pair stays correlated.
    my $sql = "select distinct path, m[path] as type from ("
            . " select m, arrayJoin(mapKeys(m)) as path"
            . " from (select JSONAllPathsWithTypes($column) as m from $table)"
            . ") order by path";
    # HTTP needs explicit format; native returns typed rows directly.
    $sql .= " format TabSeparated" if !$self->server_revision;
    $self->query($sql, sub {
        my ($rows, $err) = @_;
        return $cb->(undef, $err) if $err;
        # Handle both arrayref and named_rows hashref shapes — same idiom
        # as for_table.
        $cb->([ map {
            ref $_ eq 'HASH'
                ? { path => $_->{path}, type => $_->{type} }
                : { path => $_->[0],    type => $_->[1] }
        } @{ $rows // [] } ]);
    });
}

# is_healthy: ping with a deadline. Callback receives (1, undef) on
# success or (0, $err_msg) on timeout or ping error. The connection
# itself isn't disturbed - failure does not call finish/reset; the
# caller decides recovery.
sub is_healthy {
    my ($self, $cb, $timeout) = @_;
    die "Usage: \$ch->is_healthy(\$cb, [\$timeout])" unless ref($cb) eq 'CODE';
    $timeout //= 5;
    my $done = 0;
    my $t = EV::timer($timeout, 0, sub {
        return if $done;
        $done = 1;
        $cb->(0, "health check timeout after ${timeout}s");
    });
    $self->ping(sub {
        return if $done;
        $done = 1;
        undef $t;
        my (undef, $err) = @_;
        $cb->(!$err, $err);
    });
    return;
}

# Single PING + measure wall-clock latency. Callback receives
# ($seconds, undef) on success or (undef, $err) on failure.
# Cheaper than installing track_query_durations for a one-shot probe.
sub ping_round_trip {
    my ($self, $cb) = @_;
    die "Usage: \$ch->ping_round_trip(\$cb)" unless ref($cb) eq 'CODE';
    my $start = EV::time();
    $self->ping(sub {
        my (undef, $err) = @_;
        return $cb->(undef, $err) if $err;
        $cb->(EV::time() - $start, undef);
    });
    return;
}

# Filter callback that fires only when a query exceeds $threshold
# seconds. Installs an on_query_complete observer that composes with
# any existing handler. Returns the previous on_query_complete so the
# caller can restore it later.
sub slow_query_log {
    my ($self, $threshold, $cb) = @_;
    die "Usage: \$ch->slow_query_log(\$threshold, \$cb)"
        unless defined $threshold && ref($cb) eq 'CODE';
    my $prev = $self->on_query_complete;
    $self->on_query_complete(sub {
        # on_query_complete args: ($query_id, $rows, $bytes, $code, $dur, $err)
        my $dur = $_[4];
        $cb->(@_) if defined $dur && $dur >= $threshold;
        $prev->(@_) if $prev;
    });
    return $prev;
}

# Fetch one value from system.settings. Identifier-safe ($name is
# validated; the lookup uses parameter binding so a bad name produces
# a server-side error rather than SQL injection).
sub server_setting {
    my ($self, $name, $cb) = @_;
    die "Usage: \$ch->server_setting(\$name, \$cb)"
        unless defined $name && ref($cb) eq 'CODE';
    die "server_setting: invalid setting name '$name'"
        unless $name =~ $RE_IDENT;
    $self->query(
        "select value from system.settings where name = {n:String}",
        { params => { n => $name } },
        sub {
            my ($rows, $err) = @_;
            return $cb->(undef, $err) if $err;
            $cb->($rows && @$rows ? $rows->[0][0] : undef);
        },
    );
}

# Count rows in a table, optionally with a server-side WHERE filter.
# $where is interpolated literally so the caller is responsible for
# its safety (use parameterized queries via settings.params for
# user-supplied predicates). Returns the integer count or (undef, $err).
sub row_count {
    my ($self, $table, $where, $cb) = @_;
    ($where, $cb) = (undef, $where) if ref($where) eq 'CODE';
    die "Usage: \$ch->row_count(\$table, [\$where], \$cb)"
        unless defined $table && ref($cb) eq 'CODE';
    die "row_count: invalid table '$table'" unless $table =~ $RE_TABLE;
    my $tbl = EV::ClickHouse->bind_ident($table);
    my $sql = "select count() from $tbl";
    $sql .= " where $where" if defined $where && length $where;
    $self->query($sql, sub {
        my ($rows, $err) = @_;
        return $cb->(undef, $err) if $err;
        $cb->($rows && @$rows ? $rows->[0][0] : 0);
    });
}

# Approx on-disk + uncompressed sizes from system.parts. Returns
# { rows => N, bytes_on_disk => N, data_uncompressed_bytes => N }.
sub table_size {
    my ($self, $table, $cb) = @_;
    die "Usage: \$ch->table_size(\$table, \$cb)"
        unless defined $table && ref($cb) eq 'CODE';
    die "table_size: invalid table '$table'" unless $table =~ $RE_TABLE;
    my ($db, $name) = $table =~ /\./ ? split(/\./, $table, 2)
                                     : (undef, $table);
    my $sql = "select sum(rows), sum(bytes_on_disk),"
            . " sum(data_uncompressed_bytes)"
            . " from system.parts where active and table = {t:String}"
            . (defined $db ? " and database = {d:String}" : "");
    $self->query($sql, {
        params => {
            t => $name,
            (defined $db ? (d => $db) : ()),
        },
    }, sub {
        my ($rows, $err) = @_;
        return $cb->(undef, $err) if $err;
        my $r = $rows && @$rows ? $rows->[0] : [0, 0, 0];
        $cb->({
            rows                    => $r->[0] // 0,
            bytes_on_disk           => $r->[1] // 0,
            data_uncompressed_bytes => $r->[2] // 0,
        });
    });
}

# SYSTEM RELOAD DICTIONARY shortcut. Validates the dictionary name.
sub dictionary_reload {
    my ($self, $name, $cb) = @_;
    die "Usage: \$ch->dictionary_reload(\$name, \$cb)"
        unless defined $name && ref($cb) eq 'CODE';
    die "dictionary_reload: invalid name '$name'" unless $name =~ $RE_TABLE;
    $self->query("system reload dictionary " . EV::ClickHouse->bind_ident($name),
                 $cb);
}

# REFRESH MATERIALIZED VIEW (server >= 23.12). Validates the view name.
sub refresh_view {
    my ($self, $name, $cb) = @_;
    die "Usage: \$ch->refresh_view(\$name, \$cb)"
        unless defined $name && ref($cb) eq 'CODE';
    die "refresh_view: invalid name '$name'" unless $name =~ $RE_TABLE;
    $self->query("system refresh view " . EV::ClickHouse->bind_ident($name),
                 $cb);
}

# Poll system.mutations until a table's incomplete mutations finish.
# ALTER ... UPDATE/DELETE is asynchronous; this resolves once the
# mutation(s) reach is_done=1. $cb->({ pending => 0 }) on success,
# $cb->(undef, $err) on a failed mutation / query error / timeout.
#   poll        => seconds between polls (default 1)
#   timeout     => give up after N seconds (optional)
#   mutation_id => wait only for this specific mutation (optional)
sub wait_mutation {
    my ($self, $table, $cb, %opts) = @_;
    die "Usage: \$ch->wait_mutation(\$table, \$cb, [%opts])"
        unless defined $table && ref($cb) eq 'CODE';
    die "wait_mutation: invalid table '$table'" unless $table =~ $RE_TABLE;
    my $poll    = $opts{poll} // 1;   # defined-or: an explicit poll => 0 is honored
    my $timeout = $opts{timeout};
    my $mid     = $opts{mutation_id};
    my ($db, $name) = $table =~ /\./ ? split(/\./, $table, 2) : (undef, $table);

    # A mutation that keeps failing stays is_done=0 with latest_fail_reason
    # set, so filtering on is_done=0 surfaces both running and failing ones.
    my $sql = "select count() as pending,"
            . " anyIf(latest_fail_reason, latest_fail_reason != '') as fail"
            . " from system.mutations"
            . " where table = {t:String} and is_done = 0"
            . (defined $db  ? " and database = {d:String}"   : "")
            . (defined $mid ? " and mutation_id = {m:String}" : "");
    my %params = (t => $name);
    $params{d} = $db  if defined $db;
    $params{m} = $mid if defined $mid;

    my $started = EV::time();
    my $fail_streak = 0;          # consecutive polls that saw a fail reason
    my $timer; my $poll_once;
    $poll_once = sub {
        # query() can croak synchronously (e.g. "not connected" if the
        # connection was finished between polls); route that to $cb
        # instead of letting it escape into the event loop.
        my $ok = eval {
            $self->query($sql, { params => \%params }, sub {
                my ($rows, $err) = @_;
                if ($err) { undef $poll_once; return $cb->(undef, $err) }
                my $r = $rows && @$rows ? $rows->[0] : [0, ''];
                my ($pending, $fail) = @$r;
                # Require a fail reason to persist across polls: a single
                # transient latest_fail_reason can clear on the mutation's
                # next retry, so one sighting is not a terminal failure.
                if (defined $fail && length $fail) {
                    if (++$fail_streak >= 2) {
                        undef $poll_once;
                        return $cb->(undef, "wait_mutation: $fail");
                    }
                } else {
                    $fail_streak = 0;
                }
                if (!$pending) {
                    undef $poll_once;
                    return $cb->({ pending => 0 });
                }
                if (defined $timeout && EV::time() - $started >= $timeout) {
                    undef $poll_once;
                    return $cb->(undef,
                                 "wait_mutation: timed out after ${timeout}s");
                }
                $timer = EV::timer($poll, 0, sub { undef $timer; $poll_once->() });
            });
            1;
        };
        if (!$ok) {
            my $e = $@ || 'unknown error';
            undef $poll_once;
            $cb->(undef, $e);
        }
    };
    $poll_once->();
    return;
}

# Parse a clickhouse[+native]:// URI into a hash without opening a
# connection. Lets tooling validate user-supplied URIs ahead of
# instantiation. Returns undef on a malformed URI.
sub parse_uri {
    my ($class, $uri) = @_;
    return undef unless defined $uri;
    return undef unless $uri =~ m{
        ^clickhouse(?:\+(\w+))?://
        (?:([^:@]*?)(?::([^@]*))?\@)?
        (\[[^\]]+\]|[^/:?]+)
        (?::(\d+))?
        (?:/([^?]*))?
        (?:\?(.*))?$
    }x;
    my ($proto, $user, $pass, $host, $port, $db, $qs) =
        ($1, $2, $3, $4, $5, $6, $7);
    $host =~ s/^\[(.*)\]$/$1/;
    my %out = (host => $host);
    $out{protocol} = $proto                if defined $proto;
    $out{user}     = _uri_unescape($user)  if defined $user && $user ne '';
    $out{password} = _uri_unescape($pass)  if defined $pass;
    $out{port}     = $port + 0             if defined $port;
    $out{database} = _uri_unescape($db)    if defined $db && $db ne '';
    # Query-string keys land at the top level (path-derived host/port/etc
    # win on collision) so the resulting hash can be passed verbatim to new().
    _uri_qs_into($qs, \%out);
    $out{protocol} //= 'http';         # apply default after QS merge
    return \%out;
}

# is_retryable_error($code) -> bool. Class method (no $self required).
# Identifies the common transient ClickHouse error codes that warrant
# an automatic retry. Source: ClickHouse src/Common/ErrorCodes.cpp.
my %RETRYABLE = map { $_ => 1 } (
    159,   # TIMEOUT_EXCEEDED
    202,   # TOO_MANY_SIMULTANEOUS_QUERIES
    203,   # NO_FREE_CONNECTION
    209,   # SOCKET_TIMEOUT
    210,   # NETWORK_ERROR
    241,   # MEMORY_LIMIT_EXCEEDED       (often transient under contention)
    242,   # TABLE_IS_READ_ONLY          (replica catching up)
    252,   # TOO_MANY_PARTS              (merge backlog, retry after backoff)
    285,   # TOO_FEW_LIVE_REPLICAS
    319,   # UNKNOWN_STATUS_OF_INSERT    (idempotent insert salvages this)
    373,   # SESSION_IS_LOCKED
    # NB: deliberately NOT including 394 (QUERY_WAS_CANCELLED). A
    # cancellation expresses caller intent; auto-retrying would loop
    # and burn server resources for no benefit.
    439,   # CANNOT_SCHEDULE_TASK
    999,   # KEEPER_EXCEPTION
);
sub is_retryable_error {
    my ($self_or_class, $code) = @_;
    return 0 unless defined $code;
    $RETRYABLE{ $code + 0 } ? 1 : 0;
}

# bind_ident($name) -> backtick-quoted identifier safe for SQL splicing.
# ClickHouse identifier rules: alnum + _, no leading digit, optional
# dotted form ("db.table"). We accept that subset, croak otherwise.
# The $RE_IDENT validation rejects backticks outright, so the quoter
# can just wrap each part without escaping.
sub bind_ident {
    my ($self_or_class, $name) = @_;
    die "bind_ident: identifier must be defined and non-empty"
        unless defined $name && length $name;
    my @parts = split /\./, $name, -1;
    die "bind_ident: empty component in '$name'"
        if grep { !length } @parts;
    for my $p (@parts) {
        die "bind_ident: invalid identifier component '$p' in '$name'"
            unless $p =~ $RE_IDENT;
    }
    join '.', map { "`$_`" } @parts;
}

# Capability table: feature name → minimum native server revision.
# Lets user code branch cleanly on protocol features instead of
# hard-coding numeric revisions all over the place. HTTP connections
# have no protocol revision (server_revision == 0), so server_supports
# returns false for any non-trivial feature on HTTP - by design.
my %FEATURES = (
    block_info          => 51903,   # DBMS_MIN_REVISION_WITH_BLOCK_INFO
    server_display_name => 54372,
    version_patch       => 54401,
    progress_writes     => 54420,
    server_timezone     => 54423,
    addendum            => 54458,
);
sub server_supports {
    my ($self, $feature) = @_;
    return 0 unless ref $self;
    return 0 unless defined $feature;
    my $required = $FEATURES{$feature};
    return 0 unless defined $required;
    my $have = $self->server_revision or return 0;
    $have >= $required;
}

package EV::ClickHouse::Streamer;

sub _new {
    my ($class, $ch, $table, %opts) = @_;
    # `columns => [@names]` enables named-row mode: push_row({}) hashes
    # are reordered into arrayref by the streamer instead of the caller
    # having to know column position. `named => 1` is a tolerated alias
    # but `columns` is what actually drives the lookup.
    my $columns = $opts{columns};
    die "insert_streamer: columns must be a non-empty arrayref"
        if defined $columns && (ref($columns) ne 'ARRAY' || !@$columns);
    bless {
        ch             => $ch,
        table          => $table,
        settings       => $opts{settings},                  # per-insert hashref
        batch_size     => $opts{batch_size}     || 10_000,
        on_batch_error => $opts{on_batch_error} || sub { }, # per-failure cb
        high_water     => $opts{high_water}     || 0,       # 0 = disabled
        on_high_water  => $opts{on_high_water}  || sub { }, # ($buffered, $in_flight)
        # low_water: threshold at which await_drain callbacks fire.
        # Defaults to half of high_water; honoured only when high_water
        # is set (otherwise await_drain fires whenever buffer is empty).
        # Use defined() so an explicit `low_water => 0` (fire only when
        # the buffer is fully empty) is respected, not treated as unset.
        low_water      => defined($opts{low_water})
                            ? $opts{low_water}
                            : (($opts{high_water} || 0) / 2),
        columns        => $columns,
        high_water_active => 0,
        buffer         => [],
        in_flight      => 0,
        pending_finish => undef,
        drain_waiters  => [],
        sticky_err     => undef,
    }, $class;
}

sub push_row { EV::ClickHouse::_streamer_push_row(@_) }

sub _flush {
    my $self = shift;
    return if $self->{in_flight} || !@{ $self->{buffer} };
    my $batch = $self->{buffer};
    $self->{buffer} = [];
    $self->{in_flight} = 1;
    my $cb = sub {
        my (undef, $err) = @_;
        $self->{in_flight} = 0;
        if ($err) {
            $self->{sticky_err} //= $err;
            $self->{on_batch_error}->($err);
        }
        # Drain any buffered rows queued during the batch
        $self->_flush;
        # Reset high_water latch once we drop below the threshold
        $self->{high_water_active} = 0
            if $self->{high_water_active}
            && @{ $self->{buffer} } < $self->{high_water};
        # Fire await_drain waiters only when the buffer is at/below
        # low_water AND nothing is in flight. _flush above may have
        # immediately re-dispatched (in_flight=1, buffer=[]); waking
        # the waiter then would lie about the streamer being idle.
        my $low = $self->{low_water};
        if (!$self->{in_flight}
            && @{ $self->{drain_waiters} }
            && @{ $self->{buffer} } <= ($low || 0)) {
            my @w = @{ $self->{drain_waiters} };
            $self->{drain_waiters} = [];
            $_->(undef) for @w;     # undef err = normal drain
        }
        # Notify finish() if no work remains
        if ($self->{pending_finish}
            && !$self->{in_flight}
            && !@{ $self->{buffer} }) {
            my $fcb = delete $self->{pending_finish};
            $fcb->(undef, $self->{sticky_err});
        }
    };
    my @opt = $self->{settings} ? ($self->{settings}) : ();
    $self->{ch}->insert($self->{table}, $batch, @opt, $cb);
}

sub finish {
    my ($self, $cb) = @_;
    die "Usage: \$streamer->finish(\$cb)" unless ref($cb) eq 'CODE';
    $self->_flush;
    if (!$self->{in_flight} && !@{ $self->{buffer} }) {
        $cb->(undef, $self->{sticky_err});
    } else {
        $self->{pending_finish} = $cb;
    }
    return;
}

sub buffered_count { scalar @{ $_[0]{buffer} } }
sub in_flight      { $_[0]{in_flight} }
sub sticky_error   { $_[0]{sticky_err} }

# Register a callback that fires once the buffered row count drops
# to low_water (defaults to high_water/2; 0 if high_water not set).
# Pairs with on_high_water to close the backpressure loop:
#   on_high_water => sub { $producer->pause },
#   $streamer->await_drain(sub { $producer->resume });
# Fires synchronously if the buffer is already at/below the threshold.
sub await_drain {
    my ($self, $cb) = @_;
    die "Usage: \$streamer->await_drain(\$cb)" unless ref($cb) eq 'CODE';
    my $low = $self->{low_water} || 0;
    # Fire synchronously when nothing is in flight AND the buffer is
    # at/below low_water: there's no flush pending so no waiter would
    # ever fire otherwise.
    return $cb->(undef) if !$self->{in_flight} && @{ $self->{buffer} } <= $low;
    push @{ $self->{drain_waiters} }, $cb;
    return;
}

# Discard buffered rows + sticky error without finishing. Useful for
# "retry after permanent error" patterns where the producer wants to
# wipe the slate clean (typically after a schema-level fix) and keep
# pushing into the same streamer object. The underlying $ch is NOT
# touched - any in-flight batch already on the wire still completes.
sub reset {
    my ($self) = @_;
    $self->{buffer}            = [];
    $self->{sticky_err}        = undef;
    $self->{high_water_active} = 0;
    # Deliver any pending finish/drain callbacks with a reset error
    # rather than silently dropping them - quiet loss of a finish cb
    # leaves the producer waiting forever.
    my $pf = delete $self->{pending_finish};
    my @dw = @{ delete $self->{drain_waiters} || [] };
    $self->{drain_waiters} = [];
    $pf->(undef, 'streamer reset') if $pf;
    $_->('streamer reset') for @dw;
    return $self;
}

# Discover column names from the target table via for_table, then
# enable named-rows mode by populating $self->{columns}. Callback
# receives undef on success, error string on failure. Useful when
# the producer side doesn't know (or shouldn't care about) the
# schema in advance.
sub columns_from_table {
    my ($self, $cb) = @_;
    die "Usage: \$streamer->columns_from_table(\$cb)" unless ref($cb) eq 'CODE';
    $self->{ch}->for_table($self->{table}, sub {
        my ($info, $err) = @_;
        return $cb->($err) if $err;
        $self->{columns} = [ map { $_->{name} } @{ $info->{columns} } ];
        $cb->(undef);
    });
    return;
}

package EV::ClickHouse::Pool;
use Scalar::Util qw(refaddr);

# Built-in connection pool. Round-robin dispatch with least-busy fallback;
# each connection is independent (own auto_reconnect, own send_queue),
# so a hung query on one doesn't block the others. Pass any EV::ClickHouse
# constructor option in %args; it's applied to every pool member.
#
#   my $pool = EV::ClickHouse::Pool->new(host => 'ch', size => 10, ...);
#   $pool->query($sql, $cb);
#   $pool->insert($table, $data, $cb);
#   $pool->drain(sub { ... });   # all connections drained
#   $pool->finish;
sub new {
    my ($class, %args) = @_;
    my $size = delete $args{size} || 4;
    die "Pool size must be >= 1" if $size < 1;
    # Circuit breaker per member. After `circuit_threshold` consecutive
    # query/insert failures, mark the member dead for `circuit_cooldown`
    # seconds; _pick skips dead members. 0 disables.
    my $threshold = delete $args{circuit_threshold} || 0;
    my $cooldown  = delete $args{circuit_cooldown}  || 30;
    my @conns;
    for (1 .. $size) {
        push @conns, EV::ClickHouse->new(%args);
    }
    bless {
        conns      => \@conns,
        idx        => 0,
        cb_thresh  => $threshold,
        cb_cool    => $cooldown,
        cb_state   => [ map { { fails => 0, dead_until => 0 } } @conns ],
    }, $class;
}

# Pick the connection with the fewest in-flight queries; ties broken by
# round-robin. With circuit_threshold > 0, dead members are skipped
# (unless all are dead - then the breaker is bypassed). Hot path - the
# implementation lives in XS for ~5x lower per-pick cost.
sub _pick { EV::ClickHouse::_pool_pick($_[0]) }

# Find the {fails,dead_until} slot for a given $ch (object identity match).
sub _slot_for {
    my ($self, $ch) = @_;
    my $r = refaddr $ch;
    for my $i (0 .. $#{ $self->{conns} }) {
        return $self->{cb_state}[$i] if refaddr($self->{conns}[$i]) == $r;
    }
    return undef;
}

# Wrap the user callback so the circuit breaker can observe success/failure.
# The user's $cb is the LAST argument of query/insert/ping (per the public
# API). The slot update itself is in XS (_breaker_observe) so the wrapper
# closure body is one XSUB call rather than a handful of Perl ops.
sub _cb_observer {
    my ($self, $ch, $user_cb, $observe_failures) = @_;
    $observe_failures //= 1;
    return $user_cb unless $self->{cb_thresh} && ref($user_cb) eq 'CODE';
    my $slot = ref($ch) ? $self->_slot_for($ch) : $self->{cb_state}[$ch];
    return $user_cb unless $slot;
    my $thresh = $self->{cb_thresh};
    my $cool   = $self->{cb_cool};
    sub {
        # all-dead fallback: observe successes only (resets the breaker
        # on recovery), skip failures (so under-load loss doesn't extend
        # dead_until repeatedly).
        EV::ClickHouse::_breaker_observe($slot, $_[1], $thresh, $cool)
            if $observe_failures || !$_[1];
        $user_cb->(@_);
    };
}

# Dispatch a method on a picked connection, wrapping the trailing CODE arg
# (the user callback) with the circuit-breaker observer so success/failure
# updates the per-member slot.
sub _dispatch {
    my ($self, $method, @rest) = @_;
    my $ch = $self->_pick;
    $rest[-1] = $self->_cb_observer($ch, $rest[-1]) if ref $rest[-1] eq 'CODE';
    $ch->$method(@rest);
}

sub query  { shift->_dispatch(query  => @_) }
sub insert { shift->_dispatch(insert => @_) }
sub ping   { shift->_dispatch(ping   => @_) }

sub for_table       { shift->_pick->for_table(@_) }
sub iterate         { shift->_pick->iterate(@_) }
sub insert_streamer { shift->_pick->insert_streamer(@_) }

# Same as _dispatch but pins the target to $conn[$idx] instead of
# polling _pick. Circuit-breaker observation still applies.
sub _dispatch_to {
    my ($self, $method, $idx, @rest) = @_;
    die "${method}_to: index $idx out of range"
        if $idx < 0 || $idx >= @{ $self->{conns} };
    my $ch = $self->{conns}[$idx];
    $rest[-1] = $self->_cb_observer($ch, $rest[-1]) if ref $rest[-1] eq 'CODE';
    $ch->$method(@rest);
}
sub query_to  { shift->_dispatch_to(query  => @_) }
sub insert_to { shift->_dispatch_to(insert => @_) }

# Nominate a member: returns its connection object so subsequent calls
# stick to it. The caller is responsible for not abusing this (the pool
# can't apply the circuit breaker to calls it doesn't see).
sub nominate {
    my ($self, $idx) = @_;
    die "nominate: index $idx out of range" if $idx < 0 || $idx >= @{ $self->{conns} };
    $self->{conns}[$idx];
}

# Hedged read: dispatch the same query to N (default 2) distinct
# members and resolve with whichever returns first. Subsequent
# completions are silently dropped. Errors are reported only if every
# member fails. Recommended for tail-latency-sensitive selects on
# replicated tables; do NOT use for insert (would silently double-write
# on dedupe miss). $cb receives ($rows, undef, $member_idx) on success
# or (undef, $err) when every member fails.
sub hedged_query {
    my ($self, $sql, @rest) = @_;
    my $cb       = pop @rest;
    my %opts     = @rest;
    my $hedge_n  = delete $opts{hedge}    // 2;
    my $settings = delete $opts{settings};
    die "hedged_query: callback required" unless ref($cb) eq 'CODE';
    die "hedged_query: unknown options: " . join(', ', sort keys %opts)
        if %opts;
    my @c = @{ $self->{conns} };
    die "hedged_query: no members" unless @c;
    # Filter out circuit-broken members. If the breaker tripped everywhere
    # fall back to the full set so the caller still hears something — but
    # in that fallback skip _cb_observer too, otherwise every failed hedge
    # extends each member's dead_until (resetting cooldown indefinitely
    # under load).
    my $now = EV::time();
    my @alive = grep { $self->{cb_state}[$_]{dead_until} <= $now } 0 .. $#c;
    my $all_dead = !@alive;
    @alive = (0 .. $#c) if $all_dead;
    $hedge_n = @alive if $hedge_n > @alive;
    $hedge_n = 1      if $hedge_n < 1;
    # Reservoir-style shuffle for distinct random picks.
    my @pool = @alive;
    my @idx;
    while (@idx < $hedge_n) { push @idx, splice(@pool, int(rand(scalar @pool)), 1) }
    my $fired   = 0;
    my $pending = scalar @idx;
    my $first_err;
    for my $i (@idx) {
        my $ch = $c[$i];
        my $inner = sub {
            my ($rows, $err) = @_;
            $pending--;
            return if $fired;
            if (!$err) {
                $fired = 1;
                # 3rd arg = winning member index, so callers can attribute
                # wins / track per-replica latency without scanning conns.
                $cb->($rows, undef, $i);
                return;
            }
            $first_err //= $err;
            if (!$pending) {
                $fired = 1;
                $cb->(undef, $first_err);
            }
        };
        # Pass $i (not $ch) so _cb_observer can index cb_state directly
        # instead of walking conns via _slot_for.
        my $obs = $self->_cb_observer($i, $inner, !$all_dead);
        if ($settings) { $ch->query($sql, $settings, $obs) }
        else           { $ch->query($sql, $obs) }
    }
    return;
}

# Circuit breaker introspection: per-member state for monitoring.
# Returns ({ fails => N, dead_until => $epoch_seconds, alive => 0|1 }, ...).
sub circuit_state {
    my $self = shift;
    my $now  = EV::time();
    map +{ %$_, alive => $_->{dead_until} <= $now },
        @{ $self->{cb_state} };
}

# Aggregate stats
sub size           { scalar @{ $_[0]{conns} } }
sub pending_count  { my $t = 0; $t += $_->pending_count for @{ $_[0]{conns} }; $t }
sub conns          { @{ $_[0]{conns} } }

# Apply a code ref to every pool member. The callback receives
# ($conn, $idx) per call. Useful for warm-up (preload dictionaries,
# set session-level variables, dispatch a probe per member). The
# callback is invoked synchronously in pool order; if it throws,
# subsequent members are still visited (errors silently swallowed,
# matching the broadcast cancel/skip_pending/reset convention).
sub with_each {
    my ($self, $cb) = @_;
    die "Usage: \$pool->with_each(\$cb)" unless ref($cb) eq 'CODE';
    my @c = @{ $self->{conns} };
    for my $i (0 .. $#c) { eval { $cb->($c[$i], $i) } }
    return;
}

# Broadcast the same SELECT to every member and collect per-member
# results. Useful for `system.replicas`-style diagnostics where each
# shard needs to be queried directly. Callback fires once with an
# arrayref of { member => $i, rows => [...], err => $msg }, ordered
# by member index. Per-query settings are honoured. Dead members are
# included in the result with a "circuit open" error string rather
# than dispatched — the breaker would refuse them anyway.
sub fan_out {
    my ($self, $sql, @rest) = @_;
    my $cb       = pop @rest;
    my %opts     = @rest;
    my $settings = delete $opts{settings};
    die "fan_out: callback required" unless ref($cb) eq 'CODE';
    my @c   = @{ $self->{conns} };
    die "fan_out: no members" unless @c;
    my @out = map { { member => $_, rows => undef, err => undef } } 0 .. $#c;
    my $left = scalar @c;
    my $deliver = sub { $cb->(\@out) unless --$left };
    my $now     = EV::time();
    for my $i (0 .. $#c) {
        my $ch = $c[$i];
        # Short-circuit dead members so a long cooldown doesn't stall fan_out.
        if ($self->{cb_thresh}
            && $self->{cb_state}[$i]{dead_until} > $now) {
            $out[$i]{err} = "fan_out: member $i circuit open";
            $deliver->();
            next;
        }
        my $obs = $self->_cb_observer($i, sub {
            ($out[$i]{rows}, $out[$i]{err}) = @_;
            $deliver->();
        });
        # Wrap each member's dispatch so a synchronous croak (e.g.
        # "not connected" before auto_reconnect catches up) doesn't
        # strand the rest of the callbacks waiting on $left.
        eval {
            if ($settings) { $ch->query($sql, $settings, $obs) }
            else           { $ch->query($sql, $obs) }
            1;
        } or do {
            $out[$i]{err} = "$@" || "fan_out: dispatch failed";
            $deliver->();
        };
    }
    return;
}

# Checkout-style pin: hand the user a least-busy member, run their cb
# with ($conn, $release). Until $release->() is called, the pool will
# avoid handing the same member to other callers via _pick — useful
# for temp tables / SET / session-state work that must land on the
# same connection across multiple queries.
sub with_session {
    my ($self, $cb) = @_;
    die "Usage: \$pool->with_session(\$cb)" unless ref($cb) eq 'CODE';
    my $ch  = $self->_pick;
    my $r   = refaddr $ch;
    $self->{_pinned}{$r} = ($self->{_pinned}{$r} // 0) + 1;
    my $released = 0;
    my $release = sub {
        return if $released++;
        if (--$self->{_pinned}{$r} <= 0) { delete $self->{_pinned}{$r} }
    };
    eval { $cb->($ch, $release); 1 } or do {
        my $err = $@;
        $release->();
        die $err;
    };
    return;
}

# Drain when ALL connections have completed pending work.
sub drain {
    my ($self, $cb) = @_;
    my $left = scalar @{ $self->{conns} };
    my $err;
    for my $c (@{ $self->{conns} }) {
        $c->drain(sub {
            $err //= $_[0] if $_[0];
            $cb->($err) unless --$left;
        });
    }
}

sub finish { $_->finish for @{ $_[0]{conns} } }

# Coordinated graceful shutdown: drain every member, then finish. If
# the optional $grace_seconds elapses before all members drain, force
# finish and report a timeout in the callback. Callback receives undef
# on clean shutdown, an error string on per-member drain error or
# timeout. $cb is optional.
#
#   $pool->shutdown(10, sub {
#       my ($err) = @_;
#       warn "shutdown: $err" if $err;
#       EV::break;
#   });
sub shutdown {
    my ($self, $grace, $cb) = @_;
    # Two-arg form: $pool->shutdown($cb). Treat the coderef as the cb
    # with no grace timer rather than silently dropping it.
    ($grace, $cb) = (undef, $grace) if ref($grace) eq 'CODE';
    $cb //= sub { };
    die "Usage: \$pool->shutdown([\$grace_seconds], \$cb)" unless ref($cb) eq 'CODE';
    my $left  = scalar @{ $self->{conns} };
    my $err;
    my $timer;
    my $fired = 0;
    my $finalize = sub {
        return if $fired++;
        undef $timer;
        $self->finish;
        $cb->($err);
    };
    for my $c (@{ $self->{conns} }) {
        $c->drain(sub {
            $err //= $_[0] if $_[0];
            $finalize->() if --$left == 0;
        });
    }
    if ($grace && $grace > 0) {
        $timer = EV::timer($grace, 0, sub {
            $err //= "Pool::shutdown timed out after ${grace}s";
            $finalize->();
        });
    }
    return;
}

# Broadcast-to-all helpers — these touch every member because they affect
# state owned per connection (queued queries, in-flight cancellation, the
# socket itself). Picking a single member would silently leave the other
# pool connections untouched.
sub cancel       { for (@{ $_[0]{conns} }) { eval { $_->cancel       } } }
sub skip_pending { for (@{ $_[0]{conns} }) { eval { $_->skip_pending } } }
sub reset        { for (@{ $_[0]{conns} }) { eval { $_->reset        } } }

package EV::ClickHouse::Iterator;

sub next { EV::ClickHouse::_iterator_next(@_) }

sub error     { $_[0]{err} }
sub is_done   { $_[0]{done} && !@{ $_[0]{batches} } }
sub cancel    { $_[0]{ch}->cancel }

package EV::ClickHouse::Error;

# Lightweight error object — wraps the (message, code) pair callers
# already get on $err, plus a symbolic name and is_retryable boolean.
# Stringifies to the message so legacy callsites that string-compare
# against $err keep working.
use overload '""' => sub { $_[0]{message} }, fallback => 1;

# Symbolic names for ClickHouse error codes that user code is likely
# to want to branch on by name. Sourced from src/Common/ErrorCodes.cpp;
# extend liberally — the table is informational only.
my %CODE_NAME = (
    0   => 'OK',
    27  => 'CANNOT_PARSE_INPUT_ASSERTION_FAILED',
    32  => 'ATTEMPT_TO_READ_AFTER_EOF',
    33  => 'CANNOT_READ_ALL_DATA',
    44  => 'ILLEGAL_COLUMN',
    47  => 'UNKNOWN_IDENTIFIER',
    60  => 'UNKNOWN_TABLE',
    62  => 'SYNTAX_ERROR',
    81  => 'UNKNOWN_DATABASE',
    86  => 'RECEIVED_ERROR_FROM_REMOTE_IO_SERVER',
    113 => 'UNKNOWN_SETTING',
    159 => 'TIMEOUT_EXCEEDED',
    164 => 'READONLY',
    192 => 'UNKNOWN_USER',
    193 => 'WRONG_PASSWORD',
    194 => 'REQUIRED_PASSWORD',
    202 => 'TOO_MANY_SIMULTANEOUS_QUERIES',
    203 => 'NO_FREE_CONNECTION',
    209 => 'SOCKET_TIMEOUT',
    210 => 'NETWORK_ERROR',
    225 => 'NO_ZOOKEEPER',
    236 => 'ABORTED',
    241 => 'MEMORY_LIMIT_EXCEEDED',
    242 => 'TABLE_IS_READ_ONLY',
    252 => 'TOO_MANY_PARTS',
    285 => 'TOO_FEW_LIVE_REPLICAS',
    319 => 'UNKNOWN_STATUS_OF_INSERT',
    341 => 'UNFINISHED',
    373 => 'SESSION_IS_LOCKED',
    389 => 'INSERT_WAS_DEDUPLICATED',
    394 => 'QUERY_WAS_CANCELLED',
    439 => 'CANNOT_SCHEDULE_TASK',
    497 => 'ACCESS_DENIED',
    516 => 'AUTHENTICATION_FAILED',
    999 => 'KEEPER_EXCEPTION',
);

sub new {
    my ($class, %args) = @_;
    bless {
        message => $args{message} // '',
        code    => $args{code}    // 0,
    }, $class;
}

# Convenience: build from ($ch, $err) — the typical pair that callbacks
# receive. The ClickHouse-side code comes from $ch->last_error_code.
sub from_ch {
    my ($class, $ch, $err) = @_;
    return undef unless defined $err && length $err;
    $class->new(
        message => "$err",
        code    => (eval { $ch->last_error_code } || 0),
    );
}

sub message      { $_[0]{message} }
sub code         { $_[0]{code} }
sub name         { $CODE_NAME{ $_[0]{code} } }
sub is_retryable { EV::ClickHouse->is_retryable_error($_[0]{code}) }

# Class-level table introspection.
sub code_name    { $CODE_NAME{ $_[1] // 0 } }
sub known_codes  { sort { $a <=> $b } keys %CODE_NAME }

1;

__END__

=head1 NAME

EV::ClickHouse - Async ClickHouse client using EV

=head1 SYNOPSIS

    use EV;
    use EV::ClickHouse;

    # Discrete parameters
    my $ch = EV::ClickHouse->new(
        host       => '127.0.0.1',
        port       => 9000,
        protocol   => 'native',     # or 'http'
        user       => 'default',
        password   => '',
        database   => 'default',
        settings   => { max_threads => 4 },  # connection-level defaults
        on_connect => sub { print "connected\n" },
        on_error   => sub { warn "error: $_[0]\n" },
    );

    # Or via URI: clickhouse[+native]://user:pass@host:port/db?key=val
    my $ch = EV::ClickHouse->new(
        uri        => 'clickhouse+native://default:@127.0.0.1:9000/default',
        on_connect => sub { ... },
    );

    # select
    $ch->query("select number from system.numbers limit 3", sub {
        my ($rows, $err) = @_;
        die $err if $err;
        print "row: @$_\n" for @$rows;     # row: 0 / row: 1 / row: 2
    });

    # Per-query settings + parameterized values (no string interpolation)
    $ch->query(
        "select {x:UInt32} + {y:UInt32} as sum",
        { params => { x => 40, y => 2 }, max_execution_time => 30 },
        sub { my ($rows, $err) = @_; print $rows->[0][0], "\n" },  # 42
    );

    # insert - arrayref of rows (no TSV escaping needed)
    $ch->insert("my_table", [
        [1, "hello\tworld"],   # embedded tab is fine
        [2, undef],            # null
        [3, [10, 20]],         # Array column
    ], sub { my (undef, $err) = @_; warn "insert: $err" if $err });

    # insert - pre-formatted TSV string
    $ch->insert("my_table", "1\tfoo\n2\tbar\n", sub { ... });

    # Raw HTTP response body (HTTP only)
    $ch->query("select * from t format CSV", { raw => 1 }, sub {
        my ($body, $err) = @_;
        print $body;
    });

    EV::run;

=head1 DESCRIPTION

EV::ClickHouse is an asynchronous ClickHouse client that integrates with
the L<EV> event loop. It speaks both the ClickHouse HTTP protocol
(port 8123) and the native TCP protocol (port 9000) directly in XS, with
no external ClickHouse client library linked. zlib is required; OpenSSL
(for TLS) and liblz4 (for native compression) are optional and detected
at build time.

=head2 Features

=over 4

=item * HTTP and native TCP protocols, with the same Perl API

=item * gzip compression (HTTP) and LZ4 compression with CityHash
checksums (native)

=item * TLS/SSL via OpenSSL, with optional C<tls_skip_verify> for
self-signed certs and C<tls_ca_file> for additional roots

=item * Connection URIs (C<clickhouse[+native]://user:pass@host:port/db>),
including bracketed IPv6 literals

=item * Per-query and connection-level ClickHouse settings; parameterized
queries via C<params>; external tables (native) via C<external>

=item * Auto-reconnect with exponential backoff; queued (unsent) queries
are preserved across reconnects

=item * Keepalive pings for idle native connections; graceful drain;
query cancellation and skip_pending

=item * Streaming results via C<on_data> per-block callback (native);
on_progress for native progress packets

=item * Raw HTTP response mode for CSV / JSONEachRow / Parquet / etc.

=item * 35+ ClickHouse types including Int/UInt 8..256, Float32/64,
BFloat16, Decimal32/64/128/256, UUID, IPv4/IPv6, Nullable, Array,
Tuple, Map, LowCardinality (with cross-block dictionaries),
SimpleAggregateFunction, Nested, Geo (Point/Ring/LineString/Polygon
and the Multi variants), and JSON / Object('json') with auto-flattened
hashref leaves (Int64/Float64/Bool/String + Array variants).

=item * Opt-in decode of Date/DateTime, Decimal, and Enum columns; named-rows
(hashref) mode

=back

=head1 CONSTRUCTOR

=head2 new

    my $ch = EV::ClickHouse->new(%args);

The connection is initiated immediately; C<new> returns before it
completes. Queries issued before C<on_connect> fires are queued and
dispatched once the connection is ready.

B<Connection parameters:>

=over 4

=item uri => $uri_string

Single-string connection target:
C<clickhouse[+native]://user:pass@host:port/database?key=value>.

The C<+native> suffix selects the native protocol; otherwise HTTP is used.
Hostnames, IPv4 addresses, and bracketed IPv6 literals are all accepted
(e.g. C<clickhouse://[::1]:9000/db>). Query-string values are merged into
the constructor arguments. Discrete C<host>, C<port>, etc. arguments
override the URI.

=item host => $hostname

Server hostname. Default: C<127.0.0.1>.

B<Note:> DNS resolution is blocking unless L<EV::cares> is installed.
With L<EV::cares> available, hostnames are resolved off-loop at
construct time (the constructor returns immediately, queries queue
until the resolved address is connected). Falls back to blocking
C<getaddrinfo> otherwise.

=item hosts => [$h1, $h2, ...]

Multi-host failover list. Each entry is C<host>, C<host:port>, or a
bracketed-IPv6 literal. On a connect-phase failure (refused, timeout,
ServerHello stall), the client advances to the next host in round-robin
order; pair with C<auto_reconnect =E<gt> 1> for automatic recovery.
The single C<host> argument is honoured as a fallback when
C<hosts> isn't given.

=item port => $port

Server port. Default: C<8123> (HTTP), C<9000> (native).

=item protocol => 'http' | 'native'

Protocol to use. Default: C<http>.

=item user => $username

Username. Default: C<default>.

=item password => $password

Password. Default: empty.

=item database => $dbname

Default database. Default: C<default>. The shorter alias C<db> is also
accepted.

=item tls => 0 | 1

Enable TLS. Default: C<0>. Requires the module to be built with OpenSSL
(otherwise the constructor croaks).

=item tls_ca_file => $path

Additional CA certificate file for TLS verification, used alongside the
system trust store.

=item tls_cert_file => $path, tls_key_file => $path

PEM-encoded client certificate and matching private key for mutual TLS
(mTLS). Both must be set together. The client certificate is sent
during the TLS handshake; the server's trust chain decides whether to
accept it. Required by managed ClickHouse offerings (Aiven, Altinity
Cloud) that enforce cert-based auth. The private key must match the
public key in the certificate; the constructor errors out at handshake
time with C<"TLS client cert / private key mismatch"> otherwise.

=item tls_skip_verify => 0 | 1

Skip TLS certificate verification. Default: C<0>. Useful in development
with self-signed certs; do not use in production.

=item loop => $ev_loop

EV event loop object. Default: C<EV::default_loop>.

=back

B<Callbacks:>

=over 4

=item on_connect => sub { }

Called once the connection is fully established (after the native
ServerHello, or after the TCP/TLS handshake for HTTP).

=item on_error => sub { my ($message) = @_ }

Called on connection-level errors (DNS failure, socket error, TLS failure,
read/write errors, etc.). Default: C<sub { die @_ }>. Per-query errors
are delivered to the query's own callback as the second argument; they
do not invoke C<on_error>.

When a connection drops mid-flight, C<on_error> fires first with the
underlying cause, and C<on_disconnect> fires immediately after as the
state machine tears the socket down. If C<auto_reconnect> is set, the
reconnect attempt happens after C<on_disconnect> returns.

It is safe to call C<reset> (or C<reconnect>) from inside C<on_error> -
the freshly-armed socket survives the outer teardown that would
otherwise close it. Use this for custom recovery logic (e.g. switching
to a backup host on specific errors).

=item on_progress => sub { my ($rows, $bytes, $total_rows, $written_rows, $written_bytes) = @_ }

Called on native protocol progress packets. Not fired for HTTP.

=item on_disconnect => sub { }

Called when an established connection closes (by C<finish>, server
disconnect, or mid-flight error). Only fires if C<on_connect> had
previously fired - it does B<not> fire for connect-phase failures
(refused, timeout, ServerHello stall) since no connection was ever
established. Fires after internal state has been reset, so it is safe
to queue new queries or call C<reset> from inside the handler.

=item on_trace => sub { my ($message) = @_ }

Debug trace callback. Called with internal state-machine messages
(connect, dispatch, disconnect). Useful for diagnosing protocol issues.

=item on_failover => sub { my ($old_host, $old_port, $new_host, $new_port, $msg) = @_ }

Multi-host only. Fires after the failover wrapper rotates to the next
host in the C<hosts =E<gt> [...]> list, with the old and new (host, port)
pair plus the triggering error message. Use it for metrics ("which host
am I on?") or to log host transitions. Fires before the user's C<on_error>.

=back

B<Options:>

=over 4

=item compress => 0 | 1

Enable compression: gzip on HTTP (request and response), LZ4 with CityHash
checksums on the native protocol. Default: C<0>. Native compression
requires liblz4 at build time.

=item session_id => $id

HTTP session id for stateful operations (temporary tables, SET, etc.).
Native protocol has stateful sessions intrinsically; this option is HTTP-only.

=item connect_timeout => $seconds

TCP/TLS connection timeout. C<0> (default) means no timeout. Floating
point allowed.

=item query_timeout => $seconds

Default per-query timeout applied to every query and insert. The query
callback receives a C<timeout> error if exceeded. Override per-call via
the C<query_timeout> key in the settings hashref.

=item max_query_size => $bytes

Client-side guard: croak before sending any query whose SQL text exceeds
this many bytes. C<0> (default) disables the check. Useful as a
last-resort defense against accidentally sending unbounded strings.

=item max_recv_buffer => $bytes

Defensive ceiling on the response. The cap applies to the raw recv
buffer (every protocol), the chunked-decoded body (HTTP), and the
gzip-decompressed body (HTTP), so the same upper bound applies to the
user-visible payload regardless of transport encoding. On overflow the
query callback receives an appropriate error ("recv buffer overflow",
"chunked response too large", or "gzip body exceeds max_recv_buffer")
and the connection is torn down so no subsequent query can slip past
the cap on the same socket. C<0> (default) keeps the historical
no-cap behaviour (still bounded internally by a hard 128 MB ceiling
on compressed paths). Recommended in production when the schema is
constrained and you want a hard upper bound (e.g.
C<128 * 1024 * 1024> for 128 MB).

=item http_basic_auth => 0 | 1

HTTP only. When set, send credentials as
C<Authorization: Basic base64(user:password)> instead of the default
C<X-ClickHouse-User> / C<X-ClickHouse-Key> header pair. Use this when
the connection passes through an HTTP gateway (nginx, Envoy, ...) that
strips the X-ClickHouse-* headers but forwards Basic auth verbatim.
Default: C<0>.

=item auto_reconnect => 0 | 1

Reconnect automatically on connection loss. Default: C<0>. When enabled,
queued (unsent) queries are preserved across reconnects; in-flight queries
receive an error.

The reconnect path covers TCP/TLS connect failures, C<connect_timeout>
or C<query_timeout> expiry, and any clean server-side EOF (idle or
mid-request). Mid-query I/O errors (ECONNRESET / EPIPE) and a malformed
native ServerHello are B<not> retried - they typically indicate a
misconfigured peer or client-side bug that retry would only loop on.
Combine with C<reconnect_max_attempts> for an explicit ceiling.

=item settings => \%hash

ClickHouse settings applied to every query and insert. Per-call settings
(see L</query>, L</insert>) override these.

    settings => { async_insert => 1, max_threads => 4 }

=item keepalive => $seconds

Send a keepalive request every N seconds while the connection is idle:
a native CLIENT_PING on the native protocol or a C<GET /ping> on HTTP
(some load balancers / NATs drop idle HTTP connections after a few
seconds; TCP-level keepalive is too coarse). Default: C<0> (disabled).

=item reconnect_delay => $seconds

Initial delay for the C<auto_reconnect> exponential backoff. Each failed
attempt doubles the delay, capped at C<reconnect_max_delay>. Default:
C<0> (immediate retry, no backoff).

=item reconnect_max_delay => $seconds

Backoff ceiling. Default: C<0>, meaning no explicit cap; the implementation
still bounds the backoff exponent at 20 doublings, so with
C<reconnect_delay = 0.5> the worst case is roughly 6 days. Setting an
explicit ceiling is recommended in production.

=item reconnect_jitter => $fraction

Multiplicative jitter applied to each backoff delay: the actual sleep
is uniformly random in C<[delay, delay * (1 + jitter)]>. C<0> (default)
disables. Set to C<0.1>-C<0.5> when many clients reconnect against a
shared cluster - without jitter, every replica restart causes a
synchronised reconnect storm at the same backoff intervals. Jitter is
applied I<after> C<reconnect_max_delay> clamping, then re-clamped, so
the ceiling is never exceeded.

=item reconnect_max_attempts => $N

Cap the total number of reconnect attempts before giving up. Once the
cap is reached, C<on_error> fires with the message
C<"max reconnect attempts exceeded"> and no further attempts are made
(the user can manually call C<reset> later). Default: C<0> (unlimited
retries; be careful with permanent failures like wrong host).

=item progress_period => $seconds

Coalesce C<on_progress> packets so the callback fires at most once per
N seconds, with the per-field counters accumulated over the interval.
Useful for big SELECTs where the server can emit hundreds of progress
packets per second. Default: C<0> (fire on every packet).

=item query_log_comment => 1 | $string

Prepend a SQL block comment to every query for C<system.query_log>
traceability. C<1> auto-generates C<ev_ch user=$ENV{USER} pid=$$>;
a string is taken literally. Omit (or pass a falsy value) to disable.
Embedded C<*/> sequences are escaped to keep the comment well-formed.

=back

B<Decode options (native protocol only):>

These shape how column values are returned. All are opt-in and default
to C<0>, which returns raw numeric forms for stable round-tripping.

=over 4

=item decode_datetime => 0 | 1

Return C<Date>, C<Date32>, C<DateTime>, and C<DateTime64> as formatted
strings (e.g. C<"2024-01-15">, C<"2024-01-15 10:30:00">) instead of raw
integers. Uses UTC; columns with an explicit timezone
(C<DateTime('America/New_York')>) are converted to that zone.

=item decode_decimal => 0 | 1

Return C<Decimal32>/C<Decimal64>/C<Decimal128> as scaled floating-point
numbers instead of unscaled integers. Note: at large precisions, double
loses bits, so leave disabled if you need exact arithmetic.

=item decode_enum => 0 | 1

Return C<Enum8>/C<Enum16> as string labels instead of numeric codes.

=item named_rows => 0 | 1

Return each row as a hashref keyed by column name instead of an arrayref.

    my $ch = EV::ClickHouse->new(named_rows => 1, ...);
    $ch->query("select 1 as n", sub {
        my ($rows, $err) = @_;
        print $rows->[0]{n};  # 1
    });

=back

=head1 METHODS

=head2 query

    $ch->query($sql, sub { my ($rows, $err) = @_ });
    $ch->query($sql, \%settings, sub { my ($rows, $err) = @_ });

Executes a SQL statement. The callback receives:

=over 4

=item * C<($arrayref_of_arrayrefs)> for select with at least one row

=item * C<(undef)> for DDL/DML on success and for select with zero rows
(both protocols). When in doubt, treat C<undef> and C<[]> equivalently
with C<my @rows = @{$rows // []};>.

=item * C<(undef, $error_message)> on error (server exception or
connection error)

=back

The optional C<\%settings> hashref passes per-query ClickHouse settings
(C<max_execution_time>, C<max_threads>, C<async_insert>, etc.), overriding
connection-level defaults.

The following keys are intercepted by the client and not sent verbatim
to the server:

=over 4

=item C<params =E<gt> \%hash>

Parameterized values for C<{name:Type}> placeholders in the SQL. Encoding
and quoting is the server's job, so values do not need escaping:

    $ch->query(
        "select * from t where id = {id:UInt64} and name = {n:String}",
        { params => { id => 42, n => "O'Brien" } },
        sub { ... },
    );

Works on both protocols (HTTP uses URL-encoded C<param_*> query string;
native uses dedicated wire fields).

=item C<query_id =E<gt> $string>

Set the protocol-level query identifier. Retrievable later via
L</last_query_id>.

=item C<raw =E<gt> 1>

HTTP only. The callback receives the raw response body as a scalar string
instead of parsed rows. Use with an explicit C<format> clause:

    $ch->query("select * from t format CSV", { raw => 1 }, sub {
        my ($body, $err) = @_;
    });

Croaks if used with the native protocol.

=item C<query_timeout =E<gt> $seconds>

Per-query timeout, overriding the connection-level C<query_timeout>.

=item C<on_data =E<gt> sub { my ($rows) = @_; ... }>

Native protocol only. A code ref called for each data block as it arrives,
for streaming large result sets. Rows are delivered incrementally and
B<not> accumulated, so the final callback receives C<(undef)> rather than
all rows. The final callback always fires on completion or error, even if
no data block was emitted (empty result, server-side error before the
first block).

    $ch->query("select * from big_table",
        { on_data => sub { my ($rows) = @_; process_batch($rows) } },
        sub { my (undef, $err) = @_; warn $err if $err },
    );

=item C<external =E<gt> \%tables>

Native protocol only. Ships one or more in-memory data blocks that the
query can reference as tables, JOIN against, or filter with C<IN> -
without creating a server-side temporary table. Each entry maps a table
name to C<{ structure =E<gt> [...], data =E<gt> [...] }>:

    $ch->query(
        "select u.id, u.name from users u where u.id in _wanted",
        { external => {
            _wanted => {
                structure => [ id => 'UInt64' ],
                data      => [ [7], [42], [911] ],
            },
        } },
        sub { my ($rows, $err) = @_; ... },
    );

C<structure> is a flat list of C<name =E<gt> type> pairs (ClickHouse type
names, e.g. C<UInt64>, C<String>, C<Float64>); C<data> is an arrayref of
row arrayrefs, encoded with the same type machinery as L</insert>. An
empty C<data> arrayref is a valid zero-row table. Several external tables
may be supplied at once. Croaks on the HTTP protocol or on a malformed
spec (odd structure list, non-arrayref row, or a column type that
cannot be encoded).

=back

B<Native protocol type notes:> values come back as typed Perl scalars.
By default C<Date>/C<DateTime> are integers (days since epoch / Unix
timestamps); enable C<decode_datetime> for strings. C<Enum> values are
numeric codes; C<decode_enum> returns labels. C<Decimal> values are
unscaled integers; C<decode_decimal> scales them to floats.
C<SimpleAggregateFunction> is transparently decoded as its inner type.
C<Nested> columns become arrays of tuples. C<LowCardinality> works
correctly across multi-block results with shared dictionaries.

=head2 insert

    $ch->insert($table, $data, sub { my (undef, $err) = @_ });
    $ch->insert($table, $data, \%settings, sub { my (undef, $err) = @_ });

C<$data> may be either:

=over 4

=item * A pre-formatted TabSeparated string (tabs separate columns,
newlines separate rows, with the standard ClickHouse escapes).

=item * An arrayref of arrayrefs (rows of column values).

=back

When using arrayrefs, no TSV escaping is needed: C<undef> maps to null
and strings may contain tabs and newlines freely.

Nested arrayrefs (Array/Tuple columns) and hashrefs (Map columns) are
supported B<only on the native protocol>, where the encoder has the
column type from the server's sample block. On HTTP the same call
croaks rather than silently produce malformed TSV; use the native
protocol or pre-serialise nested types into ClickHouse TSV literal form.

    # Native: nested types encode directly.
    $ch->insert("my_table", [
        [1, "hello\tworld"],   # embedded tab
        [2, undef],            # null
        [3, [10, 20]],         # Array column   (native only)
        [4, { a => 1, b => 2 }],  # Map column  (native only)
    ], sub { ... });

The optional C<\%settings> hashref works exactly as in L</query>,
including C<query_id>, C<query_timeout>, and C<params>. Two extra
flags are recognised here:

=over 4

=item C<idempotent =E<gt> 1 | $token>

Auto-mints (or uses the supplied) C<insert_deduplication_token>, so a
reconnect-driven retry of the same insert doesn't double-write. Falsy
values are a no-op.

=item C<async_insert =E<gt> 1>

Enables ClickHouse server-side insert batching by setting
C<async_insert=1, wait_for_async_insert=0>. Both sub-settings can be
overridden by passing them explicitly.

=back

=head2 ping

    $ch->ping(sub { my ($result, $err) = @_ });

Send a no-op round trip to verify the connection is alive. On success
C<$result> is true, C<$err> is C<undef>. On error: C<(undef, $error)>.

=head2 is_healthy

    $ch->is_healthy(sub { my ($ok, $err) = @_ });
    $ch->is_healthy(sub { ... }, $timeout_seconds);

Bounded health probe: wraps L</ping> with a deadline (default 5s). The
callback receives C<(1, undef)> on a successful round trip, or
C<(0, $msg)> on ping error or timeout. Failure does B<not> tear down the
connection; recovery (C<reset>, host rotation, etc.) is the caller's
choice. Useful for L4 load-balancer probes and self-monitoring loops.

=head2 ping_round_trip

    $ch->ping_round_trip(sub {
        my ($seconds, $err) = @_;
        die "ping: $err" if $err;
        printf "rtt = %.3fms\n", $seconds * 1000;
    });

Issue a single PING and report wall-clock latency in seconds. Lighter
than installing L</track_query_durations> for a one-shot probe;
returns C<(undef, $err)> on transport failure. Pairs well with
L</is_healthy> for health-check endpoints that want both liveness and
latency.

=head2 slow_query_log

    my $prev = $ch->slow_query_log(0.1, sub {
        my ($qid, $rows, $bytes, $code, $dur, $err) = @_;
        warn sprintf("SLOW %.3fs %s\n", $dur, $qid // '?');
    });

Filtered variant of L</on_query_complete> that fires only when the
query took at least C<$threshold> seconds. Returns the previous
C<on_query_complete> so the caller can restore it. The previous
handler is also chained on every call, so installing this on top of
existing instrumentation is safe.

=head2 server_setting

    $ch->server_setting('max_threads', sub {
        my ($value, $err) = @_;
        warn "max_threads = $value\n";
    });

Looks one value up from C<system.settings>. Convenient one-liner for
"what's the server's effective C<$x>?". Returns C<undef> via the
callback if the setting name isn't present on this server.

=head2 row_count

    $ch->row_count('events', sub { ... });
    $ch->row_count('events', "ts > now() - interval 1 hour", sub { ... });

C<select count() from $table [where $where]>. C<$where> is interpolated
literally; use parameterized predicates via the L</query> C<params>
mechanism for user-supplied filters. Returns the row count or
C<(undef, $err)>.

=head2 table_size

    $ch->table_size('events', sub {
        my ($info, $err) = @_;
        # $info = { rows => N, bytes_on_disk => N, data_uncompressed_bytes => N }
    });

Sums C<system.parts> for the (optionally database-qualified) table
and returns a hashref. Active parts only - does not count detached
parts. Suitable for ops dashboards; not authoritative for per-row
billing (parts may double-count rows during MERGE).

=head2 ddl

    $ch->ddl("create table t (n UInt32) engine=Memory", sub {
        my (undef, $err) = @_; die "ddl: $err" if $err;
    });

Strict variant of L</query> for DDL/DML. Identical wire behaviour;
the separate name is a readability marker for migration scripts so
the intent of each call is obvious at the call site.

=head2 dictionary_reload

    $ch->dictionary_reload('my_dict', $cb);

Shortcut for C<system reload dictionary my_dict>. The dictionary
name is validated against C<[A-Za-z_][A-Za-z0-9_]*(?:\.[A-Za-z_][A-Za-z0-9_]*)?>
before splicing into the SQL.

=head2 refresh_view

    $ch->refresh_view('mv_aggregated_hourly', $cb);

Shortcut for C<system refresh view mv_aggregated_hourly> (requires
ClickHouse 23.12+). Same name validation as L</dictionary_reload>.

=head2 wait_mutation

    $ch->query("alter table events update tag = 'x' where id = 7", sub {
        my (undef, $err) = @_;
        die $err if $err;
        $ch->wait_mutation('events', sub {
            my ($info, $err) = @_;
            die $err if $err;       # a mutation failed, or timed out
            print "mutation done\n";
        }, poll => 0.5, timeout => 30);
    });

C<ALTER TABLE ... UPDATE>/C<DELETE> runs asynchronously on the server;
the statement returns before the mutation has been applied.
C<wait_mutation> polls C<system.mutations> until the table has no
incomplete mutations, then fires C<$cb-E<gt>({ pending =E<gt> 0 })>.

A mutation that keeps failing stays incomplete with a
C<latest_fail_reason> - once that reason persists across consecutive
polls (a single transient failure that the mutation's next retry
clears is tolerated) it is surfaced as
C<$cb-E<gt>(undef, "wait_mutation: ...")>. Options:

=over 4

=item C<poll> - seconds between polls (default C<1>).

=item C<timeout> - give up after N seconds, delivering a timeout error.
Omitted by default (polls indefinitely).

=item C<mutation_id> - wait only for one specific mutation rather than
every incomplete mutation on the table.

=back

Table-name validation matches L</for_table>; a C<db.table> name also
filters C<system.mutations> by database.

=head2 parse_uri

    my $parsed = EV::ClickHouse->parse_uri(
        'clickhouse+native://u:p@host:9000/db?compress=1'
    );
    # $parsed = {
    #   protocol => 'native', host => 'host', port => 9000,
    #   user => 'u', password => 'p', database => 'db',
    #   compress => '1',
    # };
    my $ch = EV::ClickHouse->new(%$parsed, on_connect => sub { ... });

Class method that parses a ClickHouse URI into a hash, returning
C<undef> if the URI doesn't match the expected shape. Lets tooling
validate user-supplied URIs without opening a connection. Query-
string keys are flattened to top-level args so the result drops
straight into L</new>; matches the inline URI parser there.

=head2 is_retryable_error

    EV::ClickHouse->is_retryable_error($code)   # class method
    $ch->is_retryable_error($code)              # also works on instance

Returns true if the given ClickHouse error code (as reported by
L</last_error_code> or the per-query C<$err> argument's prefix) is a
common transient failure that warrants automatic retry: timeouts,
network errors, memory pressure, replica catch-up, keeper exceptions,
etc. Authoritative-looking source list curated against ClickHouse's
C<src/Common/ErrorCodes.cpp>; expect the set to grow conservatively.

    $ch->query($sql, sub {
        my ($r, $err) = @_;
        if ($err && EV::ClickHouse->is_retryable_error($ch->last_error_code)) {
            schedule_retry($sql);
        }
    });

=head2 server_supports

    $ch->server_supports($feature_name)

Returns true if the live native server's protocol revision is high
enough to support the given feature. Feature names map to documented
protocol-revision thresholds so user code can branch cleanly on
capability instead of hard-coding revision numbers. Supported names:

    block_info           51903   block_info packet in DATA blocks
    server_display_name  54372   ServerHello carries display name
    version_patch        54401   ServerHello carries patch version
    progress_writes      54420   Progress packets include write counters
    server_timezone      54423   Server timezone string in ServerHello
    addendum             54458   Native ClientHello addendum block

HTTP connections have no protocol revision (C<server_revision> is C<0>),
so C<server_supports> returns false on HTTP for any feature. Unknown
feature names also return false. Use C<server_revision> directly if you
need the raw integer.

=head2 for_table

    $ch->for_table('events', sub {
        my ($info, $err) = @_;
        die $err if $err;
        for my $col (@{ $info->{columns} }) {
            printf "%-20s %s\n", $col->{name}, $col->{type};
        }
    });

Schema introspection: issues C<describe table $name> and delivers
C<{ columns =E<gt> [{name=E<gt>..., type=E<gt>...}, ...] }> to the
callback. Useful for generic insert pipelines that need column types
without hard-coding them. C<$name> may be C<table> or C<db.table>;
non-identifier characters are rejected up-front.

=head2 iterate

    my $it = $ch->iterate("select number from numbers(1_000_000)");
    while (my $batch = $it->next($timeout)) {
        process($_) for @$batch;
    }
    die $it->error if $it->error;

B<Native protocol only> - relies on the per-block C<on_data> hook and
will croak if invoked on an HTTP connection.

Synchronous-feeling pull iterator over a streaming select. Internally
wraps the native C<on_data> per-block callback and drives the EV loop
from inside C<-E<gt>next> until the next block arrives, the query
completes, or the optional timeout (seconds) expires. Useful for
procedural ETL / export code that doesn't fit a callback shape.

C<-E<gt>error>, C<-E<gt>is_done>, and C<-E<gt>cancel> are also
available on the returned iterator object.

=head2 on_log

    $ch->on_log(sub {
        my ($entry) = @_;
        # $entry: { event_time, host_name, query_id, thread_id,
        #          priority, source, text }
        printf "[CH %s] %s\n", $entry->{priority}, $entry->{text};
    });

Native protocol only. Fires once per row inside any C<SERVER_LOG>
packet the server emits. Useful for surfacing
C<send_logs_level =E<gt> 'information'> server-side trace events to
the application's own log stream without polling C<system.text_log>.
The row hash keys mirror the server-side log block schema; missing
keys (older revisions) come through as C<undef>.

=head2 on_query_start

    $ch->on_query_start(sub {
        my ($query_id) = @_;
        log_metric_start($query_id);
    });

Optional connection-level hook that fires the moment a query is
dispatched to the wire (after the query_id has been resolved, before
the first send byte). Symmetric with L</on_query_complete>; useful for
deriving accurate "query in flight" durations without depending on
the per-query callback closure. Keepalive PINGs are suppressed, the
same as for C<on_query_complete>. Also accepted as a constructor
argument.

=head2 on_query_complete

    $ch->on_query_complete(sub {
        my ($query_id, $rows, $bytes, $error_code, $duration_s, $err) = @_;
        log_metric(...);
    });

Optional connection-level hook that fires after every query (success
or error). Arguments: query_id (or undef), profile_rows, profile_bytes,
last_error_code, wall-clock duration in seconds, error message (or
undef). Useful for statsd/Prometheus-style instrumentation. Also
accepted as a constructor argument.

A per-query override may be passed in the C<\%settings> hashref of
L</query> or L</insert>. When set, it B<replaces> (does not augment)
the connection-level handler for that single call, so per-query
instrumentation doesn't double-count against global metrics:

    $ch->query(
        $sql,
        { on_query_complete => sub {
              my ($qid, $rows, $bytes, $code, $dur, $err) = @_;
              record_slow_query($qid, $dur);
        } },
        $cb,
    );

=head2 insert_streamer

    my $s = $ch->insert_streamer('events',
        batch_size     => 5_000,
        settings       => { query_id => 'ingest-1' },     # optional
        on_batch_error => sub { warn "batch err: $_[0]" }, # per-failure
    );
    while (my $row = next_event()) {
        $s->push_row($row);
    }
    $s->finish(sub {
        my (undef, $err) = @_;
        die "ingest failed: $err" if $err;
    });

Buffered streaming insert for ETL workloads. Rows are buffered until
C<batch_size> is reached, then dispatched as a single C<insert()>.
Dispatches are serialised; push_row keeps buffering while a batch is
in flight (the native protocol cannot pipeline INSERTs). C<finish>
flushes the remaining buffer and fires its callback once all batches
complete; if any batch failed the first error is delivered as
C<$err>. The streamer also offers C<buffered_count> and C<in_flight>
accessors for backpressure logic.

C<<< $streamer->reset >>> discards any rows still in the local buffer
and clears the sticky error so the streamer can be reused after a
permanent error (e.g. a schema fix). Does B<not> touch the underlying
C<$ch> - any batch already on the wire still completes normally. Any
callback registered via C<finish> or C<await_drain> that has not yet
fired is invoked with a C<'streamer reset'> error rather than being
silently dropped.

C<high_water> + C<on_high_water> trigger a one-shot notification when
the buffered row count crosses the watermark, intended as a hint to
slow the producer. Set C<high_water> below C<batch_size>; if
C<high_water E<gt> batch_size>, the buffer drains via C<batch_size>
flushes before the watermark is reached and C<on_high_water> never
fires. When C<high_water == batch_size> the watermark and the flush
threshold coincide: C<on_high_water> fires once per batch, right after
the flush dispatches (so C<in_flight> is already 1). The notification
re-arms only after the buffer drops below C<high_water>.

C<<< $streamer->await_drain($cb) >>> registers a callback that fires
once the buffer drops to C<low_water> (default C<high_water / 2>; 0
when C<high_water> isn't set). Pairs with C<on_high_water> to close
the backpressure loop:

    my $s = $ch->insert_streamer($table,
        batch_size    => 5_000,
        high_water    => 10_000,
        low_water     => 3_000,
        on_high_water => sub { $producer->pause },
    );
    $s->await_drain(sub { $producer->resume });

Fires synchronously if the buffer is already at/below C<low_water>.
Re-arms each call: register again from inside the callback if you
want to keep watching. The callback receives one argument: C<undef>
on a normal drain, or an error string if the streamer was C<reset>
before the buffer drained (so C<my ($err) = @_> distinguishes them).

B<Named-row mode:> pass C<columns =E<gt> [@col_names]> at construction
to accept hashref rows instead of positional arrayrefs. The streamer
reorders each pushed hash into the declared column order, so producer
code does not have to know where each column lives in the table.

    my $s = $ch->insert_streamer('events',
        columns    => [qw(ts user_id action payload)],
        batch_size => 5_000,
    );
    $s->push_row({ user_id => 7, action => 'click', ts => time });
    $s->push_row([ 1735, 7, 'view', '...' ]);   # arrayref still works

Hash keys missing from a row become C<undef>; extra keys are ignored.
Mixing arrayref and hashref pushes is allowed.

C<<< $streamer->columns_from_table($cb) >>> looks up the target table's
column list via L</for_table> and stores it as the streamer's named-row
columns, so callers can construct a streamer without knowing the schema
in advance. The callback fires once the lookup completes (C<undef> on
success, an error string on failure).

    my $s = $ch->insert_streamer('events');
    $s->columns_from_table(sub {
        my ($err) = @_;
        die "describe: $err" if $err;
        $s->push_row({ ts => time, user_id => 7, action => 'click' });
        ...
    });

=head2 insert_iter

    $ch->insert_iter('events', sub {
        # producer: return next row (arrayref or hashref) or undef when done
        return undef unless my $row = next_event();
        return $row;
    }, sub {
        my (undef, $err) = @_;
        die "ingest: $err" if $err;
    }, batch_size => 5_000, columns => [qw(ts user_id action payload)]);

Generator-driven insert. Internally wraps L</insert_streamer> with an
C<EV::idle> pump that calls C<$producer> repeatedly, respecting
C<high_water> for backpressure. C<undef> from the producer signals
end-of-stream and triggers C<finish>. C<%opts> is forwarded to
L</insert_streamer>.

=head2 kill_query

    $ch->kill_query($query_id, sub {
        my ($rows, $err) = @_;
        warn "kill: $err" if $err;
    });

Shortcut for C<kill query where query_id = '...' sync>. Validates
C<$query_id> against C<[A-Za-z0-9_-]+> before interpolating into the
SQL. Pass C<async =E<gt> 1> to send C<ASYNC> instead of C<SYNC> when
fire-and-forget semantics are wanted.

=head2 cancel_by_query_id

    $ch->cancel_by_query_id($qid);

Race-safe local cancel: only triggers L</cancel> if the connection's
current in-flight query (C<last_query_id>) matches C<$qid>, so the
caller can't accidentally kill a different query that has already
started in the meantime. Returns 1 if it cancelled, 0 if the id no
longer matched.

=head2 retry

    $ch->retry($sql,
        retries => 3,
        backoff => 0.5,        # initial delay; doubles each attempt
        jitter  => 0.25,       # add 0..25% random jitter to each wait
        cb      => sub { my ($rows, $err) = @_; ... },
    );

Retry a select (or any read-only statement) on the same connection
over exponential backoff, but only when the server-side error is in
the L</is_retryable_error> set (timeouts, memory limits, replica catch-up,
etc.). The callback fires exactly once with the final result - either
the first success or the error from the last attempt. Per-attempt
C<settings =E<gt> \%h> are honoured. C<jitter =E<gt> $fraction> adds
up to C<$fraction * current_wait> randomness on top of each
exponential step, so the spread scales with the backoff window.

Not for insert - a partial-write that the server logged but didn't
acknowledge will be re-applied; use C<idempotent =E<gt> 1> on the
underlying L</insert> instead.

=head2 insert_async

    $ch->insert_async('events', \@rows, sub { ... });
    $ch->insert_async('events', \@rows, sub { ... }, wait_for_flush => 0);

Ergonomic wrapper around server-side
C<async_insert =E<gt> 1>. Defaults to C<wait_for_flush =E<gt> 1>
(the callback fires after the batch has flushed); pass C<0> for
fire-and-forget. Pass additional settings via C<settings =E<gt> \%h>.

=head2 insert_aggregated

    $ch->insert_aggregated(
        'metrics_agg',
        agg_col  => { func => 'uniqExact', args => ['UInt64'] },
        key_cols => [qw(ts site)],
        rows     => [[1700000000, 'a', 42], ...],
        cb       => sub { my (undef, $err) = @_; ... },
    );

Generic client-side state serialization for C<AggregateFunction>
columns isn't feasible (each aggregator has its own binary format),
so this helper builds
C<insert into t (cols) select k as k, funcState(cast(v as T)) as agg union all ...>
- one single-row C<select> per row in C<rows>, wrapping each
per-row value with the C<${func}State> combinator so the server
constructs the aggregate state. Validates table, column, and
function names; per-row values are quoted via a small SQL-literal
helper (numbers raw, strings escape-quoted, undef becomes C<NULL>).
Only scalar leaf values are supported (no nested arrays).

=head2 bind_ident

    my $sql = "select * from " . EV::ClickHouse->bind_ident($table);

Backtick-quote an identifier safely for SQL splicing. Accepts simple
or dotted (C<db.table>) identifiers matching
C<[A-Za-z_][A-Za-z0-9_]*>; anything else croaks. The regex rejects
backticks outright so no escaping is needed inside the result.

=head2 track_query_durations

    $ch->track_query_durations(1024);
    say $ch->query_duration_p(0.95);

Install a fixed-size ring buffer of recent query durations (sourced
from C<on_query_complete>'s C<$duration_s> argument). Composes with a
user-supplied C<on_query_complete> (preserved, called first). Pass
C<0> to disable and restore the previous handler. Subsequent calls
replace the previous ring size.

C<query_duration_p($p)> returns the C<$p>-quantile in seconds (C<$p>
in C<[0,1]>); C<query_duration_count> returns the number of samples
currently buffered.

=head2 pending_queries

    for my $q (@{ $ch->pending_queries }) {
        printf "%s %s age=%.3fs\n",
               $q->{state}, $q->{query_id} // '-', $q->{age};
    }

Snapshot of pending queries: returns arrayref of hashrefs. The head
of the in-flight queue (if any) appears first with
C<state =E<gt> 'in_flight'>, C<query_id =E<gt> last_query_id>, and
C<age =E<gt> seconds since dispatch>. Queued entries follow with
C<state =E<gt> 'queued'> and C<age =E<gt> 0> (they have no dispatch
time yet). SQL/settings are not retained after enqueue and so are
not included.

=head2 dump_state

    my $h = $ch->dump_state;
    # { connected, connecting, dns_pending, pending_count,
    #   callback_depth, send_len/pos/cap, recv_len/cap, fd,
    #   protocol, server_revision, reconnect_attempts,
    #   host, port, send_count, compress, tls }

Read-only diagnostic snapshot of internal struct state. Intended for
debugging stuck connections; field set may shift between releases
(don't script against it in production).

=head2 for_json_paths

    $ch->for_json_paths('events', 'payload', sub {
        my ($paths, $err) = @_;
        for my $p (@$paths) { say "$p->{path} : $p->{type}" }
    });

Discovers the dynamic JSON path layout of a C<JSON>/C<Object('json')>
column. Internally walks the C<Map(String, String)> returned by
C<JSONAllPathsWithTypes(col)> with a single C<arrayJoin(mapKeys(m))>
(the map alias is preserved so each path's type is correlated via a
second lookup), dedupes, sorts by path, and returns
C<[ { path =E<gt> 'a.b.c', type =E<gt> 'Int64' }, ... ]>. Useful for
monitoring schema drift on weakly-typed columns.

=head1 EV::ClickHouse::Pool

    my $pool = EV::ClickHouse::Pool->new(
        host => 'ch', port => 9000, protocol => 'native',
        size => 8,                # other %args pass through to ::new
    );
    $pool->query($sql, $cb);
    $pool->insert($table, $data, $cb);
    $pool->drain(sub { ... });    # all connections drained
    $pool->finish;

Built-in connection pool. Each member is an independent
C<EV::ClickHouse> with its own C<auto_reconnect>, send queue, and
in-flight callback queue, so a hung query on one connection doesn't
block the others. Dispatch picks the least-busy connection; ties are
broken round-robin.

The Pool exposes per-pick dispatch via C<query>, C<insert>, C<ping>,
C<for_table>, C<iterate>, C<insert_streamer>; aggregate stats via
C<size>, C<pending_count>, C<conns> (the underlying connection list);
and broadcast lifecycle methods C<drain>, C<finish>, C<cancel>,
C<skip_pending>, C<reset> (each affects every member because the state
they touch is owned per connection, not per query). The broadcast
C<cancel>, C<skip_pending>, and C<reset> methods wrap each per-member
call in C<eval> so a member that croaks doesn't abort the broadcast;
per-member errors are silently discarded (the surviving members still
receive the call). Iterate C<conns> yourself if you need per-member
error handling.

C<<< $pool->with_each(sub { my ($conn, $idx) = @_; ... }) >>> calls
C<$cb> once per member, passing the connection object and its index.
Each per-member call is wrapped in C<eval> so a single croak does not
abort the iteration; per-member errors are silently discarded - wrap
the body yourself if you need them. Useful for one-off per-member
work that doesn't justify a new broadcast method (e.g. resetting a
counter, asking each member for C<last_error_code>, kicking off a
custom probe).

Queries that need server-side state (temporary tables, session
variables) must use a single connection, not a Pool, since successive
calls may land on different members.

C<<< $pool->with_session(sub { my ($conn, $release) = @_; ... }) >>>
checks out a least-busy member and "pins" it for the duration of the
callback: while pinned, C<_pick> avoids that member when other
callers request a connection (it remains selectable as a fallback if
every other member is unavailable). The callback must call
C<$release-E<gt>()> when its multi-query sequence completes - typically
from the innermost query's callback so the pin lasts across the
async chain.

    $pool->with_session(sub {
        my ($ch, $release) = @_;
        $ch->query("create temporary table t (n UInt32)", sub {
            $ch->query("insert into t values (1),(2),(3)", sub {
                $ch->query("select sum(n) from t", sub {
                    my ($rows) = @_;
                    say $rows->[0][0];
                    $release->();
                });
            });
        });
    });

C<<< $pool->query_to($idx, $sql, $cb) >>> /
C<<< $pool->insert_to($idx, $table, $data, $cb) >>> force-routes a
call to a specific member without going through C<_pick>. Circuit
breaker observation still applies (success/failure is recorded
against that member). Useful for replica-targeted DDL, S3 ingest
that has to land on a chosen node, or sticky-affinity reads.

C<<< $pool->nominate($idx) >>> returns the underlying connection so
subsequent calls bypass the pool entirely. Use sparingly - calls
made directly on the nominated connection don't update the
circuit-breaker state.

C<<< $pool->hedged_query($sql, hedge =E<gt> 2, $cb) >>> dispatches
the same select to C<hedge> distinct random members and resolves
with whichever returns first. The callback receives
C<($rows, undef, $member_idx)> on success (so callers can attribute
wins per member) or C<(undef, $err)> if I<every> member fails.
Extra completions after the winner are silently discarded.
Recommended for tail-latency-sensitive selects on replicated tables.
B<Do not> use for insert - would silently double-write when the
server's dedupe window misses.

C<<< $pool->fan_out($sql, $cb) >>> sends the same select to I<every>
member and collects per-member results into one arrayref:

    $pool->fan_out("select hostName(), uptime()", sub {
        for my $r (@{ $_[0] }) {
            printf "[%d] err=%s rows=%s\n",
                   $r->{member}, $r->{err} // '-',
                   $r->{rows} ? scalar @{$r->{rows}} : '-';
        }
    });

Useful for shard-aware diagnostics (per-replica lag, distinct
C<system.*> values across the pool). Errors are per-member, not
aggregated - the callback always fires with a complete list. Pass
C<settings =E<gt> \%h> for per-query options.

B<Circuit breaker:> pass C<circuit_threshold =E<gt> N> at construction
to enable per-member fail-fast. After N consecutive query/insert/ping
errors on a given member, that member is excluded from C<_pick> for
C<circuit_cooldown> seconds (default 30). A successful callback resets
the per-member fail counter. If every member is dead at pick time the
breaker is bypassed so the next attempt still has a chance to recover.
Inspect with C<$pool-E<gt>circuit_state> which returns one
C<{ fails =E<gt> N, dead_until =E<gt> $epoch, alive =E<gt> 0|1 }>
hashref per member.

B<Graceful shutdown:> C<<< $pool->shutdown($grace_seconds, $cb) >>>
drains every member, then calls C<finish> on each. If C<$grace_seconds>
elapses before every member drains, members still in flight are
force-finished and C<$cb> receives the string
C<"Pool::shutdown timed out after Ns">. On a clean shutdown C<$cb>
receives undef. C<$grace_seconds> may be 0 (or undef) to wait
indefinitely. The callback fires exactly once.

    $SIG{TERM} = sub { $pool->shutdown(10, sub { EV::break }) };

=head1 LIFECYCLE

=head2 finish

    $ch->finish;

Close the connection. Pending queries receive an error callback. Aliased
as C<disconnect>.

=head2 reset

    $ch->reset;

Disconnect and immediately reconnect using the original parameters.
Aliased as C<reconnect>.

=head2 drain

    $ch->drain(sub { ... });

Register a callback to fire once all pending queries (queued + in-flight)
have completed. If nothing is pending, the callback fires synchronously.
The classic graceful-shutdown pattern:

    $ch->query("select 1", sub { ... });
    $ch->query("select 2", sub { ... });
    $ch->drain(sub {
        $ch->finish;
        EV::break;
    });

=head2 cancel

    $ch->cancel;

Cancel the currently in-flight query. Native protocol sends CLIENT_CANCEL
and waits for the server's EndOfStream/Exception; HTTP closes the connection
(use C<auto_reconnect> or call L</reset> to recover). The query's callback
receives an error.

=head2 skip_pending

    $ch->skip_pending;

Drop every pending operation: each queued and in-flight callback is invoked
with C<(undef, $error_message)>. If a request was on the wire, the connection
is torn down; call L</reset> (or rely on C<auto_reconnect>) before issuing
new queries.

=head1 ACCESSORS

All per-query accessors (C<column_names>, C<column_types>, C<last_query_id>,
C<last_error_code>, C<last_totals>, C<last_extremes>, C<profile_rows>,
C<profile_bytes>, C<profile_rows_before_limit>) are reset at the moment a
new query is dispatched (queued or sent), I<not> when its callback fires.
It is always safe to read them inside the query's own callback. Reading
them after dispatching a subsequent query but before its callback fires
returns the initial state (0 or C<undef>), never the previous query's
data. Connection-level accessors (C<is_connected>, C<server_info>,
C<server_version>, C<server_timezone>, C<pending_count>) are unaffected.

=over 4

=item is_connected

True if the connection is established.

=item current_host

The host the connection is presently pointed at as a string. After a
multi-host failover rotation, this reflects the new target rather than
the originally-supplied one.

=item current_port

The port the connection is presently pointed at as an integer.

=item server_revision

The native protocol revision the server reports in its ServerHello,
as a positive integer (e.g. C<54459>). C<0> before the handshake
completes and for HTTP connections (which have no native handshake).
Use L</server_supports> for named-capability checks; this raw integer
is the escape hatch when you need to compare against a specific
revision number from the ClickHouse source.

=item pending_count

Number of pending operations (queued + in-flight).

=item server_info

Full server identification string (e.g. C<"ClickHouse 24.1.0 (revision 54459)">),
populated from the native ServerHello. C<undef> for HTTP connections.

=item server_version

Server version (e.g. C<"24.1.0">). Native only; C<undef> for HTTP.

=item server_timezone

Server timezone (e.g. C<"UTC">, C<"Europe/Moscow">). Native only; C<undef>
for HTTP.

=item column_names

Arrayref of column names from the most recent native query result, or
C<undef> if no query has run. Native protocol only - HTTP responses
do not carry column metadata.

    $ch->query("select 1 as foo, 2 as bar", sub {
        my $names = $ch->column_names;  # ['foo', 'bar']
    });

=item column_types

Arrayref of ClickHouse type strings from the most recent native query
(e.g. C<['UInt32', 'String', 'Nullable(DateTime)']>). Native protocol
only - C<undef> on HTTP.

=item last_query_id

C<query_id> of the most recently dispatched query, or C<undef>. Set via
C<< { query_id => 'my-id' } >> in the settings hash of L</query>/L</insert>.

=item last_tls_error

The most recent OpenSSL error string captured during TLS context setup
or handshake (e.g. C<certificate verify failed>, C<key values mismatch>),
or C<undef> if no TLS error has occurred. Always C<undef> when built
without OpenSSL. Useful for surfacing the actual crypto reason to the
operator after a connection has failed - the on_error message itself
only names the failing call site (e.g. C<SSL_connect failed>).

=item last_error_code

ClickHouse error code (integer) of the most recent server-side exception,
or C<0> if no error. The B<top-level> code is reported even when the
exception is a chain. Useful for distinguishing retryable errors (e.g.
C<202> = C<TOO_MANY_SIMULTANEOUS_QUERIES>) from permanent ones (C<60> =
C<UNKNOWN_TABLE>, C<516> = C<AUTHENTICATION_FAILED>).

=item last_totals

Arrayref of totals rows from the last query that used C<with totals>,
or C<undef>. Native only.

=item last_extremes

Arrayref of extremes rows from the last native query, or C<undef>.

=item profile_rows_before_limit

Rows that would have been returned without C<limit>. Useful for pagination
UIs. Native only.

=item profile_rows

Total rows processed by the last query. Populated from the native
ProfileInfo packet on the native protocol, or from C<X-ClickHouse-Summary>
(C<read_rows>) on HTTP.

=item profile_bytes

Total bytes processed by the last query. Populated from the native
ProfileInfo packet on the native protocol, or from C<X-ClickHouse-Summary>
(C<read_bytes>) on HTTP.

=back

=head1 ALIASES

    q          -> query
    ddl        -> query
    reconnect  -> reset
    disconnect -> finish

=head1 REQUIREMENTS

=over 4

=item * Perl 5.14 or newer

=item * L<EV> 4.11 or newer (event loop)

=item * zlib (required)

=item * OpenSSL (optional, for TLS; auto-detected at build time)

=item * liblz4 (optional, for native protocol compression; auto-detected)

=back

=head1 TROUBLESHOOTING

=over 4

=item AUTHENTICATION_FAILED on the first query

The native handshake authenticates lazily; the first query is what surfaces
a bad C<user>/C<password>. Check the server's C<users.xml> and the URI form
C<clickhouse://user:pass@host:port/db>.

=item DateTime returns a number, not a string

C<DateTime>/C<Date> decode to raw integers (Unix epoch / days since epoch)
by default for stable round-tripping. Pass C<decode_datetime =E<gt> 1> to get
ISO-formatted strings.

=item ClickHouse error C<UNKNOWN_DATABASE> on connect

The C<database> argument is sent as the default; the server must already
have that database. Use C<database =E<gt> 'default'> while bootstrapping.

=item Insert silently dropped (counts don't match)

Likely C<insert_deduplication_token> dedupe; either you're reusing a token
across distinct batches, or the table is C<ReplicatedMergeTree> with the
default dedupe window. See F<eg/idempotent_insert.pl>.

=item Hangs on connect when host is a hostname

Without L<EV::cares>, DNS resolution falls back to blocking
C<getaddrinfo>. Install L<EV::cares> for non-blocking lookup; otherwise
use an IP literal or a local caching resolver (nscd / systemd-resolved).

=item C<connect_timeout> doesn't fire

It does across TCP connect, TLS handshake, and native ServerHello. If
the timer doesn't fire, the underlying issue is usually a synchronous
DNS stall (see above) which happens before C<start_connect> arms the
timer; install L<EV::cares> to push DNS off the loop.

=item Per-query C<query_timeout> is ignored

Set it inside the C<\%settings> hashref, not as a top-level argument:
C<<< $ch->query($sql, { query_timeout =E<gt> 5 }, $cb) >>>.

=item Which host am I currently pointed at after failover?

C<<< $ch->current_host >>> and C<<< $ch->current_port >>> reflect the
live target after a multi-host rotation. Use C<<< on_failover =E<gt>
sub { ... } >>> to get notified at the moment of each rotation.

=item How do I retry only on transient errors?

C<<< EV::ClickHouse->is_retryable_error($code) >>> returns true for the
common transient codes (timeouts, network errors, replica catch-up,
keeper exceptions, ...). Inspect C<<< $ch->last_error_code >>> from
inside your query callback and schedule a retry only when the predicate
fires - permanent errors (auth failures, missing tables) won't qualify.

Sample skeleton:

    $ch->query($sql, sub {
        my ($r, $err) = @_;
        if ($err && EV::ClickHouse->is_retryable_error($ch->last_error_code)) {
            schedule_retry($sql);
        } elsif ($err) { warn "permanent: $err" }
    });

=item Idempotent insert silently drops some rows

C<<< idempotent =E<gt> 1 >>> auto-mints
C<insert_deduplication_token>; if your producer issues the SAME logical
batch twice (e.g. retry after a transient network blip) only the first
write lands, by design. To force two distinct logical batches through,
either pass an explicit C<<< idempotent =E<gt> $token >>> per batch or
omit the option for fresh inserts. See F<eg/idempotent_insert.pl>.

=item C<on_data> vs C<iterate> - which should I pick?

C<<< on_data =E<gt> sub { } >>> in the per-query settings is the
lowest-overhead streaming path: each native data block is delivered as
soon as the parser has it, no per-row allocation overhead beyond the
batch arrayref. C<iterate> is a synchronous-feeling pull wrapper around
the same machinery - useful when the surrounding code is procedural
(ETL scripts, exporters) and a callback shape doesn't fit. Both are
native-only.

=item Connection in front of nginx / reverse proxy strips X-ClickHouse-* headers

Pass C<<< http_basic_auth =E<gt> 1 >>> to send the credentials as
C<Authorization: Basic ...> instead. Most HTTP gateways forward
Authorization verbatim while filtering proprietary headers.

=back

=head1 TUNING

=over 4

=item Native vs HTTP

Native (port 9000) is typically 2-5x faster for insert and select-of-many-rows
because rows ship as binary columns instead of TSV text. Use HTTP only when
the network path requires HTTPS-only or when you need C<raw =E<gt> 1> CSV /
JSONEachRow / Parquet bodies.

=item C<compress =E<gt> 1>

Enables LZ4 (native) or gzip (HTTP). LZ4 cost is small and saves ~50-70%
on text-heavy columns. Gzip is heavier; turn on only if you're bandwidth-bound.

=item C<insert_streamer> batch_size

Default 10_000 is a good baseline. Smaller (1k-2k) reduces memory pressure
on the producer; larger (50k-100k) reduces server-side merge cost on
MergeTree. Match to your row width: ~1 MB per batch is a sweet spot.

=item C<keepalive>

Enable on long-lived idle connections (HTTP behind a load balancer or
NAT, or a native connection that may sit minutes between queries). 15-30s
is typical.

=item C<reconnect_max_attempts>

Always set in production. Default is unlimited; a permanent failure
(wrong host, wrong port, dead server) will spin C<on_error> forever
otherwise.

=item C<progress_period>

Coalesce on_progress packets to one fire per N seconds. Big SELECTs can
emit hundreds per second; throttle to 1-5s for monitoring dashboards.

=item Pull-iterator vs C<on_data>

C<on_data> has lower per-block overhead. C<iterate> trades that for a
synchronous-feeling API; use it when the surrounding code is procedural.

=item C<EV::ClickHouse::Pool>

A Pool fans concurrent queries across N independent connections, so a
slow query on one doesn't head-of-line-block the others. Use it for
read-mostly fan-out; do not use it for queries that depend on
session-level state (temporary tables, C<set>) since each query may
land on a different connection.

=back

=head2 Performance tuning checklist

=over 4

=item 1. Pick the right protocol

Native (port 9000) beats HTTP (port 8123) for almost all workloads.
HTTP is only required for HTTPS-fronted ingress, the C<raw> mode that
returns C<RowBinary> / C<JSONEachRow> / C<Parquet> bodies unparsed, or
gateway authentication that strips proprietary CH headers (see
C<http_basic_auth>).

=item 2. Tune C<batch_size> for INSERTs

Aim for ~1 MB per batch. ClickHouse merges every block into a part on
disk, so 1k blocks of 1k rows each is dramatically slower than 1 block
of 1M rows because of merge amplification. C<insert_streamer> with
C<batch_size =E<gt> $rows_for_1MB> + C<high_water> backpressure is the
production-grade default.

=item 3. Cap C<max_recv_buffer>

Without a cap, a runaway select (or a buggy upstream that returns
gigabytes) will grow the recv buffer until the process is OOM-killed.
Set C<max_recv_buffer =E<gt> 64 * 1024 * 1024> (64 MB) and let the
parser tear the connection down with a clean error if exceeded - the
caller's on_error can decide whether to retry or surface to the user.

=item 4. Watch for head-of-line blocking

A single C<EV::ClickHouse> serialises queries. Use
L<EV::ClickHouse::Pool> when concurrent queries should run in parallel
(read-mostly workloads, dashboard fan-out). For latency-sensitive
SELECTs against replicated tables, C<< $pool->hedged_query >> sends
the request to N members and resolves with the first reply,
shaving tail latency at the cost of extra server work.

=item 5. Measure latencies cheaply

C<<< $ch->track_query_durations(1024) >>> installs a fixed-size ring
buffer of recent query durations; subsequent
C<<< $ch->query_duration_p(0.95) >>> reports the p95. Useful for
in-process histograms when you don't want to wire up a metrics
backend just for one connection. Composes with a user-supplied
C<on_query_complete> (which is preserved and called first).

=item 6. Use C<server_supports> for capability gating

Don't hard-code C<server_revision E<gt>= 54420>; ask
C<<< $ch->server_supports('progress_writes') >>>. The capability
table maps human-readable feature names to revisions and is updated
when the client revision changes, so callers don't have to track
protocol numbers.

=item 7. Inspect via C<dump_state> and C<pending_queries>

When a connection seems stuck, C<<< $ch->dump_state >>> returns a
hashref snapshot (fd state, send/recv buffer pos, callback depth,
pending_count, ...) and C<<< $ch->pending_queries >>> lists the
in-flight + queued entries with their query_ids and age. Both are
read-only debug accessors - safe to call from a signal-handler-style
dump path.

=item 8. Don't fight the freelist

The XS layer keeps freelists for both cb_queue and send_queue entries,
so allocating callbacks is essentially free after warm-up. The
implication: avoid wrapping the connection in heavy wrappers that
clone the connection per call - there is no per-call setup cost worth
amortising away.

=back

=head1 ARCHITECTURE

The client is a single state machine driven by an L<EV> event loop. Each
connection holds: a TCP fd (non-blocking), a send buffer, a receive
buffer, a callback queue (next-in-line per protocol), and a pending
send queue (buffered before connect).

State transitions:

    Connect TCP --> [TLS handshake] --> [Native ServerHello]
        --> Connected --> { dispatch from send_queue;
                            parse response; deliver via cb_queue }

The connect_timeout timer covers all three pre-Connected stages.
auto_reconnect re-runs the chain via C<schedule_reconnect>.

Two key invariants:

=over 4

=item *

Native protocol is strictly request/response. Only one query is
in-flight per connection at a time. C<insert_streamer> serialises
batches against this constraint.

=item *

C<callback_depth> guards against C<self> being freed mid-callback.
Every callback dispatch increments it; C<check_destroyed> defers the
final C<Safefree> until depth returns to zero.

=back

For deeper detail (state-machine table, queue semantics) see C<CLAUDE.md>
in the source distribution.

=head1 TYPES

Per-column wire format and Perl-side gotchas. All numeric types
round-trip stable raw values by default; opt into string forms via
C<decode_datetime>, C<decode_decimal>, C<decode_enum>.

=over 4

=item Integers

Int8..Int64 / UInt8..UInt64: native Perl IV/UV. Int128/UInt128/Int256/UInt256
return decimal string representations on platforms with C<__int128> (Int128/UInt128)
or always for the 256-bit forms.

=item Floats

Float32/Float64 round-trip exactly within IEEE-754 limits. C<NaN>/C<+Inf>/
C<-Inf> are preserved.

=item BFloat16

Top 16 bits of a Float32. Encoded by truncation; decoded by zero-extension.
Suitable for ML feature columns; not for accounting.

=item Decimal32/64/128

Decoded as IV (raw integer) or NV (scaled to N decimal digits if
C<decode_decimal =E<gt> 1>). Decimal128 over very long precision may lose
trailing digits in the NV form; pass C<decode_decimal =E<gt> 0> and divide
yourself with L<Math::BigInt> for exact arithmetic.

=item Decimal256

Returns raw 32 LE bytes. Decode with L<Math::BigInt> (see
C<eg/decimal_bigmath.pl>).

=item Date / Date32 / DateTime / DateTime64

Default: integer (days since epoch / Unix seconds). With C<decode_datetime>:
C<YYYY-MM-DD> or C<YYYY-MM-DD HH:MM:SS> or C<YYYY-MM-DD HH:MM:SS.ffffff>.
DateTime carries a timezone string; the formatted output uses it.

=item Bool

Decoded as 0/1. Encoded from any truthy/falsy SV. ClickHouse stores
internally as UInt8 0/1.

=item String / FixedString

Bytes-in, bytes-out. No UTF-8 transformation.

=item UUID

Canonical hex form C<xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx>. Encode
accepts the same.

=item IPv4 / IPv6

Dotted-quad / canonical IPv6 strings.

=item Enum8 / Enum16

Default: integer code. With C<decode_enum =E<gt> 1>: label string.

=item Nullable(T)

C<undef> in Perl maps to null; otherwise the inner type's encoding.

=item Array(T)

Perl arrayref of inner-type values.

=item Tuple(T1, T2, ...)

Perl arrayref ordered as the type declaration. Named tuples
(C<Tuple(a Int32, b String)>) are still arrayref-positional;
parse the name from C<column_types> if you need it.

=item Map(K, V)

Perl hashref. Keys are stringified.

=item LowCardinality(T)

Transparent: encodes/decodes as the inner type. Cross-block dictionaries
are managed internally.

=item SimpleAggregateFunction / AggregateFunction

Decoded as the inner declared type (correct for sum/min/max/avg-ish
functions). For complex states (quantile, uniqExact, ...) wrap the select
with C<finalizeAggregation(col)> server-side.

=item Geo (Point/Ring/LineString/MultiLineString/Polygon/MultiPolygon)

Decoded as the underlying nested arrayref/tuple shape.

=item JSON / Object('json')

Decoded as a Perl hashref with dotted-path leaves auto-unflattened to
nested hashes. Encode accepts arbitrarily-nested hashrefs; supported
leaf kinds are Int64, Float64, Bool (recognised JSON::PP::Boolean
classes or C<SvIsBOOL>), String, and Array(<those>).

=item Variant / Dynamic

Recognised by the type parser, but the wire format is per-server-
version and not implemented here. Selecting a C<Variant(...)> or
C<Dynamic> column raises a clean decode error and tears the connection
down (this is safer than guessing the framing and corrupting every
subsequent column). Wrap with C<toString(col)> or
C<CAST(col AS String)> server-side to read the value as its JSON
representation.

=item Interval (Second/Minute/Hour/Day/Week/Month/Quarter/Year)

Decoded as Int64 (the unit count). The unit is implicit from the column
type.

=back

=head1 COOKBOOK

The F<eg/> directory in the source distribution carries runnable
patterns for the common production shapes. Each one is self-contained
and reads top-to-bottom.

=over 4

=item F<eg/etl_pipeline.pl>

Producer + Pool + L</insert_streamer> with C<high_water> backpressure
and C<idempotent> tokens. The reliable-ingest baseline.

=item F<eg/health_probe.pl>

Periodic L</is_healthy> probe with bounded timeout, transition logging,
and automatic L</reset> on failure. Drop-in for self-monitoring.

=item F<eg/circuit_breaker.pl>

Pool with C<circuit_threshold> + C<circuit_cooldown> shielding the
rotation from a sticky bad member. Demonstrates C<circuit_state>
introspection.

=item F<eg/csv_export.pl>

Streams a multi-million-row select to a CSV file via the per-block
C<on_data> hook (no full-result buffering). Mirrors the equivalent
L</iterate> form in a comment.

=item F<eg/migration_runner.pl>

Apply numbered SQL migration files in order, recording successes in a
C<_migrations> table and using C<idempotent> on the registry insert
so a partial apply doesn't leave the registry out of sync.

=item F<eg/failover.pl> + F<eg/pool.pl>

Multi-host failover and built-in connection pool - the reliability
primitives the cookbook recipes layer on top of.

=item F<eg/async_dns.pl>

Constructor returns immediately even for hostnames; queries queue
behind L<EV::cares> resolution.

=item F<eg/idempotent_insert.pl>

Auto-minted insert deduplication tokens that survive a reconnect-
driven retry without double-writing.

=item F<eg/external_tables.pl>

Ships a client-side data block with a query as an L<external table|/query>
- an C<IN> filter against an id set, and a JOIN against a client lookup
table - in a single round trip.

=back

=head1 EV::ClickHouse::Error

Lightweight error class. Callbacks always receive C<($result, $err_msg)>
plain strings (preserved for compatibility); this object is opt-in via
C<EV::ClickHouse::Error-E<gt>from_ch($ch, $err)> when callers want
structured access to the code, symbolic name, and retryability of the
last server-side exception.

    my $e = EV::ClickHouse::Error->from_ch($ch, $err) or return;
    if ($e->is_retryable) { schedule_retry() }
    elsif ($e->code == 60) {                              # UNKNOWN_TABLE
        warn "table missing: $e";                          # stringifies to msg
    }

=over 4

=item new(message =E<gt> $msg, code =E<gt> $code)

Plain constructor; rarely used directly.

=item from_ch($ch, $err)

Build from the C<($ch, $err)> pair available in callbacks. C<code>
comes from C<$ch-E<gt>last_error_code>. Returns C<undef> if C<$err> is
empty (so the idiom C<my $e = ...->from_ch(...) or return> works).

=item message / code / name / is_retryable

Field accessors. C<name> looks up the symbolic name for the code (e.g.
C<UNKNOWN_TABLE> for 60); returns C<undef> for codes not in the table.
C<is_retryable> consults the same list L</is_retryable_error> uses.

=item EV::ClickHouse::Error-E<gt>code_name($code)

Class-method lookup of the symbolic name for a numeric code.

=item EV::ClickHouse::Error-E<gt>known_codes

Sorted list of all numeric codes the symbolic-name table covers. The
table is informational only - codes outside it are still valid
ClickHouse errors, just unnamed by this module.

=back

The object overloads stringification to return the message, so legacy
callsites that string-compare or interpolate C<$err> keep working
verbatim when the error is wrapped.

=head1 SEE ALSO

=over 4

=item *

L<EV> - the underlying event loop.

=item *

L<EV::cares> - optional async DNS resolver picked up automatically when
installed.

=item *

L<https://clickhouse.com/docs/en/interfaces/tcp> - native binary
protocol reference.

=item *

L<https://clickhouse.com/docs/en/interfaces/http> - HTTP interface.

=item *

L<https://clickhouse.com/docs/en/operations/server-configuration-parameters/settings>
- server-side settings forwarded via the C<settings> hash.

=back

=head1 AUTHOR

vividsnow

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
