use strict;
use warnings;
use Test2::V0;

# k75: a central service delivers Knarr's routing setup (models, default,
# passthrough, keys) as JSON over admin routes guarded by their own key, and
# Knarr holds it in memory only. Key-free: the engines are offline
# LangerthaX fakes that record the key they were built with.

# The host shell may carry Knarr's own variables; none of them may leak in.
BEGIN { delete @ENV{qw( KNARR_API_KEY KNARR_ADMIN_KEY KNARR_REMOTE_CONFIG LANGFUSE_PUBLIC_KEY LANGFUSE_SECRET_KEY LANGFUSE_URL LANGFUSE_BASE_URL KNARR_LANGFUSE_TRANSPORT )} }

BEGIN {
  package LangerthaX::Engine::TestKnarrAdmin;
  use Future;
  use Langertha::Response;
  our ( @built, @chats, $gate );
  sub new {
    my ($class, %args) = @_;
    push @built, { model => $args{model}, api_key => $args{api_key} };
    bless \%args, $class;
  }
  sub chat_model { $_[0]{model} }
  sub supports { $_[1] eq 'streaming' ? 1 : 0 }
  sub chat_f {
    my ($self) = @_;
    push @chats, { model => $self->{model}, api_key => $self->{api_key} };
    return Future->done( Langertha::Response->new( content => 'from '.$self->{model}, raw => {} ) );
  }
  # Streams one chunk, then waits for the test's gate before the rest.
  sub chat_stream_realtime_f {
    my ($self, %args) = @_;
    my $cb = $args{chunk_callback};
    $cb->('part1 ');
    return $gate->then( sub { $cb->('part2'); Future->done } );
  }
  $INC{'LangerthaX/Engine/TestKnarrAdmin.pm'} = __FILE__;
}

use IO::Async::Loop;
use Net::Async::HTTP;
use HTTP::Request;
use JSON::MaybeXS;
use Log::Any::Adapter;

use Langertha::Knarr;
use Langertha::Knarr::Admin;
use Langertha::Knarr::Config;
use Langertha::Knarr::Stack;
use Langertha::Knarr::Handler::Code;

my @logs;
Log::Any::Adapter->set( 'Capture', to => \@logs, log_level => 'trace' );

my $json = JSON::MaybeXS->new( utf8 => 1, canonical => 1 );
my $loop = IO::Async::Loop->new;

my $ADMIN_KEY = 'admin-key-0123456789-abcdef';
my $PROXY_KEY = 'proxy-key-from-file-0001';
my $KEY_ONE   = 'sk-provider-one-AAAAAAAA';
my $KEY_TWO   = 'sk-provider-two-BBBBBBBB';
my $KEY_NEW   = 'sk-provider-new-CCCCCCCC';
my $PUSH_PROXY = 'proxy-key-pushed-0002';
my @SECRETS = ( $ADMIN_KEY, $KEY_ONE, $KEY_TWO, $KEY_NEW, $PUSH_PROXY );

my $http = Net::Async::HTTP->new;
$loop->add($http);

# A Knarr wired like knarr start: a Stack from the config, an Admin on it.
sub knarr_for {
  my (%opt) = @_;
  my $config = Langertha::Knarr::Config->new( data => $opt{data} // {} );
  my $stack = Langertha::Knarr::Stack->new( config => $config, loop => $loop );
  my $admin = $opt{no_admin} ? undef : Langertha::Knarr::Admin->new(
    key => $ADMIN_KEY, stack => $stack, remote_config => $opt{remote_config} // 0,
    %{ $opt{admin_args} // {} } );
  my $knarr = Langertha::Knarr->new(
    loop   => $loop,
    port   => 0,
    handler => $stack->handler,
    router  => $stack->router,
    ( defined $stack->auth_token ? ( auth_token => $stack->auth_token ) : () ),
    ( $admin ? ( admin => $admin ) : () ),
  );
  $knarr->start;
  return ( $knarr, $knarr->_server->read_handle->sockport );
}

sub send_req {
  my ( $port, $method, $path, %opt ) = @_;
  my $req = HTTP::Request->new( $method => "http://127.0.0.1:$port$path" );
  $req->header( Authorization => "Bearer $opt{bearer}" ) if defined $opt{bearer};
  $req->header( 'x-api-key' => $opt{xkey} ) if defined $opt{xkey};
  if ( defined $opt{body} ) {
    my $body = ref $opt{body} ? $json->encode( $opt{body} ) : $opt{body};
    $req->header( 'Content-Type' => 'application/json' );
    $req->header( 'Content-Length' => length $body );
    $req->content($body);
  }
  return $http->do_request( request => $req )->get;
}

sub chat {
  my ( $port, $model, %opt ) = @_;
  return send_req( $port, POST => '/v1/chat/completions', %opt,
    body => { model => $model, messages => [ { role => 'user', content => 'hi' } ] } );
}

sub decode { my $d = eval { $json->decode( $_[0]->decoded_content ) }; $d }

sub no_secret_in {
  my ( $text, $what ) = @_;
  my @found = grep { index( $text, $_ ) >= 0 } @SECRETS;
  ok( !@found, "$what carries no key" ) or diag "found: @found";
}

my %file_setup = (
  proxy_api_key => $PROXY_KEY,
  models => {
    alpha => { engine => 'TestKnarrAdmin', model => 'alpha-up', api_key => $KEY_ONE },
  },
);

# --- Without an admin the routes do not exist ---
{
  my ( $knarr, $port ) = knarr_for( data => { %file_setup }, no_admin => 1 );
  for my $route ( [ GET => '/knarr/admin/status' ], [ PUT => '/knarr/admin/config' ],
                  [ PATCH => '/knarr/admin/keys' ], [ DELETE => '/knarr/admin/config' ] ) {
    my $resp = send_req( $port, @$route, bearer => $ADMIN_KEY );
    is( $resp->code, 404, "no admin: @$route is 404" );
    is( decode($resp)->{error}{message}, "no route for @$route", '... like any unknown path' );
  }
}

# --- With an admin, started from a file-like config ---
my ( $knarr, $port ) = knarr_for( data => { %file_setup } );
my $admin = $knarr->admin;

{
  my $resp = send_req( $port, GET => '/knarr/admin/status' );
  is( $resp->code, 401, 'status without a key: 401' );
  $resp = send_req( $port, GET => '/knarr/admin/status', bearer => $PROXY_KEY );
  is( $resp->code, 401, 'the proxy key never opens the admin routes' );
  $resp = send_req( $port, GET => '/knarr/admin/status', xkey => $ADMIN_KEY );
  is( $resp->code, 401, 'the admin key only counts as Authorization: Bearer' );
  # Reset the lockout count those three left behind.
  %{ $admin->_failures } = ();

  $resp = send_req( $port, GET => '/knarr/admin/status', bearer => $ADMIN_KEY );
  is( $resp->code, 200, 'status with the admin key: 200' );
  is( scalar $resp->header('Cache-Control'), 'no-store', 'admin answers are not cached' );
  my $s = decode($resp);
  is( $s, hash {
    field generation       => 0;
    field layers           => ['env'];
    field configured       => T();
    field remote_config         => F();
    field models           => [ 'alpha' ];
    field default_engine   => F();
    field passthrough      => [];
    field applied_at       => match qr/\A\d{4}-\d\d-\d\dT\d\d:\d\d:\d\dZ\z/;
    field applied_at_epoch => match qr/\A\d+\z/;
    end;
  }, 'status: generation, time, layers, model names' );
  no_secret_in( $resp->decoded_content, 'the status' );
}

# --- The admin key opens nothing else ---
{
  my $resp = chat( $port, 'alpha', bearer => $ADMIN_KEY );
  is( $resp->code, 401, 'the admin key on a chat route: 401' );
  $resp = chat( $port, 'alpha', xkey => $ADMIN_KEY );
  is( $resp->code, 401, '... in x-api-key too' );
  $resp = send_req( $port, GET => '/v1/models', bearer => $ADMIN_KEY );
  is( $resp->code, 401, '... and on /v1/models' );
  $resp = chat( $port, 'alpha', bearer => $PROXY_KEY );
  is( $resp->code, 200, 'the proxy key still serves chat' );
  is( decode($resp)->{choices}[0]{message}{content}, 'from alpha-up', '... from the file setup' );
}

# --- PUT lays a setup over the start setup ---
my $setup = {
  proxy_api_key => $PUSH_PROXY,
  models => {
    beta  => { engine => 'TestKnarrAdmin', model => 'beta-up',  api_key => $KEY_TWO },
    gamma => { engine => 'TestKnarrAdmin', model => 'gamma-up', api_key => $KEY_TWO },
  },
  default => { engine => 'TestKnarrAdmin', model => 'default-up', api_key => $KEY_TWO },
};
{
  @LangerthaX::Engine::TestKnarrAdmin::built = ();
  my $resp = send_req( $port, PUT => '/knarr/admin/config', bearer => $ADMIN_KEY, body => $setup );
  is( $resp->code, 200, 'PUT config: 200' );
  my $s = decode($resp);
  is( $s->{generation}, 1, 'generation 1' );
  is( $s->{layers}, [ 'env', 'push' ], 'layers: the start setup and the push' );
  is( $s->{models}, [ 'alpha', 'beta', 'gamma' ], 'the pushed models next to the start models' );
  ok( $s->{default_engine}, 'with a default engine' );
  no_secret_in( $resp->decoded_content, 'the PUT answer' );
  is( scalar @LangerthaX::Engine::TestKnarrAdmin::built, 4,
    'every engine of the layered setup was built before it went live' );

  $resp = chat( $port, 'beta', bearer => $PROXY_KEY );
  is( $resp->code, 401, 'the old proxy key is gone with the old setup' );
  $resp = chat( $port, 'beta', bearer => $PUSH_PROXY );
  is( $resp->code, 200, 'the pushed proxy key serves' );
  is( decode($resp)->{choices}[0]{message}{content}, 'from beta-up', 'routed by the pushed setup' );
  is( $LangerthaX::Engine::TestKnarrAdmin::chats[-1]{api_key}, $KEY_TWO, 'with the pushed key' );
  $resp = chat( $port, 'alpha', bearer => $PUSH_PROXY );
  is( decode($resp)->{choices}[0]{message}{content}, 'from alpha-up',
    'a start model without a pushed namesake stays' );
  is( $LangerthaX::Engine::TestKnarrAdmin::chats[-1]{api_key}, $KEY_ONE, '... with its own key' );
}

# --- Invalid deliveries change nothing ---
{
  my $before = decode( send_req( $port, GET => '/knarr/admin/status', bearer => $ADMIN_KEY ) );
  my @bad = (
    [ 'not JSON', qq({"models": {"x": {"engine": "TestKnarrAdmin", "api_key": "$KEY_NEW"}}, oops),
      qr/\Athe request body is not valid JSON\z/ ],
    [ 'empty body', '', qr/empty/ ],
    [ 'a JSON array', '[1,2]', qr/JSON object/ ],
    [ 'a model without engine', { models => { x => { api_key => $KEY_NEW } } },
      qr/Model 'x': missing 'engine' key/ ],
    [ 'a models section that is no mapping', { models => 'nope' }, qr/models/ ],
    [ 'logging', { %$setup, logging => { file => '/tmp/x.jsonl' } }, qr/logging take effect only at start/ ],
    [ 'a bad langfuse transport', { %$setup, langfuse => { transport => 'smtp' } }, qr/langfuse\.transport/ ],
    [ 'a langfuse url without its own keys (the file keys must not follow it)',
      { %$setup, langfuse => { url => 'http://evil.example' } },
      qr/langfuse\.url is accepted only together with/ ],
    [ 'a langfuse section that is no mapping', { %$setup, langfuse => $KEY_NEW }, qr/langfuse/ ],
    [ 'a process setting', { %$setup, listen => [ '0.0.0.0:1' ], workers => 3 },
      qr/listen, workers take effect only at start/ ],
    [ 'an unknown key', { %$setup, $KEY_NEW => 1 }, qr/1 unknown key/ ],
    [ 'a key in the wrong place', { %$setup, default => $KEY_NEW },
      qr/default must be a mapping of key: value pairs, not '\[redacted\]'/ ],
    [ 'an engine that cannot be built', { models => { x => { engine => 'NoSuchEngineKnarr', api_key => $KEY_NEW } } },
      qr/Model 'x': / ],
    [ 'the admin key as proxy key', { %$setup, proxy_api_key => $ADMIN_KEY },
      qr/proxy_api_key must differ from the admin key/ ],
    [ 'an api_key_env (start-environment secrets must not follow a pushed url)',
      { models => { x => { engine => 'TestKnarrAdmin', api_key_env => 'HOME', url => 'http://evil.example' } } },
      qr/api_key_env is not accepted.*models\.x/ ],
    [ 'a key that is no string', { models => { x => { engine => 'TestKnarrAdmin', api_key => { k => $KEY_NEW } } } },
      qr/api_key must be a string/ ],
  );
  for my $case (@bad) {
    my ( $what, $body, $message ) = @$case;
    my $resp = send_req( $port, PUT => '/knarr/admin/config', bearer => $ADMIN_KEY, body => $body );
    is( $resp->code, 400, "PUT $what: 400" );
    like( decode($resp)->{error}{message} // '', $message, '... saying why' );
    no_secret_in( $resp->decoded_content, "... the answer to $what" );
  }
  my $after = decode( send_req( $port, GET => '/knarr/admin/status', bearer => $ADMIN_KEY ) );
  is( $after, $before, 'after all of them the status is unchanged' );
  my $resp = chat( $port, 'beta', bearer => $PUSH_PROXY );
  is( decode($resp)->{choices}[0]{message}{content}, 'from beta-up', 'and the setup still serves' );
}

# --- Body limit ---
{
  my $resp = send_req( $port, PUT => '/knarr/admin/config', bearer => $ADMIN_KEY,
    body => '{"models":{},"x":"' . ( 'a' x ( $admin->max_body + 10 ) ) . '"}' );
  is( $resp->code, 413, 'a body over max_body: 413' );
  is( decode( send_req( $port, GET => '/knarr/admin/status', bearer => $ADMIN_KEY ) )->{generation}, 1,
    '... and nothing changed' );
}

# --- PATCH swaps keys ---
{
  my $resp = send_req( $port, PATCH => '/knarr/admin/keys', bearer => $ADMIN_KEY,
    body => { beta => $KEY_NEW, default => $KEY_NEW } );
  is( $resp->code, 200, 'PATCH keys: 200' );
  is( decode($resp)->{generation}, 2, 'generation 2' );
  no_secret_in( $resp->decoded_content, 'the PATCH answer' );
  $resp = chat( $port, 'beta', bearer => $PUSH_PROXY );
  is( $LangerthaX::Engine::TestKnarrAdmin::chats[-1]{api_key}, $KEY_NEW, 'beta now uses the new key' );
  chat( $port, 'gamma', bearer => $PUSH_PROXY );
  is( $LangerthaX::Engine::TestKnarrAdmin::chats[-1]{api_key}, $KEY_TWO, 'gamma keeps its key' );
  chat( $port, 'nobody-knows', bearer => $PUSH_PROXY );
  is( $LangerthaX::Engine::TestKnarrAdmin::chats[-1]{api_key}, $KEY_NEW, 'the default engine got its new key' );

  for my $case (
    [ 'an unknown name', { beta => $KEY_ONE, $KEY_ONE => 'beta' }, qr/1 name\(s\) neither a model/ ],
    [ 'an empty key',    { beta => '' }, qr/1 key\(s\) not a non-empty string/ ],
    [ 'an empty object', {}, qr/JSON object of name: key pairs/ ],
  ) {
    my ( $what, $body, $message ) = @$case;
    $resp = send_req( $port, PATCH => '/knarr/admin/keys', bearer => $ADMIN_KEY, body => $body );
    is( $resp->code, 400, "PATCH $what: 400" );
    like( decode($resp)->{error}{message}, $message, '... saying why' );
    no_secret_in( $resp->decoded_content, "... the answer to $what" );
  }
  chat( $port, 'beta', bearer => $PUSH_PROXY );
  is( $LangerthaX::Engine::TestKnarrAdmin::chats[-1]{api_key}, $KEY_NEW, 'a refused PATCH changed no key' );
  is( decode( send_req( $port, GET => '/knarr/admin/status', bearer => $ADMIN_KEY ) )->{generation}, 2,
    '... nor the generation' );
}

# --- A running stream is not cut off by a new setup ---
{
  $LangerthaX::Engine::TestKnarrAdmin::gate = $loop->new_future;
  my $body = $json->encode({ model => 'beta', stream => JSON::MaybeXS::true(),
    messages => [ { role => 'user', content => 'hi' } ] });
  my $req = HTTP::Request->new( POST => "http://127.0.0.1:$port/v1/chat/completions" );
  $req->header( Authorization => "Bearer $PUSH_PROXY" );
  $req->header( 'Content-Type' => 'application/json', 'Content-Length' => length $body );
  $req->content($body);
  my $got = '';
  # A client of its own: the shared one would queue the PUT behind it.
  my $stream_http = Net::Async::HTTP->new;
  $loop->add($stream_http);
  my $f = $stream_http->do_request(
    request   => $req,
    on_header => sub { sub { $got .= $_[0] if @_ && defined $_[0]; return } },
  );
  $loop->loop_once(0.1) until $got =~ /part1/ || $f->is_ready;
  like( $got, qr/part1/, 'the stream has started' );

  my $resp = send_req( $port, PUT => '/knarr/admin/config', bearer => $ADMIN_KEY,
    body => { models => { delta => { engine => 'TestKnarrAdmin', model => 'delta-up', api_key => $KEY_ONE } } } );
  is( $resp->code, 200, 'a new setup goes live while the stream runs' );

  $LangerthaX::Engine::TestKnarrAdmin::gate->done;
  $f->get;
  like( $got, qr/part1.*part2/s, 'the stream got the rest from its engine' );
  like( $got, qr/data: \[DONE\]/, '... and its end marker' );

  $resp = chat( $port, 'beta', bearer => $PROXY_KEY );
  is( $resp->code, 404, 'a new request for the replaced pushed model finds no route' );
  $resp = chat( $port, 'delta', bearer => $PROXY_KEY );
  is( decode($resp)->{choices}[0]{message}{content}, 'from delta-up',
    'the new push serves; the pushed proxy key went with the old push, the start key applies again' );
}

# --- DELETE goes back to the start setup ---
{
  my $resp = send_req( $port, DELETE => '/knarr/admin/config', bearer => $ADMIN_KEY );
  is( $resp->code, 200, 'DELETE config: 200' );
  my $s = decode($resp);
  is( [ @{$s}{qw( generation layers )} ], [ 4, ['env'] ], 'generation 4, the push layer is gone' );
  is( $s->{models}, [ 'alpha' ], 'the start models' );
  $resp = chat( $port, 'alpha', bearer => $PROXY_KEY );
  is( decode($resp)->{choices}[0]{message}{content}, 'from alpha-up', 'the start setup serves again' );
}

# --- Wrong keys lock the address out ---
{
  my $now = 1_000_000;
  no warnings 'redefine';
  local *Langertha::Knarr::Admin::_now = sub { $now };
  my @codes = map { send_req( $port, GET => '/knarr/admin/status', bearer => 'wrong' )->code } 1 .. 3;
  is( \@codes, [ 401, 401, 401 ], 'three wrong keys: 401 each' );
  my $resp = send_req( $port, GET => '/knarr/admin/status', bearer => $ADMIN_KEY );
  is( $resp->code, 429, 'then even the right key waits: 429' );
  is( scalar $resp->header('Retry-After'), 1, '... with Retry-After' );
  $now += 1;
  is( send_req( $port, GET => '/knarr/admin/status', bearer => 'wrong' )->code, 401, 'after the wait, one more try' );
  $resp = send_req( $port, GET => '/knarr/admin/status', bearer => $ADMIN_KEY );
  is( [ $resp->code, scalar $resp->header('Retry-After') ], [ 429, 2 ], 'the next lockout is twice as long' );
  $now += 2;
  is( send_req( $port, GET => '/knarr/admin/status', bearer => $ADMIN_KEY )->code, 200,
    'the right key after the wait: 200' );
  is( send_req( $port, GET => '/knarr/admin/status', bearer => 'wrong' )->code, 401,
    'which ended the count: the next wrong key is free again' );
  is( send_req( $port, GET => '/knarr/admin/status', bearer => $ADMIN_KEY )->code, 200, '... no lockout' );
}

# --- remote_config without a start setup: nothing served before the first push ---
{
  my ( $ram, $rport ) = knarr_for( data => {}, remote_config => 1 );
  my $resp = chat( $rport, 'beta' );
  is( $resp->code, 503, 'remote_config, no setup: chat answers 503' );
  like( decode($resp)->{error}{message}, qr/not configured/, '... not configured' );
  is( send_req( $rport, POST => '/v1/messages',
    body => { model => 'beta', max_tokens => 5, messages => [ { role => 'user', content => 'hi' } ] } )->code,
    503, '... Anthropic too' );
  is( send_req( $rport, GET => '/v1/models' )->code, 503, '... and the model list' );
  is( send_req( $rport, GET => '/.well-known/langertha.json' )->code, 503, '... and the manifest' );

  my $s = decode( send_req( $rport, GET => '/knarr/admin/status', bearer => $ADMIN_KEY ) );
  is( [ @{$s}{qw( generation layers models )} ], [ 0, [], [] ], 'status: generation 0, no layer' );
  ok( !$s->{configured} && $s->{remote_config}, '... not configured, remote_config' );
  ok( !exists $s->{ram_only} && !exists $s->{source}, '... the old field names are gone' );
  is( send_req( $rport, PUT => '/knarr/admin/config', bearer => $ADMIN_KEY, body => { proxy_api_key => $PUSH_PROXY } )->code,
    400, 'a push without any model and no start setup: 400' );

  is( send_req( $rport, PATCH => '/knarr/admin/keys', bearer => $ADMIN_KEY, body => { beta => $KEY_ONE } )->code,
    409, 'PATCH before any setup: 409' );

  $resp = send_req( $rport, PUT => '/knarr/admin/config', bearer => $ADMIN_KEY,
    body => { models => { beta => { engine => 'TestKnarrAdmin', model => 'beta-up', api_key => $KEY_ONE } } } );
  is( $resp->code, 200, 'the first push' );
  $resp = chat( $rport, 'beta' );
  is( decode($resp)->{choices}[0]{message}{content}, 'from beta-up', 'now it serves' );

  $resp = send_req( $rport, DELETE => '/knarr/admin/config', bearer => $ADMIN_KEY );
  is( decode($resp)->{configured}, F(), 'DELETE without a start setup: not configured again' );
  is( chat( $rport, 'beta' )->code, 503, '... and chat answers 503 again' );
}

# --- Layers: the file is always there, the push lies over it ---
{
  my %file = (
    proxy_api_key => $PROXY_KEY,
    models => {
      alpha  => { engine => 'TestKnarrAdmin', model => 'alpha-up',  api_key => $KEY_ONE },
      shared => { engine => 'TestKnarrAdmin', model => 'shared-file', api_key => $KEY_ONE },
    },
    default => { engine => 'TestKnarrAdmin', model => 'default-file', api_key => $KEY_ONE },
    langfuse => { trace_name => 'from-file', url => 'http://127.0.0.1:1' },
  );
  my ( $lk, $lport ) = knarr_for( data => { %file }, remote_config => 1 );
  my $ls = decode( send_req( $lport, GET => '/knarr/admin/status', bearer => $ADMIN_KEY ) );
  ok( $ls->{configured} && $ls->{remote_config}, 'remote_config with a file setup: configured from the start' );
  is( $ls->{layers}, ['env'], '... one layer' );
  ok( !$lk->tracing, '... no tracing' );

  my $resp = send_req( $lport, PUT => '/knarr/admin/config', bearer => $ADMIN_KEY, body => {
    models => {
      shared => { engine => 'TestKnarrAdmin', model => 'shared-push', api_key => $KEY_TWO },
      extra  => { engine => 'TestKnarrAdmin', model => 'extra-push',  api_key => $KEY_TWO },
    },
    langfuse => { public_key => 'pk-lf-layer-test', secret_key => 'sk-lf-layer-test', url => 'http://127.0.0.1:2' },
  } );
  is( $resp->code, 200, "PUT over a file setup: 200" ) or diag $resp->decoded_content;
  my $s = decode($resp);
  is( $s->{layers}, [ 'env', 'push' ], 'both layers' );
  is( $s->{models}, [ 'alpha', 'extra', 'shared' ], 'file models without a namesake stay, pushed ones join' );
  ok( $s->{default_engine}, 'the file default engine stays' );
  no_secret_in( $resp->decoded_content, 'the status' );
  unlike( $resp->decoded_content, qr/pk-lf-layer-test|sk-lf-layer-test/, '... no Langfuse key either' );
  ok( $lk->tracing, 'a pushed langfuse section switches tracing on' );
  is( $lk->tracing->trace_name, 'from-file', '... the file langfuse keys it did not override stay' );

  # The proxy key is the file's (the push did not set one).
  chat( $lport, 'shared', bearer => $PROXY_KEY );
  is( $LangerthaX::Engine::TestKnarrAdmin::chats[-1]{model}, 'shared-push', 'the pushed model wins its name' );
  chat( $lport, 'alpha', bearer => $PROXY_KEY );
  is( $LangerthaX::Engine::TestKnarrAdmin::chats[-1]{model}, 'alpha-up', 'the file model serves' );

  # PATCH reaches file models; the key lands in the push layer.
  $resp = send_req( $lport, PATCH => '/knarr/admin/keys', bearer => $ADMIN_KEY,
    body => { alpha => $KEY_NEW } );
  is( $resp->code, 200, 'PATCH a file model: 200' );
  is( decode($resp)->{layers}, [ 'env', 'push' ], '... still two layers' );
  no_secret_in( $resp->decoded_content, '... the answer' );
  chat( $lport, 'alpha', bearer => $PROXY_KEY );
  is( $LangerthaX::Engine::TestKnarrAdmin::chats[-1]{api_key}, $KEY_NEW, '... alpha uses the patched key' );
  is( $lk->admin->stack->config->data->{models}{alpha}{api_key}, $KEY_NEW, '... in the merged setup' );
  is( $lk->admin->_boot_stack->config->data->{models}{alpha}{api_key}, $KEY_ONE, '... never in the file layer' );
  chat( $lport, 'shared', bearer => $PROXY_KEY );
  is( $LangerthaX::Engine::TestKnarrAdmin::chats[-1]{model}, 'shared-push', '... and the push layer is kept' );

  # A new PUT replaces the push layer, not the file.
  $resp = send_req( $lport, PUT => '/knarr/admin/config', bearer => $ADMIN_KEY,
    body => { models => { only => { engine => 'TestKnarrAdmin', model => 'only-push', api_key => $KEY_TWO } } } );
  is( decode($resp)->{models}, [ 'alpha', 'only', 'shared' ], 'a second PUT replaces the first push, not the file' );
  chat( $lport, 'alpha', bearer => $PROXY_KEY );
  is( $LangerthaX::Engine::TestKnarrAdmin::chats[-1]{api_key}, $KEY_ONE, '... alpha is back on the file key' );
  ok( !$lk->tracing, '... and without langfuse in the push, tracing is the start one again' );

  # DELETE drops the push layer, back to the file.
  send_req( $lport, PUT => '/knarr/admin/config', bearer => $ADMIN_KEY, body => {
    models => { extra => { engine => 'TestKnarrAdmin', model => 'extra-push', api_key => $KEY_TWO } } } );
  $resp = send_req( $lport, DELETE => '/knarr/admin/config', bearer => $ADMIN_KEY );
  $s = decode($resp);
  is( [ $s->{layers}, $s->{models}, $s->{configured} ], [ ['env'], [ 'alpha', 'shared' ], T() ],
    'DELETE: the file setup stays, configured' );
  chat( $lport, 'shared', bearer => $PROXY_KEY );
  is( $LangerthaX::Engine::TestKnarrAdmin::chats[-1]{model}, 'shared-file', '... the file model serves again' );
}

# --- The admin routes are not published ---
{
  my ( $open, $oport ) = knarr_for( data => { models => { alpha => $file_setup{models}{alpha} } } );
  my $resp = send_req( $oport, GET => '/.well-known/langertha.json' );
  unlike( $resp->decoded_content, qr{/knarr/admin}, 'the manifest does not name the admin routes' );
  my @protocol_paths = map { $_->{path} } grep { !$_->{admin} } @{ $open->_routes };
  ok( !( grep { m{\A/knarr/} } @protocol_paths ), 'no protocol route under /knarr/' );
}

# --- One process only ---
like(
  dies {
    Langertha::Knarr->new( loop => $loop, workers => 2, admin => Langertha::Knarr::Admin->new(
      key => $ADMIN_KEY, stack => Langertha::Knarr::Stack->new(
        config => Langertha::Knarr::Config->new( data => {} ) ) ) );
  },
  qr/workers '2' cannot be combined with admin routes/,
  'workers > 1 with an admin croaks',
);
like( dies { Langertha::Knarr::Admin->new( key => 'short', stack => {} ) },
  qr/key must be a string of at least 16 characters/, 'a short admin key croaks' );
my $short_err = dies { Langertha::Knarr::Admin->new( key => 'sk-too-short', stack => {} ) };
unlike( $short_err // '', qr/sk-too-short/, '... without echoing it' );
like( dies { Langertha::Knarr->new( loop => $loop ) }, qr/Attribute \(handler\) is required/,
  'without an admin the handler is still required' );

# --- Nothing above wrote a key into the log ---
{
  my $all = join "\n", map { $_->[2] // '' } @logs;
  ok( scalar @logs, 'the log captured something' );
  no_secret_in( $all, 'the log' );
  like( $all, qr/Admin: setup replaced, generation 1/, 'the log says what changed' );
  like( $all, qr/Admin: refused a request from \S+ without the admin key/, '... and who knocked' );
}

done_testing;
