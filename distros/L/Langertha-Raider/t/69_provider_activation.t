#!/usr/bin/env perl
# ABSTRACT: raider --provider: from a provider manifest to the engine of one run (k119)
use strict;
use warnings;
use Test2::V0;
use Future;
use JSON::MaybeXS ();
use Path::Tiny;
use YAML::PP ();
use lib 't/lib';
use Test::Raider::Env qw( clear_engine_env isolate_home );
use Test::Raider::FakeHTTPS;
isolate_home();
clear_engine_env();
use Langertha::Manifest::Builder;
use Langertha::Manifest::Endpoint;
use Langertha::Raider::Config;
use Langertha::Raider::EngineResolver;
use Langertha::Raider::Provider::Activation;
use Langertha::Raider::Provider::Fetch;

my $class = 'Langertha::Raider::Provider::Activation';
my $pki   = Test::Raider::FakeHTTPS->pki( names => [ 'provider.example', 'localhost' ] );

# A fetcher that reads the manifest from another path of the same origin,
# so one server can serve every case.
package My::Fetch {
  use Moose;
  extends 'Langertha::Raider::Provider::Fetch';
  our $VERSION = '0.001';   # the User-Agent names it
  has manifest_path => ( is => 'rw' );
  around target_url => sub {
    my ( $orig, $self, @args ) = @_;
    my $url = $self->$orig(@args);
    my $path = $self->manifest_path;
    $url =~ s{/\.well-known/langertha\.json\z}{$path} if defined $path;
    return $url;
  };
  __PACKAGE__->meta->make_immutable;
}

my $T = JSON::MaybeXS->true;
my $F = JSON::MaybeXS->false;

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

sub endpoint { my ( $dialect, %over ) = @_; return { id => 'chat', dialect => $dialect, base_url => 'ORIGIN/v1', auth_ref => 'api', %over } }

my %manifests = (
  '/one.json'      => manifest(),
  '/two.json'      => manifest( models => [
                        { id => 'a', endpoint_ref => 'chat', capabilities => { tools_native => $T } },
                        { id => 'b', endpoint_ref => 'chat', capabilities => { tools_native => $T } } ] ),
  '/none.json'     => manifest( models => [] ),
  '/notools.json'  => manifest( models => [ { id => 'm1', endpoint_ref => 'chat', capabilities => { tools_native => $F } } ] ),
  '/cross.json'    => manifest( endpoints => [ endpoint( 'openai-chat', base_url => 'https://other.example/v1' ) ] ),
  '/port.json'     => manifest( endpoints => [ endpoint( 'openai-chat', base_url => 'https://provider.example:1/v1' ) ] ),
  '/http.json'     => manifest( endpoints => [ endpoint( 'openai-chat', base_url => 'HTTPORIGIN/v1' ) ] ),
  '/pigeon.json'   => manifest( endpoints => [ endpoint('carrier-pigeon') ] ),
  '/lmstudio.json' => manifest( endpoints => [ endpoint('lmstudio') ] ),
  '/oauth.json'    => manifest( auth => [ { id => 'api', type => 'oauth2' } ] ),
  '/noauth.json'   => manifest( endpoints => [ endpoint( 'openai-chat', auth_ref => undef ) ], auth => [] ),
  '/multi.json'    => manifest(
    endpoints => [
      endpoint('openai-chat'),
      { id => 'msg', dialect => 'anthropic', base_url => 'ORIGIN', auth_ref => 'api' },
      { id => 'coo', dialect => 'carrier-pigeon', base_url => 'ORIGIN/coo', auth_ref => 'api' },
    ],
    models => [
      { id => 'x', endpoint_ref => 'coo',  capabilities => { tools_native => $T } },
      { id => 'x', endpoint_ref => 'chat', capabilities => { tools_native => $T } },
      { id => 'y', endpoint_ref => 'chat', capabilities => { tools_native => $T } },
      { id => 'y', endpoint_ref => 'msg',  capabilities => { tools_native => $T } },
      { id => 'z', endpoint_ref => 'coo',  capabilities => { tools_native => $T } },
    ] ),
  ( map { ( '/dialect-'.$_.'.json' => manifest( endpoints => [ endpoint($_) ] ) ) }
    $class->mapped_dialects ),
);
my %routes = map {
  my $doc = JSON::MaybeXS->new( canonical => 1 )->encode( $manifests{$_} );
  ( $_ => sub {
    my ( $req ) = @_;
    my $host = $req->{headers}{host};
    ( my $served = $doc ) =~ s{HTTPORIGIN}{http://$host}g;
    $served =~ s{ORIGIN}{https://$host}g;
    Test::Raider::FakeHTTPS->json( 200, $served );
  } );
} keys %manifests;
my $srv  = Test::Raider::FakeHTTPS->new( pki => $pki, routes => \%routes );
my $host = 'provider.example:'.$srv->port;
my $base = 'https://'.$host;

# What these fetches check is never the clock: a budget far above the 10s
# default, so a loaded machine (a swapped-out server child) does not turn
# an activation into "timed out" (k136).
sub fetcher {
  my ( %args ) = @_;
  return My::Fetch->new(
    timeout        => 120,
    allow_internal => 1,
    ssl_options    => { SSL_ca_file => $pki->{ca} },
    resolver       => sub { Future->done('127.0.0.1') },
    %args,
  );
}

sub activate {
  my ( $path, %opt ) = @_;
  my $fetch = delete $opt{fetch} // fetcher();
  $fetch->manifest_path($path);
  return $class->new( fetch => $fetch )->activate_f( $host, has_api_key => 1, %opt )->get;
}

subtest 'every dialect Langertha knows is mapped or explicitly unsupported' => sub {
  my %mapped      = map { $_ => 1 } $class->mapped_dialects;
  my %unsupported = map { $_ => 1 } $class->unsupported_dialects;
  for my $dialect ( Langertha::Manifest::Endpoint->known_dialects ) {
    ok( ( $mapped{$dialect} ? 1 : 0 ) + ( $unsupported{$dialect} ? 1 : 0 ) == 1,
      $dialect.': mapped or unsupported, not both' );
  }
  my %known = map { $_ => 1 } Langertha::Manifest::Endpoint->known_dialects;
  ok( $known{$_}, $_.' is a dialect Langertha knows' ) for sort keys %mapped, keys %unsupported;
  like( $class->unsupported_dialect('lmstudio'), qr/no tool calling/, 'lmstudio says why' );
  is( [ $class->engine_for_dialect('carrier-pigeon') ], [], 'no guess for an unknown dialect' );
};

subtest 'the default rule: one model, its endpoint, the dialect\'s engine' => sub {
  my $got = activate('/one.json');
  is( $got, {
    status       => 'completed',
    provider_id  => 'example-provider',
    manifest_url => $base.'/one.json',
    endpoint     => 'chat',
    dialect      => 'openai-chat',
    engine_name  => 'openai',
    engine_class => 'Langertha::Engine::OpenAI',
    url          => $base.'/v1',
    model        => 'm1',
    auth         => 'api',
    addresses       => ['127.0.0.1'],
    connect_address => '127.0.0.1',
    warnings        => [],
  }, 'the activation, without a credential in it' );
  is( activate( '/one.json', model => 'm1' )->{model}, 'm1', '-m naming the one model' );
  is( activate( '/two.json', model => 'b' )->{model}, 'b', '-m picks one of several' );
};

subtest 'model choice refusals' => sub {
  my $got = activate('/two.json');
  is( $got->{status}, 'usage', 'several models without -m: a command-line error' );
  like( $got->{error}, qr/lists several models; choose one with -m MODEL \(models: a, b\)/, 'lists the ids' );
  $got = activate( '/one.json', model => 'gpt-9' );
  is( $got->{status}, 'usage', 'a model the manifest does not list' );
  like( $got->{error}, qr/model 'gpt-9' is not in the manifest of example-provider \(models: m1\)/, 'says which exist' );
  $got = activate('/none.json');
  is( [ @$got{qw( status error )} ], [ 'failed', 'the manifest of example-provider lists no models' ], 'no models at all' );
  like( activate( '/none.json', model => 'm1' )->{error}, qr/\(it lists none\)/, '-m against an empty list' );
};

subtest 'a model on several endpoints' => sub {
  my $got = activate( '/multi.json', model => 'x' );
  is( [ @$got{qw( status endpoint dialect )} ], [ 'completed', 'chat', 'openai-chat' ],
    'the one endpoint raider has an adapter for' );
  $got = activate( '/multi.json', model => 'y' );
  is( $got->{status}, 'failed', 'two usable endpoints: no choice made' );
  like( $got->{error}, qr/model 'y' is offered on several endpoints \(chat: openai-chat, msg: anthropic\); raider does not choose/,
    'names them' );
  like( activate( '/multi.json', model => 'z' )->{error}, qr/dialect 'carrier-pigeon' is unknown/,
    'only on an unknown dialect' );
};

subtest 'dialect and auth refusals' => sub {
  my $got = activate('/pigeon.json');
  is( [ @$got{qw( status error )} ],
    [ 'failed', "endpoint 'chat': dialect 'carrier-pigeon' is unknown to this raider (no adapter for it)" ],
    'unknown dialect: no guessing' );
  $got = activate('/lmstudio.json');
  is( $got->{status}, 'failed', 'lmstudio: unsupported' );
  like( $got->{error}, qr/dialect 'lmstudio' is not supported: .*no tool calling/, 'says why' );
  $got = activate('/oauth.json');
  is( [ @$got{qw( status error )} ],
    [ 'failed', "endpoint 'chat': auth 'api' has type 'oauth2', which this raider cannot supply" ], 'unknown auth type' );
  $got = activate( '/one.json', has_api_key => 0 );
  is( [ @$got{qw( status error )} ],
    [ 'usage', "endpoint 'chat' needs an API key (auth 'api', type api_key); pass it with -k KEY" ], 'auth_ref without a key' );
  $got = activate( '/noauth.json', has_api_key => 0 );
  is( [ @$got{qw( status auth )} ], [ 'completed', undef ], 'an endpoint without auth needs no key' );
};

subtest 'origin refusals: another host, another port, plain http' => sub {
  my $got = activate('/cross.json');
  is( $got->{status}, 'refused', 'another host' );
  like( $got->{error}, qr{base_url https://other\.example/v1 is not of the origin the manifest came from \(https://provider\.example:\d+\); no credential goes to another origin},
    'says so' );
  is( activate('/port.json')->{status}, 'refused', 'another port' );
  $got = activate('/http.json');
  is( [ @$got{qw( status error )} ], [ 'refused', "endpoint 'chat': base_url http://$host/v1 is not https" ], 'plain http' );
};

subtest 'address policy: the endpoint host is checked at use time' => sub {
  my $got = activate( '/one.json', fetch => fetcher( allow_internal => 0 ) );
  is( $got->{status}, 'refused', 'an internal provider without --allow-internal' );
  like( $got->{error}, qr/provider\.example resolves to 127\.0\.0\.1 \(loopback address\); only --allow-internal/, 'says why' );

  # The name resolves to the released loopback for the manifest, then to
  # the metadata address when the endpoint is about to be used.
  my @answers = ( '127.0.0.1', '169.254.169.254' );
  $got = activate( '/one.json', fetch => fetcher( resolver => sub { Future->done( shift @answers ) } ) );
  is( $got->{status}, 'refused', 'the second resolution is checked too' );
  like( $got->{error}, qr/^endpoint 'chat': provider\.example resolves to 169\.254\.169\.254 \(metadata address\); never allowed/, 'says why' );

  my $missing = activate('/missing.json');
  is( [ $missing->{status}, $missing->{error} =~ /HTTP 404/ ? 1 : 0 ], [ 'failed', 1 ], 'a fetch failure is passed on' );
  my $bad = $class->new( fetch => fetcher() )->activate_f('http://provider.example')->get;
  is( $bad->{status}, 'usage', 'a target that is none' );
  like( $bad->{error}, qr/^only https is allowed for a provider manifest, not http:\/\/$/, 'without a file and line' );
};

subtest 'the address the engine is pinned to (k141)' => sub {
  # The manifest comes from 127.0.0.1; the use-time check sees two
  # addresses. Both passed, the first is the one the engine connects to.
  my @answers = ( ['127.0.0.1'], [ '127.0.0.3', '127.0.0.1' ] );
  my $got = activate( '/one.json', fetch => fetcher( resolver => sub { Future->done( @{ shift @answers } ) } ) );
  is( [ @$got{qw( status addresses connect_address )} ], [ 'completed', [ '127.0.0.3', '127.0.0.1' ], '127.0.0.3' ],
    'the first address of the use-time check' );

  @answers = ( ['127.0.0.1'], [ '127.0.0.1', '169.254.169.254' ] );
  $got = activate( '/one.json', fetch => fetcher( resolver => sub { Future->done( @{ shift @answers } ) } ) );
  is( $got->{status}, 'refused', 'one refused address refuses the host, even when the first one passes' );
  like( $got->{error}, qr/resolves to 169\.254\.169\.254 \(metadata address\)/, 'says which' );

  @answers = ( ['127.0.0.1'], [ 'fe80::1%lo', '127.0.0.1' ] );
  $got = activate( '/one.json', fetch => fetcher( resolver => sub { Future->done( @{ shift @answers } ) } ) );
  is( [ @$got{qw( status error )} ],
    [ 'failed', "endpoint 'chat': provider.example resolves first to fe80::1%lo, a scoped address the engine connection cannot be pinned to" ],
    'a scoped first address cannot be pinned: an error, not an unpinned engine' );

  my @asked;
  my $fetch = fetcher( resolver => sub { push @asked, @_; Future->done('127.0.0.1') } );
  $fetch->manifest_path('/one.json');
  $got = $class->new( fetch => $fetch )->activate_f( '127.0.0.1:'.$srv->port, has_api_key => 1 )->get;
  is( [ @$got{qw( status url addresses connect_address )} ],
    [ 'completed', 'https://127.0.0.1:'.$srv->port.'/v1', ['127.0.0.1'], '127.0.0.1' ], 'an address literal stands for itself' );
  is( \@asked, [], '... and is never resolved' );
};

subtest 'a model without tools_native: a warning' => sub {
  my $got = activate('/notools.json');
  is( $got->{status}, 'completed', 'still usable' );
  is( $got->{warnings}, [ "model 'm1' does not declare tools_native; raider works through tool calls" ], 'the warning' );
};

# The engine of each dialect, built like the run builds it: .raider.yml
# and the environment carry keys, URLs and a model for other providers.
my $root = Path::Tiny->tempdir;
my $yml = { api_key => 'yml-secret', url => 'https://api.example', model => 'yml-model', temperature => 0.3 };
$yml->{$_} = { api_key => 'yml-section-secret', url => 'https://section.example', connect_address => '198.51.100.9' }
  for qw( openai anthropic gemini ollama aki responses );
$root->child('.raider.yml')->spew_utf8( YAML::PP->new->dump_string($yml) );
my $config = Langertha::Raider::Config->new( root => "$root" );
my %env_keys = map { $_ => 'env-secret' }
  qw( OPENAI_API_KEY ANTHROPIC_API_KEY GEMINI_API_KEY LANGERTHA_OPENAI_API_KEY LANGERTHA_ANTHROPIC_API_KEY
      LANGERTHA_GEMINI_API_KEY LANGERTHA_OLLAMA_API_KEY LANGERTHA_AKI_API_KEY LANGERTHA_PERPLEXITY_API_KEY
      LANGERTHA_ANTHROPICBASE_API_KEY );

subtest 'engine class, url, model and key per dialect' => sub {
  local @ENV{ keys %env_keys } = values %env_keys;
  my %expect = (
    'openai-chat'      => [ openai             => 'Langertha::Engine::OpenAI' ],
    'responses'        => [ responses          => 'Langertha::Engine::OpenAIResponses' ],
    'perplexity-agent' => [ 'perplexity-agent' => 'Langertha::Engine::Perplexity' ],
    'anthropic'        => [ anthropic          => 'Langertha::Engine::Anthropic' ],
    'anthropic-compat' => [ 'anthropic-compat' => 'Langertha::Engine::AnthropicBase' ],
    'gemini'           => [ gemini             => 'Langertha::Engine::Gemini' ],
    'ollama'           => [ ollama             => 'Langertha::Engine::Ollama' ],
    'aki'              => [ aki                => 'Langertha::Engine::AKI' ],
  );
  is( [ sort keys %expect ], [ $class->mapped_dialects ], 'the table under test is the whole table' );
  for my $dialect ( sort keys %expect ) {
    my $got = activate( '/dialect-'.$dialect.'.json' );
    is( [ @$got{qw( status engine_name engine_class )} ], [ 'completed', @{ $expect{$dialect} } ], $dialect.': activation' )
      or do { diag( $dialect.': '.( $got->{error} // 'no error' ) ); next };
    for my $case ( [ 'cli-key', { api_key => 'cli-key' } ], [ undef, {} ] ) {
      my ( $key, $args ) = @$case;
      my $label = $dialect.( defined $key ? ' with -k' : ' without a key' );
      my $resolver = Langertha::Raider::EngineResolver->new(
        config => $config, provider => $got, engine_options => { temperature => 0.7, connect_address => '203.0.113.9' }, %$args );
      is( $resolver->engine_name, $expect{$dialect}[0], $label.': engine name' );
      is( $resolver->api_key_env, undef, $label.': no key variable' );
      my $engine = $resolver->build_engine;
      isa_ok( $engine, $expect{$dialect}[1] );
      is( $engine->url, $base.'/v1', $label.': url is the endpoint base_url, not .raider.yml\'s' );
      is( $engine->chat_model, 'm1', $label.': model from the manifest, not .raider.yml\'s' );
      is( $engine->api_key, $key, $label.': the key is only the command line\'s, never .raider.yml or the environment' );
      is( $engine->temperature, 0.7, $label.': other -o options apply as with -e' );
      is( Langertha::Manifest::Builder->dialect_for_engine($engine), $dialect,
        $label.': core names the engine by the same dialect' );
      is( $engine->user_agent->max_redirect, 0, $label.': the synchronous user agent follows no redirect' );
      is( $engine->connect_address, '127.0.0.1',
        $label.': pinned to the checked address, not to -o\'s or .raider.yml\'s (k141)' );
      isa_ok( $engine->user_agent, 'Langertha::HTTP::UserAgent' );
      is( [ map { $engine->user_agent->$_ } qw( connect_host connect_address ) ], [ 'provider.example', '127.0.0.1' ],
        $label.': the synchronous user agent carries the pin' );
      # Gemini puts the key in the query. The explicit api_key => undef the
      # resolver passes without -k makes it send none and read no
      # environment variable (core k376; before it warned and sent key=).
      my @warnings;
      my $request = do {
        local $SIG{__WARN__} = sub { push @warnings, @_ };
        $engine->chat_request( [ { role => 'user', content => 'hi' } ] );
      };
      is( \@warnings, [], $label.': no warning building the request' );
      like( $request->uri->as_string, qr{^\Q$base\E/v1/}, $label.': requests go to the endpoint' );
      if ( defined $key ) {
        like( $request->uri->as_string, qr/[?&]key=\Q$key\E(?:&|\z)/, $label.': Gemini carries the -k key in the query' )
          if $dialect eq 'gemini';
      }
      else {
        unlike( $request->uri->as_string, qr/[?&]key=/, $label.': no key parameter in the URL' );
      }
      unlike( $request->as_string, qr/secret/, $label.': no configured key in the request' );
    }
  }
};

subtest 'no unpinned engine in provider mode (k141)' => sub {
  my %activation = %{ activate('/one.json') };
  for my $address ( undef, '' ) {
    my $resolver = Langertha::Raider::EngineResolver->new(
      config => $config, provider => { %activation, connect_address => $address }, api_key => 'cli-key' );
    like( dies { $resolver->build_engine }, qr/the provider activation carries no connect_address; not building an unpinned engine/,
      'connect_address '.( defined $address ? "''" : 'undef' ).': croaks' );
  }
};

subtest 'without a provider the resolver is unchanged' => sub {
  local @ENV{ keys %env_keys } = values %env_keys;
  my $resolver = Langertha::Raider::EngineResolver->new( config => $config, engine => 'openai' );
  is( $resolver->api_key, 'yml-section-secret', '.raider.yml key as before' );
  is( { $resolver->engine_args }->{url}, 'https://section.example', '.raider.yml url as before' );
  is( $resolver->model, 'yml-model', '.raider.yml model as before' );
};

done_testing;
