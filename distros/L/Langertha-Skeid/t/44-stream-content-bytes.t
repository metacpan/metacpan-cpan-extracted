use strict;
use warnings;
use utf8;
use Test::More;
use Encode ();
use Langertha::Skeid::Protocol::Anthropic::Stream;
use Langertha::Skeid::Protocol::Ollama::Stream;

# Both stream translators report content_bytes in usage() -- documented as the fallback measure
# of what a stream carried when an upstream never reports token counts. The deltas arrive as
# decoded characters, so length() counts characters and every non-ASCII answer is undercounted:
# "Köln" is 4 characters but 5 bytes, an emoji outside the BMP 1 character but 4 bytes
# (skeid #35, from the skeid #33 audit). Bytes means UTF-8 bytes.

my @deltas = ('Köln ', '東京 ', "\x{1F363}");
my $bytes  = 0;
$bytes += length(Encode::encode_utf8($_)) for @deltas;   # 6 + 7 + 4
is $bytes, 17, 'the fixture is 17 UTF-8 bytes (and 9 characters)';

for my $class (qw(Langertha::Skeid::Protocol::Anthropic::Stream Langertha::Skeid::Protocol::Ollama::Stream)) {
  my $stream = $class->new(model => 'm1');
  $stream->start;
  $stream->delta({ choices => [ { index => 0, delta => { content => $_ } } ] }) for @deltas;
  my (undef, undef, $content_bytes) = $stream->usage;
  is $content_bytes, $bytes, "$class counts content_bytes in UTF-8 bytes, not characters";
}

done_testing;
