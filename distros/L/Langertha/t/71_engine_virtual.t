#!/usr/bin/env perl
# ABSTRACT: Langertha::Engine::Virtual answers by rules, by script and by preset, without a network

use strict;
use warnings;
use utf8;

use Test2::Bundle::More;
use Path::Tiny;
use LWP::Protocol;

use Langertha;
use Langertha::Engine::Virtual;
use Langertha::Engine::Mock;
use Langertha::Virtual::Rules qw( answer tool tools after );

# The virtual engine replaces the ad-hoc mock engines of the test suites
# (langertha-raider's Test::Raider::MockAI, t/64's scripted HTTP): a test
# states the replies it wants as rules, and everything above the transport --
# request building, the OpenAI-dialect parser, Response, the tool loops --
# runs for real. These tests pin the rule language as documented in the POD
# (exact string, Regexp captures, predicate, after, fallback, script, presets,
# rules_file), that a request no rule answers fails loudly instead of
# answering something, and that nothing reaches the network.

my $data_dir = path(__FILE__)->parent->child('data');

# Every request must be answered in-process: LWP never picks a protocol.
{
  no warnings 'redefine';
  *LWP::Protocol::create = sub { die "Langertha::Engine::Virtual opened a network protocol\n" };
}

sub chat {
  my ( $engine, @messages ) = @_;
  return $engine->chat_f( messages => \@messages )->get;
}

sub user { return { role => 'user', content => $_[0] } }

# A conversation that ends with the results of one assistant turn's calls.
sub after_tools {
  my ( $prompt, @calls ) = @_;
  my $id = 0;
  my @ids = map { 'c'.++$id } @calls;
  return (
    user($prompt),
    { role => 'assistant', content => undef, tool_calls => [ map {
      { id => $ids[$_], type => 'function', function => { name => $calls[$_][0], arguments => '{}' } }
    } 0 .. $#calls ] },
    map { { role => 'tool', tool_call_id => $ids[$_], content => $calls[$_][1] } } 0 .. $#calls,
  );
}

subtest 'an exact string trigger matches only the exact text of the last user message' => sub {
  my $engine = Langertha::Engine::Virtual->new(
    rules    => [ 'Hello' => answer('Hi there!') ],
    fallback => answer('no match'),
  );
  my $response = $engine->simple_chat('Hello');
  isa_ok( $response, ['Langertha::Response'], 'simple_chat gives a Response' );
  is( "$response", 'Hi there!', 'exact text answers' );
  is( $response->finish_reason, 'stop', 'a text reply finishes with stop' );
  is( $response->model, 'virtual', 'the default model comes back' );
  is( $engine->simple_chat('hello'), 'no match', 'no case folding' );
  is( $engine->simple_chat('Hello '), 'no match', 'no trimming' );
  is( $engine->simple_chat('Hello there'), 'no match', 'no prefix match' );
  is( chat( $engine, user('Hello'), { role => 'assistant', content => 'Hi there!' } ), 'no match',
    'a string trigger looks at the last message only' );
  is( chat( $engine, user('Hello'), user('Again') ), 'no match', 'the last user message, not an earlier one' );
  is( chat( $engine, { role => 'user', content => [ { type => 'text', text => 'Hello' } ] } ), 'Hi there!',
    'a content-part list is matched by its text' );
};

subtest 'a Regexp trigger passes its captures to a sub reaction' => sub {
  my @seen;
  my $engine = Langertha::Engine::Virtual->new(
    rules => [
      qr/\AAdd (\d+) and (\d+)\z/ => sub {
        my ( $request, @captures ) = @_;
        push @seen, [ $request->{text}, @captures ];
        return answer( $captures[0] + $captures[1] );
      },
      qr/\Aping\z/ => 'pong',
    ],
  );
  is( $engine->simple_chat('Add 7 and 15'), '22', 'the sub computed from the captures' );
  is_deeply( \@seen, [ [ 'Add 7 and 15', 7, 15 ] ], 'request first, then the captures in order' );
  is( $engine->simple_chat('ping'), 'pong', 'a Regexp without groups matches; a plain string reaction answers' );
};

subtest 'a sub reaction sees the request and may return any reaction' => sub {
  my $request;
  my $engine = Langertha::Engine::Virtual->new(
    model         => 'my-model',
    system_prompt => 'Be brief.',
    rules         => [ 'Inspect' => sub { ($request) = @_; return { answer => 'seen', tool_calls => [ [ 'probe', { x => 1 } ] ] } } ],
  );
  my $response = chat( $engine, user('Inspect') );
  is( $response->content, 'seen', 'text and calls in one reply: the text' );
  is( $response->tool_call->name, 'probe', 'text and calls in one reply: the call' );
  is( $response->finish_reason, 'tool_calls', 'a reply with calls finishes with tool_calls' );
  is( $request->{text}, 'Inspect', 'text is the last user message' );
  is( $request->{last_user_text}, 'Inspect', 'last_user_text too' );
  is( $request->{number}, 1, 'the first request' );
  is( $request->{model}, 'my-model', 'the model the request named' );
  is_deeply( [ map { $_->{role} } @{ $request->{messages} } ], [qw( system user )], 'the system prompt went along' );
  is_deeply( $request->{tool_results}, [], 'no tool results' );
  is( $response->model, 'my-model', 'the model comes back' );
};

subtest 'a sub trigger is a predicate over the request' => sub {
  my $engine = Langertha::Engine::Virtual->new(
    rules => [
      sub { my ($request) = @_; @{ $request->{messages} } > 2 } => answer('long conversation'),
      sub { 0 } => answer('never'),
    ],
    fallback => answer('short'),
  );
  is( $engine->simple_chat('one'), 'short', 'false predicate: next rule, then fallback' );
  is( chat( $engine, user('a'), { role => 'assistant', content => 'b' }, user('c') ), 'long conversation',
    'true predicate answers' );
};

subtest 'the first matching rule wins' => sub {
  my $engine = Langertha::Engine::Virtual->new(
    rules => [ qr/\Ago/ => answer('regexp'), 'go' => answer('string') ],
  );
  is( $engine->simple_chat('go'), 'regexp', 'earlier rule answers' );
};

subtest 'after rules answer the turn that ends in tool results' => sub {
  my @captured;
  my $engine = Langertha::Engine::Virtual->new(
    rules => [
      'List'                                           => tool( ls => {} ),
      after( tool => 'bash', result => qr/Exit code: (\d+)/ ) => sub {
        my ( $request, @captures ) = @_;
        push @captured, [@captures];
        return answer( 'bash said '.$captures[0] );
      },
      after( tool => qr/\A(read)_file\z/ ) => sub { my ( $request, $verb ) = @_; return answer("did $verb") },
      after('ls')                                      => sub {
        my ($request) = @_;
        my ($ls) = grep { $_->{name} eq 'ls' } @{ $request->{tool_results} };
        return answer( 'files: '.$ls->{content} );
      },
      after()                                          => answer('some tool'),
    ],
    fallback => answer('fallback'),
  );
  is( chat( $engine, after_tools( 'List', [ ls => 'a.txt b.txt' ] ) ), 'files: a.txt b.txt',
    'the tool name selects the rule; the string trigger of the prompt does not fire again' );
  is( chat( $engine, after_tools( 'Run', [ bash => "Exit code: 3\nboom" ] ) ), 'bash said 3',
    'the result Regexp captures' );
  is_deeply( \@captured, [ [3] ], 'only the result captures, no tool captures for a string tool' );
  is( chat( $engine, after_tools( 'Read', [ read_file => 'x' ] ) ), 'did read', 'tool name Regexp captures' );
  is( chat( $engine, after_tools( 'Other', [ grep => 'y' ] ) ), 'some tool', 'after() takes any tool' );
  is( chat( $engine, after_tools( 'Two', [ grep => 'y' ], [ ls => 'z' ] ) ), 'files: z',
    'parallel results: any of them may match' );
  my $view = $engine->requests->[-1];
  is_deeply( $view->{tool_results}, [
    { id => 'c1', name => 'grep', content => 'y' },
    { id => 'c2', name => 'ls',   content => 'z' },
  ], 'tool_results: id, the name of the call it answers, the text' );
  is( $view->{text}, undef, 'text is undef after a tool result' );
  is( $view->{last_user_text}, 'Two', 'last_user_text still names the prompt' );
  is( $engine->simple_chat('List')->tool_call->name, 'ls', 'the prompt itself still triggers the call' );
  my $no_after = Langertha::Engine::Virtual->new( rules => [ 'List' => tool( ls => {} ) ], fallback => 'fb' );
  is( chat( $no_after, after_tools( 'List', [ ls => 'a' ] ) ), 'fb',
    'without an after rule the tool-result turn goes to the fallback' );
};

subtest 'tools() emits several calls with unique ids' => sub {
  my $engine = Langertha::Engine::Virtual->new(
    rules => [ 'Both' => tools( [ [ ls => { dir => '.' } ], tool( pwd => {} ) ] ) ],
  );
  my $first  = $engine->simple_chat('Both');
  my $second = $engine->simple_chat('Both');
  is_deeply( [ map { $_->name } @{ $first->tool_calls } ], [qw( ls pwd )], 'both calls, in order' );
  is_deeply( $first->tool_calls->[0]->arguments, { dir => '.' }, 'arguments survive the wire' );
  is_deeply( [ map { $_->id } @{ $first->tool_calls }, @{ $second->tool_calls } ],
    [qw( call_virtual_1 call_virtual_2 call_virtual_3 call_virtual_4 )], 'ids never repeat' );
  is_deeply( $engine->calls, [ [ ls => { dir => '.' } ], [ pwd => {} ], [ ls => { dir => '.' } ], [ pwd => {} ] ],
    'calls records every emitted call' );
};

subtest 'non-ASCII text and arguments are encoded once' => sub {
  my $engine = Langertha::Engine::Virtual->new(
    rules => [ "Grüße" => tools( [ [ say => { text => 'Ä€✓' } ] ] ) ],
    fallback => sub { answer( 'echo: '.$_[0]{text} ) },
  );
  is( $engine->simple_chat("Grüße")->tool_call->arguments->{text}, 'Ä€✓', 'arguments round-trip' );
  is( $engine->simple_chat("Straße"), "echo: Straße", 'text round-trips' );
};

subtest 'fallback answers what no rule matches; without one the request fails loudly' => sub {
  my $with = Langertha::Engine::Virtual->new( rules => [ 'a' => 'b' ], fallback => answer('fb') );
  is( $with->simple_chat('zzz'), 'fb', 'fallback' );

  my $without = Langertha::Engine::Virtual->new( rules => [ 'a' => 'b' ] );
  eval { $without->simple_chat('zzz') };
  like( $@, qr/\ALangertha::Engine::Virtual request failed: 500 No Reaction - no rule matches and no fallback is set \(request 1, last message: the user message 'zzz'\)/,
    'sync: croaks naming the message' );
  eval { $without->simple_chat_f('zzz')->get };
  like( $@, qr/request failed: 500 No Reaction - no rule matches .*request 2/, '_f: fails the same way' );
  eval { chat( $without, after_tools( 'x', [ ls => 'y' ] ) ) };
  like( $@, qr/last message: the tool result of ls/, 'a tool-result turn names the tool' );

  my $dies = Langertha::Engine::Virtual->new( fallback => sub { die "boom\n" } );
  eval { $dies->simple_chat('x') };
  like( $@, qr/request failed: 500 Reaction Failed - boom/, 'a dying sub fails the request with its error' );
  my $junk = Langertha::Engine::Virtual->new( fallback => sub { [] } );
  eval { $junk->simple_chat('x') };
  like( $@, qr/500 Reaction Failed - .*must be a text, a HashRef/, 'a sub returning no reaction fails' );
};

subtest 'script mode answers request by request, in order' => sub {
  my @numbers;
  my $engine = Langertha::Engine::Virtual->new(
    script => [
      tool( read_file => { path => 'app.txt' } ),
      sub { my ($request) = @_; push @numbers, $request->{number}; return answer('second') },
      'third',
    ],
  );
  is( $engine->simple_chat('anything')->tool_call->name, 'read_file', 'first entry' );
  is( $engine->simple_chat('anything'), 'second', 'second entry, a sub' );
  is_deeply( \@numbers, [2], 'the sub got the request' );
  is( $engine->simple_chat('Hello'), 'third', 'third entry, whatever the prompt' );
  is_deeply( $engine->script, [ $engine->script->[0], $engine->script->[1], 'third' ], 'the script itself is untouched' );
  eval { $engine->simple_chat('more') };
  like( $@, qr/500 No Reaction - the script has run out and no fallback is set \(request 4/, 'exhausted: fails' );

  my $with = Langertha::Engine::Virtual->new( script => ['one'], fallback => 'done' );
  is_deeply( [ map { "".$with->simple_chat('x') } 1 .. 3 ], [qw( one done done )], 'exhausted: fallback' );
};

subtest 'rules are checked when the engine is built' => sub {
  my %bad = (
    'odd pair list'        => [ rules => ['a'] ],
    'undef trigger'        => [ rules => [ undef, 'x' ] ],
    'ArrayRef trigger'     => [ rules => [ [], 'x' ] ],
    'unknown reaction key' => [ rules => [ a => { foo => 1 } ] ],
    'empty reaction'       => [ rules => [ a => {} ] ],
    'answer and text'      => [ rules => [ a => { answer => 'x', text => 'y' } ] ],
    'bad tool call'        => [ rules => [ a => { tool_calls => [ [ '', {} ] ] } ] ],
    'bad arguments'        => [ rules => [ a => { tool_calls => [ [ 'ls', [] ] ] } ] ],
    'undef reaction'       => [ rules => [ a => undef ] ],
    'bad script entry'     => [ script => [ 'ok', [] ] ],
    'bad fallback'         => [ fallback => [] ],
    'rules and script'     => [ rules => [ a => 'b' ], script => ['c'] ],
  );
  for my $case ( sort keys %bad ) {
    my $ok = eval { Langertha::Engine::Virtual->new( @{ $bad{$case} } ); 1 };
    ok( !$ok, "$case croaks" );
    like( $@, qr/\ALangertha::Engine::Virtual: /, "$case: the message names the class" );
  }
  ok( Langertha::Engine::Virtual->new, 'no rules at all is allowed (every request then fails)' );
};

subtest 'the helpers build plain data and refuse misuse' => sub {
  is_deeply( answer('x'), { answer => 'x' }, 'answer' );
  is_deeply( tool('ls'), { tool_calls => [ [ ls => {} ] ] }, 'tool without arguments' );
  is_deeply( after(), { after => {} }, 'after()' );
  is_deeply( after('ls'), { after => { tool => 'ls' } }, 'after($name)' );
  is_deeply( after( tool => 'ls', result => 'ok' ), { after => { tool => 'ls', result => 'ok' } }, 'named after' );
  for my $misuse (
    [ answer => sub { answer(undef) } ],
    [ tool   => sub { tool( ls => 'x' ) } ],
    [ tools  => sub { tools( ['ls'] ) } ],
    [ after  => sub { after( tool => 'read_file', answer('x') ) } ],
    [ after  => sub { after( bogus => 1 ) } ],
  ) {
    my ( $name, $code ) = @$misuse;
    ok( !eval { $code->(); 1 }, "$name misuse croaks" );
    like( $@, qr/\ALangertha::Virtual::Rules::$name /, "$name: names the helper" );
  }
};

subtest 'rules_file loads rules, after rules and fallback from YAML' => sub {
  my $engine = Langertha::Engine::Virtual->new( rules_file => $data_dir->child('virtual_rules.yml')->stringify );
  ok( $engine->has_rules_file, 'rules_file is kept' );
  is( $engine->simple_chat('Hello'), 'Hi there!', 'answer reaction' );
  is( $engine->simple_chat('Just text'), 'plain answer', 'a plain string reaction' );
  my $call = $engine->simple_chat('Write a note.')->tool_call;
  is( $call->name, 'write_file', 'tool_calls reaction' );
  my %arguments = %{ $call->arguments };
  my $append = delete $arguments{append};
  is_deeply( \%arguments, { path => 'notes/a.txt', content => "hello\n" }, 'arguments' );
  ok( ref $append && !$append, 'a YAML false arrives as a JSON false, not a string' );
  is( chat( $engine, after_tools( 'Write a note.', [ write_file => 'Wrote 6 bytes' ] ) ), 'Fertig.',
    'the after mapping keys on the tool name' );
  is( $engine->simple_chat('something else'), 'done', 'fallback' );

  my $scripted = Langertha::Engine::Virtual->new( rules_file => $data_dir->child('virtual_script.yml') );
  is( $scripted->simple_chat('x')->tool_call->name, 'read_file', 'script from YAML, first step' );
  is( $scripted->simple_chat('x'), 'Done.', 'second step, text is an alias of answer' );

  my $dir = Path::Tiny->tempdir;
  my $unknown = $dir->child('unknown.yml');
  $unknown->spew_utf8("rules: {}\ntitle: a scenario\n");
  ok( !eval { Langertha::Engine::Virtual->new( rules_file => "$unknown" ); 1 }, 'unknown key croaks' );
  like( $@, qr/unknown keys: title/, '... naming it' );
  ok( !eval { Langertha::Engine::Virtual->new( rules_file => $data_dir->child('virtual_rules.yml')->stringify,
    fallback => 'x' ); 1 }, 'a key in both the file and the constructor croaks' );
  like( $@, qr/fallback is given to the constructor and in rules_file/, '... naming the key' );
  my $code_like = $dir->child('code.yml');
  $code_like->spew_utf8("rules:\n  a: { perl: 'sub { 1 }' }\n");
  ok( !eval { Langertha::Engine::Virtual->new( rules_file => "$code_like" ); 1 }, 'no code from YAML' );
  like( $@, qr/unknown keys: perl/, '... it is just an unknown key' );
};

subtest 'preset echo answers with the prompt' => sub {
  my $echo = Langertha::Engine::Virtual->preset('echo');
  isa_ok( $echo, ['Langertha::Engine::Virtual'], 'an engine' );
  for my $prompt ( 'Hello', "Two\nlines", 'Ünïcödé', '' ) {
    is( $echo->simple_chat($prompt), $prompt, "echoes '$prompt'" );
  }
  ok( !eval { Langertha::Engine::Virtual->preset('nope'); 1 }, 'unknown preset croaks' );
  like( $@, qr/unknown preset nope \(known: echo, files\)/, '... listing the known ones' );
};

subtest 'preset files turns its exact prompts into read_file, write_file and bash calls' => sub {
  my $files = Langertha::Engine::Virtual->preset('files');
  my @cases = (
    [ 'Read the file notes/a.txt'          => read_file  => { path => 'notes/a.txt' } ],
    [ 'Write the file a.txt: hello world'  => write_file => { path => 'a.txt', content => 'hello world' } ],
    [ "Write the file b.txt: one\ntwo"     => write_file => { path => 'b.txt', content => "one\ntwo" } ],
    [ 'Run the command ls -la'             => bash       => { command => 'ls -la' } ],
  );
  for my $case (@cases) {
    my ( $prompt, $name, $arguments ) = @$case;
    my $call = $files->simple_chat($prompt)->tool_call;
    is( $call->name, $name, "'$prompt' calls $name" );
    is_deeply( $call->arguments, $arguments, '... with these arguments' );
  }
  is( chat( $files, after_tools( 'Read the file a', [ read_file => 'content of a' ] ) ), 'content of a',
    'after the tool it answers with the result' );
  for my $prompt ( 'read the file a.txt', 'Read the file a.txt please', 'Run the command' ) {
    like( $files->simple_chat($prompt), qr/\AI know these prompts:\nRead the file PATH\n/,
      "'$prompt' is not a trigger: the fallback lists the prompts" );
  }
};

subtest 'Mock is the same engine under another name' => sub {
  ok( Langertha::Engine::Mock->isa('Langertha::Engine::Virtual'), 'Mock isa Virtual' );
  is( Langertha->resolve_engine_class('Mock'), 'Langertha::Engine::Mock', 'resolves Mock' );
  is( Langertha->resolve_engine_class('Virtual'), 'Langertha::Engine::Virtual', 'resolves Virtual' );
  ok( ( grep { $_ eq 'mock' } @{ Langertha->available_engine_ids } ), 'mock is an engine id' );
  ok( ( grep { $_ eq 'virtual' } @{ Langertha->available_engine_ids } ), 'virtual is an engine id' );
  my $mock = Langertha->new_engine( Mock => rules => [ 'Hi' => answer('Ho') ] );
  isa_ok( $mock, ['Langertha::Engine::Mock'], 'new_engine builds a Mock' );
  is( $mock->simple_chat('Hi'), 'Ho', 'and it answers by its rules' );
  isa_ok( Langertha::Engine::Mock->preset('echo'), ['Langertha::Engine::Mock'], 'Mock->preset builds a Mock' );
};

subtest 'what the engine claims and what it refuses' => sub {
  my $engine = Langertha::Engine::Virtual->new;
  ok( $engine->isa('Langertha::Engine::Remote'), 'a Remote engine' );
  ok( !$engine->isa('Langertha::Engine::OpenAIBase'), 'not an OpenAIBase: it composes only what it serves' );
  ok( $engine->supports($_), "supports $_" ) for qw( chat tools_native tool_choice_named system_prompt streaming );
  ok( !$engine->supports($_), "does not support $_" )
    for qw( embedding transcription image_generation temperature response_format_json_schema image_input );
  is( Langertha::Engine::Virtual->api_key_env, undef, 'reads no API key' );
  is( Langertha::Engine::Virtual->api_key_required, 0, 'needs no API key' );
  is_deeply( $engine->list_models, ['virtual'], 'list_models without a request' );
  is( $engine->async_loop, undef, 'no event loop of its own' );
  is( scalar @{ $engine->requests }, 0, 'list_models sent nothing' );
  my $response = $engine->user_agent->get('http://virtual.invalid/v1/models');
  is( $response->code, 404, 'any other endpoint is a 404, answered in-process' );
};

done_testing;
