#!/usr/bin/env perl
# ABSTRACT: Pin every function-tool input form Langertha::Tool accepts

use strict;
use warnings;
use Test2::Bundle::More;
use Langertha::Tool;

# Why: karr k210 makes Tool->from_hash croak on a provider built-in / server-side
# tool hash (anything with a non-function `type`) instead of dropping it or
# turning it into a function tool. That guard sits in front of every input the
# value object already parses, so this table pins each accepted function-tool
# form first: if the guard ever swallows one of them, a row here goes red.
# Every row must parse to the same canonical tool and survive format_list on
# every wire.

my $schema = { type => 'object', properties => { city => { type => 'string' } } };
my $empty  = { type => 'object', properties => {} };

my $nested_openai = { type => 'function', function => { name => 'w', description => 'd', parameters => $schema } };
my $flat_openai   = { type => 'function', name => 'w', description => 'd', parameters => $schema };

my @forms = (
  [ 'Langertha::Tool object',
    Langertha::Tool->new( name => 'w', description => 'd', input_schema => $schema ),
    $schema ],
  [ 'OpenAI chat {type=>function, function=>{...}}',
    $nested_openai,
    $schema ],
  [ 'OpenAI Responses flat {type=>function, name, parameters}',
    $flat_openai,
    $schema ],
  [ 'MCP {name, inputSchema}',
    { name => 'w', description => 'd', inputSchema => $schema },
    $schema ],
  [ 'Anthropic / canonical {name, input_schema}',
    { name => 'w', description => 'd', input_schema => $schema },
    $schema ],
  [ 'Anthropic explicit client tool {type=>custom, name, input_schema}',
    { type => 'custom', name => 'w', description => 'd', input_schema => $schema },
    $schema ],
  [ 'Gemini functionDeclaration {name, parameters}',
    { name => 'w', description => 'd', parameters => $schema },
    $schema ],
  [ 'name-only / schemaless {name, description}',
    { name => 'w', description => 'd' },
    $empty ],
);

for my $row (@forms) {
  my ( $label, $input, $want_schema ) = @$row;
  subtest $label => sub {
    is( scalar Langertha::Tool->classify($input), 'function', 'classify: function' );
    my $tool = Langertha::Tool->from_hash($input);
    ok( $tool, 'parses' ) or return;
    is( $tool->name, 'w', 'name' );
    is( $tool->description, 'd', 'description' );
    is_deeply( $tool->input_schema, $want_schema, 'input_schema' );

    my $list = Langertha::Tool->from_list( [$input] );
    is( scalar @$list, 1, 'from_list keeps it' );

    for my $fmt (qw( openai anthropic gemini ollama responses hermes )) {
      my $out = Langertha::Tool->format_list( $fmt, [$input] );
      my $n = $fmt eq 'gemini' ? scalar @{ $out->[0]{functionDeclarations} } : scalar @$out;
      is( $n, 1, "format_list($fmt) emits it" );
    }
  };
}

# k217: the flat Responses function form and the nested OpenAI chat form
# describe the same tool, so from_hash must resolve both to an identical
# Langertha::Tool -- checked here by comparing their wire output on every
# format, not just the schema each parses to in the table above.
subtest 'flat Responses function form == nested OpenAI chat form on every wire' => sub {
  for my $fmt (qw( openai anthropic gemini ollama responses hermes )) {
    is_deeply(
      Langertha::Tool->format_list( $fmt, [$flat_openai] ),
      Langertha::Tool->format_list( $fmt, [$nested_openai] ),
      "format_list($fmt) flat == nested",
    );
  }
};

done_testing;
