use strict;
use warnings;
use Test2::V0;

# Regression (k42): a request that names no model (A2A always; ACP without
# agent_name, AG-UI, OpenAI, Anthropic and Ollama bodies without one) reached
# the default engine with the model 'default': Handler::Router filled in that
# placeholder and Router::resolve let the requested name override the
# default engine's own `model:`. A real upstream rejects 'default'. Now a
# request without a model gets the default engine's configured model, or the
# provider default when `default:` names none; a model the client does name
# still reaches the default engine as asked.
#
# Key-free: the default engine is an offline LangerthaX fake that records the
# model it was built with.

BEGIN {
  package LangerthaX::Engine::TestKnarrDefault;
  use Future;
  use Langertha::Response;
  our $engine_default = 'provider-default';
  sub new { my ($class, %args) = @_; bless \%args, $class }
  sub built_model { $_[0]{model} }
  sub chat_model { $_[0]{model} // $engine_default }
  sub chat_f {
    my ($self) = @_;
    return Future->done( Langertha::Response->new(
      content => 'sent as ' . ( $self->{model} // '(none)' ),
      raw     => {},
    ) );
  }
  $INC{'LangerthaX/Engine/TestKnarrDefault.pm'} = __FILE__;
}

use Langertha::Knarr::Config;
use Langertha::Knarr::Router;
use Langertha::Knarr::Session;
use Langertha::Knarr::Handler::Router;
use Langertha::Knarr::Handler::Passthrough;
use Langertha::Knarr::Protocol::OpenAI;
use Langertha::Knarr::Protocol::A2A;
use Langertha::Knarr::Protocol::ACP;
use Langertha::Knarr::Protocol::AGUI;
use HTTP::Request;
use JSON::MaybeXS;

my $json    = JSON::MaybeXS->new( utf8 => 1, canonical => 1 );
my $session = Langertha::Knarr::Session->new( id => 's' );
my $http    = HTTP::Request->new( POST => '/' );

sub router_for {
  my (%default) = @_;
  my $config = Langertha::Knarr::Config->new( data => {
    auto_discover => 0,
    models        => {},
    default       => { engine => 'TestKnarrDefault', %default },
  } );
  return Langertha::Knarr::Router->new( config => $config );
}

# Model-less requests as each protocol parses them off the wire.
my %request = (
  a2a => sub {
    Langertha::Knarr::Protocol::A2A->new->parse_chat_request( $http, \$json->encode({
      jsonrpc => '2.0', id => 1, method => 'tasks/send',
      params  => { id => 't1', message => { role => 'user', parts => [ { type => 'text', text => 'hi' } ] } },
    }) );
  },
  acp => sub {
    Langertha::Knarr::Protocol::ACP->new->parse_chat_request( $http, \$json->encode({
      input => [ { parts => [ { content => 'hi' } ] } ],
    }) );
  },
  agui => sub {
    Langertha::Knarr::Protocol::AGUI->new->parse_chat_request( $http, \$json->encode({
      threadId => 'th', runId => 'r', messages => [ { role => 'user', content => 'hi' } ],
    }) );
  },
  openai => sub {
    Langertha::Knarr::Protocol::OpenAI->new->parse_chat_request( $http, \$json->encode({
      messages => [ { role => 'user', content => 'hi' } ],
    }) );
  },
);

# --- Router::resolve: no model name → the default engine as configured ---
{
  my $router = router_for( model => 'gpt-cfg' );
  for my $none ( undef, '' ) {
    my ($engine, $model, $alias_only) = $router->resolve($none);
    is $engine->built_model, 'gpt-cfg', 'no model: engine built with default\'s model ('.( $none // 'undef' ).')';
    is $model, 'gpt-cfg', 'no model: resolved model is default\'s model';
    ok !$alias_only, 'no model: not alias-only';
    is [ $router->resolve( $none, skip_default => 1 ) ], [], 'no model + skip_default: nothing';
  }

  my ($engine, $model) = $router->resolve('gpt-asked');
  is $engine->built_model, 'gpt-asked', 'named model still overrides default\'s model';
  is $model, 'gpt-asked', 'named model resolved as asked';

  my $bare = router_for();
  my ($be, $bm, $balias) = $bare->resolve(undef);
  is $be->built_model, undef, 'default without model: engine built without one';
  ok $balias, 'default without model: alias-only (provider default answers)';

  my $none = Langertha::Knarr::Router->new( config => Langertha::Knarr::Config->new );
  like dies { $none->resolve(undef) }, qr/No model specified/, 'no model, no default engine: croaks';
}

# --- Handler::Router: every model-less protocol reaches default's model ---
{
  my $h = Langertha::Knarr::Handler::Router->new( router => router_for( model => 'gpt-cfg' ) );
  for my $proto ( sort keys %request ) {
    my $req = $request{$proto}->();
    is $req->model, undef, "$proto: request carries no model";
    my $r = $h->handle_chat_f( $session, $req )->get;
    is $r->content, 'sent as gpt-cfg', "$proto: default engine used its configured model";
    is $r->model, 'gpt-cfg', "$proto: answer labeled with the configured model";

    my $s = $h->handle_stream_f( $session, $request{$proto}->() )->get;
    my $text = '';
    while ( defined( my $c = $s->next_chunk_f->get ) ) { $text .= $c }
    is $text, 'sent as gpt-cfg', "$proto stream: default engine used its configured model";
  }

  my $named = Langertha::Knarr::Protocol::OpenAI->new->parse_chat_request( $http, \$json->encode({
    model => 'gpt-asked', messages => [ { role => 'user', content => 'hi' } ],
  }) );
  my $r = $h->handle_chat_f( $session, $named )->get;
  is $r->content, 'sent as gpt-asked', 'openai: a named model reaches the default engine as asked';
}

# --- default: without model: → provider default, never 'default' ---
{
  my $h = Langertha::Knarr::Handler::Router->new( router => router_for() );
  my $r = $h->handle_chat_f( $session, $request{a2a}->() )->get;
  is $r->content, 'sent as (none)', 'a2a: default engine built without a model';
  is $r->model, 'provider-default', 'a2a: answer labeled with the engine default';
}

# --- With a passthrough that does not serve the protocol: default engine ---
{
  my $h = Langertha::Knarr::Handler::Router->new(
    router      => router_for( model => 'gpt-cfg' ),
    passthrough => Langertha::Knarr::Handler::Passthrough->new(
      upstreams => { openai => 'http://127.0.0.1:9/v1' },
    ),
  );
  for my $proto (qw( a2a acp agui )) {
    my $r = $h->handle_chat_f( $session, $request{$proto}->() )->get;
    is $r->content, 'sent as gpt-cfg', "$proto + passthrough: default engine used its configured model";
  }
}

done_testing;
