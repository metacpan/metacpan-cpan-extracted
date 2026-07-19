use strict;
use warnings;
use Test::More 0.98;

# Parser conformance cases carried over from the pre-greenfield suite
# (legacy-tests/original-t/01,04,06), re-expressed against the single
# current parser: the kitchen-sink fixtures from graphql-js (the
# exhaustive syntax documents), unicode escape decoding including
# surrogate pairs, and explicit rejection of invalid escapes.

use GraphQL::Houtou qw(parse);
use GraphQL::Houtou::Error ();
use Scalar::Util qw(blessed);

sub slurp {
  my ($path) = @_;
  open my $fh, '<', $path or die "open($path): $!";
  local $/;
  return <$fh>;
}

subtest 'kitchen-sink executable document parses to the expected shape' => sub {
  my $ast = parse(slurp('t/kitchen-sink.graphql'));
  is scalar(@$ast), 6, 'six top-level definitions';
  is $ast->[0]{kind}, 'operation', 'first definition is an operation';
  is_deeply [ sort map { $_->{kind} } @$ast ],
    [ ('fragment') x 1, ('operation') x 5 ],
    'definition kinds are five operations and one fragment';
};

subtest 'kitchen-sink schema document parses to the expected shape' => sub {
  my $ast = parse(slurp('t/schema-kitchen-sink.graphql'));
  is scalar(@$ast), 35, 'thirty-five top-level definitions';
  is $ast->[0]{kind}, 'schema', 'first definition is the schema block';
};

subtest 'string unicode escapes are decoded' => sub {
  # \u sequences are written with a doubled backslash so the escape
  # reaches the GraphQL lexer, not Perl's.
  my $bmp = parse("{ field(arg: \"A\\u03A9\") }");
  is $bmp->[0]{selections}[0]{arguments}{arg}, "A\x{03A9}",
    'BMP escape decodes to the code point';

  my $pair = parse("{ field(arg: \"\\uD83D\\uDE00\") }");
  is $pair->[0]{selections}[0]{arguments}{arg}, "\x{1F600}",
    'surrogate pair decodes to the astral code point';
};

subtest 'invalid unicode escapes die with a structured error' => sub {
  my $ok = eval { parse("{ field(arg: \"\\u00GG\") }"); 1 };
  ok !$ok, 'invalid escape dies';
  ok blessed($@) && $@->isa('GraphQL::Houtou::Error'), 'error is a Houtou error object';
  like $@->message, qr/Invalid Unicode escape sequence/, 'error names the escape problem';
};

subtest 'type system extensions must add content' => sub {
  for my $source (
    'extend scalar DateTime',
    'extend type Query',
    'extend interface Node',
    'extend union Search',
    'extend enum Status',
    'extend input Filter',
    'extend schema',
  ) {
    my $ok = eval { parse($source); 1 };
    ok !$ok, "$source is rejected";
    like $@->message, qr/extension must add a directive or member/,
      'error explains the missing extension content';
  }
};

subtest 'nested selections keep the legacy AST shape with locations' => sub {
  my $ast = parse('{ user { id } }');
  is $ast->[0]{kind}, 'operation', 'operation kind';
  my $user = $ast->[0]{selections}[0];
  is $user->{kind}, 'field', 'field kind';
  is $user->{name}, 'user', 'field name';
  is $user->{selections}[0]{name}, 'id', 'nested field name';
  ok exists $user->{location}, 'fields carry locations';
};

subtest 'executable definition descriptions are preserved' => sub {
  my $ast = parse(<<'GRAPHQL');
"Operation docs"
query Described(
  "Variable docs"
  $id: ID!
) {
  node(id: $id) { id }
}

"""
Fragment docs
on multiple lines.
"""
fragment NodeFields on Node { id }
GRAPHQL

  is $ast->[0]{description}, 'Operation docs', 'operation description preserved';
  is $ast->[0]{variables}{id}{description}, 'Variable docs',
    'variable definition description preserved';
  is $ast->[1]{description}, "Fragment docs\non multiple lines.",
    'fragment block description normalized and preserved';
};

subtest 'descriptions are not permitted on query shorthand' => sub {
  my $ok = eval { parse('"Not allowed" { field }'); 1 };
  ok !$ok, 'description before query shorthand is rejected';
};

done_testing;
