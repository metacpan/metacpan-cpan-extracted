use strict;
use warnings;

use Test::More 0.98;

use GraphQL::Houtou::Schema;
use GraphQL::Houtou::Directive;
use GraphQL::Houtou::Type::Interface;
use GraphQL::Houtou::Type::InputObject;
use GraphQL::Houtou::Type::Object;
use GraphQL::Houtou::Type::Scalar;
use GraphQL::Houtou::Type::Scalar qw($Boolean $String);
use GraphQL::Houtou::Schema qw(lookup_type);

use GraphQL::Houtou::Validation qw(check_query_cost validate);

my $Node;
my $User;
my $Page;

$Node = GraphQL::Houtou::Type::Interface->new(
  name => 'Node',
  fields => {
    id => { type => $String->non_null },
  },
  resolve_type => sub { $User },
);

$User = GraphQL::Houtou::Type::Object->new(
  name => 'User',
  interfaces => [ $Node ],
  fields => {
    id => { type => $String->non_null },
    name => { type => $String },
  },
);

$Page = GraphQL::Houtou::Type::Object->new(
  name => 'Page',
  interfaces => [ $Node ],
  fields => {
    id => { type => $String->non_null },
    title => { type => $String },
  },
);

my $Mutation = GraphQL::Houtou::Type::Object->new(
  name => 'Mutation',
  fields => {
    renameUser => {
      type => $User,
      args => {
        id => { type => $String->non_null },
        name => { type => $String->non_null },
      },
      resolve => sub { +{} },
    },
  },
);

my $Subscription = GraphQL::Houtou::Type::Object->new(
  name => 'Subscription',
  fields => {
    importantUser => {
      type => $User,
      resolve => sub { +{} },
    },
    otherUser => {
      type => $User,
      resolve => sub { +{} },
    },
  },
);

my $Odd = GraphQL::Houtou::Type::Scalar->new(
  name => 'Odd',
  serialize => sub { $_[0] },
  parse_value => sub { $_[0] eq 'odd' ? $_[0] : die "Not odd.\n" },
);

my $LookupInput = GraphQL::Houtou::Type::InputObject->new(
  name => 'LookupInput',
  fields => { id => { type => $String->non_null } },
);

my $schema = GraphQL::Houtou::Schema->new(
  query => GraphQL::Houtou::Type::Object->new(
    name => 'Query',
    fields => {
      viewer => {
        type => $User,
        directives => [],
        resolve => sub { +{} },
      },
      node => {
        type => $Node,
        args => {
          id => { type => $String->non_null },
        },
        resolve => sub { +{} },
      },
      lookup => {
        type => $Node,
        args => { input => { type => $LookupInput->non_null } },
        resolve => sub { +{} },
      },
      listShapes => {
        type => $String,
        cost => 7,
        args => {
          required => { type => $String->list->non_null },
          nested => { type => $String->non_null->list->non_null->list->non_null },
        },
        resolve => sub { 'ok' },
      },
      users => {
        type => $User->list,
        cost => 2,
        list_size => 5,
        resolve => sub { [] },
      },
      tags => {
        type => $String->list,
        cost => 2,
        list_size => 100,
        resolve => sub { [] },
      },
    },
  ),
  mutation => $Mutation,
  subscription => $Subscription,
  types => [ $User, $Page, $Node, $Odd, $LookupInput ],
  directives => [
    @GraphQL::Houtou::Directive::SPECIFIED_DIRECTIVES,
    GraphQL::Houtou::Directive->new(
      name => 'mask',
      locations => [ qw(FIELD) ],
      args => {
        enabled => { type => $Boolean->non_null },
      },
    ),
    GraphQL::Houtou::Directive->new(
      name => 'tag',
      repeatable => 1,
      locations => [ qw(FIELD) ],
      args => {
        name => { type => $String->non_null },
      },
    ),
    GraphQL::Houtou::Directive->new(
      name => 'odd',
      locations => [ qw(FIELD) ],
      args => { value => { type => $Odd->non_null } },
    ),
    GraphQL::Houtou::Directive->new(
      name => 'flags',
      locations => [ qw(FIELD) ],
      args => { values => { type => $Boolean->list } },
    ),
    GraphQL::Houtou::Directive->new(
      name => 'variableTag',
      locations => [ qw(VARIABLE_DEFINITION) ],
      args => { enabled => { type => $Boolean->non_null } },
    ),
  ],
);

sub messages {
  my ($errors) = @_;
  return [ map $_->{message}, @$errors ];
}

subtest 'validation facade stays minimal' => sub {
  is_deeply [ sort @GraphQL::Houtou::Validation::EXPORT_OK ],
    [qw(check_query_cost validate)], 'validation and cost APIs are exported';
  ok(
    GraphQL::Houtou::Validation->can('validate'),
    'public validate entrypoint exists',
  );
  ok(
    !GraphQL::Houtou::Validation->can('validate_xs'),
    'internal XS symbol is not exposed as public facade method',
  );
};

subtest 'weighted query cost is enforced in XS' => sub {
  my $query = q|{ users { id name } }|;
  is_deeply check_query_cost($schema, $query, max_cost => 12), [],
    'field cost plus list multiplier fits the exact budget';

  is_deeply check_query_cost(
    $schema,
    q|query Cheap { shape } query Expensive { users { id name } }|,
    max_cost => 1,
    operation_name => 'Cheap',
  ), [], 'only the selected operation contributes to query cost';

  is_deeply messages(check_query_cost($schema, $query, max_cost => 11)), [
    'Query cost exceeds maximum of 11 in anonymous operation',
  ], 'list result multiplies its child selection cost';

  is_deeply check_query_cost(
    $schema, q|{ listShapes(required: ["a"], nested: [["b"]]) }|,
    max_cost => 7,
  ), [], 'custom leaf cost is used';

  is_deeply messages(check_query_cost(
    $schema, q|{ tags }|, max_cost => 101,
  )), [
    'Query cost exceeds maximum of 101 in anonymous operation',
  ], 'scalar lists charge their estimated result item count';

  my $runtime = $schema->build_native_runtime(
    max_cost => 11,
    validate => 0,
    program_cache_max => 0,
  );
  my $result = $runtime->execute_document($query);
  is_deeply messages($result->{errors}), [
    'Query cost exceeds maximum of 11 in anonymous operation',
  ], 'runtime enforces cost independently from document validation';

  $result = $runtime->execute_document($query, max_cost => 12);
  ok !exists $result->{errors}, 'per-call cost limit can override the runtime';

  my $cached_runtime = $schema->build_native_runtime(
    max_cost => 12,
    validate => 0,
    program_cache_max => 2,
  );
  $result = $cached_runtime->execute_document($query);
  ok !exists $result->{errors},
    'query enters the program cache after passing its cost limit';
  $result = $cached_runtime->execute_document($query, max_cost => 11);
  is_deeply messages($result->{errors}), [
    'Query cost exceeds maximum of 11 in anonymous operation',
  ], 'a stricter per-call limit is not bypassed by a cached program';
};

subtest 'valid query passes' => sub {
  my $errors = validate($schema, q|{
    viewer {
      id
      name
    }
  }|);

  is_deeply $errors, [], 'no validation errors';
};

subtest 'type system definitions are not executable' => sub {
  my $errors = validate($schema, q|
    type LocalOnly { id: String }
    query Q { viewer { id } }
  |);
  is_deeply messages($errors), [
    "The 'type' definition is not executable.",
  ];
};

subtest 'lookup_type resolves Houtou wrappers' => sub {
  my $type = lookup_type(
    { type => [ list => { type => [ non_null => { type => 'String' } ] } ] },
    $schema->name2type,
  );

  isa_ok $type, 'GraphQL::Houtou::Type::List';
  isa_ok $type->of, 'GraphQL::Houtou::Type::NonNull';
  isa_ok $type->of->of, 'GraphQL::Houtou::Type::Scalar';
  is $type->of->of->name, 'String', 'named leaf stays Houtou scalar';
};

subtest 'duplicate operation names are rejected' => sub {
  my $errors = validate($schema, q|
    query Q { viewer { id } }
    query Q { viewer { name } }
  |);

  is_deeply messages($errors), [
    "Operation 'Q' is defined more than once.",
  ];
};

subtest 'duplicate fragment names are rejected' => sub {
  my $errors = validate($schema, q|
    query Q { viewer { ...UserFields } }
    fragment UserFields on User { id }
    fragment UserFields on User { name }
  |);

  is_deeply messages($errors), [
    "Fragment 'UserFields' is defined more than once.",
  ];
};

subtest 'duplicate arguments and variables are rejected before hash overwrite' => sub {
  my $errors = validate($schema, q|{
    node(id: "first", id: "second") { id }
  }|);
  is_deeply messages($errors), [
    "Argument 'id' is provided more than once.",
  ], 'duplicate field arguments are retained as validation diagnostics';

  $errors = validate($schema, q|
    query Q($id: String!, $id: String!) { node(id: $id) { id } }
  |);
  is_deeply messages($errors), [
    "Variable '\$id' is defined more than once.",
  ], 'duplicate variable definitions are retained as validation diagnostics';
};

subtest 'duplicate input object fields are rejected before hash overwrite' => sub {
  my $errors = validate($schema, q|{
    lookup(input: { id: "first", id: "second" }) { id }
  }|);
  is_deeply messages($errors), [
    "Input field 'id' is provided more than once.",
  ];
};

subtest 'leaf and composite fields require the correct selection shape' => sub {
  my $errors = validate($schema, q|{
    viewer
  }|);
  is_deeply messages($errors), [
    "Field 'viewer' of type 'User' must have a selection of subfields.",
  ], 'composite field without a selection is rejected';

  $errors = validate($schema, q|{
    viewer { name { id } }
  }|);
  is_deeply messages($errors), [
    "Field 'name' must not have a selection since type 'String' has no subfields.",
  ], 'leaf field with a selection is rejected without cascading errors';
};

subtest 'direct fields with the same response key must merge' => sub {
  my $errors = validate($schema, q|{
    viewer { value: id value: name }
  }|);
  is_deeply messages($errors), [
    "Fields 'value' conflict because they select different fields or arguments.",
  ], 'aliases cannot merge different fields';

  $errors = validate($schema, q|{
    first: node(id: "1") { id }
    first: node(id: "2") { id }
  }|);
  is_deeply messages($errors), [
    "Fields 'first' conflict because they select different fields or arguments.",
  ], 'the same field with different arguments conflicts';

  $errors = validate($schema, q|{
    viewer { value: name value: name }
  }|);
  is_deeply $errors, [], 'identical fields can merge';

  my $duplicate_flood = join ' ', ('value: name') x 1_000;
  $errors = validate($schema, "{ viewer { $duplicate_flood } }");
  is_deeply $errors, [], 'same-key duplicate floods stay mergeable';
};

subtest 'field merging expands fragments and respects exclusive types' => sub {
  my $errors = validate($schema, q|
    query Q { viewer { ...A ...B } }
    fragment A on User { value: id }
    fragment B on User { value: name }
  |);
  is_deeply messages($errors), [
    "Fields 'value' conflict because they select different fields or arguments.",
  ], 'conflicts across fragment spreads are rejected';

  $errors = validate($schema, q|{
    node(id: "1") {
      ... on User { value: name }
      ... on Page { value: title }
    }
  }|);
  is_deeply $errors, [], 'different object type conditions are mutually exclusive'
    or diag explain $errors;

  $errors = validate($schema, q|{
    node(id: "1") {
      ... on User { value: name }
      ... on Page { value: id }
    }
  }|);
  is_deeply messages($errors), [
    "Fields 'value' conflict because they select different fields or arguments.",
  ], 'exclusive fields must still have the same response shape';
};

subtest 'merged composite fields validate their combined subfields' => sub {
  my $errors = validate($schema, q|{
    first: viewer { value: id }
    first: viewer { value: name }
  }|);
  is_deeply messages($errors), [
    "Fields 'value' conflict because they select different fields or arguments.",
  ], 'subfield conflicts split across composite fields are rejected';

  $errors = validate($schema, q|{
    first: viewer { id }
    first: viewer { name }
  }|);
  is_deeply $errors, [], 'compatible composite selections merge';

  my $composite_flood = join ' ', ('first: viewer { id }') x 1_000;
  $errors = validate($schema, "{ $composite_flood }");
  is_deeply $errors, [], 'same-key composite floods stay mergeable';
};

subtest 'anonymous operation must be alone' => sub {
  my $errors = validate($schema, q|
    { viewer { id } }
    query Q { viewer { id } }
  |);

  is_deeply messages($errors), [
    'Anonymous operations must be the only operation in the document.',
  ];
};

subtest 'unknown field and missing required argument are rejected' => sub {
  my $errors = validate($schema, q|{
    viewer {
      missing
    }
    node {
      id
    }
  }|);

  is_deeply messages($errors), [
    "Field 'missing' does not exist on type 'User'.",
    "Required argument 'id' was not provided.",
  ];
};

subtest 'output types cannot be used as variables' => sub {
  my $errors = validate($schema, q|
    query Q($user: User) {
      viewer { id }
    }
  |);

  is_deeply messages($errors), [
    "Variable '\$user' is never used in operation 'Q'.",
    "Variable '\$user' is type 'User' which cannot be used as an input type.",
  ];
};

subtest 'undefined variable use is rejected' => sub {
  my $errors = validate($schema, q|{
    node(id: $id) {
      id
    }
  }|);

  is_deeply messages($errors), [
    "Variable '\$id' is used but not defined.",
  ];
};

subtest 'field arguments enforce variable positions in XS' => sub {
  my $errors = validate($schema, q|
    query Q($id: Boolean) { node(id: $id) { id } }
  |);
  is_deeply messages($errors), [
    "Variable '\$id' cannot be used for argument 'id' because its type is incompatible.",
  ];

  $errors = validate($schema, q|
    query Q($id: String = "1") { node(id: $id) { id } }
  |);
  is_deeply $errors, [], 'a non-null variable default permits a nullable variable';
};

subtest 'built-in scalar literals are validated in XS' => sub {
  my $errors = validate($schema, q|{
    node(id: true) { id }
  }|);
  is_deeply messages($errors), [
    'Value is not a valid String literal.',
  ];
};

subtest 'literal shape and non-null values are validated in XS' => sub {
  my $errors = validate($schema, q|{
    node(id: null) { id }
  }|);
  is_deeply messages($errors), [
    "Null is not a valid value for non-null type 'String'.",
  ], 'an explicit null cannot satisfy a non-null argument';

  $errors = validate($schema, q|{
    node(id: []) { id }
  }|);
  is_deeply messages($errors), [
    'List value is not valid for a non-list type.',
  ], 'an empty list cannot bypass scalar validation';

  $errors = validate($schema, q|{
    node(id: {}) { id }
  }|);
  is_deeply messages($errors), [
    'Input object value is not valid for a non-input-object type.',
  ], 'an empty object cannot bypass scalar validation';

  $errors = validate($schema, q|{
    lookup(input: "not-an-object") { id }
  }|);
  is_deeply messages($errors), [
    'Scalar value is not valid for an input object type.',
  ], 'a scalar cannot satisfy an input object argument';
};

subtest 'non-null list wrappers validate compiled schema types' => sub {
  my $errors = validate($schema, q|{
    listShapes(required: ["a", "b"], nested: [["a"], ["b"]])
  }|);
  is_deeply $errors, [], 'non-null and nested list literals are accepted';

  $errors = validate($schema, q|{
    listShapes(required: "a", nested: "b")
  }|);
  is_deeply $errors, [], 'a single value is promoted through list wrappers';

  $errors = validate($schema, q|{
    listShapes(required: ["a"], nested: [[null]])
  }|);
  is_deeply messages($errors), [
    "Null is not a valid value for non-null type 'String'.",
  ], 'nested non-null list items are enforced';
};

subtest 'variable default values are validated in XS' => sub {
  my $errors = validate($schema, q|
    query Q($id: String = true) { node(id: $id) { id } }
  |);
  is_deeply messages($errors), [
    'Value is not a valid String literal.',
  ], 'a variable default must match its declared input type';

  $errors = validate($schema, q|
    query Q($id: String = "1") { node(id: $id) { id } }
  |);
  is_deeply $errors, [], 'a correctly typed variable default is accepted';
};

subtest 'unused variables are rejected, including fragment-aware usage' => sub {
  my $errors = validate($schema, q|
    query Q($used: Boolean!, $unused: String) {
      node(id: "1") { ...UserName }
    }
    fragment UserName on User { name @include(if: $used) }
  |);

  is_deeply messages($errors), [
    "Variable '\$unused' is never used in operation 'Q'.",
  ], 'a variable used through a fragment counts as used';
};

subtest 'unused fragments are rejected using transitive operation reachability' => sub {
  my $errors = validate($schema, q|
    query Q { viewer { ...Outer } }
    fragment Outer on User { ...Inner }
    fragment Inner on User { id }
    fragment Unused on User { name }
  |);

  is_deeply messages($errors), [
    "Fragment 'Unused' is never used.",
  ], 'transitively reached fragments are used';
};

subtest 'unknown fragment targets and cycles are rejected' => sub {
  my $errors = validate($schema, q|
    query Q { viewer { ...Loop } }
    fragment Loop on MissingType { ...Loop }
  |);

  is_deeply messages($errors), [
    "Fragment 'Loop' references unknown type 'MissingType'.",
    "Fragment 'Loop' participates in a cycle.",
  ];
};

subtest 'fragment spreads must be type-compatible' => sub {
  my $errors = validate($schema, q|
    query Q {
      viewer {
        ...OnQuery
      }
    }

    fragment OnQuery on Query {
      viewer { id }
    }
  |);

  is_deeply messages($errors), [
    "Fragment 'OnQuery' cannot be spread here because type 'Query' can never apply to 'User'.",
  ];
};

subtest 'inline fragments must be type-compatible' => sub {
  my $errors = validate($schema, q|
    query Q {
      viewer {
        ... on Query {
          viewer { id }
        }
      }
    }
  |);

  is_deeply messages($errors), [
    "Inline fragment on 'Query' cannot be used where type 'User' is expected.",
  ];
};

subtest 'subscription must have a single top-level field' => sub {
  my $errors = validate($schema, q|
    subscription S {
      importantUser { id }
      otherUser { id }
    }
  |);

  is_deeply messages($errors), [
    'Subscription needs to have only one field; got (importantUser otherUser)',
  ];

  $errors = validate($schema, q|
    subscription S {
      user: importantUser { id }
      user: importantUser { name }
    }
  |);
  is_deeply $errors, [], 'one merged response name is one subscription root field';

  $errors = validate($schema, q|
    subscription S { __typename }
  |);
  is_deeply messages($errors), [
    'Subscription root field must not be an introspection field.',
  ], 'subscription root cannot select introspection';
};

subtest 'directive validation rejects unknown directives and invalid locations' => sub {
  my $errors = validate($schema, q|
    query Q @skip(if: true) {
      viewer {
        id @unknown
      }
    }
  |);

  is_deeply messages($errors), [
    "Directive '\@skip' may not be used on QUERY.",
    "Unknown directive '\@unknown'.",
  ];
};

subtest 'variable definition directives parse and validate' => sub {
  my $errors = validate($schema, q|
    query Q($id: String! @variableTag(enabled: true)) {
      node(id: $id) { id }
    }
  |);
  is_deeply $errors, [], 'valid variable definition directive passes';

  $errors = validate($schema, q|
    query Q($id: String! @skip(if: true)) { node(id: $id) { id } }
  |);
  is_deeply messages($errors), [
    "Directive '\@skip' may not be used on VARIABLE_DEFINITION.",
  ], 'directive location is enforced on variable definitions';
};

subtest 'directive validation rejects duplicate non-repeatable directives' => sub {
  my $errors = validate($schema, q|
    {
      viewer {
        id @mask(enabled: true) @mask(enabled: false)
        name @tag(name: "a") @tag(name: "b")
      }
    }
  |);

  is_deeply messages($errors), [
    "Directive '\@mask' is not repeatable and cannot be used more than once at this location.",
  ];
};

subtest 'directive validation checks required and unknown arguments' => sub {
  my $errors = validate($schema, q|
    {
      viewer {
        id @skip
        name @mask(enabled: true, extra: false)
      }
    }
  |);

  is_deeply messages($errors), [
    "Required argument 'if' was not provided to directive '\@skip'.",
    "Unknown argument 'extra' on directive '\@mask'.",
  ];
};

subtest 'directive validation checks literal argument types' => sub {
  my $errors = validate($schema, q|
    {
      viewer {
        id @skip(if: "nope")
      }
    }
  |);

  is_deeply messages($errors), [
    q{Argument 'if' on directive '@skip' has invalid value: Not a Boolean.},
  ];
};

subtest 'directive validation preserves custom scalar callbacks' => sub {
  my $errors = validate($schema, q|{
    viewer { id @odd(value: "even") }
  }|);
  like messages($errors)->[0], qr/^Argument 'value'.*Not odd\./,
    'custom scalar parse_value rejects an invalid directive literal';
};

subtest 'fragment directive variables use each operation context' => sub {
  my $errors = validate($schema, q|
    query Q($enabled: Boolean) { viewer { ...Names } }
    fragment Names on User { name @flags(values: [$enabled]) }
  |);
  is_deeply $errors, [], 'nested directive variable in a fragment is resolved';

  $errors = validate($schema, q|
    query Q($enabled: String) { viewer { ...Names } }
    fragment Names on User { name @flags(values: [$enabled]) }
  |);
  like messages($errors)->[0], qr/cannot be used for a list item/,
    'fragment directive variable position is checked per operation';
};

subtest 'fragment field variables use each operation context' => sub {
  my $errors = validate($schema, q|
    query Q($id: String!) { ...Lookup }
    fragment Lookup on Query { node(id: $id) { id } }
  |);
  is_deeply $errors, [], 'field argument variable in a fragment is resolved'
    or diag explain $errors;

  $errors = validate($schema, q|
    query Q($id: Boolean) { ...Outer }
    fragment Outer on Query { ...Lookup }
    fragment Lookup on Query { node(id: $id) { id } }
  |);
  like messages($errors)->[0], qr/cannot be used for argument 'id'/,
    'nested fragment variable position is checked in the operation context';

  $errors = validate($schema, q|
    query Q { ...Lookup }
    fragment Lookup on Query { node(id: $id) { id } }
  |);
  is_deeply messages($errors), ["Variable '\$id' is used but not defined."],
    'undefined fragment variable is reported once for the operation';

  $errors = validate($schema, q|
    query Q { ...Bad }
    fragment Bad on Query { missing }
  |);
  is scalar(grep { /Field 'missing' does not exist/ } @{ messages($errors) }), 1,
    'non-variable fragment errors are not duplicated by operation traversal';
};

done_testing;
