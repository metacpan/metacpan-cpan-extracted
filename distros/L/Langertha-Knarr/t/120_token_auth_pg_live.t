use strict;
use warnings;
use Test2::V0;
use POSIX ();
use Time::HiRes qw( sleep time );
use FindBin qw( $Bin );
use File::Temp qw( tempdir );
use Path::Tiny;
use Digest::SHA qw( sha256_hex );
use JSON::MaybeXS;
use YAML::PP;
use HTTP::Tiny;

# k82 end to end: `knarr start` with a token_auth config against a real
# PostgreSQL. A schema of its own gets a table, a view over it shaped like
# the platform's (token_hash, model, provider, expires_at timestamptz) and a
# trigger that NOTIFYs the listen channel on every change; it is dropped in
# END, also on INT/TERM/HUP. The routes go to a local mock: `local` as an
# OpenAI-compatible upstream (Skeid), `openai` as the provider with a url.
# Knarr runs as the real CLI on a free local port, once with one worker and
# once with two (prefork). Nothing leaves this host but the database
# connection; no provider key is real.
#
# Needs KNARR_TEST_PG_DSN, KNARR_TEST_PG_USER and KNARR_TEST_PG_PASS.

plan skip_all => 'needs a real fork()' if $^O eq 'MSWin32';
plan skip_all => 'DBD::Pg not installed' unless eval { require DBI; require DBD::Pg; 1 };
plan skip_all => 'set KNARR_TEST_PG_DSN, KNARR_TEST_PG_USER, KNARR_TEST_PG_PASS'
  unless $ENV{KNARR_TEST_PG_DSN} && $ENV{KNARR_TEST_PG_USER} && $ENV{KNARR_TEST_PG_PASS};

my $json = JSON::MaybeXS->new( utf8 => 1, canonical => 1 );
my $dsn  = $ENV{KNARR_TEST_PG_DSN};
my $user = $ENV{KNARR_TEST_PG_USER};
my $pass = $ENV{KNARR_TEST_PG_PASS};
my $lib  = path($Bin)->parent->child('lib')->absolute->stringify;
my $knarr_bin = path($Bin)->parent->child( 'bin', 'knarr' )->absolute->stringify;
my $dir  = tempdir( CLEANUP => 1 );

sub admin_dbh {
  DBI->connect( $dsn, $user, $pass, { RaiseError => 1, PrintError => 0, PrintWarn => 0, AutoCommit => 1 } );
}

sub free_port {
  require IO::Socket::INET;
  my $s = IO::Socket::INET->new( Listen => 1, LocalAddr => '127.0.0.1', LocalPort => 0 )
    or die "free_port: $!";
  my $p = $s->sockport;
  $s->close;
  return $p;
}

my $schema  = 'knarr_k82_e2e_'.$$.'_'.int(time);
my $channel = $schema.'_tokens';
my $owner   = $$;
my %children;   # pid => 1: servers and the mock, stopped before the schema goes
$SIG{$_} = sub { exit 1 } for qw( INT TERM HUP );   # so END still runs
END {
  local $?;   # the children's exit statuses are not this test's
  if ( defined $owner && $owner == $$ ) {
    for my $pid ( keys %children ) {
      kill TERM => $pid;
      waitpid( $pid, 0 );
    }
    if ($schema) {
      my $dbh = eval { admin_dbh() };
      eval { $dbh->do( 'DROP SCHEMA IF EXISTS '.$dbh->quote_identifier($schema).' CASCADE' ) } if $dbh;
      diag "could not drop schema $schema: ".( $@ || 'no connection' ) if !$dbh || $@;
    }
  }
}

# --- The mock upstream, in its own process before anything else runs: it
# plays Skeid under /skeid/v1 and OpenAI under /openai/v1 and writes every
# request it gets to a file.
my $mock_log  = "$dir/mock.jsonl";
my $mock_port = free_port();
{
  my $pid = fork // die "fork: $!";
  unless ($pid) {
    require IO::Async::Loop;
    require Net::Async::HTTP::Server;
    require HTTP::Response;
    my $loop = IO::Async::Loop->new;
    my $server = Net::Async::HTTP::Server->new( on_request => sub {
      my ( $srv, $req ) = @_;
      my $data = eval { $json->decode( $req->body ) } || {};
      my ($who) = $req->path =~ m{\A/(\w+)/};
      path($mock_log)->append( $json->encode({
        path    => $req->path,
        auth    => scalar $req->header('Authorization'),
        api_key => scalar $req->header('x-api-key'),
        model   => $data->{model},
        stream  => $data->{stream} ? 1 : 0,
        raw     => join( "\n", map { "$_->[0]: $_->[1]" } $req->headers ) . "\n" . ( $req->body // '' ),
      }) . "\n" );
      my $resp = HTTP::Response->new(200);
      $resp->protocol('HTTP/1.1');
      if ( $data->{stream} ) {
        $resp->content_type('text/event-stream');
        $resp->content( join '',
          map { 'data: ' . $json->encode($_) . "\n\n" }
            { id => 'c1', object => 'chat.completion.chunk', model => $data->{model},
              choices => [ { index => 0, delta => { role => 'assistant', content => 'from ' } } ] },
            { id => 'c1', object => 'chat.completion.chunk', model => $data->{model},
              choices => [ { index => 0, delta => { content => $who // '?' }, finish_reason => 'stop' } ] } );
        $resp->add_content("data: [DONE]\n\n");
      }
      else {
        $resp->content_type('application/json');
        $resp->content( $json->encode({ id => 'c1', object => 'chat.completion', model => $data->{model},
          choices => [ { index => 0, finish_reason => 'stop',
            message => { role => 'assistant', content => 'from ' . ( $who // '?' ) } } ],
          usage => { prompt_tokens => 3, completion_tokens => 2, total_tokens => 5 } }) );
      }
      $resp->content_length( length $resp->content );
      $req->respond($resp);
    } );
    $loop->add($server);
    $server->listen( addr => { family => 'inet', socktype => 'stream', ip => '127.0.0.1', port => $mock_port } )->get;
    $loop->run;
    POSIX::_exit(0);
  }
  $children{$pid} = 1;
}

sub mock_requests {
  return () unless -e $mock_log;
  return map { $json->decode($_) } path($mock_log)->lines( { chomp => 1 } );
}

# --- The schema: table, view, NOTIFY trigger.
my $admin   = admin_dbh();
my $q_s     = $admin->quote_identifier($schema);
my $table   = $q_s.'.'.$admin->quote_identifier('issued_tokens');
my $view    = 'tester_token_auth';
my $q_view  = $q_s.'.'.$admin->quote_identifier($view);
$admin->do("CREATE SCHEMA $q_s");
$admin->do( "CREATE TABLE $table (token_hash text PRIMARY KEY, model text NOT NULL,"
  ." provider text NOT NULL, expires_at timestamptz NOT NULL, issued_by text)" );
$admin->do("CREATE VIEW $q_view AS SELECT token_hash, model, provider, expires_at FROM $table");
my $q_fn = $q_s.'.'.$admin->quote_identifier('notify_tokens');
$admin->do( "CREATE FUNCTION $q_fn() RETURNS trigger LANGUAGE plpgsql AS \$\$ BEGIN"
  ." PERFORM pg_notify(".$admin->quote($channel).", ''); RETURN NULL; END \$\$" );
$admin->do( "CREATE TRIGGER notify_tokens AFTER INSERT OR UPDATE OR DELETE ON $table"
  ." FOR EACH STATEMENT EXECUTE FUNCTION $q_fn()" );

my %KEY = (
  K82_E2E_SKEID_KEY  => 'sk-skeid-e2e-route-key-111',
  K82_E2E_OPENAI_KEY => 'sk-openai-e2e-route-key-222',
);
my @tokens;   # every token used here, for the leak checks

sub add_token {
  my ( $token, $model, $provider, $expires_in ) = @_;
  push @tokens, $token;
  $admin->do( "INSERT INTO $table (token_hash, model, provider, expires_at)"
    ." VALUES (?, ?, ?, now() + make_interval(secs => ?))",
    undef, lc sha256_hex($token), $model, $provider, $expires_in );
}

sub delete_token {
  my ($token) = @_;
  $admin->do( "DELETE FROM $table WHERE token_hash = ?", undef, lc sha256_hex($token) );
}

# --- Knarr's backends, told apart by the application_name in the DSN.
sub backends {
  my ($app) = @_;
  return @{ $admin->selectall_arrayref(
    'SELECT pid, query, extract(epoch from query_start) AS started FROM pg_stat_activity'
    .' WHERE application_name = ? ORDER BY pid', { Slice => {} }, $app ) };
}

sub wait_until {
  my ( $timeout, $cond ) = @_;
  my $end = time + $timeout;
  while ( time < $end ) {
    my $r = $cond->();
    return $r if $r;
    sleep 0.1;
  }
  return;
}

# --- Requests.
my $ua = HTTP::Tiny->new( keep_alive => 0, timeout => 15 );

sub chat {
  my ( $port, $token, $model, %opt ) = @_;
  my $res = $ua->post( "http://127.0.0.1:$port/v1/chat/completions", {
    headers => { 'Content-Type' => 'application/json',
      ( defined $token ? ( Authorization => "Bearer $token" ) : () ) },
    content => $json->encode({ model => $model, messages => [ { role => 'user', content => 'hi' } ],
      ( $opt{stream} ? ( stream => JSON::MaybeXS->true ) : () ) }),
  } );
  return $res;
}

sub content_of {
  my ($res) = @_;
  my $d = eval { $json->decode( $res->{content} ) } or return;
  return $d->{choices}[0]{message}{content};
}

# $n requests at once, each from its own short-lived client process; the
# statuses.
sub chat_parallel {
  my ( $port, $n, $token, $model ) = @_;
  my @kids;
  for ( 1 .. $n ) {
    pipe( my $r, my $w ) or die "pipe: $!";
    my $pid = fork // die "fork: $!";
    unless ($pid) {
      close $r;
      my $res = chat( $port, $token, $model );
      print {$w} $res->{status};
      close $w;
      POSIX::_exit(0);
    }
    close $w;
    push @kids, [ $pid, $r ];
  }
  my @status;
  for my $k (@kids) {
    my $fh = $k->[1];
    my $got = do { local $/; <$fh> };
    waitpid( $k->[0], 0 );
    push @status, $got;
  }
  return @status;
}

# --- Knarr, started the way an operator starts it: the CLI with a config file.
sub start_knarr {
  my (%arg) = @_;
  my $port = free_port();
  my $config = "$dir/knarr-$arg{name}.yaml";
  YAML::PP->new( boolean => 'JSON::PP' )->dump_file( $config, {
    token_auth => {
      backend      => 'postgresql',
      dsn          => "$dsn;application_name=$arg{app}",
      user         => $user,
      password_env => 'KNARR_TEST_PG_PASS',
      relation     => "$schema.$view",
      listen       => $channel,
      hash         => 'sha256',
      columns      => { hash => 'token_hash', model => 'model', provider => 'provider', expires => 'expires_at' },
      match_model  => JSON::MaybeXS->true,
    },
    routes => {
      local  => { upstream => "http://127.0.0.1:$mock_port/skeid/v1", key_env => 'K82_E2E_SKEID_KEY' },
      openai => { provider => 'openai', url => "http://127.0.0.1:$mock_port/openai/v1",
                  key_env => 'K82_E2E_OPENAI_KEY' },
    },
  } );
  my $log = "$dir/knarr-$arg{name}.log";
  my $request_log = "$dir/requests-$arg{name}.jsonl";
  my $pid = fork // die "fork: $!";
  unless ($pid) {
    # Nothing of the host may leak in: no Langfuse, no proxy key, no
    # provider keys.
    delete @ENV{ grep { /\A(?:LANGFUSE_|LANGERTHA_|TEST_LANGERTHA_)/ || /_API_KEY\z/
      || ( /\AKNARR_/ && $_ ne 'KNARR_TEST_PG_PASS' ) } keys %ENV };
    $ENV{$_} = $KEY{$_} for keys %KEY;
    open STDOUT, '>>', $log or POSIX::_exit(2);
    open STDERR, '>>', $log or POSIX::_exit(2);
    { exec $^X, "-I$lib", $knarr_bin, 'start', '-c', $config, '-v',
      '-H', '127.0.0.1', '-p', $port, '-w', $arg{workers}, '--log-file', $request_log };
    POSIX::_exit(3);
  }
  $children{$pid} = 1;
  # Up once it answers at all: without a token that is a 401, which needs
  # no database.
  my $up = wait_until( 30, sub {
    my $res = $ua->get("http://127.0.0.1:$port/v1/models");
    $res->{status} == 401 ? 1 : 0;
  } );
  return { pid => $pid, port => $port, up => $up, log => $log, request_log => $request_log, app => $arg{app} };
}

sub stop_knarr {
  my ($k) = @_;
  kill TERM => $k->{pid};
  my $gone = wait_until( 20, sub { waitpid( $k->{pid}, POSIX::WNOHANG() ) == $k->{pid} } );
  unless ($gone) {
    kill KILL => $k->{pid};
    waitpid( $k->{pid}, 0 );
  }
  delete $children{ $k->{pid} };
  return;
}

my $TOK_LOCAL   = 'tok-e2e-local-'.$$.'-aaaaaaaaaa';
my $TOK_OPENAI  = 'tok-e2e-openai-'.$$.'-bbbbbbbbbb';
my $TOK_EXPIRED = 'tok-e2e-expired-'.$$.'-cccccccccc';
my $TOK_UNKNOWN = 'tok-e2e-unknown-'.$$.'-dddddddddd';
push @tokens, $TOK_UNKNOWN;
add_token( $TOK_LOCAL,   'skeid-e2e-model', 'local',  900 );
add_token( $TOK_OPENAI,  'gpt-e2e',         'openai', 900 );
add_token( $TOK_EXPIRED, 'skeid-e2e-model', 'local',  -60 );

my @runs;

subtest 'one worker' => sub {
  my $k = start_knarr( name => 'single', app => $schema.'_w1', workers => 1 );
  push @runs, $k;
  ok( $k->{up}, 'knarr start serves' ) or return;
  my $port = $k->{port};

  ok( wait_until( 10, sub { backends( $k->{app} ) == 1 } ),
    'the store connected at start, before any token request (one backend)' );

  # valid token, local route
  my $res = chat( $port, $TOK_LOCAL, 'skeid-e2e-model' );
  is( $res->{status}, 200, 'valid token: 200' );
  is( content_of($res), 'from skeid', '... answered through the local route' );
  my ($got) = grep { $_->{path} =~ m{\A/skeid/} } mock_requests();
  ok( $got, 'the local mock got the request' );
  is( $got->{path}, '/skeid/v1/chat/completions', '... on the upstream\'s chat path' );
  is( $got->{auth}, "Bearer $KEY{K82_E2E_SKEID_KEY}", '... with the key from key_env' );
  is( $got->{model}, 'skeid-e2e-model', '... for the token\'s model' );

  # openai route
  $res = chat( $port, $TOK_OPENAI, 'gpt-e2e' );
  is( $res->{status}, 200, 'openai token: 200' );
  is( content_of($res), 'from openai', '... answered through the provider route' );
  ($got) = grep { $_->{path} =~ m{\A/openai/} } mock_requests();
  is( $got->{auth}, "Bearer $KEY{K82_E2E_OPENAI_KEY}", '... with that route\'s key' );

  # refusals
  is( chat( $port, $TOK_LOCAL, 'gpt-e2e' )->{status}, 403, 'another model: 403' );
  is( chat( $port, $TOK_EXPIRED, 'skeid-e2e-model' )->{status}, 401, 'expired token: 401' );
  is( chat( $port, $TOK_UNKNOWN, 'skeid-e2e-model' )->{status}, 401, 'unknown token: 401' );
  is( chat( $port, undef, 'skeid-e2e-model' )->{status}, 401, 'no token: 401' );

  # model list
  $res = $ua->get( "http://127.0.0.1:$port/v1/models", { headers => { Authorization => "Bearer $TOK_LOCAL" } } );
  is( $res->{status}, 200, '/v1/models: 200' );
  is( [ map { $_->{id} } @{ ( eval { $json->decode( $res->{content} ) } || {} )->{data} || [] } ],
    ['skeid-e2e-model'], '... the token\'s model only' );

  # streaming
  $res = chat( $port, $TOK_LOCAL, 'skeid-e2e-model', stream => 1 );
  is( $res->{status}, 200, 'streaming: 200' );
  like( $res->{content}, qr/"content":"from "/, '... the chunks' );
  like( $res->{content}, qr/data: \[DONE\]\s*\z/, '... ending with data: [DONE]' );
  ok( ( grep { $_->{stream} } mock_requests() ), '... streamed from the upstream' );

  # cached hits, then revoke: the trigger's NOTIFY drops the cache
  my ($b) = backends( $k->{app} );
  is( chat( $port, $TOK_LOCAL, 'skeid-e2e-model' )->{status}, 200, 'valid token again: 200' );
  my ($b2) = backends( $k->{app} );
  is( $b2->{started}, $b->{started}, '... from the cache: no query reached the database' );
  delete_token($TOK_LOCAL);
  my @seen;
  my $denied = wait_until( 5, sub {
    my $s = chat( $port, $TOK_LOCAL, 'skeid-e2e-model' )->{status};
    push @seen, $s;
    $s == 401;
  } );
  ok( $denied, 'after DELETE + NOTIFY: 401, without a restart' );
  is( [ grep { $_ != 200 && $_ != 401 } @seen ], [], '... nothing but 200 before it' );

  # the connection killed: fail-closed, then back
  my ($victim) = backends( $k->{app} );
  $admin->do( 'SELECT pg_terminate_backend(?)', undef, $victim->{pid} );
  @seen = ();
  my $closed = wait_until( 5, sub {
    my $s = chat( $port, $TOK_OPENAI, 'gpt-e2e' )->{status};
    push @seen, $s;
    $s == 503;
  } );
  ok( $closed, 'backend terminated: 503 (fail-closed)' );
  is( [ grep { $_ != 200 && $_ != 503 } @seen ], [], '... nothing else on the way' );
  @seen = ();
  my $back = wait_until( 20, sub {
    my $s = chat( $port, $TOK_OPENAI, 'gpt-e2e' )->{status};
    push @seen, $s;
    $s == 200;
  } );
  ok( $back, 'after the reconnect: 200 again' );
  is( [ grep { $_ != 200 && $_ != 503 } @seen ], [], '... only 503 until then' );
  my @now = backends( $k->{app} );
  is( scalar @now, 1, '... on one connection' );
  isnt( $now[0]{pid}, $victim->{pid}, '... a new backend' );

  # the reconnected store LISTENs again
  my $TOK_LATE = 'tok-e2e-late-'.$$.'-eeeeeeeeee';
  add_token( $TOK_LATE, 'gpt-e2e', 'openai', 900 );
  is( chat( $port, $TOK_LATE, 'gpt-e2e' )->{status}, 200, 'a token issued after the reconnect: 200' );
  delete_token($TOK_LATE);
  ok( wait_until( 5, sub { chat( $port, $TOK_LATE, 'gpt-e2e' )->{status} == 401 } ),
    '... revoked: 401 (LISTEN is back)' );

  stop_knarr($k);
  ok( wait_until( 5, sub { !backends( $k->{app} ) } ), 'stopped: its connection is gone' );
};

subtest 'two workers (prefork)' => sub {
  my $TOK = 'tok-e2e-workers-'.$$.'-ffffffffff';
  add_token( $TOK, 'skeid-e2e-model', 'local', 900 );
  my $k = start_knarr( name => 'workers', app => $schema.'_w2', workers => 2 );
  push @runs, $k;
  ok( $k->{up}, 'knarr start -w 2 serves' ) or return;
  my $port = $k->{port};

  ok( wait_until( 10, sub { backends( $k->{app} ) == 2 } ),
    'two backends before any token request: one per worker, none for the supervisor' );
  sleep 0.5;
  is( scalar backends( $k->{app} ), 2, '... and no third' );

  # Each worker has its own connection: once both connections ran the token
  # query, both workers checked the token.
  my $is_lookup = sub { $_[0]{query} =~ /\bSELECT\b.*\Q$view\E/si };
  my @status;
  my $both = wait_until( 40, sub {
    push @status, chat_parallel( $port, 6, $TOK, 'skeid-e2e-model' );
    ( grep { $is_lookup->($_) } backends( $k->{app} ) ) == 2;
  } );
  ok( $both, 'both workers looked the token up' )
    or diag $json->encode( [ backends( $k->{app} ) ] );
  ok( scalar @status, 'requests were sent' );
  is( [ grep { $_ != 200 } @status ], [], '... every one 200' );

  # Revoke: from then on every worker refuses -- each one queries again
  # (its cache dropped by the NOTIFY) and finds nothing.
  delete_token($TOK);
  my ($revoked_at) = $admin->selectrow_array('SELECT extract(epoch from clock_timestamp())');
  sleep 0.3;
  @status = ();
  my $denied = wait_until( 40, sub {
    push @status, chat_parallel( $port, 6, $TOK, 'skeid-e2e-model' );
    ( grep { $is_lookup->($_) && $_->{started} > $revoked_at } backends( $k->{app} ) ) == 2;
  } );
  ok( $denied, 'after DELETE + NOTIFY both workers asked the database again' )
    or diag $json->encode( [ backends( $k->{app} ) ] );
  is( [ grep { $_ != 401 } @status ], [], '... and every request got 401' );

  stop_knarr($k);
  ok( wait_until( 5, sub { !backends( $k->{app} ) } ), 'stopped: both connections are gone' );
};

# The route engine classes are loaded when the stack is built, before the
# fork: no worker's first request pays the class load (about 2 s before).
subtest 'no request waits for an engine class to load' => sub {
  for my $k (@runs) {
    my @ms = map { ( eval { $json->decode($_) } || {} )->{duration_ms} // () }
      ( -e $k->{request_log} ? path( $k->{request_log} )->lines( { chomp => 1 } ) : () );
    ok( scalar @ms, "$k->{app}: requests logged" );
    is( [ grep { $_ >= 1000 } @ms ], [], '... each one, the first of every worker included, under 1000 ms' )
      or diag "duration_ms: @ms";
  }
};

subtest 'no secret in a log line, the request log or an upstream request' => sub {
  my @secrets = ( $pass, values %KEY, map { ( $_, lc sha256_hex($_) ) } @tokens );
  my $re = join '|', map { quotemeta } @secrets;
  $re = qr/$re/i;
  my @token_secrets = map { ( $_, lc sha256_hex($_) ) } @tokens;
  my $token_re = join '|', map { quotemeta } @token_secrets;
  $token_re = qr/$token_re/i;
  for my $k (@runs) {
    my $log = -e $k->{log} ? path( $k->{log} )->slurp_raw : '';
    ok( length $log, "$k->{app}: the server log was captured" );
    like( $log, qr/token store: connected/, '... at trace level' );
    like( $log, qr/token check: /, '... with the token check\'s own lines' );
    unlike( $log, $re, '... no token, hash, password or route key in it' );
    my $rl = -e $k->{request_log} ? path( $k->{request_log} )->slurp_raw : '';
    ok( length $rl, '... the request log was written' );
    unlike( $rl, $re, '... none in the request log' );
  }
  my $mock = join "\n", map { $_->{raw} } mock_requests();
  ok( length $mock, 'the upstream requests were captured' );
  unlike( $mock, $token_re, 'no token or token hash reached an upstream' );
};

done_testing;
