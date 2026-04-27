use strict;
use warnings;
use Test::More;

use Langertha::Response;
use Langertha::ToolCall;

# tool_call_args: no tool_calls -> undef
{
  my $r = Langertha::Response->new( content => 'plain' );
  is $r->tool_call_args, undef, 'no tool_calls -> undef';
  is $r->tool_call,      undef, 'tool_call -> undef';
  ok !$r->has_tool_calls, 'predicate false';
}

# Legacy HashRef form is upgraded to Langertha::ToolCall by BUILDARGS.
{
  my $r = Langertha::Response->new(
    content    => '{"summary":"hi"}',
    tool_calls => [{
      name      => 'extract',
      arguments => { summary => 'hi' },
      synthetic => 1,
    }],
  );
  ok $r->has_tool_calls, 'predicate true';
  isa_ok $r->tool_calls->[0], 'Langertha::ToolCall', 'HashRef upgraded to object';
  is_deeply $r->tool_call_args, { summary => 'hi' }, 'first tool args';
  is_deeply $r->tool_call_args('extract'), { summary => 'hi' }, 'named tool args';
  is $r->tool_call_args('missing'), undef, 'unknown name -> undef';
  ok $r->tool_calls->[0]->synthetic, 'synthetic flag preserved';
  is $r->tool_call->name, 'extract', 'tool_call returns the object';
}

# Direct Langertha::ToolCall objects work too.
{
  my $tc = Langertha::ToolCall->new(
    name      => 'lookup',
    arguments => { q => 'foo' },
  );
  my $r = Langertha::Response->new(
    content    => '',
    tool_calls => [ $tc ],
  );
  is $r->tool_call->name, 'lookup', 'object preserved';
  ok !$r->tool_call->synthetic, 'native call has synthetic=0';
}

# clone_with should carry tool_calls through
{
  my $r = Langertha::Response->new(
    content    => 'x',
    tool_calls => [{ name => 'a', arguments => { v => 1 } }],
  );
  my $r2 = $r->clone_with( content => 'y' );
  is $r2->content, 'y', 'content overridden';
  is $r2->tool_calls->[0]->name, 'a', 'tool_calls cloned (object ref)';
  is_deeply $r2->tool_call_args, { v => 1 }, 'cloned args still readable';
}

done_testing;
