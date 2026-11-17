#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use Test::More;
use Test::Fatal qw( exception );
use Langertha::Engine::Virtual;
use Langertha::Virtual::Rules qw( answer error );
use Langertha::Holmgang::Target;

# k16: a target that rejects a request because it exceeds its context window
# is its own status (context_exceeded), one that cannot see an image is
# no_vision (k27), every other failure is error (ADR 0006). The signatures and
# negatives are cai-platform's t/eval_context_exceeded.t (af7561a5), here as
# real failed requests of a Virtual engine; network-free.

my $USER = [ { role => 'user', content => 'Bitte pruefen.' } ];

sub target_with {
  my ( $reaction, %o ) = @_;
  return Langertha::Holmgang::Target->new(
    engine => Langertha::Engine::Virtual->new( rules => [ qr/./ => $reaction ] ),
    %o,
  );
}

sub turn {
  my ( $target, %o ) = @_;
  my $f = $target->chat_turn_f( messages => $USER, %o );
  ok $f->is_done, 'the Future is done, not failed';
  return $f->get;
}

subtest 'context window: backend signatures' => sub {
  my @yes = (
    [ OpenAI     => q({"error":{"code":"context_length_exceeded","message":"…"}}) ],
    [ vLLM       => q({"message":"This model's maximum context length is 32768 tokens. However, you requested 40000 tokens"}) ],
    [ 'vLLM v1'  => q({"message":"The decoder prompt (length 40000) is longer than the maximum model length of 32768."}) ],
    [ 'vLLM max_model_len' => q({"message":"max_tokens must be at most max_model_len - prompt tokens"}) ],
    [ 'llama.cpp' => q({"error":{"code":400,"message":"the request exceeds the available context size, try increasing it","type":"exceed_context_size_error"}}) ],
    [ SGLang     => q({"error":"The input (40000 tokens) is longer than the model's context length (32768 tokens)."}) ],
    [ TGI        => q({"error":"Input validation error: `inputs` tokens + `max_new_tokens` must be <= 32768. Given: 40000"}) ],
    [ LiteLLM    => q({"error":{"message":"litellm.ContextWindowExceededError: …"}}) ],
    [ Ollama     => q({"error":"input length exceeds the context length"}) ],
    [ Anthropic  => q({"type":"error","error":{"type":"invalid_request_error","message":"prompt is too long: 210000 tokens > 200000 maximum"}}) ],
    [ generic    => q({"error":"context window exceeded"}) ],
  );
  for my $sig (@yes) {
    my ( $backend, $body ) = @$sig;
    my $turn = turn( target_with( error( 400, $body ) ) );
    is $turn->{error_class}, 'context_exceeded', $backend;
    is $turn->{response}, undef, "$backend: no response";
    like $turn->{error}, qr/\A\S+ request failed: 400 Bad Request - /, "$backend: Langertha's error text";
  }
};

subtest 'no vision: signatures, and they win over context_exceeded' => sub {
  my @yes = (
    [ 'llama.cpp' => q({"error":{"code":500,"message":"image input is not supported - hint: if this is unexpected, you may need to provide the mmproj","type":"server_error"}}) ],
    [ vLLM        => q({"object":"error","message":"Qwen/Qwen3-8B is not a multimodal model","type":"BadRequestError","code":400}) ],
  );
  for my $sig (@yes) {
    my ( $backend, $body ) = @$sig;
    is turn( target_with( error( 400, $body ) ) )->{error_class}, 'no_vision', $backend;
  }
  is +Langertha::Holmgang::Target->classify_error(
    'image input is not supported; also the maximum context length is 4096' ),
    'no_vision', 'both match: no_vision first (ADR 0006 precedence)';
};

subtest 'negatives' => sub {
  my $turn = turn( target_with( error( 500, 'upstream down' ) ) );
  is $turn->{error_class}, 'error', '500 without a hint: error';
  is $turn->{error}, 'Langertha::Engine::Virtual request failed: 500 Internal Server Error - upstream down',
    'error text kept, without die\'s location';

  $turn = turn( target_with( sub { die "read timeout\n" } ) );
  is $turn->{error_class}, 'error', 'timeout: error';
  like $turn->{error}, qr/read timeout/, 'timeout text kept';

  $turn = turn( target_with( answer("This model's maximum context length is 32768 tokens.") ) );
  is $turn->{error_class}, undef, '200 mentioning the phrase: no class';
  is $turn->{error}, undef, '... and no error';
  isa_ok $turn->{response}, 'Langertha::Response';
  like $turn->{response}->content, qr/maximum context length/, '... the answer is the response';

  is +Langertha::Holmgang::Target->classify_error(undef), 'error', 'no text: error';
  is +Langertha::Holmgang::Target->classify_error(''),    'error', 'empty text: error';
};

subtest 'a signature past Langertha\'s 500-character cut is found' => sub {
  my $body = '{"error":{"detail":"' . ( 'x' x 900 ) . '","message":"This model\'s maximum context length is 32768 tokens."}}';
  my $before = $Langertha::Role::HTTP::error_body_max_length;
  my $turn = turn( target_with( error( 400, $body ) ) );
  is $turn->{error_class}, 'context_exceeded', 'classified on the uncut body';
  cmp_ok length $turn->{error}, '>', 900, 'error text not cut at 500';
  is $Langertha::Role::HTTP::error_body_max_length, $before, 'Langertha\'s limit restored after the call';

  my $plain = Langertha::Engine::Virtual->new( rules => [ qr/./ => error( 400, $body ) ] );
  my $cut = ( $plain->chat_f( messages => $USER )->failure )[0];
  unlike $cut, qr/maximum context length/, 'control: without the target Langertha cuts it off';
};

subtest 'variant settings go into every request and win' => sub {
  my $engine = Langertha::Engine::Virtual->new( rules => [ qr/./ => answer('ok') ] );
  my $target = Langertha::Holmgang::Target->new( engine => $engine,
    variant => { max_tokens => 4000, chat_template_kwargs => { enable_thinking => 0 } } );
  turn( $target, max_tokens => 512, seed => 7 );
  my $body = $engine->requests->[0]{body};
  is $body->{max_tokens}, 4000, 'variant max_tokens beats the turn\'s';
  is $body->{seed}, 7, 'turn option passed through';
  is_deeply $body->{chat_template_kwargs}, { enable_thinking => 0 }, 'extra variant field on the wire';

  my $bare = Langertha::Holmgang::Target->new( engine => $engine );
  is_deeply $bare->variant, {}, 'variant defaults to {}';
};

subtest 'a croak instead of a Future is a failed turn' => sub {
  {
    package Local::Croaks;
    sub new    { bless {}, shift }
    sub chat_f { die "Local::Croaks: tools together with response_format are refused\n" }
  }
  {
    package Local::NoFuture;
    sub new    { bless {}, shift }
    sub chat_f { 'not a future' }
  }
  my $turn = turn( Langertha::Holmgang::Target->new( engine => Local::Croaks->new ) );
  is $turn->{error_class}, 'error', 'croak before the request: error';
  like $turn->{error}, qr/refused\z/, 'croak text kept, trailing newline removed';
  $turn = turn( Langertha::Holmgang::Target->new( engine => Local::NoFuture->new ) );
  is $turn->{error_class}, 'error', 'no Future from chat_f: error';
};

subtest 'constructor checks' => sub {
  like exception { Langertha::Holmgang::Target->new }, qr/engine/, 'engine required';
  like exception { Langertha::Holmgang::Target->new( engine => {} ) }, qr/engine must be/, 'engine must have chat_f';
  like exception { Langertha::Holmgang::Target->new( engine => Local::Croaks->new, variant => [] ) },
    qr/variant must be a HashRef/, 'variant must be a HashRef';
};

subtest 'scrub: what goes and what stays (k38)' => sub {
  my $T = 'Langertha::Holmgang::Target';
  my @cases = (
    [ 'die location, anywhere',
      'boom at /home/x/lib/A.pm line 3. then Carp::croak(...) called at /home/x/b.pl line 9',
      'boom then Carp::croak(...) called' ],
    [ 'die location with the line of a read handle (k42)',
      'no input at lib/A.pm line 3, <$fh> line 7. and at b.pl line 2, <DATA> chunk 1.',
      'no input and' ],
    [ 'absolute paths',
      'cannot open /srv/models/m.gguf, see ~/.config/x/y.json or C:\Users\me\key.txt',
      'cannot open <path>, see <path> or <path>' ],
    [ 'URL credentials and query keys, the URL kept',
      'GET https://u:p@llm.invalid/v1/models?key=AAA&alt=json&access_token=BBB#x',
      'GET https://***@llm.invalid/v1/models?key=***&alt=json&access_token=***#x' ],
    [ 'header values',
      'Authorization: Bearer abc.def x-goog-api-key: K1 "api_key":"K2" Authorization: Basic dXNlcg== echo: bearer zz9',
      'Authorization: Bearer *** x-goog-api-key: *** "api_key":"***" Authorization: Basic *** echo: bearer ***' ],
    [ 'key shapes',
      'Incorrect API key provided: sk-proj-FAKEFAKEFAKEFAKE00, also AIzaFAKEFAKEFAKEFAKEFAKEFAKEFAKEFAKE00',
      'Incorrect API key provided: ***, also ***' ],
    [ 'nothing to scrub: unchanged',
      'Langertha::Engine::Virtual request failed: 500 Internal Server Error - 1/2 of tokens/s and/or {"a":1}',
      'Langertha::Engine::Virtual request failed: 500 Internal Server Error - 1/2 of tokens/s and/or {"a":1}' ],
  );
  is $T->scrub( $_->[1] ), $_->[2], $_->[0] for @cases;
  is $T->scrub(undef), undef, 'undef stays undef';

  my $t = Langertha::Holmgang::Target->new(
    engine => Langertha::Engine::Virtual->new( rules => [], api_key => 'odd-FAKE-key' ) );
  is $t->scrub('echo odd-FAKE-key and odd-FAKE-key'), 'echo *** and ***', 'the engine\'s own key, of any shape';
  is +Langertha::Holmgang::Target->new( engine => Langertha::Engine::Virtual->new( rules => [], api_key => 'abc' ) )
    ->scrub('abc def'), 'abc def', 'a key under 4 characters is not hunted (cai-platform)';

  my $turn = turn( Langertha::Holmgang::Target->new(
    engine => Langertha::Engine::Virtual->new( api_key => 'odd-FAKE-key', rules => [ qr/./ => error( 400,
      'maximum context length exceeded for /srv/m.gguf, key odd-FAKE-key' ) ] ) ) );
  is $turn->{error_class}, 'context_exceeded', 'the turn: classified';
  like $turn->{error}, qr/maximum context length exceeded for <path>, key \*\*\*\z/, '... and its error text scrubbed';
};

done_testing;
