#!/usr/bin/env perl
# ABSTRACT: chat_f's forced-tool rewrite refuses or announces a response_format it would replace
use strict;
use warnings;

use Test2::Bundle::More;
use lib 't/lib';

use JSON::MaybeXS;
use Langertha::Engine::Perplexity;
use Langertha::Engine::Ollama;
use Langertha::Engine::NousResearch;
use Test::MockAsyncHTTP;

# karr k250 (ADR 0005, k250 Update): on an engine without tool_choice_named
# but with json_schema response_format, chat_f rewrites a forced named tool
# into response_format=json_schema. That per-request value used to replace a
# response_format the caller also asked for -- per request or on the engine --
# silently, so the caller got the tool's schema back instead of the shape
# they asked for and never learned why. The ruling:
#   (a) forced tool + a non-text response_format in the same chat_f call:
#       two conflicting intents, croak before anything is sent ("pick one");
#   (b) the response_format only comes from the engine attribute: the
#       request is the more specific intent, the forced tool wins, carp that
#       the engine's response_format is replaced for this request;
#   (c) a `text` response_format (either source) asks for no structure, so
#       it is no conflict: the rewrite stays silent.
# The source is told apart the way the request builders read it
# (_chat_effective_response_format, k249). On NousResearch the hermes schema
# prompt (k234) must carry the rewritten tool schema, not the replaced one.

my $json = JSON::MaybeXS->new( utf8 => 1, canonical => 1 );

my $tool_schema  = { type => 'object', properties => { city => { type => 'string' } }, required => ['city'] };
my $other_schema = { type => 'object', properties => { n => { type => 'number' } }, required => ['n'] };
my $tool = { name => 'extract', description => 'Extract', input_schema => $tool_schema };
my $rf   = { type => 'json_schema', json_schema => { name => 'other', schema => $other_schema } };

my $args_json = '{"city":"Berlin"}';
my %engine = (
  perplexity => {
    make  => sub { Langertha::Engine::Perplexity->new( api_key => 'k', model => 'sonar', @_ ) },
    reply => { id => 'resp_1', model => 'sonar', status => 'completed',
      output => [ { type => 'message', status => 'completed',
        content => [ { type => 'output_text', text => $args_json } ] } ],
      usage => { input_tokens => 1, output_tokens => 1, total_tokens => 2 } },
    # The json_schema the body carries, in this wire's spelling.
    schema_of => sub { $_[0]{response_format}{json_schema}{schema} },
  },
  ollama => {
    make  => sub { Langertha::Engine::Ollama->new( url => 'http://127.0.0.1:11434', model => 'qwen3:8b', @_ ) },
    reply => { model => 'qwen3:8b', message => { role => 'assistant', content => $args_json }, done => JSON->true },
    schema_of => sub { ref $_[0]{format} eq 'HASH' ? $_[0]{format} : undef },
  },
  nousresearch => {
    make  => sub { Langertha::Engine::NousResearch->new( api_key => 'k', model => 'Hermes-4-70B', @_ ) },
    reply => { choices => [ { message => { role => 'assistant', content => $args_json }, finish_reason => 'stop' } ] },
    schema_of => sub { $_[0]{response_format}{json_schema}{schema} },
  },
);

# ($response, $error, $body, \@warnings) for one chat_f call with a forced tool.
sub forced {
  my ( $name, $engine_args, @chat_args ) = @_;
  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, @_ };
  my $mock = Test::MockAsyncHTTP->new(
    responses => [ Test::MockAsyncHTTP->mock_json_response( $engine{$name}{reply} ) ] );
  my $e = $engine{$name}{make}->( _async_http => $mock, @$engine_args );
  my $response = eval {
    $e->chat_f( messages => ['Which city?'], tools => [$tool],
      tool_choice => { type => 'tool', name => 'extract' }, @chat_args )->get;
  };
  my $error = $@;
  my ($request) = $mock->requests;
  return ( $response, $error, $request ? $json->decode( $request->content ) : undef, \@warnings );
}

sub rewritten_ok {
  my ( $name, $label, $response, $body ) = @_;
  is_deeply( $engine{$name}{schema_of}->($body), $tool_schema, "$name $label: the wire carries the tool schema" );
  my $tc = $response && $response->tool_call('extract');
  ok( $tc && $tc->synthetic, "$name $label: synthetic ToolCall" );
  is_deeply( $tc ? $tc->arguments : undef, { city => 'Berlin' }, "$name $label: arguments from the reply" );
}

for my $name (qw( perplexity ollama nousresearch )) {
  subtest "$name: a forced tool and a per-request response_format conflict -- croak (a)" => sub {
    my ( $response, $error, $body, $warnings ) = forced( $name, [], response_format => $rf );
    ok( !defined $response, 'no response' );
    like( $error, qr/forced tool_choice.*response_format.*pick one/s, 'croaks: pick one' );
    like( $error, qr/'extract'/, 'names the forced tool' );
    ok( !defined $body, 'nothing sent' );

    ( $response, $error, $body ) = forced( $name, [ response_format => $rf ], response_format => $rf );
    like( $error, qr/pick one/, 'also when the engine carries one: the request asked for both' );
    ok( !defined $body, 'nothing sent' );

    ( $response, $error, $body ) = forced( $name, [], response_format => { type => 'json_object' } );
    like( $error, qr/pick one/, 'json_object is structure too: croaks' );
  };

  subtest "$name: an engine response_format is replaced for the request, with a warning (b)" => sub {
    my ( $response, $error, $body, $warnings ) = forced( $name, [ response_format => $rf ] );
    is( $error, '', 'no croak' );
    rewritten_ok( $name, 'engine rf', $response, $body );
    is( scalar @$warnings, 1, 'one warning' );
    like( $warnings->[0] // '', qr/forced tool_choice 'extract'.*engine's response_format.*replaced/s,
      'the warning says the engine response_format is replaced' );
  };

  subtest "$name: a text response_format is no conflict -- silent rewrite (c)" => sub {
    for my $case ( [ 'per request', [], response_format => { type => 'text' } ],
                   [ 'engine',      [ response_format => { type => 'text' } ] ] ) {
      my ( $label, $engine_args, @chat_args ) = @$case;
      my ( $response, $error, $body, $warnings ) = forced( $name, $engine_args, @chat_args );
      is( $error, '', "$label text: no croak" );
      rewritten_ok( $name, "$label text", $response, $body );
      is( scalar @$warnings, 0, "$label text: silent" );
    }
    my ( $response, $error, $body, $warnings ) = forced( $name, [] );
    is( $error, '', 'no response_format at all: no croak' );
    is( scalar @$warnings, 0, 'no response_format at all: silent' );
  };
}

subtest 'nousresearch: the hermes schema prompt carries the rewritten tool schema (k234)' => sub {
  my ( $response, $error, $body ) = forced( 'nousresearch', [ response_format => $rf ] );
  my ($in_prompt) = ( $body->{messages}[0]{content} // '' ) =~ m{<schema>\s*(.*?)\s*</schema>}s;
  ok( defined $in_prompt, 'a <schema> system prompt leads' );
  is_deeply( $json->decode( $in_prompt // 'null' ), $tool_schema, 'with the tool schema, not the engine one' );
  is( scalar( () = ( $json->encode($body) =~ /<schema>/g ) ), 1, 'exactly one schema prompt' );
};

done_testing;
