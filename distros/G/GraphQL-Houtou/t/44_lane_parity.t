use strict;
use warnings;
use Test::More 0.98;

# Completion semantics exist once per execution lane (async, fast SV which
# also backs execute_bundle, and fast JSON), so a guard added to one lane
# can silently be missing from the others (docs/xs-coding-rules.md rule 8).
# This test runs one battery of completion edge cases through every lane
# and asserts they all produce the same normalized response:
#   - an abstract value that resolves to no member type is a field error
#     plus null (never the raw source hash leaking unselected fields)
#   - a non-arrayref resolver result for a list field is a field error
#     plus null (never a request-killing croak, never the raw value)
#   - errors inside list items carry the item index in their path
#
# The one intended representation difference: booleans are 1/0 in the Perl
# envelope and true/false in JSON, so normalization maps them together.

use JSON::PP ();

use GraphQL::Houtou qw(build_native_runtime);
use GraphQL::Houtou::Schema;
use GraphQL::Houtou::Type::Interface;
use GraphQL::Houtou::Type::Object;
use GraphQL::Houtou::Type::Scalar qw($String);

my $json = JSON::PP->new->canonical->allow_nonref;

my $Node = GraphQL::Houtou::Type::Interface->new(
  name => 'Node',
  fields => { name => { type => $String } },
  tag_resolver => sub { $_[0]{kind} },
);
my $Ship = GraphQL::Houtou::Type::Object->new(
  name => 'Ship',
  interfaces => [ $Node ],
  runtime_tag => 'ship',
  fields => {
    name => { type => $String },
    boom => { type => $String, resolve => sub { die "boom\n" } },
  },
);

my $schema = GraphQL::Houtou::Schema->new(
  query => GraphQL::Houtou::Type::Object->new(
    name => 'Query',
    fields => {
      shipsScalar => { type => $Ship->list, resolve => sub { 'not-a-list' } },
      nodeNoMatch => { type => $Node, resolve => sub { +{ kind => 'ghost', name => 'g' } } },
      nodesMixed => {
        type => $Node->list,
        resolve => sub { [ { kind => 'ship', name => 'a' }, { kind => 'ghost', name => 'g' } ] },
      },
      ships => {
        type => $Ship->list,
        resolve => sub { [ { kind => 'ship', name => 'a' }, { kind => 'ship', name => 'b' } ] },
      },
    },
  ),
  types => [ $Node, $Ship ],
);

my $ABSTRACT_ERROR = 'Abstract type Node must resolve to an Object type at runtime';

my %CASES = (
  'non-arrayref list value is a field error' => {
    query => '{ shipsScalar { name } }',
    expected => {
      data => { shipsScalar => undef },
      errors => [
        { message => 'list value must be an array reference', path => ['shipsScalar'] },
      ],
    },
  },
  'unresolvable abstract value is a field error' => {
    query => '{ nodeNoMatch { name } }',
    expected => {
      data => { nodeNoMatch => undef },
      errors => [ { message => $ABSTRACT_ERROR, path => ['nodeNoMatch'] } ],
    },
  },
  'unresolvable abstract list item is a field error with its index' => {
    query => '{ nodesMixed { name } }',
    expected => {
      data => { nodesMixed => [ { name => 'a' }, undef ] },
      errors => [ { message => $ABSTRACT_ERROR, path => [ 'nodesMixed', 1 ] } ],
    },
  },
  'list item resolver errors carry the item index in their path' => {
    query => '{ ships { name boom } }',
    expected => {
      data => { ships => [
        { name => 'a', boom => undef },
        { name => 'b', boom => undef },
      ] },
      errors => [
        { message => 'boom', path => [ 'ships', 0, 'boom' ] },
        { message => 'boom', path => [ 'ships', 1, 'boom' ] },
      ],
    },
  },
);

# Decode/normalize a lane result (envelope or JSON text) into one shape:
# booleans and JSON::PP wrappers flattened, errors reduced to message+path
# and sorted for stable comparison.
sub normalize {
  my ($result) = @_;
  my $decoded = ref $result ? $result : $json->decode($result);
  my $envelope = {
    data => _plain($decoded->{data}),
    errors => [
      sort { ($a->{message} cmp $b->{message}) || ($json->encode($a->{path}) cmp $json->encode($b->{path})) }
      map { { message => _chomped($_->{message}), path => _plain($_->{path}) } }
      @{ $decoded->{errors} || [] }
    ],
  };
  return $envelope;
}

sub _chomped { my ($m) = @_; $m =~ s/\n\z// if defined $m; $m }

sub _plain {
  my ($value) = @_;
  return undef if !defined $value;
  if (ref $value eq 'HASH') {
    return { map { ($_ => _plain($value->{$_})) } keys %$value };
  }
  if (ref $value eq 'ARRAY') {
    return [ map { _plain($_) } @$value ];
  }
  return $value ? 1 : 0 if JSON::PP::is_bool($value);
  return "$value";
}

for my $label (sort keys %CASES) {
  my ($query, $expected) = @{ $CASES{$label} }{qw(query expected)};
  subtest $label => sub {
    my $runtime = build_native_runtime($schema);
    my $bundle = $runtime->compile_bundle_for_document($query);
    my %lanes = (
      'async auto (no variables)' => $runtime->execute_document($query),
      'fast SV (with variables)' => $runtime->execute_document($query, variables => {}),
      'fast JSON (no variables)' => $runtime->execute_document_to_json($query),
      'fast JSON (with variables)' => $runtime->execute_document_to_json($query, variables => {}),
      'bundle envelope' => $runtime->execute_bundle($bundle),
      'bundle JSON' => $runtime->execute_bundle_to_json($bundle),
    );
    my $want = normalize({ %$expected });
    for my $lane (sort keys %lanes) {
      is_deeply normalize($lanes{$lane}), $want, $lane;
    }
  };
}

subtest 'successful responses omit errors in every lane' => sub {
  my $query = '{ ships { name } }';
  my $runtime = build_native_runtime($schema);
  my $bundle = $runtime->compile_bundle_for_document($query);
  my %lanes = (
    'async auto (no variables)' => $runtime->execute_document($query),
    'fast SV (with variables)' => $runtime->execute_document($query, variables => {}),
    'fast JSON (no variables)' => $json->decode(
      $runtime->execute_document_to_json($query),
    ),
    'fast JSON (with variables)' => $json->decode(
      $runtime->execute_document_to_json($query, variables => {}),
    ),
    'bundle envelope' => $runtime->execute_bundle($bundle),
    'bundle JSON' => $json->decode($runtime->execute_bundle_to_json($bundle)),
  );
  for my $lane (sort keys %lanes) {
    ok !exists $lanes{$lane}{errors}, $lane;
  }
};

done_testing;
