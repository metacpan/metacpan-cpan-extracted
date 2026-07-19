use strict;
use warnings;

use Test::More;

use GraphQL::Houtou qw(build_schema execute build_native_runtime print_schema);
use GraphQL::Houtou::Schema;
use GraphQL::Houtou::Type::Object;
use GraphQL::Houtou::Type::InputObject;
use GraphQL::Houtou::Type::Scalar qw($String $ID);
use GraphQL::Houtou::Validation;

my $SDL = <<'SDL';
type Query {
  find(by: LookupBy): String
}

input LookupBy @oneOf {
  id: ID
  email: String
}
SDL

sub lookup_schema {
  return build_schema($SDL, resolvers => {
    Query => {
      find => sub {
        my (undef, $args) = @_;
        my ($key) = keys %{ $args->{by} };
        return "$key=$args->{by}{$key}";
      },
    },
  });
}

subtest '@oneOf is a specified directive' => sub {
  my $schema = lookup_schema();
  my $result = execute($schema, '{ __schema { directives { name locations } } }');
  ok !exists $result->{errors}, 'no errors';
  my %directives = map { $_->{name} => $_ } @{ $result->{data}{__schema}{directives} };
  ok $directives{oneOf}, '@oneOf appears in introspection';
  is_deeply $directives{oneOf}{locations}, ['INPUT_OBJECT'], 'INPUT_OBJECT location';

  my $printed = print_schema($schema);
  like $printed, qr/^input LookupBy \@oneOf \{$/m, 'usage printed on the input type';
  unlike $printed, qr/^directive \@oneOf/m, 'definition omitted like other specified directives';
};

subtest 'introspection isOneOf reflects the SDL directive' => sub {
  my $result = execute(lookup_schema(), '{ __type(name: "LookupBy") { isOneOf } }');
  ok !exists $result->{errors}, 'no errors';
  ok $result->{data}{__type}{isOneOf}, 'isOneOf true';
};

subtest 'schema validation: oneOf fields must be nullable without defaults' => sub {
  my $NonNullable = GraphQL::Houtou::Type::InputObject->new(
    name => 'BadOneOf',
    is_one_of => 1,
    fields => {
      id => { type => $ID->non_null },
      email => { type => $String, default_value => 'x@example.com' },
    },
  );
  my $schema = GraphQL::Houtou::Schema->new(
    query => GraphQL::Houtou::Type::Object->new(
      name => 'Query',
      fields => {
        find => { type => $String, args => { by => { type => $NonNullable } } },
      },
    ),
  );
  my $errors = join "\n", @{ $schema->validation_errors };
  like $errors, qr/OneOf input field BadOneOf\.id must be nullable/, 'non-null field rejected';
  like $errors, qr/OneOf input field BadOneOf\.email cannot have a default value/,
    'default value rejected';
};

subtest 'literal values validate statically' => sub {
  my $schema = lookup_schema();
  my %cases = (
    '{ find(by: { id: "1", email: "x" }) }' => qr/must specify exactly one key/,
    '{ find(by: {}) }' => qr/must specify exactly one key/,
    '{ find(by: { id: null }) }' => qr/field 'id' must be non-null/,
  );
  for my $query (sort keys %cases) {
    my $errors = GraphQL::Houtou::Validation::validate($schema, $query);
    like join("\n", map { ref $_ ? $_->{message} : $_ } @$errors), $cases{$query},
      "validate flags $query";
  }
  my $ok = GraphQL::Houtou::Validation::validate($schema, '{ find(by: { id: "1" }) }');
  is_deeply $ok, [], 'valid literal passes validation';
};

subtest 'literal values are enforced at execution' => sub {
  # validate => 0 keeps these requests on the execution-time enforcement
  # path (the request-stage validator would reject them first otherwise);
  # this is the lane persisted/pre-validated deployments run on.
  my $runtime = build_native_runtime(lookup_schema(), validate => 0);
  my $ok = $runtime->execute_document('{ find(by: { email: "x@example.com" }) }');
  ok !exists $ok->{errors}, 'no errors for exactly one field';
  is $ok->{data}{find}, 'email=x@example.com', 'value resolved';

  my $two = $runtime->execute_document('{ find(by: { id: "1", email: "x" }) }');
  like $two->{errors}[0]{message}, qr/OneOf Input Object 'LookupBy' must specify exactly one key/,
    'two keys rejected';

  my $null_value = $runtime->execute_document('{ find(by: { id: null }) }');
  like $null_value->{errors}[0]{message}, qr/OneOf Input Object 'LookupBy' field 'id' must be non-null/,
    'null value rejected';
};

subtest 'variable values are enforced at execution' => sub {
  my $runtime = build_native_runtime(lookup_schema());
  my $query = 'query Q($by: LookupBy) { find(by: $by) }';

  my $ok = $runtime->execute_document($query, variables => { by => { id => '7' } });
  ok !exists $ok->{errors}, 'no errors';
  is $ok->{data}{find}, 'id=7', 'exactly one key accepted';

  # Variable coercion failures are request errors: an errors-only
  # envelope (no data key), not an exception.
  my $two = $runtime->execute_document($query, variables => { by => { id => '7', email => 'x' } });
  ok !exists $two->{data}, 'request error has no data key';
  like $two->{errors}[0]{message}, qr/must specify exactly one key/,
    'two keys rejected via variables';

  my $empty = $runtime->execute_document($query, variables => { by => {} });
  like $empty->{errors}[0]{message}, qr/must specify exactly one key/,
    'empty object rejected via variables';

  my $null_member = $runtime->execute_document($query, variables => { by => { email => undef } });
  like $null_member->{errors}[0]{message}, qr/field 'email' must be non-null/,
    'null member rejected via variables';
};

subtest 'variable nested inside a literal object is enforced' => sub {
  my $runtime = build_native_runtime(lookup_schema());
  my $query = 'query Q($id: ID) { find(by: { id: $id }) }';

  my $ok = $runtime->execute_document($query, variables => { id => '9' });
  ok !exists $ok->{errors}, 'no errors';
  is $ok->{data}{find}, 'id=9', 'variable-fed member accepted';

  my $missing = $runtime->execute_document($query, variables => {});
  like $missing->{errors}[0]{message}, qr/OneOf Input Object 'LookupBy'/,
    'missing nested variable rejected';
};

done_testing;
