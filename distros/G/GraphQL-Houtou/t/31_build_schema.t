use strict;
use warnings;

use Test::More;

use GraphQL::Houtou qw(build_schema execute);
use GraphQL::Houtou::Schema;

my $SDL = <<'SDL';
"""A pet"""
interface Pet {
  name: String!
}

type Dog implements Pet {
  name: String!
  barkVolume: Int
}

type Query {
  dog(id: ID = "1"): Dog
  pets: [Pet!]
  now: DateTime
  color: Color
}

enum Color {
  RED @deprecated(reason: "no red")
  GREEN
}

union Thing = Dog

input LookupBy @oneOf {
  id: ID
  email: String
}

"""A point in time"""
scalar DateTime @specifiedBy(url: "https://example.com/dt")

directive @slow(ms: Int) repeatable on FIELD | VARIABLE_DEFINITION
SDL

subtest 'build_schema constructs an executable schema' => sub {
  my $schema = build_schema($SDL, resolvers => {
    Query => {
      dog => sub {
        my (undef, $args) = @_;
        return { name => "Rex-$args->{id}", barkVolume => 3 };
      },
      now => sub { '2026-07-04T00:00:00Z' },
    },
  });
  isa_ok $schema, 'GraphQL::Houtou::Schema';

  my $result = execute($schema, '{ dog { name barkVolume } now }');
  ok !exists $result->{errors}, 'no execution errors';
  is_deeply $result->{data}, {
    dog => { name => 'Rex-1', barkVolume => 3 },
    now => '2026-07-04T00:00:00Z',
  }, 'resolvers and argument default values work';
};

subtest 'type registry round trip' => sub {
  my $schema = GraphQL::Houtou::Schema->from_doc($SDL);
  my $name2type = $schema->name2type;

  isa_ok $name2type->{Dog}, 'GraphQL::Houtou::Type::Object';
  isa_ok $name2type->{Pet}, 'GraphQL::Houtou::Type::Interface';
  isa_ok $name2type->{Color}, 'GraphQL::Houtou::Type::Enum';
  isa_ok $name2type->{Thing}, 'GraphQL::Houtou::Type::Union';
  isa_ok $name2type->{LookupBy}, 'GraphQL::Houtou::Type::InputObject';
  isa_ok $name2type->{DateTime}, 'GraphQL::Houtou::Type::Scalar';

  is $name2type->{Pet}{description}, 'A pet', 'type description preserved';
  is_deeply [ map { $_->name } @{ $name2type->{Dog}->interfaces } ], ['Pet'],
    'implements list resolved to type objects';
  is_deeply [ map { $_->name } @{ $name2type->{Thing}->types } ], ['Dog'],
    'union members resolved to type objects';

  my $dog_fields = $name2type->{Dog}->fields;
  is $dog_fields->{name}{type}->to_string, 'String!', 'non-null wrapper resolved';

  my $values = $name2type->{Color}->values;
  is $values->{RED}{deprecation_reason}, 'no red',
    '@deprecated on enum value mapped to deprecation_reason';
  ok !$values->{GREEN}{deprecation_reason}, 'GREEN not deprecated';

  is $name2type->{DateTime}->specified_by_url, 'https://example.com/dt',
    '@specifiedBy mapped to specified_by_url';

  my %directives = map { $_->name => $_ } @{ $schema->directives };
  ok $directives{slow}, 'custom directive registered';
  ok $directives{slow}->repeatable, 'repeatable keyword parsed';
  is_deeply $directives{slow}->locations, [qw(FIELD VARIABLE_DEFINITION)],
    'directive locations preserved';
  is $directives{slow}->args->{ms}{type}->to_string, 'Int',
    'directive argument type resolved';
  ok $directives{skip}, 'specified directives are kept alongside custom ones';
};

subtest 'root operation types come from the schema definition' => sub {
  my $schema = GraphQL::Houtou::Schema->from_doc('
    schema { query: RootQ mutation: RootM }
    type RootQ { ping: String }
    type RootM { bump: String }
  ');
  is $schema->query->name, 'RootQ', 'explicit query root respected';
  is $schema->mutation->name, 'RootM', 'explicit mutation root respected';
};

subtest 'root operation types are inferred by name' => sub {
  my $schema = GraphQL::Houtou::Schema->from_doc('
    type Query { ping: String }
    type Mutation { bump: String }
  ');
  is $schema->query->name, 'Query', 'Query inferred';
  is $schema->mutation->name, 'Mutation', 'Mutation inferred';
};

subtest 'forward references across definitions work' => sub {
  my $schema = GraphQL::Houtou::Schema->from_doc('
    type Query { user: User }
    type User { name: String friends: [User] }
  ');
  my $result = $schema->execute(
    '{ user { name friends { name } } }',
    root_value => {
      user => { name => 'a', friends => [ { name => 'b' } ] },
    },
  );
  ok !exists $result->{errors}, 'no errors';
  is $result->{data}{user}{friends}[0]{name}, 'b',
    'self-referencing type resolves lazily';
};

subtest 'type system extensions are merged before schema construction' => sub {
  my $extension_sdl = <<'SDL';
type Query { base: String }
extend type Query { greeting: String }

interface Resource { id: ID! }
interface Named { id: ID! name: String! }
extend interface Named implements Resource { label: String }
type User implements Named & Resource { id: ID! name: String! label: String role: Role }

enum Role { USER }
extend enum Role { ADMIN }

input Filter { name: String }
extend input Filter { role: Role }

union Result = User
type Team { name: String! }
extend union Result = Team

scalar Token
extend scalar Token @specifiedBy(url: "https://example.com/token")
SDL
  my $schema = build_schema($extension_sdl, resolvers => {
    Query => { greeting => sub { 'hello' } },
  });

  is $schema->query->fields->{greeting}{type}->to_string, 'String',
    'object extension field is available';
  is $schema->name2type->{Named}->fields->{label}{type}->to_string, 'String',
    'interface extension field is available';
  is_deeply [ map { $_->name } @{ $schema->name2type->{Named}->interfaces } ],
    ['Resource'], 'interface extension can add an implemented interface';
  is_deeply [ map { $_->name } @{ $schema->get_possible_types($schema->name2type->{Resource}) } ],
    ['User'], 'possible object types propagate through interface inheritance';
  ok $schema->name2type->{Role}->values->{ADMIN}, 'enum extension value is available';
  is $schema->name2type->{Filter}->fields->{role}{type}->to_string, 'Role',
    'input extension field is available';
  is_deeply [ map { $_->name } @{ $schema->name2type->{Result}->types } ],
    [qw(User Team)], 'union extension member is available';
  is $schema->name2type->{Token}->specified_by_url, 'https://example.com/token',
    'scalar extension directive is applied';
  is execute($schema, '{ greeting }')->{data}{greeting}, 'hello',
    'resolver can attach to an extension field';
};

subtest 'schema extensions can supply operation roots' => sub {
  my $schema = build_schema('
    type Query { ping: String }
    type RootMutation { update: String }
    extend schema { mutation: RootMutation }
  ');
  is $schema->query->name, 'Query', 'implicit query root is retained';
  is $schema->mutation->name, 'RootMutation', 'mutation root comes from schema extension';
};

subtest 'invalid type system extensions are rejected' => sub {
  eval { build_schema('type Query { a: String } extend type Missing { b: String }') };
  like $@, qr/Cannot extend type 'Missing'/, 'extension target must exist';

  eval { build_schema('type Query { a: String } extend type Query { a: Int }') };
  like $@, qr/redefines fields 'a'/, 'extension cannot redefine a field';

  eval { build_schema('type Query { a: String } extend enum Query { A }') };
  like $@, qr/Cannot extend type 'Query' as enum/, 'extension kind must match target';

  eval { build_schema('
    directive @once on OBJECT
    type Query @once { a: String }
    extend type Query @once
  ') };
  like $@, qr/repeats non-repeatable directive '\@once'/,
    'extension cannot repeat a non-repeatable directive';

  my $repeatable = eval { build_schema('
    directive @tag repeatable on OBJECT
    type Query @tag { a: String }
    extend type Query @tag
  ') };
  ok $repeatable, 'extension may repeat a repeatable directive';

  my $invalid_inheritance = build_schema('
    interface Resource { id: ID! }
    interface Named implements Resource { id: ID! name: String! }
    type Query implements Named { id: ID! name: String! }
  ');
  like join("\n", @{ $invalid_inheritance->validation_errors }),
    qr/Query must implement Resource because it is implemented by Named/,
    'implementors must explicitly include inherited interfaces';
};

subtest 'abstract dispatch via resolvers option' => sub {
  my $schema = build_schema('
    type Query { pets: [Pet!] }
    interface Pet { name: String! }
    type Dog implements Pet { name: String! }
  ', resolvers => {
    Query => { pets => sub { [ { name => 'Rex' } ] } },
    Pet => { resolve_type => sub { 'Dog' } },
  });
  my $result = execute($schema, '{ pets { name } }');
  ok !exists $result->{errors}, 'no errors';
  is $result->{data}{pets}[0]{name}, 'Rex', 'interface dispatch works';
};

subtest 'build errors' => sub {
  eval { GraphQL::Houtou::Schema->from_doc('type Query { a: String } type Query { b: String }') };
  like $@, qr/Type 'Query' was defined more than once/, 'duplicate type';

  eval { GraphQL::Houtou::Schema->from_doc('type Foo { a: String }') };
  like $@, qr/Must provide schema definition with query type or a type named Query/,
    'missing query root';

  eval { GraphQL::Houtou::Schema->from_doc('schema { query: Nope } type Query { a: String }') };
  like $@, qr/Specified query type 'Nope' not found/, 'unknown root type';

  eval {
    my $schema = GraphQL::Houtou::Schema->from_doc('type Query { a: Missing }');
    $schema->query->fields;
  };
  like $@, qr/Unknown type 'Missing'/, 'unknown field type reference';

  eval {
    GraphQL::Houtou::Schema->from_doc('
      schema { query: Query }
      schema { query: Query }
      type Query { a: String }
    ');
  };
  like $@, qr/Must provide only one schema definition/, 'duplicate schema definition';

  eval { build_schema('type Query { a: String }', resolvers => { Nope => {} }) };
  like $@, qr/Cannot attach resolvers to unknown type 'Nope'/, 'unknown resolver type';

  eval { build_schema('type Query { a: String }', resolvers => { Query => { nope => sub {} } }) };
  like $@, qr/Cannot attach a field resolver to 'Query\.nope'/, 'unknown resolver field';

  eval { build_schema('type Query { a: String a: Int }') };
  like $@, qr/Type field 'a' is defined more than once/, 'duplicate SDL field';

  eval { build_schema('type Query { a(x: String, x: Int): String }') };
  like $@, qr/Argument 'x' is defined more than once/, 'duplicate SDL argument';

  eval { build_schema('type Query { a(input: Filter): String } input Filter { x: String x: Int }') };
  like $@, qr/Input field 'x' is defined more than once/, 'duplicate SDL input field';

  eval { build_schema('type Query { color: Color } enum Color { RED RED }') };
  like $@, qr/Enum value 'RED' is defined more than once/, 'duplicate SDL enum value';
};

subtest 'custom scalars pass values through by default' => sub {
  my $schema = build_schema('
    type Query { when: DateTime }
    scalar DateTime
  ', resolvers => {
    Query => { when => sub { '2026-07-04' } },
  });
  my $result = execute($schema, '{ when }');
  ok !exists $result->{errors}, 'no errors';
  is $result->{data}{when}, '2026-07-04', 'identity serialize';
};

subtest 'type-system directive applications are validated' => sub {
  my $valid = GraphQL::Houtou::Schema->from_doc(<<'SDL');
directive @tag(label: String!, rank: Int) repeatable on OBJECT | FIELD_DEFINITION
type Query @tag(label: "root") {
  value: String @deprecated(reason: "old") @tag(label: "first", rank: 1) @tag(label: "second")
}
SDL
  is_deeply $valid->validation_errors, [],
    'defined repeatable directive with valid locations and arguments passes';
  is scalar(@{ $valid->name2type->{Query}->fields->{value}{directives} || [] }), 2,
    'non-deprecated directives survive deprecated metadata extraction';

  my @cases = (
    [
      'type Query @missing { value: String }',
      qr/Unknown directive '\@missing' on type Query/,
      'unknown directive',
    ],
    [
      'directive @fieldOnly on FIELD_DEFINITION type Query @fieldOnly { value: String }',
      qr/cannot be used at OBJECT on type Query/,
      'invalid directive location',
    ],
    [
      'directive @once on OBJECT type Query @once @once { value: String }',
      qr/is not repeatable and cannot be used more than once/,
      'duplicate non-repeatable directive',
    ],
    [
      'directive @tag(label: String!) on OBJECT type Query @tag { value: String }',
      qr/Required argument 'label' was not provided/,
      'missing required directive argument',
    ],
    [
      'directive @tag(rank: Int) on OBJECT type Query @tag(rank: "high") { value: String }',
      qr/Argument 'rank'.*is invalid for type Int/,
      'invalid directive argument value',
    ],
    [
      'input Filter { required: String! } directive @tag(filter: Filter) on OBJECT type Query @tag(filter: {}) { value: String }',
      qr/Argument 'filter'.*required input field required is missing/,
      'missing nested required input field',
    ],
    [
      'directive @tag on OBJECT type Query @tag(extra: true) { value: String }',
      qr/Unknown argument 'extra' on directive '\@tag'/,
      'unknown directive argument',
    ],
    [
      'type Query @deprecated { value: String }',
      qr/Directive '\@deprecated' cannot be used at OBJECT/,
      'specified directive location is enforced',
    ],
    [
      'directive @tag on OBJECT | OBJECT type Query { value: String }',
      qr/Directive '\@tag' repeats location 'OBJECT'/,
      'directive definition locations must be unique',
    ],
    [
      'directive @tag on SOMEWHERE type Query { value: String }',
      qr/Directive '\@tag' has unknown location 'SOMEWHERE'/,
      'directive definition locations must be recognized',
    ],
  );
  for my $case (@cases) {
    my ($sdl, $pattern, $label) = @$case;
    my $schema = GraphQL::Houtou::Schema->from_doc($sdl);
    like join("\n", @{ $schema->validation_errors }), $pattern, $label;
  }

  my $parsed = eval {
    GraphQL::Houtou::Schema->from_doc(
      'directive @tag(label: String) on OBJECT type Query @tag(label: $value) { value: String }',
    );
    1;
  };
  ok !$parsed, 'variables are rejected in type-system directive arguments';
  like $@, qr/Expected name or constant/,
    'type-system directive arguments use constant values';
};

done_testing;
