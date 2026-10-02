#!/usr/bin/env perl
# ABSTRACT: One hermes lift — ToolCall->extract_hermes_from_text and the engine split agree

use strict;
use warnings;

use Test2::Bundle::More;

use Langertha::ToolCall;
use Langertha::Engine::NousResearch;

# The Output::Tools facade is under test on purpose (third door of the parity
# check below). Loading it carps its deprecation notice once; that notice is
# expected here, anything else it says is passed on.
my @facade_warnings;
{
  local $SIG{__WARN__} = sub {
    return push @facade_warnings, $_[0] if $_[0] =~ /backwards-compatibility facade/;
    warn @_;
  };
  require Langertha::Output::Tools;
}
is( scalar @facade_warnings, 1, 'loading Langertha::Output::Tools carps its deprecation notice once' );
like( $facade_warnings[0], qr/New code should use Langertha::ToolCall directly/,
  'the notice names Langertha::ToolCall as the replacement' );

# karr k255 (ADR 0001, k253 Update): the public door
# Langertha::ToolCall->extract_hermes_from_text (Output::Tools, skeid's
# protocols) and the engine's _hermes_split_text (chat_f, streaming, the tool
# loop) used to disagree on a <tool_call> block that carries no call: the door
# deleted it, the engine kept it as text. Text the model wrote must not vanish
# on one path and survive on another, so both doors give the same answer, and
# a block without a call stays where it was.

my @cases = (
  [ 'invalid JSON kept as text',
    'Hi <tool_call>{not json}</tool_call> there.',
    'Hi <tool_call>{not json}</tool_call> there.', [] ],
  [ 'object without name kept as text',
    'A <tool_call>{"arguments":{"x":1}}</tool_call> B',
    'A <tool_call>{"arguments":{"x":1}}</tool_call> B', [] ],
  [ 'empty name kept as text',
    '<tool_call>{"name":"","arguments":{}}</tool_call>',
    '<tool_call>{"name":"","arguments":{}}</tool_call>', [] ],
  [ 'non-object JSON kept as text',
    'x <tool_call>[1,2]</tool_call> y',
    'x <tool_call>[1,2]</tool_call> y', [] ],
  [ 'nested tag block kept as text',
    'N <tool_call><tool_call>{"name":"go","arguments":{}}</tool_call></tool_call> end',
    'N <tool_call><tool_call>{"name":"go","arguments":{}}</tool_call></tool_call> end', [] ],
  [ 'valid call lifted, broken one beside it kept in place',
    'a <tool_call>oops</tool_call> b <tool_call>{"name":"go","arguments":{"x":1}}</tool_call> c',
    'a <tool_call>oops</tool_call> b  c', [ { name => 'go', arguments => { x => 1 } } ] ],
  [ 'non-object arguments become {}',
    '<tool_call>{"name":"go","arguments":"x=1"}</tool_call>',
    '', [ { name => 'go', arguments => {} } ] ],
);

my $engine = Langertha::Engine::NousResearch->new( api_key => 'test-key' );

for my $case (@cases) {
  my ( $label, $text, $want_text, $want_calls ) = @$case;

  my ( $door_text, $door_calls ) = Langertha::ToolCall->extract_hermes_from_text($text);
  is( $door_text, $want_text, "ToolCall door: $label (text)" );
  is_deeply( [ map { { name => $_->name, arguments => $_->arguments } } @$door_calls ],
    $want_calls, "ToolCall door: $label (calls)" );

  my ( $eng_text, $eng_calls ) = $engine->_hermes_split_text($text);
  is( $eng_text, $door_text, "engine split agrees: $label (text)" );
  # _hermes_split_text also carries the k345 undecodable flag through its
  # reduced hash (k350, asserted below), so parity is checked on name+arguments.
  is_deeply( [ map { { name => $_->{name}, arguments => $_->{arguments} } } @$eng_calls ],
    $want_calls, "engine split agrees: $label (calls)" );

  my ( $out_text, $out_calls ) = Langertha::Output::Tools->parse_hermes_calls_from_text($text);
  is( $out_text, $door_text, "Output::Tools agrees: $label (text)" );
  is( scalar @$out_calls, scalar @$want_calls, "Output::Tools agrees: $label (count)" );
}

# karr k350: a hermes call whose arguments do not decode to an object is
# flagged the same way the other wire constructors flag it (k345), so the tool
# loop answers it an error result the model can retry rather than silently
# running the tool on {}. Both the door and the engine split set the flag.
for my $case (
  [ 'a non-object (string)', '<tool_call>{"name":"go","arguments":"x=1"}</tool_call>' ],
  [ 'a JSON array',          '<tool_call>{"name":"go","arguments":[1,2]}</tool_call>' ],
) {
  my ( $label, $text ) = @$case;
  my ( undef, $door_calls ) = Langertha::ToolCall->extract_hermes_from_text($text);
  ok( $door_calls->[0]->arguments_undecodable, "door flags $label" );
  like( $door_calls->[0]->arguments_error, qr/\A\S/, "door records why ($label)" );
  is_deeply( $door_calls->[0]->arguments, {}, "door leaves arguments {} ($label)" );

  my ( undef, $eng_calls ) = $engine->_hermes_split_text($text);
  ok( $eng_calls->[0]{arguments_undecodable}, "engine split carries the flag for $label" );
  is( $eng_calls->[0]{arguments_error}, $door_calls->[0]->arguments_error,
    "engine split carries the reason for $label" );
}

# A JSON array names the reason exactly; a valid object stays unflagged.
{
  my ( undef, $arr ) = Langertha::ToolCall->extract_hermes_from_text(
    '<tool_call>{"name":"go","arguments":[1,2]}</tool_call>' );
  is( $arr->[0]->arguments_error, 'not a JSON object', 'a JSON array: not a JSON object' );
  my ( undef, $ok ) = Langertha::ToolCall->extract_hermes_from_text(
    '<tool_call>{"name":"go","arguments":{"x":1}}</tool_call>' );
  ok( !$ok->[0]->arguments_undecodable, 'a valid object is not flagged' );
}

# A custom call tag reaches the door, and the default tag is then plain text.
{
  my $text = '<function_call>{"name":"go","arguments":{}}</function_call> <tool_call>{"name":"no"}</tool_call>';
  my ( $clean, $calls ) = Langertha::ToolCall->extract_hermes_from_text( $text, tag => 'function_call' );
  is( scalar @$calls, 1, 'tag option lifts the custom tag' );
  is( $calls->[0]->name, 'go', 'tag option: call name' );
  is( $clean, '<tool_call>{"name":"no"}</tool_call>', 'tag option: the default tag is text' );

  my $custom = Langertha::Engine::NousResearch->new( api_key => 'k', hermes_call_tag => 'function_call' );
  my ( $eng_clean, $eng_calls ) = $custom->_hermes_split_text($text);
  is( $eng_clean, $clean, 'engine with hermes_call_tag agrees with the door (text)' );
  is( scalar @$eng_calls, 1, 'engine with hermes_call_tag agrees with the door (calls)' );
}

done_testing;
