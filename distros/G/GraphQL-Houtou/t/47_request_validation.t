use strict;
use warnings;
use Test::More 0.98;

# execute_document runs query validation before compiling (P0-1): invalid
# requests return an errors-only envelope (no "data" key) instead of
# executing against missing fields or silently dropping required
# arguments. Also pins the validator fixes that wiring exposed: Role::Tiny
# DOES dispatch for input types, always-available built-in scalars,
# introspection meta fields, boolean literals vs variable markers, and the
# spec's AllowedVariableUsage default-value rule.

use JSON::PP ();

use GraphQL::Houtou qw(build_native_runtime);
use GraphQL::Houtou::Schema;
use GraphQL::Houtou::Type::Enum;
use GraphQL::Houtou::Type::InputObject;
use GraphQL::Houtou::Type::Object;
use GraphQL::Houtou::Type::Scalar qw($Boolean $Int $String);

my $Filter = GraphQL::Houtou::Type::InputObject->new(
  name => 'Filter',
  fields => { q => { type => $String } },
);

my $Color = GraphQL::Houtou::Type::Enum->new(
  name => 'Color',
  values => {
    RED => {},
    GREEN => {},
  },
);

my $Item = GraphQL::Houtou::Type::Object->new(
  name => 'Item',
  fields => { name => { type => $String } },
);

my $schema = GraphQL::Houtou::Schema->new(
  query => GraphQL::Houtou::Type::Object->new(
    name => 'Query',
    fields => {
      hello => {
        type => $String,
        args => {
          name => { type => $String->non_null },
          filter => { type => $Filter },
          numbers => { type => $Int->list },
          color => { type => $Color },
          upcase => { type => $Boolean, default_value => 0 },
        },
        resolve => sub { 'hi ' . $_[1]{name} },
      },
      item => {
        type => $Item,
        resolve => sub { +{ name => 'thing' } },
      },
    },
  ),
  types => [ $Filter, $Item, $Color ],
);

# program_cache_max forces a fresh runtime instance per subtest (the
# no-options form memoizes one runtime per schema).
sub runtime { build_native_runtime($schema, program_cache_max => 100, @_) }

subtest 'invalid documents return an errors-only envelope' => sub {
  my $runtime = runtime();

  my $unknown = $runtime->execute_document('{ nope }');
  ok !exists $unknown->{data}, 'no data key on a request error';
  like $unknown->{errors}[0]{message}, qr/Field 'nope' does not exist/, 'unknown field';
  ok $unknown->{errors}[0]{locations}[0]{line}, 'error carries locations';

  my $missing_arg = $runtime->execute_document('{ hello }');
  like $missing_arg->{errors}[0]{message}, qr/Required argument 'name'/,
    'missing required argument is a request error';

  my $undefined_var = $runtime->execute_document('{ hello(name: $ghost) }');
  like $undefined_var->{errors}[0]{message}, qr/Variable '\$ghost' is used but not defined/,
    'undefined variable use is a request error';

  my $missing_subselection = $runtime->execute_document('{ item }');
  ok !exists $missing_subselection->{data},
    'a composite field without a subselection is a request error';
  like $missing_subselection->{errors}[0]{message}, qr/must have a selection of subfields/,
    'the subselection error is exposed through execute_document';

  my $unused_variable = $runtime->execute_document(
    'query Q($unused: String) { hello(name: "Ana") }');
  ok !exists $unused_variable->{data}, 'an unused variable is a request error';
  like $unused_variable->{errors}[0]{message}, qr/Variable '\$unused' is never used/,
    'the unused-variable error is exposed through execute_document';

  my $unused_fragment = $runtime->execute_document(
    'query Q { hello(name: "Ana") } fragment F on Query { hello(name: "F") }');
  ok !exists $unused_fragment->{data}, 'an unused fragment is a request error';
  like $unused_fragment->{errors}[0]{message}, qr/Fragment 'F' is never used/,
    'the unused-fragment error is exposed through execute_document';

  my $nested_input_variable = $runtime->execute_document(
    'query Q($bad: Boolean) { hello(name: "Ana", filter: { q: $bad }) }');
  like $nested_input_variable->{errors}[0]{message},
    qr/cannot be used for an input object field/,
    'nested input object variable positions are validated';

  my $list_item_variable = $runtime->execute_document(
    'query Q($bad: Boolean) { hello(name: "Ana", numbers: [$bad]) }');
  like $list_item_variable->{errors}[0]{message}, qr/cannot be used for a list item/,
    'list item variable positions are validated';

  my $unknown_enum = $runtime->execute_document(
    '{ hello(name: "Ana", color: BLUE) }');
  like $unknown_enum->{errors}[0]{message}, qr/not a valid Color literal/,
    'unknown enum values are rejected';

  my $string_enum = $runtime->execute_document(
    '{ hello(name: "Ana", color: "RED") }');
  like $string_enum->{errors}[0]{message}, qr/not a valid Color literal/,
    'strings are not accepted as enum literals';
};

subtest 'valid documents that used to be false positives execute cleanly' => sub {
  my $runtime = runtime();
  my %cases = (
    'non-null variable' =>
      [ 'query Q($n: String!) { hello(name: $n) }', { n => 'Ana' } ],
    'referenced builtin scalar list' =>
      [ 'query Q($n: String!, $tags: [Int!]) { hello(name: $n, numbers: $tags) }',
        { n => 'Ana', tags => [ 1, 2 ] } ],
    'input object variable' =>
      [ 'query Q($n: String!, $f: Filter) { hello(name: $n, filter: $f) }',
        { n => 'Ana', f => { q => 'x' } } ],
    'boolean literal argument' =>
      [ '{ hello(name: "Ana", upcase: true) }', {} ],
    'enum literal argument' =>
      [ '{ hello(name: "Ana", color: RED) }', {} ],
    'nullable variable with default into Boolean! directive arg' =>
      [ 'query Q($n: String!, $show: Boolean = true) { hello(name: $n) @include(if: $show) }',
        { n => 'Ana' } ],
  );
  for my $label (sort keys %cases) {
    my ($query, $variables) = @{ $cases{$label} };
    my $result = $runtime->execute_document($query, variables => $variables);
    ok !exists $result->{errors}, "$label passes validation"
      or diag explain $result->{errors};
    is $result->{data}{hello}, 'hi Ana', "$label executes";
  }
};

subtest 'introspection meta fields validate on the query root only' => sub {
  my $runtime = runtime();

  my $meta = $runtime->execute_document(
    '{ __schema { queryType { name } } __type(name: "Item") { name } item { __typename } }',
  );
  ok !exists $meta->{errors}, 'meta fields on the root pass'
    or diag explain $meta->{errors};
  is $meta->{data}{item}{__typename}, 'Item', '__typename anywhere';

  my $nested = $runtime->execute_document('{ item { __schema { queryType { name } } } }');
  like $nested->{errors}[0]{message}, qr/__schema.*does not exist/,
    '__schema off the root is rejected';
};

subtest 'validation can be disabled per runtime and per call' => sub {
  my $off = runtime(validate => 0);
  my $result = $off->execute_document('{ nope }');
  is_deeply $result, { data => {} },
    'validate => 0 runtime skips request validation';

  my $on = runtime();
  my $skipped = $on->execute_document('{ nope }', validate => 0);
  is_deeply $skipped, { data => {} }, 'per-call validate => 0 override';

  my $forced = $off->execute_document('{ nope }', validate => 1);
  like $forced->{errors}[0]{message}, qr/does not exist/, 'per-call validate => 1 override';
};

subtest 'program cache hits skip revalidation, invalid documents never cache' => sub {
  my $runtime = runtime();
  my $query = 'query Q($n: String!) { hello(name: $n) }';
  is $runtime->program_cache_size, 0, 'cache starts empty';
  $runtime->execute_document($query, variables => { n => 'a' });
  is $runtime->program_cache_size, 1, 'valid document cached after first run';
  my $again = $runtime->execute_document($query, variables => { n => 'b' });
  is $again->{data}{hello}, 'hi b', 'cached run executes';

  $runtime->execute_document('{ nope }');
  is $runtime->program_cache_size, 1, 'invalid document did not enter the cache';
  my $still = $runtime->execute_document('{ nope }');
  like $still->{errors}[0]{message}, qr/does not exist/, 'still rejected on repeat';
};

subtest 'the JSON lane returns the same errors-only envelope' => sub {
  my $runtime = runtime();
  my $json = $runtime->execute_document_to_json('{ nope }');
  my $decoded = JSON::PP->new->utf8->decode($json);
  ok !exists $decoded->{data}, 'no data key';
  like $decoded->{errors}[0]{message}, qr/does not exist/, 'error message';
};

subtest 'executable descriptions do not affect validation or execution' => sub {
  my $runtime = runtime();
  my $result = $runtime->execute_document(<<'GRAPHQL', variables => { name => 'Ana' });
"Operation docs"
query Described("Variable docs" $name: String!) {
  hello(name: $name)
  ...Greeting
}
"Fragment docs"
fragment Greeting on Query {
  item { name }
}
GRAPHQL
  ok !exists $result->{errors}, 'described document passes validation'
    or diag explain $result->{errors};
  is $result->{data}{hello}, 'hi Ana', 'descriptions are execution-neutral';
};

done_testing;
