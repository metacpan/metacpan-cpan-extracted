use strict;
use warnings;
use Test::More;

use Langertha::Knarr::Input;
use Langertha::Knarr::Output;

# Input: normalize tools from mixed schemas
{
  my $canonical = Langertha::Knarr::Input->normalize_tools([
    {
      type => 'function',
      function => {
        name => 'add',
        description => 'Add numbers',
        parameters => { type => 'object' },
      },
    },
    {
      name => 'sub',
      description => 'Subtract numbers',
      input_schema => { type => 'object' },
    },
  ]);

  is scalar(@$canonical), 2, 'canonical tools count';
  is $canonical->[0]{name}, 'add', 'openai tool normalized';
  is $canonical->[1]{name}, 'sub', 'anthropic tool normalized';

  my $openai = Langertha::Knarr::Input->to_openai_tools($canonical);
  is $openai->[0]{type}, 'function', 'converted to openai function tool';

  my $anth = Langertha::Knarr::Input->to_anthropic_tools($canonical);
  is $anth->[0]{name}, 'add', 'converted to anthropic tool';
}

# Input: normalize tool choice
{
  my $tc1 = Langertha::Knarr::Input->normalize_tool_choice('required');
  is $tc1->{type}, 'any', 'required normalized to any';

  my $tc2 = Langertha::Knarr::Input->normalize_tool_choice({
    type => 'function',
    function => { name => 'add' },
  });
  is $tc2->{type}, 'tool', 'function normalized to tool';
  is $tc2->{name}, 'add', 'tool name preserved';

  my $oai = Langertha::Knarr::Input->to_openai_tool_choice($tc2);
  is $oai->{type}, 'function', 'tool converted to openai function choice';

  my $anth = Langertha::Knarr::Input->to_anthropic_tool_choice($tc2);
  is $anth->{type}, 'tool', 'tool converted to anthropic tool choice';
}

# Output: extract openai raw + convert to ollama calls
{
  my $meta = Langertha::Knarr::Output->extract_from_raw({
    choices => [{
      finish_reason => 'tool_calls',
      message => {
        content => '',
        tool_calls => [{
          id => 'call_1',
          type => 'function',
          function => { name => 'add', arguments => '{"a":1,"b":2}' },
        }],
      },
    }],
  });

  is $meta->{finish_reason}, 'tool_calls', 'finish_reason extracted';
  is scalar(@{$meta->{tool_calls}}), 1, 'canonical call extracted';
  is $meta->{tool_calls}[0]{name}, 'add', 'call name extracted';

  my $ollama = Langertha::Knarr::Output->to_ollama_tool_calls($meta->{tool_calls});
  is $ollama->[0]{function}{name}, 'add', 'converted to ollama tool call';
  is $ollama->[0]{function}{arguments}{a}, 1, 'arguments decoded to hash';
}

# Output: parse Hermes XML calls
{
  my ($clean, $calls) = Langertha::Knarr::Output->parse_hermes_calls_from_text(
    "before\n<tool_call>{\"name\":\"add\",\"arguments\":{\"a\":2,\"b\":3}}</tool_call>\nafter"
  );
  unlike $clean, qr/<tool_call>/, 'xml removed from text';
  like $clean, qr/before/s, 'text before call preserved';
  like $clean, qr/after/s, 'text after call preserved';
  is scalar(@$calls), 1, 'one hermes call extracted';
  is $calls->[0]{name}, 'add', 'hermes call name';
}

done_testing;
