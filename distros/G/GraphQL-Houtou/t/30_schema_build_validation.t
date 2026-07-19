use strict;
use warnings;

use Test::More;

use GraphQL::Houtou::Schema;
use GraphQL::Houtou::Type::Object;
use GraphQL::Houtou::Type::Interface;
use GraphQL::Houtou::Type::InputObject;
use GraphQL::Houtou::Type::Union;
use GraphQL::Houtou::Type::Enum;
use GraphQL::Houtou::Type::Scalar qw($String $Int $ID);
use GraphQL::Houtou::Directive;

my $Node = GraphQL::Houtou::Type::Interface->new(
  name => 'Node',
  fields => { id => { type => $ID } },
);

my $Pet;
$Pet = GraphQL::Houtou::Type::Interface->new(
  name => 'Pet',
  fields => sub { {
    name => { type => $String->non_null },
    friend => { type => $Pet },
  } },
);

sub query_with {
  my (%fields) = @_;
  return GraphQL::Houtou::Type::Object->new(name => 'Query', fields => { %fields });
}

sub build_errors {
  my ($schema) = @_;
  eval { $schema->build_runtime };
  return $@;
}

subtest 'a valid schema passes and memoizes' => sub {
  my $Dog = GraphQL::Houtou::Type::Object->new(
    name => 'Dog',
    interfaces => [ $Node ],
    fields => { id => { type => $ID->non_null }, bark => { type => $String } },
  );
  my $schema = GraphQL::Houtou::Schema->new(
    query => query_with(dog => { type => $Dog, resolve => sub { {} } }),
  );
  is_deeply $schema->validation_errors, [], 'no validation errors';
  ok eval { $schema->build_runtime; 1 }, 'build_runtime succeeds' or diag $@;
  ok $schema->{_schema_validated}, 'validation result is memoized';
};

subtest 'non-null covariance against nullable interface field is allowed' => sub {
  my $Dog = GraphQL::Houtou::Type::Object->new(
    name => 'Dog',
    interfaces => [ $Node ],
    fields => { id => { type => $ID->non_null } },
  );
  my $schema = GraphQL::Houtou::Schema->new(
    query => query_with(dog => { type => $Dog }),
  );
  is_deeply $schema->validation_errors, [], 'ID! satisfies interface field of type ID';
};

subtest 'missing interface field is rejected' => sub {
  my $Cat = GraphQL::Houtou::Type::Object->new(
    name => 'Cat',
    interfaces => [ $Node ],
    fields => { meow => { type => $String } },
  );
  my $schema = GraphQL::Houtou::Schema->new(
    query => query_with(cat => { type => $Cat }),
  );
  my $error = build_errors($schema);
  like $error, qr/Interface field Node\.id expected but Cat does not provide it/,
    'missing field reported';
};

subtest 'field type mismatch is rejected' => sub {
  my $Cat = GraphQL::Houtou::Type::Object->new(
    name => 'Cat',
    interfaces => [ $Node ],
    fields => { id => { type => $Int } },
  );
  my $schema = GraphQL::Houtou::Schema->new(
    query => query_with(cat => { type => $Cat }),
  );
  like build_errors($schema),
    qr/Interface field Node\.id expects type ID but Cat\.id is type Int/,
    'incompatible field type reported';
};

subtest 'covariant object field type against interface-typed field' => sub {
  my $Dog; $Dog = GraphQL::Houtou::Type::Object->new(
    name => 'Dog',
    interfaces => [ $Pet ],
    fields => sub { {
      name => { type => $String->non_null },
      friend => { type => $Dog },
    } },
  );
  my $schema = GraphQL::Houtou::Schema->new(
    query => query_with(dog => { type => $Dog }),
    types => [ $Dog, $Pet ],
  );
  is_deeply $schema->validation_errors, [],
    'Dog.friend: Dog satisfies Pet.friend: Pet because Dog implements Pet';
};

subtest 'missing interface field argument is rejected' => sub {
  my $Sized = GraphQL::Houtou::Type::Interface->new(
    name => 'Sized',
    fields => {
      size => { type => $Int, args => { unit => { type => $String } } },
    },
  );
  my $Box = GraphQL::Houtou::Type::Object->new(
    name => 'Box',
    interfaces => [ $Sized ],
    fields => { size => { type => $Int } },
  );
  my $schema = GraphQL::Houtou::Schema->new(
    query => query_with(box => { type => $Box }),
  );
  like build_errors($schema),
    qr/Interface field argument Sized\.size\(unit:\) expected but Box\.size does not provide it/,
    'missing argument reported';
};

subtest 'interface argument type must match invariantly' => sub {
  my $Sized = GraphQL::Houtou::Type::Interface->new(
    name => 'Sized',
    fields => {
      size => { type => $Int, args => { unit => { type => $String } } },
    },
  );
  my $Box = GraphQL::Houtou::Type::Object->new(
    name => 'Box',
    interfaces => [ $Sized ],
    fields => {
      size => { type => $Int, args => { unit => { type => $Int } } },
    },
  );
  my $schema = GraphQL::Houtou::Schema->new(
    query => query_with(box => { type => $Box }),
  );
  like build_errors($schema),
    qr/Interface field argument Sized\.size\(unit:\) expects type String but Box\.size\(unit:\) is type Int/,
    'argument type mismatch reported';
};

subtest 'additional required argument on object field is rejected' => sub {
  my $Sized = GraphQL::Houtou::Type::Interface->new(
    name => 'Sized',
    fields => { size => { type => $Int } },
  );
  my $Box = GraphQL::Houtou::Type::Object->new(
    name => 'Box',
    interfaces => [ $Sized ],
    fields => {
      size => { type => $Int, args => { unit => { type => $String->non_null } } },
    },
  );
  my $schema = GraphQL::Houtou::Schema->new(
    query => query_with(box => { type => $Box }),
  );
  like build_errors($schema),
    qr/Object field Box\.size includes required argument unit that is missing from the Interface field Sized\.size/,
    'extra required argument reported';

  my $BoxWithDefault = GraphQL::Houtou::Type::Object->new(
    name => 'BoxWithDefault',
    interfaces => [ $Sized ],
    fields => {
      size => {
        type => $Int,
        args => { unit => { type => $String->non_null, default_value => 'cm' } },
      },
    },
  );
  my $ok_schema = GraphQL::Houtou::Schema->new(
    query => query_with(box => { type => $BoxWithDefault }),
  );
  is_deeply $ok_schema->validation_errors, [],
    'extra required argument with default value is allowed';
};

subtest 'input object fields must be input types' => sub {
  my $Payload = GraphQL::Houtou::Type::Object->new(
    name => 'Payload',
    fields => { ok => { type => $String } },
  );
  my $BadInput = GraphQL::Houtou::Type::InputObject->new(
    name => 'BadInput',
    fields => { payload => { type => $Payload } },
  );
  my $schema = GraphQL::Houtou::Schema->new(
    query => query_with(
      find => { type => $String, args => { input => { type => $BadInput } } },
    ),
  );
  like build_errors($schema),
    qr/The type of BadInput\.payload must be Input Type but got: Payload/,
    'output type in input position reported';
};

subtest 'argument types must be input types' => sub {
  my $Payload = GraphQL::Houtou::Type::Object->new(
    name => 'Payload',
    fields => { ok => { type => $String } },
  );
  my $schema = GraphQL::Houtou::Schema->new(
    query => query_with(
      find => { type => $String, args => { payload => { type => $Payload } } },
    ),
  );
  like build_errors($schema),
    qr/The type of Query\.find\(payload:\) must be Input Type but got: Payload/,
    'object type as argument reported';
};

subtest 'union members must be object types' => sub {
  my $schema = GraphQL::Houtou::Schema->new(
    query => query_with(
      thing => {
        type => GraphQL::Houtou::Type::Union->new(
          name => 'Thing',
          types => [ $String ],
        ),
      },
    ),
  );
  like build_errors($schema),
    qr/Union type Thing can only include Object types, found String/,
    'scalar union member reported';
};

subtest 'validation errors accumulate' => sub {
  my $Cat = GraphQL::Houtou::Type::Object->new(
    name => 'Cat',
    interfaces => [ $Node, $Pet ],
    fields => { meow => { type => $String } },
  );
  my $schema = GraphQL::Houtou::Schema->new(
    query => query_with(cat => { type => $Cat }),
  );
  my $errors = $schema->validation_errors;
  cmp_ok scalar(@$errors), '>=', 3, 'reports all missing interface fields at once';
};

subtest 'root operation types must be distinct objects' => sub {
  my $shared = query_with(value => { type => $String });
  my $same_roots = GraphQL::Houtou::Schema->new(
    query => $shared,
    mutation => $shared,
  );
  like join("\n", @{ $same_roots->validation_errors }),
    qr/root types must be different; Query is used more than once/,
    'the same object cannot be used for two operation roots';

  my $scalar_root = GraphQL::Houtou::Schema->new(query => $String);
  like join("\n", @{ $scalar_root->validation_errors }),
    qr/query root type must be an Object type, found String/,
    'query root must be an object type';
};

subtest 'user-defined type-system names cannot use the introspection prefix' => sub {
  my $Bad = GraphQL::Houtou::Type::Object->new(
    name => '__Bad',
    fields => { __field => { type => $String } },
  );
  my $schema = GraphQL::Houtou::Schema->new(
    query => query_with(
      bad => {
        type => $Bad,
        args => { __arg => { type => $String } },
      },
    ),
    types => [ $Bad ],
  );
  my $errors = join("\n", @{ $schema->validation_errors });
  like $errors, qr/Type must not begin with '__'/, 'reserved type name rejected';
  like $errors, qr/Field __Bad\.__field must not begin with '__'/,
    'reserved field name rejected';
  like $errors, qr/Argument Query\.bad\(__arg:\) must not begin with '__'/,
    'reserved argument name rejected';
};

subtest 'unbroken required input object cycles are rejected' => sub {
  my ($First, $Second);
  $First = GraphQL::Houtou::Type::InputObject->new(
    name => 'First',
    fields => sub { { second => { type => $Second->non_null } } },
  );
  $Second = GraphQL::Houtou::Type::InputObject->new(
    name => 'Second',
    fields => sub { { first => { type => $First->non_null } } },
  );
  my $schema = GraphQL::Houtou::Schema->new(
    query => query_with(
      find => { type => $String, args => { input => { type => $First } } },
    ),
    types => [ $First, $Second ],
  );
  like join("\n", @{ $schema->validation_errors }),
    qr/unbroken chain of singular Non-Null fields: First -> Second -> First/,
    'mutually required singular fields cannot form a cycle';
};

subtest 'nullable and list input object cycles are allowed' => sub {
  my $Nullable;
  $Nullable = GraphQL::Houtou::Type::InputObject->new(
    name => 'NullableCycle',
    fields => sub { { next => { type => $Nullable } } },
  );
  my $Listed;
  $Listed = GraphQL::Houtou::Type::InputObject->new(
    name => 'ListCycle',
    fields => sub { { next => { type => $Listed->non_null->list->non_null } } },
  );
  my $schema = GraphQL::Houtou::Schema->new(
    query => query_with(
      nullable => { type => $String, args => { input => { type => $Nullable } } },
      listed => { type => $String, args => { input => { type => $Listed } } },
    ),
    types => [ $Nullable, $Listed ],
  );
  is_deeply $schema->validation_errors, [],
    'nullable fields and lists provide a way to satisfy a recursive input type';
};

subtest 'schema default values must match their input types' => sub {
  my $Options = GraphQL::Houtou::Type::InputObject->new(
    name => 'Options',
    fields => {
      count => { type => $Int->non_null },
      label => { type => $String },
    },
  );
  my $schema = GraphQL::Houtou::Schema->new(
    query => query_with(
      search => {
        type => $String,
        args => {
          count => { type => $Int, default_value => 'many' },
          options => {
            type => $Options,
            default_value => { count => 1, unknown => 1 },
          },
          missing => { type => $Options, default_value => { label => 'x' } },
          nested => {
            type => $Options->list,
            default_value => [ { count => 1 }, { label => 'x' } ],
          },
          required => { type => $String->non_null, default_value => undef },
        },
      },
    ),
    types => [ $Options ],
  );
  my $errors = join("\n", @{ $schema->validation_errors });
  like $errors, qr/default value for argument Query\.search\(count:\) is invalid for type Int/,
    'invalid scalar default rejected';
  like $errors, qr/default value for argument Query\.search\(options:\) is invalid for type Options/,
    'invalid nested input object default rejected';
  like $errors,
    qr/default value for argument Query\.search\(missing:\).*required input field count is missing/,
    'missing required input field rejected';
  like $errors,
    qr/default value for argument Query\.search\(nested:\).*required input field \[1\]\.count is missing/,
    'missing required field in a nested list element rejected';
  like $errors, qr/default value for argument Query\.search\(required:\) is invalid for type String!/
    , 'null default for a non-null type rejected';

  my $valid = GraphQL::Houtou::Schema->new(
    query => query_with(
      search => {
        type => $String,
        args => {
          counts => { type => $Int->list, default_value => 1 },
          options => { type => $Options, default_value => { count => 1 } },
        },
      },
    ),
    types => [ $Options ],
  );
  is_deeply $valid->validation_errors, [],
    'valid defaults and list singleton coercion are accepted';
};

subtest 'programmatic type definitions enforce non-empty fields' => sub {
  my $EmptyObject = GraphQL::Houtou::Type::Object->new(
    name => 'EmptyObject', fields => {},
  );
  my $EmptyInterface = GraphQL::Houtou::Type::Interface->new(
    name => 'EmptyInterface', fields => {},
  );
  my $EmptyInput = GraphQL::Houtou::Type::InputObject->new(
    name => 'EmptyInput', fields => {},
  );
  my $EmptyEnum = GraphQL::Houtou::Type::Enum->new(
    name => 'EmptyEnum', values => {},
  );
  my $schema = GraphQL::Houtou::Schema->new(
    query => $EmptyObject,
    types => [ $EmptyInterface, $EmptyInput, $EmptyEnum ],
  );
  my $errors = join "\n", @{ $schema->validation_errors };
  like $errors, qr/Object type EmptyObject must define one or more fields/,
    'empty object rejected';
  like $errors, qr/Interface type EmptyInterface must define one or more fields/,
    'empty interface rejected';
  like $errors, qr/Input Object type EmptyInput must define one or more fields/,
    'empty input object rejected';
  like $errors, qr/Enum type EmptyEnum must define one or more values/,
    'empty enum remains covered';
};

subtest 'programmatic interface lists are unique and irreflexive' => sub {
  my $Self;
  $Self = GraphQL::Houtou::Type::Interface->new(
    name => 'Self',
    fields => { id => { type => $ID } },
    interfaces => sub { [ $Self ] },
  );
  my $schema = GraphQL::Houtou::Schema->new(
    query => GraphQL::Houtou::Type::Object->new(
      name => 'Query',
      fields => { id => { type => $ID } },
      interfaces => [ $Node, $Node ],
    ),
    types => [ $Self ],
  );
  my $errors = join "\n", @{ $schema->validation_errors };
  like $errors, qr/Type Query can only implement Node once/,
    'duplicate implemented interface rejected';
  like $errors, qr/Type Self cannot implement itself/,
    'self implementation rejected';
};

subtest 'interface inheritance must remain acyclic' => sub {
  my ($A, $B, $C);
  $A = GraphQL::Houtou::Type::Interface->new(
    name => 'A', fields => { id => { type => $ID } },
    interfaces => sub { [ $B ] },
  );
  $B = GraphQL::Houtou::Type::Interface->new(
    name => 'B', fields => { id => { type => $ID } },
    interfaces => sub { [ $C ] },
  );
  $C = GraphQL::Houtou::Type::Interface->new(
    name => 'C', fields => { id => { type => $ID } },
    interfaces => sub { [ $A ] },
  );
  my $cyclic = GraphQL::Houtou::Schema->new(
    query => query_with(value => { type => $String }),
    types => [ $A, $B, $C ],
  );
  like join("\n", @{ $cyclic->validation_errors }),
    qr/Interface implementation cannot contain a circular reference: A -> B -> C -> A/,
    'transitive interface cycle rejected';

  my $Base = GraphQL::Houtou::Type::Interface->new(
    name => 'Base', fields => { id => { type => $ID } },
  );
  my $Left = GraphQL::Houtou::Type::Interface->new(
    name => 'Left', interfaces => [ $Base ],
    fields => { id => { type => $ID }, left => { type => $String } },
  );
  my $Right = GraphQL::Houtou::Type::Interface->new(
    name => 'Right', interfaces => [ $Base ],
    fields => { id => { type => $ID }, right => { type => $String } },
  );
  my $Top = GraphQL::Houtou::Type::Interface->new(
    name => 'Top', interfaces => [ $Left, $Right, $Base ],
    fields => {
      id => { type => $ID }, left => { type => $String },
      right => { type => $String },
    },
  );
  my $valid = GraphQL::Houtou::Schema->new(
    query => query_with(value => { type => $Top }),
    types => [ $Base, $Left, $Right, $Top ],
  );
  is_deeply $valid->validation_errors, [],
    'diamond interface inheritance is not mistaken for a cycle';
};

subtest 'programmatic directive definitions validate names and locations' => sub {
  my $duplicate = GraphQL::Houtou::Directive->new(
    name => 'tag', locations => ['FIELD'],
  );
  my $schema = GraphQL::Houtou::Schema->new(
    query => query_with(value => { type => $String }),
    directives => [
      $duplicate,
      GraphQL::Houtou::Directive->new(
        name => 'tag', locations => [ 'FIELD', 'FIELD', 'NOWHERE' ],
      ),
      GraphQL::Houtou::Directive->new(name => 'empty', locations => []),
    ],
  );
  my $errors = join "\n", @{ $schema->validation_errors };
  like $errors, qr/Directive '\@tag' is defined more than once/,
    'duplicate directive name rejected';
  like $errors, qr/Directive '\@tag' repeats location 'FIELD'/,
    'duplicate directive location rejected';
  like $errors, qr/Directive '\@tag' has unknown location 'NOWHERE'/,
    'unknown directive location rejected';
  like $errors, qr/Directive '\@empty' must include one or more locations/,
    'empty directive locations rejected';
};

done_testing;
