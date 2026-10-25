use strict;
use warnings;
use Test2::V0;
use IO::Async::Loop;
use Log::Any::Adapter;
use IO::Async::Timer::Periodic;
use Time::HiRes qw( time sleep );

# k82: Langertha::Knarr::TokenStore::Pg against a real PostgreSQL.
# The live part needs KNARR_TEST_PG_DSN, KNARR_TEST_PG_USER and
# KNARR_TEST_PG_PASS; it creates its own schema and drops it again.
use Langertha::Knarr::TokenStore::Pg;

my $class = 'Langertha::Knarr::TokenStore::Pg';
my @args  = ( dsn => 'dbi:Pg:dbname=none', relation => 'r', listen => 'c' );

subtest 'without DBD::Pg: a clear error at construction' => sub {
  local @INC = ( sub { die "Can't locate $_[1] (hidden)\n" if $_[1] eq 'DBD/Pg.pm'; return }, @INC );
  my $had = exists $INC{'DBD/Pg.pm'};
  skip_all 'DBD::Pg already loaded' if $had;
  like( dies { $class->new(@args) },
    qr/\Atoken_auth backend postgresql needs DBD::Pg/, 'croaks naming DBD::Pg' );
  delete $INC{'DBD/Pg.pm'};
};

my $have_pg = eval { require DBD::Pg; 1 };

subtest 'constructor checks' => sub {
  skip_all 'DBD::Pg not installed' unless $have_pg;
  like( dies { $class->new( @args, columns => { hash => 'h', token => 'x' } ) },
    qr/unknown column key\(s\) token/, 'an unknown column key croaks' );
  my $s = $class->new(@args);
  ok( !$s->available, 'not available before the first connect' );
  like( $s->_dsn, qr/connect_timeout=3;keepalives_idle=30;keepalives_interval=10;keepalives_count=3\z/,
    'connect timeout and keepalives added to the DSN' );
  my $own = $class->new( @args, dsn => 'dbi:Pg:dbname=x;connect_timeout=5;keepalives_idle=5' );
  unlike( $own->_dsn, qr/connect_timeout=3|keepalives_idle=30/, 'the DSN\'s own settings win' );
};

subtest 'probe target from the DSN' => sub {
  skip_all 'DBD::Pg not installed' unless $have_pg;
  local $ENV{PGHOST};
  local $ENV{PGPORT};
  my $t = sub { [ $class->new( @args, dsn => $_[0] )->_tcp_target ] };
  is( $t->('dbi:Pg:host=db.example;port=6543;dbname=x'), [ 'db.example', 6543 ], 'host and port' );
  is( $t->('dbi:Pg:dbname=x;host=db.example'), [ 'db.example', 5432 ], 'default port' );
  is( $t->('dbi:Pg:host=db.example;hostaddr=10.0.0.5;dbname=x'), [ '10.0.0.5', 5432 ], 'hostaddr wins' );
  is( $t->('dbi:Pg:host=/var/run/postgresql;dbname=x'), [], 'Unix socket: no probe' );
  is( $t->('dbi:Pg:dbname=x'), [], 'no host: no probe' );
  is( $t->('dbi:Pg:service=platform'), [], 'service: no probe' );
  is( $t->('dbi:Pg:host=a,b;dbname=x'), [], 'host list: no probe' );
  local $ENV{PGHOST} = 'env-host';
  local $ENV{PGPORT} = '6000';
  is( $t->('dbi:Pg:dbname=x'), [ 'env-host', 6000 ], 'PGHOST / PGPORT' );
};

my $loop = IO::Async::Loop->new;

# Runs the loop until $cond is true or $secs pass.
sub run_until {
  my ( $cond, $secs ) = @_;
  my $until = time + $secs;
  $loop->loop_once(0.1) until $cond->() || time > $until;
  return $cond->();
}

# k82 follow-up: a server that is down or unreachable must not stop the
# loop -- the DBI connect only runs after a non-blocking TCP probe.
for my $case (
  [ 'closed port',         'dbi:Pg:host=127.0.0.1;port=1;dbname=x' ],
  [ 'unroutable address',  'dbi:Pg:host=192.0.2.1;port=5432;dbname=x' ],
) {
  my ( $name, $target ) = @$case;
  subtest "unreachable server ($name): loop keeps running, lookups fail fast" => sub {
    skip_all 'DBD::Pg not installed' unless $have_pg;
    my @logs;
    Log::Any::Adapter->set( 'Capture', to => \@logs, log_level => 'trace' );
    my $dbi_connects = 0;
    my $orig = \&DBI::connect;
    no warnings 'redefine';
    local *DBI::connect = sub { $dbi_connects++; goto &$orig };

    my ( $last, $max_gap ) = ( time, 0 );
    my $ticker = IO::Async::Timer::Periodic->new(
      interval => 0.05,
      on_tick  => sub { my $now = time; $max_gap = $now - $last if $now - $last > $max_gap; $last = $now },
    );
    $loop->add($ticker);
    $ticker->start;

    my @ev;
    my $s = $class->new( dsn => $target, relation => 'r', listen => 'c', loop => $loop, connect_timeout => 2 );
    $s->on_invalidate( sub { push @ev, @_ } );
    my $t0 = time;
    my $f = $s->lookup_f( '0' x 64 );
    ok( !$f->is_ready, 'the first lookup waits for the attempt' );
    ok( run_until( sub { $f->is_ready }, 6 ), 'settled' );
    my $took = time - $t0;
    $loop->loop_once(0.1);
    $ticker->stop;
    $loop->remove($ticker);

    ok( $f->is_failed, 'failed' );
    is( [ $f->failure ], [ "token store unavailable\n", 'token_store' ], 'with the fixed text' );
    cmp_ok( $took, '<', 3, 'within connect_timeout' );
    cmp_ok( $max_gap, '<', 0.5, 'the loop was never blocked for 0.5 s' );
    is( $dbi_connects, 0, 'no DBI connect without a probe that got through' );
    ok( !$s->available, 'not available' );

    my $f2 = $s->lookup_f( '0' x 64 );
    ok( $f2->is_failed, 'during the backoff a lookup fails at once' );
    is( ( $f2->failure )[0], "token store unavailable\n", '... with the fixed text' );

    my $text = join "\n", map { join ' ', grep { defined } @$_ } @logs;
    like( $text, qr/not reachable/, 'logged as not reachable' );
    Log::Any::Adapter->set('Null');
  };
}

unless ( $have_pg && $ENV{KNARR_TEST_PG_DSN} && $ENV{KNARR_TEST_PG_USER} && $ENV{KNARR_TEST_PG_PASS} ) {
  note 'live part skipped: set KNARR_TEST_PG_DSN, KNARR_TEST_PG_USER, KNARR_TEST_PG_PASS';
  done_testing;
  exit 0;
}

my @logs;
Log::Any::Adapter->set( 'Capture', to => \@logs, log_level => 'trace' );

my $dsn  = $ENV{KNARR_TEST_PG_DSN};
my $user = $ENV{KNARR_TEST_PG_USER};
my $pass = $ENV{KNARR_TEST_PG_PASS};

sub admin_dbh {
  DBI->connect( $dsn, $user, $pass, { RaiseError => 1, PrintError => 0, PrintWarn => 0, AutoCommit => 1 } );
}

my $schema = 'knarr_k82_'.$$.'_'.int(time);
my $owner  = $$;
$SIG{$_} = sub { exit 1 } for qw( INT TERM HUP );   # so END still drops the schema
END {
  if ( $schema && $owner == $$ ) {
    my $dbh = eval { admin_dbh() };
    eval { $dbh->do( 'DROP SCHEMA IF EXISTS '.$dbh->quote_identifier($schema).' CASCADE' ) } if $dbh;
    diag "could not drop schema $schema: ".( $@ || 'no connection' ) if !$dbh || $@;
  }
}

# Odd names on purpose: mixed case, spaces, a dot in the view name, a
# quote in the channel. All of it must go through quote_identifier.
my $admin   = admin_dbh();
my $q_s     = $admin->quote_identifier($schema);
my $table   = $q_s.'.'.$admin->quote_identifier('Token Rows');
my $view    = 'Tok-View.Odd';
my $q_view  = $admin->quote_identifier( undef, $schema, $view );
my $q_slow  = $admin->quote_identifier( undef, $schema, 'Slow View' );
my $channel = qq{Knarr "K82" $$};
my %columns = ( hash => 'Token Hash', model => 'Model', provider => 'Provider', expires => 'Expires At' );
my %q_col   = map { $_ => $admin->quote_identifier( $columns{$_} ) } keys %columns;

$admin->do("CREATE SCHEMA $q_s");
$admin->do( "CREATE TABLE $table ($q_col{hash} text PRIMARY KEY, $q_col{model} text NOT NULL,"
  ." $q_col{provider} text, $q_col{expires} timestamptz NOT NULL, revoked boolean NOT NULL DEFAULT false)" );
$admin->do( "CREATE VIEW $q_view AS SELECT $q_col{hash}, $q_col{model}, $q_col{provider}, $q_col{expires}"
  ." FROM $table WHERE NOT revoked" );
$admin->do( "CREATE VIEW $q_slow AS SELECT v.* FROM $q_view v, (SELECT pg_sleep(3)) s" );
my $q_fn = $q_s.'.'.$admin->quote_identifier('notify_tokens');
$admin->do( "CREATE FUNCTION $q_fn() RETURNS trigger LANGUAGE plpgsql AS \$\$ BEGIN"
  ." PERFORM pg_notify(".$admin->quote($channel).", ''); RETURN NULL; END \$\$" );
$admin->do("CREATE TRIGGER notify_tokens AFTER INSERT OR UPDATE OR DELETE ON $table FOR EACH STATEMENT EXECUTE FUNCTION $q_fn()");

sub hash_of { Langertha::Knarr::TokenStore::Pg->hash_token( $_[0] ) }

sub add_token {
  my ( $token, $model, $provider, $expires_in ) = @_;
  $admin->do( "INSERT INTO $table ($q_col{hash}, $q_col{model}, $q_col{provider}, $q_col{expires})"
    ." VALUES (?, ?, ?, now() + make_interval(secs => ?))", undef, hash_of($token), $model, $provider, $expires_in );
}

sub store {
  return $class->new(
    dsn          => $dsn,
    user         => $user,
    password_env => 'KNARR_TEST_PG_PASS',
    relation     => "$schema.$view",
    listen       => $channel,
    columns      => {%columns},
    loop         => $loop,
    @_,
  );
}

add_token( 'tok-valid',   'gpt-4o', 'openai',    600 );
add_token( 'tok-expired', 'gpt-4o', 'openai',    -60 );
add_token( 'tok-other',   'claude', 'anthropic', 600 );

my @events;
my $store = store();
$store->on_invalidate( sub { push @events, $_[0] } );

subtest 'lookups through the loop' => sub {
  ok( !$store->available, 'not connected before the first lookup' );
  my $row = $store->lookup_f( hash_of('tok-valid') )->get;
  is( $row, { model => 'gpt-4o', provider => 'openai', expires => D() }, 'valid token -> row' );
  cmp_ok( $row->{expires}, '>', time + 500, 'expires as an epoch number' );
  cmp_ok( $row->{expires}, '<', time + 700, '... the right one' );
  ok( $store->available, 'available once connected' );

  is( $store->lookup_f( hash_of('tok-expired') )->get, undef, 'expired -> undef' );
  is( $store->lookup_f( hash_of('tok-unknown') )->get, undef, 'unknown -> undef' );
  is( $store->lookup_f( uc hash_of('tok-other') )->get->{model}, 'claude', 'an uppercase hash is lowercased' );

  my $f1 = $store->lookup_f( hash_of('tok-valid') );
  my $f2 = $store->lookup_f( hash_of('tok-other') );
  my $f3 = $store->lookup_f( hash_of('tok-valid') );
  is( scalar @{ $store->_queue }, 1, 'one query in flight, the same hash joins it, the other waits' );
  ok( !$f1->is_ready, 'not answered synchronously' );
  Future->needs_all( $f1, $f2, $f3 )->get;
  is( [ map { $_->get->{model} } $f1, $f2, $f3 ], [qw( gpt-4o claude gpt-4o )], 'all three answered' );
  is( \@events, [], 'nothing invalidated so far' );
};

subtest 'revoke + NOTIFY invalidates through the loop' => sub {
  @events = ();
  $admin->do( "UPDATE $table SET revoked = true WHERE $q_col{hash} = ?", undef, hash_of('tok-other') );
  ok( run_until( sub { @events }, 10 ), 'the notification arrived while the loop ran' );
  is( $events[0], 'notify', 'invalidate(notify)' );
  is( $store->lookup_f( hash_of('tok-other') )->get, undef, 'revoked token -> undef' );

  @events = ();
  $admin->do( 'NOTIFY '.$admin->quote_identifier($channel) );
  ok( run_until( sub { @events }, 10 ), 'an explicit NOTIFY on the channel invalidates too' );
  @events = ();
  $admin->do('NOTIFY some_other_channel');
  run_until( sub { @events }, 1 );
  is( \@events, [], 'other channels are not listened to' );
};

subtest 'a killed backend: unavailable, invalidated, reconnects, LISTENs again' => sub {
  @events = ();
  my $pid = $store->_dbh->{pg_pid};
  $admin->do( 'SELECT pg_terminate_backend(?)', undef, $pid );
  ok( run_until( sub { grep { $_ eq 'disconnect' } @events }, 10 ), 'invalidate(disconnect) from the socket watch' );
  ok( !$store->available, 'not available' );
  my $f = $store->lookup_f( hash_of('tok-valid') );
  ok( $f->is_failed, 'a lookup fails at once while reconnecting' );
  is( [ $f->failure ], [ "token store unavailable\n", 'token_store' ], 'fixed text, no DB detail' );

  ok( run_until( sub { $store->available }, 15 ), 'reconnected after the backoff' );
  isnt( $store->_dbh->{pg_pid}, $pid, 'a new backend' );
  is( $store->lookup_f( hash_of('tok-valid') )->get->{model}, 'gpt-4o', 'lookups work again' );

  @events = ();
  $admin->do( 'NOTIFY '.$admin->quote_identifier($channel) );
  ok( run_until( sub { @events }, 10 ), 'LISTEN is back after the reconnect' );
};

subtest 'a lookup in flight when the backend dies fails' => sub {
  my @ev;
  my $slow = store( relation => "$schema.Slow View" );
  $slow->on_invalidate( sub { push @ev, $_[0] } );
  $slow->start;
  ok( !$slow->available, 'start returns before the attempt is done' );
  ok( run_until( sub { $slow->available }, 10 ), 'start connects' );
  my $f = $slow->lookup_f( hash_of('tok-valid') );
  $loop->loop_once(0.2);
  $admin->do( 'SELECT pg_terminate_backend(?)', undef, $slow->_dbh->{pg_pid} );
  ok( run_until( sub { $f->is_ready }, 10 ), 'the pending lookup was settled' );
  ok( $f->is_failed, '... as failed' );
  is( ( $f->failure )[0], "token store unavailable\n", '... with the fixed text' );
  is( \@ev, ['disconnect'], 'and invalidated' );
};

subtest 'a lookup slower than query_timeout counts as a lost connection' => sub {
  my @ev;
  my $slow = store( relation => "$schema.Slow View", query_timeout => 1 );
  $slow->on_invalidate( sub { push @ev, $_[0] } );
  my $f = $slow->lookup_f( hash_of('tok-valid') );
  ok( run_until( sub { $f->is_ready }, 10 ), 'settled' );
  ok( $f->is_failed, 'failed' );
  is( \@ev, ['disconnect'], 'invalidated' );
  ok( !$slow->available, 'not available until it reconnected' );
  ok( run_until( sub { $slow->available }, 15 ), 'reconnects' );
};

subtest 'blocking lookup (PSGI): notifications delivered before the query' => sub {
  my @order;
  my $sync = store();
  $sync->on_invalidate( sub { push @order, "invalidate:$_[0]" } );
  is( $sync->lookup( hash_of('tok-valid') )->{model}, 'gpt-4o', 'blocking hit' );
  is( $sync->lookup( hash_of('tok-expired') ), undef, 'blocking expired' );
  ok( !$sync->_watch, 'no socket watch without the loop' );

  $admin->do( 'NOTIFY '.$admin->quote_identifier($channel) );
  sleep 0.5;
  push @order, 'before';
  my $row = $sync->lookup( hash_of('tok-valid') );
  push @order, 'after';
  is( \@order, [ 'before', 'invalidate:notify', 'after' ], 'the pending NOTIFY fired before lookup returned' );

  @order = ();
  $admin->do( 'NOTIFY '.$admin->quote_identifier($channel) );
  sleep 0.5;
  $sync->poll;
  is( \@order, ['invalidate:notify'], 'poll alone delivers it' );

  @order = ();
  $admin->do( 'SELECT pg_terminate_backend(?)', undef, $sync->_dbh->{pg_pid} );
  sleep 0.5;
  $sync->poll;
  is( \@order, ['invalidate:disconnect'], 'poll alone notices the lost connection and invalidates' );
  ok( !$sync->available, 'not available' );
  like( dies { $sync->lookup( hash_of('tok-valid') ) }, qr/\Atoken store unavailable/, 'lost: croaks' );
  is( \@order, ['invalidate:disconnect'], 'invalidated once' );
  like( dies { $sync->lookup( hash_of('tok-valid') ) }, qr/\Atoken store unavailable/,
    'within the backoff: refused without a connect' );
  sleep 1.2;
  is( $sync->lookup( hash_of('tok-valid') )->{model}, 'gpt-4o', 'after the backoff the next lookup reconnects' );
};

subtest 'fork: the child replaces the inherited connection, the parent keeps its own' => sub {
  my $parent_pid = $store->_dbh->{pg_pid};
  my $child = fork;
  die "fork: $!" unless defined $child;
  if ( !$child ) {
    my $ok = eval {
      $loop->post_fork if $loop->can('post_fork');
      my $got = 0;
      $store->on_invalidate( sub { $got++ } );
      my $row = $store->lookup_f( hash_of('tok-valid') )->get;
      $row && $row->{model} eq 'gpt-4o' && $got == 1 && $store->_dbh->{pg_pid} != $parent_pid;
    };
    require POSIX;
    POSIX::_exit( $ok ? 0 : 1 );
  }
  waitpid $child, 0;
  is( $? >> 8, 0, 'child: invalidated, own connection, lookup works' );
  ok( $store->available, 'parent still connected' );
  is( $store->_dbh->{pg_pid}, $parent_pid, 'on the same backend' );
  is( $store->lookup_f( hash_of('tok-valid') )->get->{model}, 'gpt-4o', 'parent lookups unaffected' );
};

subtest 'secrets stay out of failures and logs' => sub {
  local $ENV{KNARR_TEST_PG_WRONG} = 'wr0ng-pa55-k82';
  my $bad = store( password_env => 'KNARR_TEST_PG_WRONG' );
  my $f = $bad->lookup_f( hash_of('tok-valid') );
  ok( run_until( sub { $f->is_ready }, 10 ), 'the attempt ends' );
  ok( $f->is_failed, 'a failed connect fails the lookup' );
  is( [ $f->failure ], [ "token store unavailable\n", 'token_store' ], 'fixed text only' );
  like( dies { store( password_env => 'KNARR_TEST_PG_WRONG' )->lookup( hash_of('tok-valid') ) },
    qr/\Atoken store unavailable\n?(?: at \S+ line \d+\.\n)?\z/,
    'blocking: the fixed text and the caller line, no DSN or user' );

  my $text = join "\n", map { ref $_ eq 'ARRAY' ? join( ' ', grep { defined } @$_ ) : "$_" } @logs;
  like( $text, qr/token store: connect failed/, 'the failed connect was logged' );
  unlike( $text, qr/\Q$pass\E/, 'the database password is in no log line' );
  unlike( $text, qr/wr0ng-pa55-k82/, 'nor the wrong one' );
  unlike( $text, qr/[0-9a-f]{64}/, 'no token hash in the log' );
  unlike( $text, qr/tok-valid/, 'no token in the log' );
};

$store->_teardown;
done_testing;
