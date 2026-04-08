use strict;
use warnings;
use Test2::V0;
use JSON::MaybeXS qw( encode_json );

use Langertha::Tool;
use Langertha::ToolCall;
use Langertha::ToolChoice;

# --- Tool ---
{
  my $t = Langertha::Tool->new(
    name        => 'list_files',
    description => 'List files',
    input_schema => { type => 'object', properties => { path => { type => 'string' } }, required => ['path'] },
  );
  is( $t->to_openai->{type}, 'function', 'openai wraps in function' );
  is( $t->to_openai->{function}{name}, 'list_files', 'openai name' );
  is( $t->to_openai->{function}{parameters}{required}[0], 'path', 'openai parameters' );
  is( $t->to_anthropic->{name}, 'list_files', 'anthropic name' );
  is( $t->to_anthropic->{input_schema}{type}, 'object', 'anthropic schema' );
}

# from_openai roundtrip
{
  my $hash = {
    type => 'function',
    function => {
      name => 'fetch_url',
      description => 'fetch a url',
      parameters => { type => 'object', properties => { url => { type => 'string' } } },
    },
  };
  my $t = Langertha::Tool->from_openai($hash);
  ok( $t, 'parsed' );
  is( $t->name, 'fetch_url', 'name' );
  is( $t->description, 'fetch a url', 'description' );
  is( $t->to_openai->{function}{name}, 'fetch_url', 'roundtrip' );
}

# from_anthropic
{
  my $t = Langertha::Tool->from_anthropic({
    name => 'calc',
    description => 'do math',
    input_schema => { type => 'object', properties => {} },
  });
  ok( $t, 'parsed' );
  is( $t->name, 'calc', 'name' );
}

# from_list mixed
{
  my $list = Langertha::Tool->from_list([
    { type => 'function', function => { name => 'a' } },
    { name => 'b', input_schema => {} },
    { garbage => 1 },
    {},
  ]);
  is( scalar @$list, 2, 'two valid tools, two skipped' );
  is( $list->[0]->name, 'a', 'first' );
  is( $list->[1]->name, 'b', 'second' );
}

# --- ToolCall ---
{
  my $call = Langertha::ToolCall->new(
    name => 'list_files',
    arguments => { path => '/tmp' },
    id => 'call_xyz',
  );
  is( $call->to_openai->{function}{name}, 'list_files', 'openai name' );
  like( $call->to_openai->{function}{arguments}, qr/path/, 'openai args encoded' );
  is( $call->to_anthropic_block->{type}, 'tool_use', 'anthropic block' );
  is( $call->to_anthropic_block->{input}{path}, '/tmp', 'anthropic input' );
  is( $call->to_ollama->{function}{arguments}{path}, '/tmp', 'ollama args' );
}

# from_openai with json string args
{
  my $call = Langertha::ToolCall->from_openai({
    id => 'call_1',
    type => 'function',
    function => { name => 'fetch', arguments => encode_json({ url => 'http://x' }) },
  });
  ok( $call, 'parsed' );
  is( $call->arguments->{url}, 'http://x', 'json args decoded' );
  is( $call->id, 'call_1', 'id' );
}

# from_anthropic
{
  my $call = Langertha::ToolCall->from_anthropic({
    type => 'tool_use',
    id => 'toolu_1',
    name => 'calc',
    input => { x => 1, y => 2 },
  });
  ok( $call, 'parsed' );
  is( $call->arguments->{y}, 2, 'input mapped' );
}

# extract from openai response
{
  my @calls = Langertha::ToolCall->extract({
    choices => [{
      message => {
        content => '',
        tool_calls => [
          { id => 'a', type => 'function', function => { name => 'one', arguments => '{}' } },
          { id => 'b', type => 'function', function => { name => 'two', arguments => '{}' } },
        ],
      },
    }],
  });
  is( scalar @calls, 2, 'extracted two openai calls' );
  is( $calls[0]->name, 'one', 'first name' );
}

# extract from anthropic response
{
  my @calls = Langertha::ToolCall->extract({
    content => [
      { type => 'text', text => 'hi' },
      { type => 'tool_use', id => 't1', name => 'first', input => {} },
      { type => 'tool_use', id => 't2', name => 'second', input => { a => 1 } },
    ],
  });
  is( scalar @calls, 2, 'extracted two anthropic calls' );
  is( $calls[1]->arguments->{a}, 1, 'second args' );
}

# Hermes from text
{
  my ($clean, $calls) = Langertha::ToolCall->extract_hermes_from_text(
    'Sure thing. <tool_call>{"name":"go","arguments":{"x":1}}</tool_call> Done.'
  );
  is( $clean, 'Sure thing.  Done.', 'cleaned' );
  is( scalar @$calls, 1, 'one hermes call' );
  is( $calls->[0]->name, 'go', 'hermes name' );
  is( $calls->[0]->arguments->{x}, 1, 'hermes args' );
}

# --- ToolChoice ---
{
  is( Langertha::ToolChoice->auto->type, 'auto', 'auto' );
  is( Langertha::ToolChoice->any->type,  'any',  'any' );
  is( Langertha::ToolChoice->none->type, 'none', 'none' );
  my $s = Langertha::ToolChoice->specific('calc');
  is( $s->type, 'tool', 'specific tool type' );
  is( $s->name, 'calc', 'specific tool name' );

  is( Langertha::ToolChoice->any->to_openai, 'required', 'openai required' );
  is( Langertha::ToolChoice->auto->to_openai, 'auto',     'openai auto' );
  is( Langertha::ToolChoice->none->to_openai, 'none',     'openai none' );

  my $oai = Langertha::ToolChoice->specific('calc')->to_openai;
  is( $oai->{type}, 'function', 'openai function type' );
  is( $oai->{function}{name}, 'calc', 'openai function name' );

  is( Langertha::ToolChoice->any->to_anthropic->{type},  'any',  'anth any' );
  is( Langertha::ToolChoice->none->to_anthropic->{type}, 'none', 'anth none' );
  my $anth = Langertha::ToolChoice->specific('calc')->to_anthropic;
  is( $anth->{type}, 'tool', 'anth tool type' );
  is( $anth->{name}, 'calc', 'anth tool name' );
}

# from_hash with various inputs
{
  is( Langertha::ToolChoice->from_hash('required')->type, 'any', 'string required' );
  is( Langertha::ToolChoice->from_hash('auto')->type,     'auto', 'string auto' );
  is( Langertha::ToolChoice->from_hash({ type => 'tool', name => 'x' })->name, 'x', 'tool name from hash' );
  is( Langertha::ToolChoice->from_hash({ type => 'function', function => { name => 'y' } })->name, 'y', 'function name from hash' );
  is( Langertha::ToolChoice->from_hash(undef), undef, 'undef passes through' );
}

# --- Facade backwards compat ---
{
  local $SIG{__WARN__} = sub { return if $_[0] =~ /backwards-compatibility facade/; warn @_ };
  require Langertha::Input::Tools;
  require Langertha::Output::Tools;
}
{
  my $norm = Langertha::Input::Tools->normalize_tools([
    { type => 'function', function => { name => 'a', description => 'aa' } },
    { name => 'b', input_schema => { type => 'object' } },
  ]);
  is( scalar @$norm, 2, 'facade normalize' );
  is( $norm->[0]{name}, 'a', 'first name' );

  my $oai = Langertha::Input::Tools->to_openai_tools($norm);
  is( $oai->[0]{type}, 'function', 'facade to_openai' );

  my $anth = Langertha::Input::Tools->to_anthropic_tools($norm);
  is( $anth->[1]{name}, 'b', 'facade to_anthropic' );
}

{
  my $meta = Langertha::Output::Tools->extract_from_raw({
    choices => [{
      message => {
        content => 'hello',
        tool_calls => [
          { id => 'a', type => 'function', function => { name => 'go', arguments => '{}' } },
        ],
      },
      finish_reason => 'tool_calls',
    }],
  });
  is( $meta->{text}, 'hello', 'facade text' );
  is( scalar @{ $meta->{tool_calls} }, 1, 'facade one call' );
  is( $meta->{tool_calls}[0]{name}, 'go', 'facade call name' );
  is( $meta->{finish_reason}, 'tool_calls', 'facade finish_reason' );
}

{
  my $oai = Langertha::Output::Tools->to_openai_tool_calls([
    { name => 'x', arguments => { a => 1 } },
  ]);
  is( $oai->[0]{type}, 'function', 'facade to_openai_calls' );
  like( $oai->[0]{function}{arguments}, qr/"a":1/, 'args encoded' );
}

done_testing;
