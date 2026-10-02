use strict;
use warnings;
use Test2::V0;
use Future;
use JSON::MaybeXS;
use HTTP::Request;

use Langertha::Knarr::Session;
use Langertha::Knarr::Request;
use Langertha::Knarr::Response;
use Langertha::Knarr::Handler::Engine;
use Langertha::Knarr::Protocol::OpenAI;
use Langertha::Response;
use Langertha::Engine::OpenAI;
use Langertha::Engine::Anthropic;

# Guards the routed-path per-request reasoning_effort contract (karr #4).
#
# On the routed path Knarr dropped control fields that would survive raw
# passthrough. reasoning_effort is the first of those to be forwarded:
# parse_chat_request lifts the OpenAI top-level reasoning_effort into the
# Request, and chat_f_args passes it to chat_f only when the target engine
# reports the reasoning_effort capability. Langertha then places it on the
# engine's own wire (top-level reasoning_effort on OpenAI).
#
# Key-free and no network: the round-trip uses a fake CaptureEngine, and the
# wire-contract check only builds a Langertha::Request::HTTP object -- it is
# never sent.

# Records the args chat_f received and reports capabilities (t/25 pattern).
{
  package CaptureEngine;
  use Moose;
  has chat_model => ( is => 'ro', default => 'cap-1' );
  has captured   => ( is => 'rw' );
  has caps       => ( is => 'ro', default => sub { { reasoning_effort => 1 } } );
  sub supports { $_[0]->caps->{ $_[1] } ? 1 : 0 }
  sub chat_f {
    my ($self, %args) = @_;
    $self->captured(\%args);
    return Future->done(
      Langertha::Response->new( content => 'ok', model => 'cap-1' )
    );
  }
  sub simple_chat_f { $_[0]->chat_f( messages => [ @_[1..$#_] ] ) }
  __PACKAGE__->meta->make_immutable;
}

sub _captured_reasoning_effort {
  my ($caps) = @_;
  my $engine = CaptureEngine->new( caps => $caps );
  my $h = Langertha::Knarr::Handler::Engine->new( engine => $engine );
  my $req = Langertha::Knarr::Request->new(
    protocol         => 'openai',
    model            => 'cap-1',
    messages         => [ { role => 'user', content => 'hi' } ],
    reasoning_effort => 'high',
  );
  $h->handle_chat_f( Langertha::Knarr::Session->new( id => 's' ), $req )->get;
  return $engine->captured;
}

subtest 'reasoning_effort forwarded when engine supports it' => sub {
  my $cap = _captured_reasoning_effort( { reasoning_effort => 1 } );
  is $cap->{reasoning_effort}, 'high', 'reasoning_effort reached chat_f';
};

subtest 'reasoning_effort dropped when engine lacks the capability' => sub {
  my $cap = _captured_reasoning_effort( { reasoning_effort => 0 } );
  ok !exists $cap->{reasoning_effort}, 'reasoning_effort dropped, no leak';
};

subtest 'OpenAI protocol parses top-level reasoning_effort into the Request' => sub {
  my $proto = 'Langertha::Knarr::Protocol::OpenAI';
  # Minimal HTTP::Request stand-in: parse_chat_request only reads headers.
  my $http_req = HTTP::Request->new( POST => '/v1/chat/completions' );
  my $body = encode_json({
    model            => 'gpt-4o',
    messages         => [ { role => 'user', content => 'hi' } ],
    reasoning_effort => 'high',
  });
  my $req = $proto->new->parse_chat_request( $http_req, \$body );
  is $req->reasoning_effort, 'high', 'reasoning_effort lifted from the wire body';
};

subtest 'Wire contract: reasoning_effort lands top-level in the OpenAI body' => sub {
  my $engine = Langertha::Engine::OpenAI->new( api_key => 'x', model => 'gpt-4o' );
  ok $engine->supports('reasoning_effort'), 'OpenAI reports the reasoning_effort capability';
  my $request = $engine->chat_request(
    $engine->chat_messages( { role => 'user', content => 'hi' } ),
    controls => { reasoning_effort => 'high' },
  );
  my $decoded = decode_json( $request->content );
  is $decoded->{reasoning_effort}, 'high', 'top-level reasoning_effort on the OpenAI wire';
};

subtest 'Cross-protocol: Anthropic engine also reports the capability' => sub {
  my $engine = Langertha::Engine::Anthropic->new( api_key => 'x', model => 'claude-sonnet-4-6' );
  ok $engine->supports('reasoning_effort'),
    'an OpenAI reasoning_effort request routes correctly onto an Anthropic engine';
};

done_testing;
