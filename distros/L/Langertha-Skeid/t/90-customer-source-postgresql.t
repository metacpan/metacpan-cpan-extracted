use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use IO::Socket::INET;
use Path::Tiny qw(path);
use POSIX qw(WNOHANG);
use FindBin;
use Mojo::IOLoop;
use Mojo::UserAgent;
use Time::HiRes qw(time);
use Langertha::Skeid;
use Langertha::Skeid::CustomerSource::DBI;

# customer_source against a REAL PostgreSQL (ADR 0026, k108/k109): the manual procedure of
# examples/service/skeid.yaml, run by a test. Runs only with
#
#   SKEID_TEST_PG_DSN    dbi:Pg:dbname=<maintenance db>;host=<h>;port=<p>   a role that may
#   SKEID_TEST_PG_USER   CREATE DATABASE (and, to test a read-only role, CREATE ROLE)
#   SKEID_TEST_PG_PASS
#
# and skips otherwise, so `prove -lr t/` stays offline. From the DBIO test cluster:
#
#   eval "$(dbio-db env postgresql)"
#   SKEID_TEST_PG_DSN=$DBIO_TEST_PG_DSN SKEID_TEST_PG_USER=$DBIO_TEST_PG_USER \
#     SKEID_TEST_PG_PASS=$DBIO_TEST_PG_PASS prove -lv t/90-customer-source-postgresql.t
#
# It creates its own database skeid_verify_<pid> (and role skeid_reader_<pid>), touches nothing
# else, and drops both at the end -- also when a test dies. Covered:
#   1. connect + query in a child process with DBD::Pg, a text[] column `models`
#   2. LISTEN/NOTIFY child: a NOTIFY refreshes within well under the poll interval
#   3. reconnect after pg_terminate_backend, and the last good snapshot kept while the
#      database refuses connections
#   4. the fetcher under `skeid serve --workers 3`
# Measured latencies are printed as diagnostics.

my ($created_db, $created_role) = (0, 0);
my ($DSN, $USER, $PASS) = @ENV{qw( SKEID_TEST_PG_DSN SKEID_TEST_PG_USER SKEID_TEST_PG_PASS )};
plan skip_all => 'set SKEID_TEST_PG_DSN, SKEID_TEST_PG_USER and SKEID_TEST_PG_PASS to run against PostgreSQL'
  unless $DSN && $DSN =~ /\Adbi:Pg:/i && defined $USER;
eval { require DBI; require DBD::Pg; 1 } or plan skip_all => 'DBD::Pg is needed';
$PASS //= '';

delete @ENV{qw( OPENBAO_ROLE_ID OPENBAO_SECRET_ID OPENBAO_ADDR SKEID_ADMIN_API_KEY
  SKEID_TRUST_KEY_ID_HEADER )};

my $DB     = 'skeid_verify_' . $$;
my $ROLE   = 'skeid_reader_' . $$;
my $RPASS  = 'rp-' . join '', map { sprintf '%08x', int rand 2**32 } 1 .. 3;
my $LISTEN = 'skeid_customer_keys';

sub dsn_for {
  my ($db) = @_;
  my $d = $DSN;
  $d =~ s/\bdbname=[^;]*/dbname=$db/ or $d .= ";dbname=$db";
  return $d;
}
sub admin { DBI->connect(@_ ? dsn_for($_[0]) : $DSN, $USER, $PASS, { RaiseError => 1, PrintError => 0, AutoCommit => 1 }) }

sub cleanup {
  return unless $created_db || $created_role;
  my $ok = eval {
    my $a = admin();
    if ($created_db) {
      $a->do("ALTER DATABASE $DB WITH ALLOW_CONNECTIONS true");
      $a->do('SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = ' . $a->quote($DB));
      $a->do("DROP DATABASE IF EXISTS $DB");
      $created_db = 0;
    }
    if ($created_role) {
      $a->do("DROP ROLE IF EXISTS $ROLE");
      $created_role = 0;
    }
    $a->disconnect;
    1;
  };
  warn "cleanup of $DB failed: $@" unless $ok;
}
END { local $?; cleanup() }

# --- the database, shaped as examples/service/skeid.yaml says ---------------------------------
my $adm = admin();
$adm->do("CREATE DATABASE $DB");
$created_db = 1;
my $can_role = eval { $adm->do("CREATE ROLE $ROLE LOGIN PASSWORD " . $adm->quote($RPASS)); 1 };
$created_role = 1 if $can_role;

my $db = admin($DB);
$db->do($_) for (
  'CREATE SCHEMA console',
  'CREATE TABLE console.api_keys (key_id text PRIMARY KEY, label text, plan text,
     models text[], revoked_at timestamptz)',
  'CREATE SCHEMA skeid',
  'CREATE VIEW skeid.customer_keys AS
     SELECT key_id, label AS name, plan AS policy, models
       FROM console.api_keys WHERE revoked_at IS NULL',
  q{CREATE FUNCTION console.notify_skeid() RETURNS trigger LANGUAGE plpgsql AS
      $$ BEGIN PERFORM pg_notify('skeid_customer_keys', ''); RETURN NULL; END $$},
  'CREATE TRIGGER api_keys_notify AFTER INSERT OR UPDATE OR DELETE ON console.api_keys
     FOR EACH STATEMENT EXECUTE FUNCTION console.notify_skeid()',
);
if ($can_role) {
  $db->do($_) for (
    "GRANT USAGE ON SCHEMA skeid TO $ROLE",
    "GRANT SELECT ON skeid.customer_keys TO $ROLE",
  );
}
my $READER   = $can_role ? $ROLE  : $USER;
my $READER_PW = $can_role ? $RPASS : $PASS;
$ENV{SKEID_T90_DB_PASSWORD} = $READER_PW;

my %KEY = map { $_ => "sk-verify-$_-" . $$ } qw( alice bob carol dave );
my %ID  = map { $_ => Langertha::Skeid->key_id_for_key($KEY{$_}) } keys %KEY;
sub add_key { my ($who, @r) = @_;
  $db->do('INSERT INTO console.api_keys (key_id, label, plan, models) VALUES (?,?,?,?)',
    undef, $ID{$who}, $who, @r ? @r : (undef, undef)) }
sub revoke  { my ($who) = @_;
  $db->do('UPDATE console.api_keys SET revoked_at = now() WHERE key_id = ?', undef, $ID{$who}) }

sub source_cfg {
  my (%extra) = @_;
  return { dsn => dsn_for($DB), user => $READER, password_env => 'SKEID_T90_DB_PASSWORD',
    relation => 'skeid.customer_keys', refresh_interval_s => 60, connect_timeout_s => 3, %extra };
}

sub wait_until {
  my ($cond, $max) = @_;
  my $t0  = time;
  my $end = $t0 + ($max // 5);
  my $tick = Mojo::IOLoop->recurring(0.005 => sub { });
  Mojo::IOLoop->one_tick until $cond->() || time > $end;
  Mojo::IOLoop->remove($tick);
  return $cond->() ? time - $t0 : undef;
}

sub backends {
  return $db->selectrow_array(
    'SELECT count(*) FROM pg_stat_activity WHERE datname = ? AND usename = ? AND pid <> pg_backend_pid()',
    undef, $DB, $READER);
}

# === 1. connect + query in a child, with a text[] column =====================================
{
  $db->do('INSERT INTO console.api_keys (key_id, label, plan, models) VALUES (?,?,?,?)',
    undef, $ID{alice}, 'alice', undef, '{qwen3-32b,llama-3.3}');
  add_key('bob');
  $db->do('INSERT INTO console.api_keys (key_id, label, revoked_at) VALUES (?,?,now())',
    undef, $ID{carol}, 'carol');

  my $f = Langertha::Skeid::CustomerSource::DBI->new(config =>
    Langertha::Skeid::CustomerSource->normalize_config(source_cfg()));
  my ($err, $rows);
  $f->fetch(sub { ($err, $rows) = @_; Mojo::IOLoop->stop });
  my $guard = Mojo::IOLoop->timer(15 => sub { $err = 'guard'; Mojo::IOLoop->stop });
  my $ticks = 0;
  my $tick  = Mojo::IOLoop->recurring(0.02 => sub { $ticks++ });
  Mojo::IOLoop->start;
  Mojo::IOLoop->remove($_) for $guard, $tick;
  ok !defined($err), 'the fetch on real PostgreSQL succeeds' or diag $err;
  my %by = map { $_->{key_id} => $_ } @{ $rows // [] };
  is scalar(keys %by), 2, 'the revoked key (revoked_at set) is not in the view';
  is_deeply $by{$ID{alice}}{models}, [ 'qwen3-32b', 'llama-3.3' ], 'text[] models arrives as an array ref';
  is $by{$ID{alice}}{name}, 'alice', 'the name column arrives';
  ok !defined($by{$ID{bob}}{models}), 'a NULL models stays undef';
  ok !defined($by{$ID{bob}}{policy}), 'and a NULL policy';

  # The statement as the module issues it, checked against the real planner.
  ok eval { $db->selectall_arrayref(Langertha::Skeid::CustomerSource->statement('skeid.customer_keys')); 1 },
    'the generated statement runs unchanged';

  # A wrong password: an error without the password.
  my $bad = Langertha::Skeid::CustomerSource::DBI->new(config =>
    Langertha::Skeid::CustomerSource->normalize_config(source_cfg()));
  $bad->config->{password} = 'definitely-wrong-pw-' . $$;
  my ($e2, $r2);
  $bad->fetch(sub { ($e2, $r2) = @_; Mojo::IOLoop->stop });
  $guard = Mojo::IOLoop->timer(15 => sub { $e2 = 'guard'; Mojo::IOLoop->stop });
  Mojo::IOLoop->start;
  Mojo::IOLoop->remove($guard);
  ok defined($e2) && !defined($r2), 'a refused login is an error without rows';
  unlike $e2 // '', qr/definitely-wrong-pw/, 'which never carries the password';
  unlike $e2 // '', qr/\Q$READER_PW\E/, 'nor the real one';
}

# === 2 + 3. NOTIFY, revocation latency, reconnect, outage ===================================
{
  my $cfg = {
    client_auth     => { keys => [] },
    customer_source => source_cfg(listen => $LISTEN, refresh_interval_s => 4, max_stale_s => 0),
  };
  my @warn;
  local $SIG{__WARN__} = sub { push @warn, @_ };
  my $skeid = Langertha::Skeid->new(
    config_reload_interval => 0,
    config_loader          => sub { $cfg },
    store_usage_event      => sub { { ok => 1 } },
  );
  $skeid->start_customer_source;
  ok defined wait_until(sub { $skeid->client_key_allowed($ID{alice}) }, 15),
    'the real fetcher loads the keys from PostgreSQL';
  ok $skeid->client_key_allowed($ID{bob}), 'both live keys are in force';
  ok !$skeid->client_key_allowed($ID{carol}), 'the revoked one is not';
  my $st = $skeid->customer_source_status;
  is $st->{rows}{accepted}, 2, 'status: two rows accepted';
  ok $st->{ok}, 'status ok';

  # The LISTEN child has to be up before a NOTIFY means anything.
  ok defined wait_until(sub { backends() >= 2 }, 10), 'a listener connection exists next to the fetches'
    or diag 'backends: ' . backends();
  sleep 1;

  # 2. NOTIFY -> refresh, far below the 4 s poll.
  add_key('dave');
  my $lat = wait_until(sub { $skeid->client_key_allowed($ID{dave}) }, 6);
  ok defined($lat) && $lat < 2, 'an inserted key is let in by NOTIFY, well under the poll interval'
    or diag 'latency: ' . ($lat // 'never');
  diag sprintf 'NOTIFY -> key in force: %.0f ms (poll interval 4000 ms)', 1000 * ($lat // -1);

  revoke('dave');
  my $rev = wait_until(sub { !$skeid->client_key_allowed($ID{dave}) }, 6);
  ok defined($rev) && $rev < 2, 'a revoked key is refused by NOTIFY, well under the poll interval'
    or diag 'latency: ' . ($rev // 'never');
  diag sprintf 'revocation latency (commit -> refused): %.0f ms', 1000 * ($rev // -1);

  # 3a. the connection of the Skeid role is killed: nothing may break, and the next change
  # still arrives (poll at the latest: the listener comes back with a fetch).
  my $killed = $adm->selectrow_array(
    'SELECT count(*) FROM (SELECT pg_terminate_backend(pid) FROM pg_stat_activity
       WHERE datname = ? AND usename = ?) t', undef, $DB, $READER);
  cmp_ok $killed, '>=', 1, "pg_terminate_backend hit $killed Skeid connection(s)";
  ok $skeid->client_key_allowed($ID{alice}), 'keys stay in force right after the connection is killed';
  $db->do('UPDATE console.api_keys SET revoked_at = NULL WHERE key_id = ?', undef, $ID{carol});
  my $back = wait_until(sub { $skeid->client_key_allowed($ID{carol}) }, 12);
  ok defined $back, 'a change after the kill is picked up (reconnect)' or diag 'never';
  diag sprintf 'change after pg_terminate_backend picked up after %.1f s', $back // -1;
  ok defined wait_until(sub { $skeid->customer_source_status->{ok} }, 5), 'status ok again';

  # The listener is back too: a NOTIFY is quick again.
  ok defined wait_until(sub { backends() >= 2 }, 10), 'the listener reconnected';
  sleep 1;
  revoke('carol');
  my $rev2 = wait_until(sub { !$skeid->client_key_allowed($ID{carol}) }, 6);
  ok defined($rev2) && $rev2 < 2, 'NOTIFY works again after the reconnect'
    or diag 'latency: ' . ($rev2 // 'never');
  diag sprintf 'revocation after reconnect: %.0f ms', 1000 * ($rev2 // -1);

  # 3b. the database refuses connections: the last good snapshot stays, the status says why.
  $adm->do("ALTER DATABASE $DB WITH ALLOW_CONNECTIONS false");
  $adm->do('SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = ' . $adm->quote($DB)
    . ' AND usename = ' . $adm->quote($READER));
  my $down = wait_until(sub { !$skeid->customer_source_status->{ok} }, 12);
  ok defined $down, 'the status turns to not ok during the outage';
  diag sprintf 'outage visible in status after %.1f s', $down // -1;
  $st = $skeid->customer_source_status;
  ok $st->{failures} >= 1, 'failures counted';
  ok $skeid->client_key_allowed($ID{alice}) && $skeid->client_key_allowed($ID{bob}),
    'the last good snapshot stays in force during the outage';
  ok !$skeid->client_key_allowed($ID{carol}), 'and is the state before the outage';
  unlike($st->{error} // '', qr/\Q$READER_PW\E/, 'the error carries no password');
  $adm->do("ALTER DATABASE $DB WITH ALLOW_CONNECTIONS true");
  my $heal = wait_until(sub { $skeid->customer_source_status->{ok} }, 15);
  ok defined $heal, 'the source recovers when the database accepts connections again';
  diag sprintf 'recovered after %.1f s', $heal // -1;
  is $skeid->customer_source_status->{failures}, 0, 'with the failure count reset';

  my $leak = join "\n", @warn;
  unlike $leak, qr/\Q$READER_PW\E/, 'no warning carried the password';
  $skeid->stop_customer_source;
}

# === 4. skeid serve --workers 3 ===============================================================
SKIP: {
  my $tmp  = tempdir(CLEANUP => 1);
  my $bin  = path($FindBin::Bin)->parent->child('bin', 'skeid')->stringify;
  my $sock = IO::Socket::INET->new(Listen => 1, LocalAddr => '127.0.0.1', LocalPort => 0, ReuseAddr => 1);
  my $port = $sock->sockport;
  close $sock;

  # Password and admin key through the environment: no secret on disk or on the command line.
  my $cfg = path($tmp)->child('skeid.yaml');
  $cfg->spew_utf8(join "\n",
    'client_auth: { keys: [] }',
    'customer_source:',
    '  dsn: ' . dsn_for($DB),
    "  user: $READER",
    '  password_env: SKEID_T90_DB_PASSWORD',
    '  relation: skeid.customer_keys',
    "  listen: $LISTEN",
    '  refresh_interval_s: 30',
    '  connect_timeout_s: 3',
    '');
  $db->do('UPDATE console.api_keys SET revoked_at = NULL WHERE key_id = ?', undef, $ID{bob});
  $db->do('UPDATE console.api_keys SET revoked_at = now() WHERE key_id = ?', undef, $ID{dave});

  my $out = path($tmp)->child('serve.out');
  local $ENV{PERL5LIB} = join(':', grep { !ref } @INC);
  local $ENV{SKEID_ADMIN_API_KEY} = 'admin-' . $$;
  my $pid = fork;
  die "fork: $!" unless defined $pid;
  if (!$pid) {
    open STDOUT, '>', "$out" or die $!;
    open STDERR, '>&', \*STDOUT or die $!;
    chdir $tmp or die $!;
    exec $^X, $bin, 'serve', '--listen', "127.0.0.1:$port", '--config', "$cfg", '--workers', '3';
    die "exec: $!";
  }
  my $ua = Mojo::UserAgent->new(max_redirects => 0)->connect_timeout(2)->request_timeout(5);
  $ua->ioloop(Mojo::IOLoop->new);   # its own loop: the parent test drives nothing else here
  my $base = "http://127.0.0.1:$port";
  my $up = 0;
  for (1 .. 100) {
    $up = 1, last if eval { $ua->get("$base/health")->result->code == 200 };
    select undef, undef, undef, 0.1;
  }
  ok $up, 'skeid serve --workers 3 is listening' or diag $out->slurp_utf8;
  skip 'serve did not start', 8 unless $up;

  my $text = $out->slurp_utf8;
  like $text, qr/Workers: 3/, 'three workers';
  like $text, qr/Customer source: skeid\.customer_keys/, 'the start announces the source';
  like $text, qr/Customer source: \d+ accepted/, 'the startup fetch succeeded before listening';
  unlike $text, qr/\Q$READER_PW\E/, 'the server output carries no password';

  my $status = sub {
    my ($key) = @_;
    my $tx = $ua->post("$base/v1/chat/completions" => { Authorization => "Bearer $key" } =>
      json => { model => 'm', messages => [ { role => 'user', content => 'hi' } ] });
    return $tx->result->code;
  };
  my @codes = map { $status->($KEY{alice}) } 1 .. 12;
  is scalar(grep { $_ != 401 } @codes), 12, 'a source key is let in on every one of 12 requests (not 401)';
  is $status->('sk-nobody-' . $$), 401, 'an unknown key is refused';
  is $status->($KEY{dave}), 401, 'a revoked key is refused';

  # Each worker has its own listener: at least three idle connections of the Skeid role.
  my $listeners = wait_until(sub { backends() >= 3 }, 15);
  ok defined $listeners, 'every worker holds its own database connection(s)'
    or diag 'backends: ' . backends();

  # Revocation reaches every worker through NOTIFY (poll is 30 s).
  sleep 1;
  revoke('alice');
  my $t0 = time;
  my $all = 0;
  while (time - $t0 < 8) {
    my @c = map { $status->($KEY{alice}) } 1 .. 12;
    $all = scalar(grep { $_ == 401 } @c) == 12 ? 1 : 0;
    last if $all;
  }
  ok $all, 'after a revocation all 12 requests, over all workers, are 401'
    or diag 'not all refused within 8 s';
  diag sprintf 'prefork revocation: all workers refuse after %.0f ms', 1000 * (time - $t0);

  my $cfgres = $ua->get("$base/skeid/config" => { Authorization => 'Bearer admin-' . $$ })->result;
  is $cfgres->code, 200, 'GET /skeid/config';
  ok $cfgres->json('/customer_source/ok'), 'customer_source ok in the admin config';
  unlike $cfgres->body, qr/\Q$READER_PW\E/, 'and without the password';
  for my $who (keys %KEY) {
    unlike $cfgres->body, qr/\Q$KEY{$who}\E/, "nor the key of $who";
  }

  kill 'QUIT', $pid;
  my $dead = 0;
  for (1 .. 100) {
    if (waitpid($pid, WNOHANG) == $pid) { $dead = 1; last }
    select undef, undef, undef, 0.1;
  }
  unless ($dead) { kill 'KILL', $pid; waitpid($pid, 0) }
  ok $dead, 'skeid serve stops on SIGQUIT';
  ok defined wait_until(sub { backends() == 0 }, 10), 'and leaves no database connection behind'
    or diag 'backends: ' . backends();
}

$db->disconnect;
$adm->disconnect;
cleanup();
{
  my $a = admin();
  my ($left) = $a->selectrow_array('SELECT count(*) FROM pg_database WHERE datname = ?', undef, $DB);
  is $left, 0, "database $DB is dropped";
  $a->disconnect;
}

done_testing;
