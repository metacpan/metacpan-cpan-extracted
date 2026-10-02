use strict;
use warnings;
use Test::More;
use JSON::MaybeXS qw(decode_json);
use Langertha::Skeid::Protocol::Anthropic::Stream;

# Anthropic's official SDKs dispatch a stream frame on the "type" inside its data, not on the
# SSE event line. The text block start went out as `event: content_block_start` with data type
# "content_block", so an SDK never saw the text block open (skeid #32). The invariant checked
# here is generic: on every frame the translator emits, the event name equals the data's type,
# for a text stream, a tool stream, one mixing both, and an in-band error.

sub frames {
  my ($bytes) = @_;
  my @frames;
  while ($bytes =~ /^event: (\S+)\ndata: (.*)\n\n/mg) {
    push @frames, { name => $1, data => decode_json($2) };
  }
  return @frames;
}

sub run_stream {
  my (@chunks) = @_;
  my $stream = Langertha::Skeid::Protocol::Anthropic::Stream->new(model => 'm');
  my $out = $stream->start;
  $out .= $stream->delta($_) for @chunks;
  $out .= $stream->finish;
  return $out;
}

sub text_chunk { { choices => [ { index => 0, delta => { content => $_[0] } } ] } }

my %streams = (
  text => run_stream(
    text_chunk('Hel'), text_chunk('lo'),
    { choices => [ { index => 0, delta => {}, finish_reason => 'stop' } ],
      usage => { prompt_tokens => 3, completion_tokens => 2 } },
  ),
  tool => run_stream(
    { choices => [ { index => 0, delta => { tool_calls => [
      { index => 0, id => 'call_1', type => 'function',
        function => { name => 'get_weather', arguments => '' } } ] } } ] },
    { choices => [ { index => 0, delta => { tool_calls => [
      { index => 0, function => { arguments => '{"city":"Berlin"}' } } ] } } ] },
    { choices => [ { index => 0, delta => {}, finish_reason => 'tool_calls' } ] },
  ),
  text_then_tool => run_stream(
    text_chunk('Checking.'),
    { choices => [ { index => 0, delta => { tool_calls => [
      { index => 0, id => 'call_1', type => 'function',
        function => { name => 'get_weather', arguments => '{}' } } ] } } ] },
    { choices => [ { index => 0, delta => {}, finish_reason => 'tool_calls' } ] },
  ),
  error => do {
    my $stream = Langertha::Skeid::Protocol::Anthropic::Stream->new(model => 'm');
    $stream->start . $stream->delta(text_chunk('Hi'))
      . $stream->delta({ error => { message => 'boom', type => 'server_error' } });
  },
);

for my $kind (sort keys %streams) {
  my @frames = frames($streams{$kind});
  ok scalar(@frames) >= 2, "$kind: stream emitted frames";
  for my $i (0 .. $#frames) {
    is $frames[$i]{data}{type}, $frames[$i]{name},
      "$kind frame $i: data type equals event name ($frames[$i]{name})";
  }
}

# The text block start in particular, shaped as Anthropic's streaming spec shows it.
my ($text_open) = grep { $_->{name} eq 'content_block_start' } frames($streams{text});
is_deeply $text_open->{data},
  { type => 'content_block_start', index => 0, content_block => { type => 'text', text => '' } },
  'text block start matches the spec frame';

done_testing;
