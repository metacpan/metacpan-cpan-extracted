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
use Langertha::Knarr::Protocol::Ollama;
use Langertha::Response;
use Langertha::Engine::OpenAI;
use Langertha::Engine::Ollama;

# Guards the routed-path per-request control contract for seed,
# parallel_tool_use and prompt_cache_key (karr #4, "alle gaten").
#
# reasoning_effort (t/29) was the first of these controls. These three are
# the rest that have a native inbound wire field to read: each protocol
# parser lifts the field only where its wire actually carries it (OpenAI's
# top-level seed / parallel_tool_calls / prompt_cache_key, Ollama's
# options.seed), and chat_f_args forwards it to chat_f only when the target
# engine advertises the matching capability. Langertha then places it on the
# engine's own wire. The gate is strict on purpose: a control is dropped onto
# an engine whose role inventory does not advertise it, even where that
# engine's wire would technically accept the field (e.g. seed on OpenAI).
#
# Key-free and no network: the round-trip uses a fake CaptureEngine, and the
# wire-contract checks only build a Langertha::Request::HTTP object that is
# never sent.

# Records the args chat_f received and reports capabilities (t/25 pattern).
{
  package CaptureEngine;
  use Moose;
  has chat_model => ( is => 'ro', default => 'cap-1' );
  has captured   => ( is => 'rw' );
  has caps       => ( is => 'ro', default => sub {
    { seed => 1, parallel_tool_use => 1, prompt_cache_key => 1 }
  });
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

# Runs one request through the Engine handler with the given caps and returns
# the args chat_f captured. %req_extra sets the control attribute under test.
sub _captured {
  my ( $caps, %req_extra ) = @_;
  my $engine = CaptureEngine->new( caps => $caps );
  my $h = Langertha::Knarr::Handler::Engine->new( engine => $engine );
  my $req = Langertha::Knarr::Request->new(
    protocol => 'openai',
    model    => 'cap-1',
    messages => [ { role => 'user', content => 'hi' } ],
    %req_extra,
  );
  $h->handle_chat_f( Langertha::Knarr::Session->new( id => 's' ), $req )->get;
  return $engine->captured;
}

subtest 'seed' => sub {
  is _captured( { seed => 1 }, seed => 42 )->{seed}, 42,
    'seed forwarded when the engine advertises the seed capability';
  ok !exists _captured( { seed => 0 }, seed => 42 )->{seed},
    'seed dropped when the engine lacks the seed capability';

  my $proto = 'Langertha::Knarr::Protocol::OpenAI'->new;
  my $body  = encode_json({
    model    => 'gpt-4o',
    messages => [ { role => 'user', content => 'hi' } ],
    seed     => 7,
  });
  is $proto->parse_chat_request(
    HTTP::Request->new( POST => '/v1/chat/completions' ), \$body
  )->seed, 7, 'OpenAI protocol lifts the top-level seed';

  my $ol_proto = 'Langertha::Knarr::Protocol::Ollama'->new;
  my $ol_body  = encode_json({
    model    => 'llama3',
    messages => [ { role => 'user', content => 'hi' } ],
    options  => { seed => 9 },
  });
  is $ol_proto->parse_chat_request(
    HTTP::Request->new( POST => '/api/chat' ), \$ol_body
  )->seed, 9, 'Ollama protocol lifts options.seed';

  # Wire contract: an engine that advertises seed places it. Ollama is the one
  # of the three target wire formats whose role inventory advertises seed, and
  # it nests it under options.
  my $engine = Langertha::Engine::Ollama->new( url => 'http://x/', model => 'llama3' );
  ok $engine->supports('seed'), 'Ollama advertises the seed capability';
  my $request = $engine->chat_request(
    $engine->chat_messages( { role => "user", content => "hi" } ),
    controls => { seed => 123 },
  );
  is decode_json( $request->content )->{options}{seed}, 123,
    'seed lands under Ollama options on the wire';

  # The deliberate asymmetry of "alle gaten": OpenAI's wire accepts seed, but
  # its role inventory does not advertise the capability, so the gate drops it.
  ok !Langertha::Engine::OpenAI->new( api_key => 'x', model => 'gpt-4o' )->supports('seed'),
    'OpenAI does not advertise seed, so a routed seed is gated out';
};

subtest 'parallel_tool_use' => sub {
  is _captured( { parallel_tool_use => 1 }, parallel_tool_use => 0 )->{parallel_tool_use}, 0,
    'a false parallel_tool_use is forwarded (defined, not dropped)';
  is _captured( { parallel_tool_use => 1 }, parallel_tool_use => 1 )->{parallel_tool_use}, 1,
    'a true parallel_tool_use is forwarded';
  ok !exists _captured( { parallel_tool_use => 0 }, parallel_tool_use => 1 )->{parallel_tool_use},
    'parallel_tool_use dropped when the engine lacks the capability';

  my $proto = 'Langertha::Knarr::Protocol::OpenAI'->new;
  my $body  = encode_json({
    model                => 'gpt-4o',
    messages             => [ { role => 'user', content => 'hi' } ],
    parallel_tool_calls  => JSON::MaybeXS::false(),
  });
  my $req = $proto->parse_chat_request(
    HTTP::Request->new( POST => '/v1/chat/completions' ), \$body
  );
  ok defined $req->parallel_tool_use, 'OpenAI protocol lifts parallel_tool_calls (present)';
  ok !$req->parallel_tool_use, '... and preserves its false value';

  # Wire contract: OpenAI serialises parallel_tool_use as parallel_tool_calls,
  # but only when tools are present.
  my $engine = Langertha::Engine::OpenAI->new( api_key => 'x', model => 'gpt-4o' );
  ok $engine->supports('parallel_tool_use'), 'OpenAI advertises parallel_tool_use';
  my $request = $engine->chat_request(
    $engine->chat_messages( { role => "user", content => "hi" } ),
    controls => { parallel_tool_use => 0 },
    tools    => [ { type => 'function', function => { name => 'f', parameters => { type => 'object' } } } ],
  );
  my $decoded = decode_json( $request->content );
  ok exists $decoded->{parallel_tool_calls}, 'parallel_tool_calls on the OpenAI wire';
  ok !$decoded->{parallel_tool_calls}, '... carrying the disabled value';
};

subtest 'prompt_cache_key' => sub {
  is _captured( { prompt_cache_key => 1 }, prompt_cache_key => 'route-7' )->{prompt_cache_key}, 'route-7',
    'prompt_cache_key forwarded when the engine advertises the capability';
  ok !exists _captured( { prompt_cache_key => 0 }, prompt_cache_key => 'route-7' )->{prompt_cache_key},
    'prompt_cache_key dropped when the engine lacks the capability';

  my $proto = 'Langertha::Knarr::Protocol::OpenAI'->new;
  my $body  = encode_json({
    model            => 'gpt-4o',
    messages         => [ { role => 'user', content => 'hi' } ],
    prompt_cache_key => 'route-7',
  });
  is $proto->parse_chat_request(
    HTTP::Request->new( POST => '/v1/chat/completions' ), \$body
  )->prompt_cache_key, 'route-7', 'OpenAI protocol lifts the top-level prompt_cache_key';

  # Wire contract: OpenAI serialises it flat as prompt_cache_key.
  my $engine = Langertha::Engine::OpenAI->new( api_key => 'x', model => 'gpt-4o' );
  ok $engine->supports('prompt_cache_key'), 'OpenAI advertises prompt_cache_key';
  my $request = $engine->chat_request(
    $engine->chat_messages( { role => "user", content => "hi" } ),
    controls => { prompt_cache_key => 'route-7' },
  );
  is decode_json( $request->content )->{prompt_cache_key}, 'route-7',
    'prompt_cache_key lands flat on the OpenAI wire';
};

done_testing;
