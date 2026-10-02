use strict;
use warnings;
use Test2::V0;
use JSON::MaybeXS;

# k17: Anthropic's stop_reason is a closed enum (end_turn, max_tokens,
# stop_sequence, tool_use, pause_turn, refusal). The routed engine Response
# carries the backend's own finish_reason -- for an OpenAI-dialect backend
# 'tool_calls' / 'length' / 'stop' / 'content_filter' (core k248 even turns a
# gpt-oss 'stop' next to tool calls into 'tool_calls'). Passing that through
# verbatim hands an Anthropic SDK a value outside its enum, so a client that
# loops on stop_reason eq 'tool_use' never runs the tools.

use Langertha::Knarr::Request;
use Langertha::Knarr::Response;
use Langertha::Knarr::Protocol::Anthropic;
use Langertha::ToolCall;

my $json  = JSON::MaybeXS->new( utf8 => 1 );
my $proto = Langertha::Knarr::Protocol::Anthropic->new;
my $areq  = Langertha::Knarr::Request->new( protocol => 'anthropic', model => 'claude-test' );

my $tool_call = Langertha::ToolCall->new(
  id => 'call_1', name => 'get_weather', arguments => { city => 'Berlin' },
);

sub stop_reason_for {
  my ( $finish_reason, $with_tools ) = @_;
  my $r = Langertha::Knarr::Response->new(
    content => $with_tools ? '' : 'hi',
    ( defined $finish_reason ? ( finish_reason => $finish_reason ) : () ),
    ( $with_tools ? ( tool_calls => [ $tool_call ] ) : () ),
  );
  my ( undef, undef, $body ) = $proto->format_chat_response( $r, $areq );
  return $json->decode($body)->{stop_reason};
}

subtest 'OpenAI-dialect finish_reason maps to Anthropic vocabulary' => sub {
  is stop_reason_for( 'tool_calls', 1 ),    'tool_use',   'tool_calls -> tool_use';
  is stop_reason_for( 'function_call', 1 ), 'tool_use',   'legacy function_call -> tool_use';
  is stop_reason_for( 'length' ),           'max_tokens', 'length -> max_tokens';
  is stop_reason_for( 'stop' ),             'end_turn',   'stop -> end_turn';
  is stop_reason_for( 'stop', 1 ),          'tool_use',   'stop next to tool calls -> tool_use';
  is stop_reason_for( 'content_filter' ),   'refusal',    'content_filter -> refusal';
};

subtest 'values already in Anthropic vocabulary pass through' => sub {
  for my $v (qw( end_turn max_tokens stop_sequence tool_use pause_turn refusal )) {
    is stop_reason_for($v), $v, "$v passes through";
  }
};

subtest 'case-insensitive (Gemini spells STOP / MAX_TOKENS)' => sub {
  is stop_reason_for('STOP'),       'end_turn',   'STOP -> end_turn';
  is stop_reason_for('MAX_TOKENS'), 'max_tokens', 'MAX_TOKENS -> max_tokens';
};

subtest 'undef and unknown values fall back to a valid enum value' => sub {
  is stop_reason_for(undef),        'end_turn', 'undef -> end_turn';
  is stop_reason_for( undef, 1 ),   'tool_use', 'undef with tool calls -> tool_use';
  is stop_reason_for('SAFETY'),     'end_turn', 'unmapped value -> end_turn';
  is stop_reason_for( 'weird', 1 ), 'tool_use', 'unmapped value with tool calls -> tool_use';
};

subtest 'streaming message_delta carries an Anthropic stop_reason' => sub {
  # Without a finish_reason (a stream whose backend reported none, or the
  # error path) the stream closes with end_turn; t/43 covers the mapped
  # reasons (k18). Assert the emitted value stays inside the enum.
  my $out = $proto->format_stream_close($areq);
  my ($data) = $out =~ /^event: message_delta\ndata: (.+)$/m;
  ok defined $data, 'message_delta event emitted';
  my $d = $json->decode($data);
  is $d->{delta}{stop_reason}, 'end_turn', 'message_delta stop_reason is end_turn';
};

done_testing;
