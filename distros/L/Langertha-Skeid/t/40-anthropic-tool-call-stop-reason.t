use strict;
use warnings;
use Test::More;
use JSON::MaybeXS qw(decode_json);
use Langertha::Skeid::Protocol::Anthropic;
use Langertha::Skeid::Protocol::Anthropic::Stream;

# gpt-oss on vLLM-style servers (captured live on AKI.IO, gpt-oss-120b) answers a tool call
# with finish_reason 'stop' instead of 'tool_calls'. Skeid translates the raw upstream JSON,
# so core's normalization of Response.finish_reason (core k248) does not reach it: the
# Anthropic face sent tool_use blocks with stop_reason end_turn, and an Anthropic client reads
# end_turn as "the model is done" and never runs the tools. Tool calls present wins over
# 'stop', on the plain JSON path and on the stream (skeid #31). The captures in t/data/ are
# copied verbatim from core's t/data/.

sub slurp {
  my ($name) = @_;
  open my $fh, '<:raw', "t/data/$name" or die "t/data/$name: $!";
  local $/;
  return scalar <$fh>;
}

sub stream_events {
  my ($bytes) = @_;
  my @events;
  while ($bytes =~ /^event: (\S+)\ndata: (.*)\n\n/mg) {
    push @events, { name => $1, data => decode_json($2) };
  }
  return @events;
}

sub run_stream {
  my (@chunks) = @_;
  my $stream = Langertha::Skeid::Protocol::Anthropic::Stream->new(model => 'gpt-oss-120b');
  my $out = $stream->start;
  $out .= $stream->delta($_) for @chunks;
  $out .= $stream->finish;
  return stream_events($out);
}

sub final_stop_reason {
  my (@events) = @_;
  my ($delta) = grep { $_->{name} eq 'message_delta' } @events;
  return $delta->{data}{delta}{stop_reason};
}

sub sse_chunks {
  my ($sse) = @_;
  return map { decode_json($_) } grep { $_ ne '[DONE]' } ($sse =~ /^data: (.*)$/mg);
}

# --- non-streaming ---------------------------------------------------------------------------

{
  my $res = decode_json(slurp('akiopenai_gptoss_tool_call_response.json'));
  is $res->{choices}[0]{finish_reason}, 'stop', 'capture: the wire says stop next to tool_calls';

  my $msg = Langertha::Skeid::Protocol::Anthropic->response_from_openai($res, 'm1');
  my @tool_use = grep { $_->{type} eq 'tool_use' } @{$msg->{content}};
  is scalar(@tool_use), 1, 'the tool call becomes a tool_use block';
  is $tool_use[0]{name}, 'add', 'tool_use block carries the call';
  is_deeply $tool_use[0]{input}, { a => 7, b => 15 }, 'tool_use input decoded';
  is $msg->{stop_reason}, 'tool_use', 'stop next to tool calls reports stop_reason tool_use';
}

{
  my $base = decode_json(slurp('akiopenai_gptoss_tool_call_response.json'));

  my %res = %$base;
  $res{choices} = [{ %{$base->{choices}[0]}, finish_reason => 'length' }];
  is(Langertha::Skeid::Protocol::Anthropic->response_from_openai(\%res, 'm1')->{stop_reason},
    'max_tokens', 'length next to tool calls stays max_tokens (a cut-off call is not a finished one)');

  $res{choices} = [{ %{$base->{choices}[0]}, finish_reason => 'tool_calls' }];
  is(Langertha::Skeid::Protocol::Anthropic->response_from_openai(\%res, 'm1')->{stop_reason},
    'tool_use', 'tool_calls still maps to tool_use');

  $res{choices} = [{ index => 0, finish_reason => 'stop',
    message => { role => 'assistant', content => 'Hello there' } }];
  is(Langertha::Skeid::Protocol::Anthropic->response_from_openai(\%res, 'm1')->{stop_reason},
    'end_turn', 'stop without tool calls stays end_turn');
}

# --- streaming -------------------------------------------------------------------------------

my @capture = sse_chunks(slurp('akiopenai_gptoss_tool_call_stream.sse'));

{
  my @events = run_stream(@capture);
  is final_stop_reason(@events), 'tool_use', 'capture as sent (finish tool_calls): tool_use';
}

{
  # The streamed capture itself finishes with tool_calls; the quirk seen on the non-streaming
  # path is replayed here by setting the last chunk's finish_reason to stop.
  my @chunks = map { decode_json(JSON::MaybeXS::encode_json($_)) } @capture;
  is $chunks[-1]{choices}[0]{finish_reason}, 'tool_calls', 'last capture chunk carries the finish';
  $chunks[-1]{choices}[0]{finish_reason} = 'stop';

  my @events = run_stream(@chunks);
  my @tool_starts = grep { $_->{name} eq 'content_block_start'
                           && $_->{data}{content_block}{type} eq 'tool_use' } @events;
  is scalar(@tool_starts), 1, 'a tool_use block was emitted';
  is final_stop_reason(@events), 'tool_use',
    'stop after emitted tool_use blocks ends with message_delta stop_reason tool_use';

  my @names = map { $_->{name} } @events;
  is $names[-2], 'message_delta', 'message_delta is the closing event before message_stop';
}

{
  my @events = run_stream(
    { choices => [{ index => 0, delta => { content => 'Hello' } }] },
    { choices => [{ index => 0, delta => {}, finish_reason => 'stop' }] },
  );
  is final_stop_reason(@events), 'end_turn', 'text-only stream with stop stays end_turn';
}

{
  my @chunks = map { decode_json(JSON::MaybeXS::encode_json($_)) } @capture;
  $chunks[-1]{choices}[0]{finish_reason} = 'length';
  is final_stop_reason(run_stream(@chunks)), 'max_tokens',
    'length after tool_use blocks stays max_tokens';
}

done_testing;
