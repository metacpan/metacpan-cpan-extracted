#!/usr/bin/env perl
# ABSTRACT: raider --provider HOST: the command line, and a run on a manifest's endpoint (k119)
use strict;
use warnings;
use utf8;
use Test2::V0;
use Encode qw( decode_utf8 );
use Future;
use JSON::MaybeXS ();
use Path::Tiny;
use lib 't/lib';
use Test::Raider::Env qw( clear_engine_env isolate_home );
use Test::Raider::FakeHTTPS;
isolate_home();
clear_engine_env();

my $pki = Test::Raider::FakeHTTPS->pki( names => [ 'provider.example', 'localhost', 'provider.invalid' ] );
our $CA = $pki->{ca};
# The engine's own TLS client trusts the test CA through the default CA
# store: IO::Socket::SSL reads SSL_CERT_FILE.
$ENV{SSL_CERT_FILE} = $CA;

use Langertha::Engine::Anthropic;
use Langertha::Raider::CLI::Main;
use Langertha::Raider::CLI::Output;
use Langertha::Raider::Config;
use Langertha::Raider::EngineResolver;

# The manifest fetch trusts the test CA; for raider's checks every name
# resolves to the fake server. The engine connects to the address raider
# checked (k141), so nothing needs DNS: provider.invalid (RFC 6761) never
# resolves, and a run on it works only through the pin.
package My::Provider {
  use Moose;
  extends 'Langertha::Raider::CLI::Provider';
  has '+fetch_args' => ( default => sub { {
    ssl_options => { SSL_ca_file => $main::CA },
    resolver    => sub { Future->done('127.0.0.1') },
    # not the production 10 s: a loaded machine must not turn a slow fetch into a red test
    timeout     => 120,
  } } );
  __PACKAGE__->meta->make_immutable;
}

package My::Main {
  use Moose;
  extends 'Langertha::Raider::CLI::Main';
  sub provider_class { 'My::Provider' }
  __PACKAGE__->meta->make_immutable;
}

sub buffer {
  my $buf = '';
  open my $fh, '>:encoding(UTF-8)', \$buf or die $!;
  return ( $fh, sub { $fh->flush; decode_utf8($buf) } );
}

my $root = Path::Tiny->tempdir;
# A .raider.yml with a key, a URL and a model meant for another provider.
$root->child('.raider.yml')->spew_utf8(
  "api_key: yml-secret\nurl: https://api.example/v1\nmodel: yml-model\nopenai:\n  api_key: yml-section-secret\n" );

sub main_run {
  my ( @argv ) = @_;
  my ( $out, $read_out ) = buffer();
  my ( $err, $read_err ) = buffer();
  local $ENV{ANSI_COLORS_DISABLED};
  my $exit = My::Main->new(
    output => Langertha::Raider::CLI::Output->new( out => $out, color => 0 ),
    err    => $err,
    in     => do { open my $in, '<', \'' or die $!; $in },
  )->run( '-r', "$root", '--no-session', '--no-trace', @argv );
  my @res = ( $exit, $read_out->(), $read_err->() );
  diag $res[2] if $res[2] =~ /timed out/;
  return @res;
}

my $T = JSON::MaybeXS->true;

sub manifest {
  my ( %over ) = @_;
  return {
    schema_version => 1,
    kind           => 'langertha-provider',
    provider_id    => 'example-provider',
    issuer         => 'ORIGIN',
    endpoints      => [ { id => 'chat', dialect => 'openai-chat', base_url => 'ORIGIN/v1', auth_ref => 'api' } ],
    auth           => [ { id => 'api', type => 'api_key' } ],
    models         => [ { id => 'm1', endpoint_ref => 'chat', capabilities => { tools_native => $T } } ],
    %over,
  };
}

my $other = Test::Raider::FakeHTTPS->new( pki => $pki, routes => {} );
my $other_port = $other->port;

my %manifests = (
  '/.well-known/langertha.json' => manifest(),
  '/two.json'    => manifest( models => [ { id => 'a', endpoint_ref => 'chat' }, { id => 'b', endpoint_ref => 'chat' } ] ),
  '/noauth.json' => manifest( endpoints => [ { id => 'chat', dialect => 'openai-chat', base_url => 'ORIGIN/v1' } ], auth => [],
                      models => [ { id => 'm1', endpoint_ref => 'chat' } ] ),
  '/redir.json'  => manifest( endpoints => [ { id => 'chat', dialect => 'openai-chat', base_url => 'ORIGIN/redir/v1', auth_ref => 'api' } ] ),
  '/pigeon.json' => manifest( endpoints => [ { id => 'chat', dialect => 'carrier-pigeon', base_url => 'ORIGIN/v1', auth_ref => 'api' } ] ),
);
my %routes = map {
  my $doc = JSON::MaybeXS->new( canonical => 1 )->encode( $manifests{$_} );
  ( $_ => sub {
    my ( $req ) = @_;
    ( my $served = $doc ) =~ s{ORIGIN}{https://$req->{headers}{host}}g;
    Test::Raider::FakeHTTPS->json( 200, $served );
  } );
} keys %manifests;
$routes{'/v1/chat/completions'} = sub {
  Test::Raider::FakeHTTPS->json( 200, {
    id => 'c1', object => 'chat.completion', created => 1, model => 'm1',
    choices => [ { index => 0, finish_reason => 'stop', message => { role => 'assistant', content => 'hello from the provider' } } ],
    usage => { prompt_tokens => 3, completion_tokens => 4, total_tokens => 7 },
  } );
};
# Every request to /redir/ is sent on to the other origin.
for my $path ( '/redir/v1/chat/completions', '/redir/v1/models' ) {
  ( my $to = $path ) =~ s{^/redir}{};
  $routes{$path} = sub { Test::Raider::FakeHTTPS->response( 307, '', Location => 'https://127.0.0.1:'.$other_port.$to ) };
}
my $srv  = Test::Raider::FakeHTTPS->new( pki => $pki, routes => \%routes );
my $host = '127.0.0.1:'.$srv->port;

# Run with the manifest at $path of the provider's origin.
sub provider_run {
  my ( $path, @args ) = @_;
  no warnings 'redefine';
  my $orig = \&Langertha::Raider::Provider::Fetch::target_url;
  local *Langertha::Raider::Provider::Fetch::target_url = sub {
    my $url = $orig->(@_);
    $url =~ s{/\.well-known/langertha\.json\z}{$path};
    return $url;
  };
  return main_run( '--provider', $host, '--allow-internal', @args );
}

# The requests since the first $seen, without the session embedding
# requests the raider sends on the side (they may arrive a subtest late;
# the last subtest checks every request).
sub requests_since {
  my ( $server, $seen ) = @_;
  my @requests = $server->requests;
  return grep { $_->{path} !~ m{/embeddings\z} } @requests[ $seen .. $#requests ];
}

my %env_keys = map { $_ => 'env-secret' } qw( OPENAI_API_KEY LANGERTHA_OPENAI_API_KEY ANTHROPIC_API_KEY );

subtest 'a run on the endpoint the manifest declares' => sub {
  local @ENV{ keys %env_keys } = values %env_keys;
  my $seen = () = $srv->requests;
  my ( $exit, $out, $err ) = main_run( '--provider', $host, '--allow-internal', '-k', 'sk-cli', '--json', 'say hello' );
  is( $exit, 0, 'exit 0' ) or diag $err;
  my $doc = JSON::MaybeXS->new->decode($out);
  is( [ @$doc{qw( status response )} ], [ 'completed', 'hello from the provider' ], 'the endpoint answered' );
  my @requests = requests_since( $srv, $seen );
  is( [ map { $_->{method}.' '.$_->{path} } @requests ],
    [ 'GET /.well-known/langertha.json', 'POST /v1/chat/completions' ], 'manifest, then the chat at base_url' );
  ok( !exists $requests[0]{headers}{authorization}, 'no key with the manifest fetch' );
  is( $requests[1]{headers}{authorization}, 'Bearer sk-cli', 'the -k key with the chat' );
  my $sent = JSON::MaybeXS->new->canonical->encode( [ map { $_->{headers} } @requests ] );
  unlike( $sent, qr/secret/, 'no key from .raider.yml or the environment' );
  unlike( $out.$err, qr/sk-cli/, 'the key is not in the output' );
};

subtest 'an endpoint without auth gets no key at all' => sub {
  local @ENV{ keys %env_keys } = values %env_keys;
  my $seen = () = $srv->requests;
  my ( $exit, $out, $err ) = provider_run( '/noauth.json', '--json', 'say hello' );
  is( $exit, 0, 'exit 0' ) or diag $err;
  like( $err, qr/^raider --provider: warning: model 'm1' does not declare tools_native; raider works through tool calls$/m,
    'the tools_native warning on stderr' );
  my @requests = requests_since( $srv, $seen );
  is( [ map { $_->{path} } @requests ], [ '/noauth.json', '/v1/chat/completions' ], 'manifest, then the chat' );
  ok( !exists $requests[1]{headers}{authorization}, 'no Authorization: the configured keys stay home' );
};

subtest 'the engine connects to the address raider checked, not to the name again (k141)' => sub {
  # raider's check resolves provider.invalid to 127.0.0.1; the system never
  # resolves it. Without the pin the engine would look the name up afresh
  # (a DNS answer that may have changed since the check) and fail here.
  my $pinned = 'provider.invalid:'.$srv->port;
  my $seen = () = $srv->requests;
  my ( $exit, $out, $err ) = main_run( '--provider', $pinned, '--allow-internal', '-k', 'sk-cli', '--json', 'say hello' );
  is( $exit, 0, 'exit 0' ) or diag $err;
  my $doc = eval { JSON::MaybeXS->new->decode($out) } // {};
  is( [ @$doc{qw( status response )} ], [ 'completed', 'hello from the provider' ], 'the endpoint answered' );
  my @requests = requests_since( $srv, $seen );
  is( [ map { $_->{method}.' '.$_->{path} } @requests ],
    [ 'GET /.well-known/langertha.json', 'POST /v1/chat/completions' ], 'manifest, then the chat, both at the checked address' );
  is( $requests[1]{headers}{host}, $pinned, 'the chat still names the host' );
  is( $requests[1]{headers}{authorization}, 'Bearer sk-cli', '... and carries the -k key' );
};

subtest 'the pinned engine still verifies TLS against the host name (k141)' => sub {
  local $ENV{PERL_LWP_SSL_CA_FILE} = $CA;
  my $engine_for = sub {
    my ( $name ) = @_;
    return Langertha::Raider::EngineResolver->new(
      config   => Langertha::Raider::Config->new( root => "$root" ),
      provider => { engine_name => 'openai', engine_class => 'Langertha::Engine::OpenAI',
                    url => 'https://'.$name.':'.$srv->port.'/v1', model => 'm1', connect_address => '127.0.0.1' },
      api_key  => 'sk-cli',
    )->build_engine;
  };
  my $seen = () = $srv->requests;
  is( $engine_for->('provider.invalid')->simple_chat_f('hi')->get->content, 'hello from the provider',
    'control: the name the certificate carries, pinned, answers' );
  is( scalar( () = requests_since( $srv, $seen ) ), 1, 'control: one request' );

  # The same server and address under a name its certificate does not carry.
  $seen = () = $srv->requests;
  my $wrong = $engine_for->('wrong.invalid');
  like( dies { $wrong->simple_chat_f('hi')->get }, qr/\A127\.0\.0\.1:\d+ - hostname verification failed/,
    'a name the certificate does not carry: the async request, connected to the pinned address, fails the name check' );
  like( dies { $wrong->simple_chat('hi') }, qr/500 Can't connect to wrong\.invalid:\d+ \(hostname verification failed\)/,
    '... and so does the synchronous one' );
  is( [ requests_since( $srv, $seen ) ], [], 'no request reached the server, the key never left' );
};

subtest 'a redirect does not carry the key to another origin' => sub {
  my $seen = () = $srv->requests;
  my ( $exit, $out, $err ) = provider_run( '/redir.json', '-k', 'sk-cli', '--json', 'say hello' );
  is( $exit, 1, 'the run fails' );
  is( JSON::MaybeXS->new->decode($out)->{status}, 'failed', 'a failed document' );
  is( [ map { $_->{path} } requests_since( $srv, $seen ) ], [ '/redir.json', '/redir/v1/chat/completions' ],
    'the chat POST got the redirect' );
  is( [ $other->requests ], [], 'the other origin got nothing' );
  unlike( $out.$err, qr/sk-cli/, 'the key is not in the output' );
};

subtest 'command-line errors: exit 2' => sub {
  for my $case (
    [ [ '--provider', $host, '-e', 'openai', 'hi' ], qr/^--provider: not with -e\/--engine; the provider manifest decides the engine and its URL$/, '-e' ],
    [ [ '--provider', $host, '-o', 'engine=openai', 'hi' ], qr/^--provider: not with -o engine=/, '-o engine=' ],
    [ [ '--provider', $host, '-o', 'url=https://x.example', 'hi' ], qr/^--provider: not with -o url=/, '-o url=' ],
    [ [ '--provider', $host, 'config', 'explain' ], qr/^--provider: not with config explain$/, 'config explain' ],
    [ [ '--allow-internal', 'hi' ], qr/^--allow-internal: only with --provider$/, '--allow-internal alone' ],
    [ [ '--provider', 'http://'.$host, 'hi' ], qr/^raider --provider: only https is allowed/, 'an http target' ],
    [ [ '--provider', $host, '--allow-internal', 'hi' ],
      qr/^raider --provider: endpoint 'chat' needs an API key \(auth 'api', type api_key\); pass it with -k KEY$/, 'no key' ],
    [ [ '--provider', $host, '--allow-internal', '-k', 'sk', '-m', 'gpt-9', 'hi' ],
      qr/^raider --provider: model 'gpt-9' is not in the manifest of example-provider \(models: m1\)$/, 'an unknown model' ],
  ) {
    my ( $args, $message, $what ) = @$case;
    my $seen = () = $srv->requests;
    my ( $exit, $out, $err ) = main_run(@$args);
    is( $exit, 2, "$what: exit 2" );
    is( $out, '', "$what: nothing on stdout" );
    like( $err, $message, "$what: message" );
  }
  local $ENV{OPENAI_API_KEY} = 'env-secret';
  my ( $exit, $out, $err ) = provider_run( '/two.json', 'hi' );
  is( $exit, 2, 'several models without -m: exit 2' );
  like( $err, qr/lists several models; choose one with -m MODEL \(models: a, b\)/, 'lists them' );
  ( $exit, $out, $err ) = main_run( '--provider', $host, '--allow-internal', '-o', 'api_key=sk', '-o', 'model=m1', '--json', 'hi' );
  is( $exit, 0, '-o api_key= and -o model= count as -k and -m' ) or diag $err;
};

subtest 'provider-side refusals: exit 1' => sub {
  my ( $exit, $out, $err ) = main_run( '--provider', $host, '-k', 'sk', 'hi' );
  is( $exit, 1, 'an internal address without --allow-internal' );
  like( $err, qr/^raider --provider: refused: 127\.0\.0\.1 is \(loopback address\); only --allow-internal/,
    'refused, saying why' );
  ( $exit, $out, $err ) = provider_run( '/pigeon.json', '-k', 'sk', 'hi' );
  is( $exit, 1, 'an unknown dialect' );
  like( $err, qr/^raider --provider: failed: endpoint 'chat': dialect 'carrier-pigeon' is unknown to this raider/, 'no guessing' );
};

subtest 'every request of this file, embeddings included' => sub {
  my @requests = $srv->requests;
  my @with_key = grep { exists $_->{headers}{authorization} } @requests;
  ok( scalar @with_key, 'some requests carried a key' );
  is( [ grep { $_->{headers}{authorization} !~ /\ABearer (?:sk-cli|sk)\z/ } @with_key ], [],
    'only ever a command-line key' );
  is( [ grep { $_->{path} =~ /\.json\z/ && exists $_->{headers}{authorization} } @requests ], [],
    'never with a manifest fetch' );
  unlike( JSON::MaybeXS->new->canonical->encode( \@requests ), qr/secret/, 'no configured key anywhere' );
  is( [ $other->requests ], [], 'the other origin got nothing, ever' );
};

subtest 'the synchronous user agent follows no redirect either (REPL /model list)' => sub {
  local $ENV{PERL_LWP_SSL_CA_FILE} = $CA;
  # Control: Langertha's own agent follows a GET redirect to another origin
  # and leaves the key behind (core k374; plain LWP would keep x-api-key).
  # It still sends the request there -- to a host no address check has seen,
  # which is why the provider engine follows no redirect at all.
  my $url = 'https://'.$host.'/redir';
  my $control = Langertha::Engine::Anthropic->new( url => $url, api_key => 'sk-control', model => 'm1' );
  eval { $control->list_models };
  my @followed = $other->requests;
  is( [ map { $_->{method}.' '.$_->{path} } @followed ], [ 'GET /v1/models' ],
    'control: an engine built without the provider settings follows the GET redirect to the other origin' );
  is( [ grep { exists $_->{headers}{'x-api-key'} || exists $_->{headers}{authorization} } @followed ], [],
    'control: ... without its key' );
  unlike( JSON::MaybeXS->new->canonical->encode( \@followed ), qr/sk-control/, 'control: the key is nowhere in it' );

  # Why raider keeps its setting under the pin (k141): the pin refuses a hop
  # to another host, but follows one to another port of the pinned host --
  # another origin than the endpoint's. $other listens on 127.0.0.1 as well.
  my $seen_other = () = $other->requests;
  my $pinned = Langertha::Engine::Anthropic->new( url => $url, api_key => 'sk-control', model => 'm1',
    connect_address => '127.0.0.1' );
  eval { $pinned->list_models };
  is( [ map { $_->{method}.' '.$_->{path} } requests_since( $other, $seen_other ) ], [ 'GET /v1/models' ],
    'control: pinned, without the provider settings, the hop to another port of the host is followed' );

  $seen_other = () = $other->requests;
  my $engine = Langertha::Raider::EngineResolver->new(
    config   => Langertha::Raider::Config->new( root => "$root" ),
    provider => { engine_name => 'anthropic', engine_class => 'Langertha::Engine::Anthropic', url => $url, model => 'm1',
                  connect_address => '127.0.0.1' },
    api_key  => 'sk-cli',
  )->build_engine;
  my $seen = () = $srv->requests;
  eval { $engine->list_models };
  is( [ map { $_->{path} } requests_since( $srv, $seen ) ], ['/redir/v1/models'], 'the GET got the redirect' );
  is( [ requests_since( $other, $seen_other ) ], [], 'and did not follow it' );
};

subtest 'usage' => sub {
  my ( $exit, $out ) = main_run('--help');
  like( $out, qr/--provider HOST\[:PORT\]/, '--help names --provider' );
  like( $out, qr/--allow-internal +With --provider/, '... and --allow-internal' );
};

done_testing;
