use strict;
use warnings;

use Test::More;

use GraphQL::Houtou qw(execute);
use GraphQL::Houtou::Schema;
use GraphQL::Houtou::Type::Object;
use GraphQL::Houtou::Type::InputObject;
use GraphQL::Houtou::Type::Scalar qw($String $Boolean);
use GraphQL::Houtou::Directive;
use GraphQL::Houtou::Introspection ();

# ------------------------------------------------------------------
# Schema exercising the modern introspection surface
# ------------------------------------------------------------------
my $DateTime = GraphQL::Houtou::Type::Scalar->new(
  name => 'DateTime',
  specified_by_url => 'https://scalars.graphql.org/andimarek/date-time',
  serialize => sub { $_[0] },
  parse_value => sub { $_[0] },
);

my $UserBy = GraphQL::Houtou::Type::InputObject->new(
  name => 'UserBy',
  is_one_of => 1,
  fields => {
    id => { type => $String },
    email => { type => $String },
  },
);

my $PlainInput = GraphQL::Houtou::Type::InputObject->new(
  name => 'PlainInput',
  fields => {
    q => { type => $String },
  },
);

my $Delay = GraphQL::Houtou::Directive->new(
  name => 'delay',
  repeatable => 1,
  locations => [ qw(FIELD VARIABLE_DEFINITION) ],
  args => {
    ms => { type => $String },
    legacyMs => {
      type => $String,
      deprecation_reason => 'Use `ms` instead',
    },
  },
);

my $schema = GraphQL::Houtou::Schema->new(
  description => 'Example schema for modern introspection',
  query => GraphQL::Houtou::Type::Object->new(
    name => 'Query',
    fields => {
      now => { type => $DateTime, resolve => sub { '2026-07-04T00:00:00Z' } },
      user => {
        type => $String,
        args => {
          by => { type => $UserBy },
          plain => { type => $PlainInput },
        },
        resolve => sub { 'alice' },
      },
    },
  ),
  directives => [
    @GraphQL::Houtou::Directive::SPECIFIED_DIRECTIVES,
    $Delay,
  ],
);

# ------------------------------------------------------------------
# NOTE: each __type check runs as its own query because the exec-state lane
# currently drops field aliases (tracked separately); introspection behavior
# itself does not depend on aliases.
sub type_field {
  my ($type_name, $field) = @_;
  my $result = execute($schema, qq<{ __type(name: "$type_name") { $field } }>);
  ok !exists $result->{errors}, "no errors introspecting $type_name.$field";
  return $result->{data}{__type}{$field};
}

subtest '__Type.isOneOf distinguishes oneOf input objects' => sub {
  ok type_field('UserBy', 'isOneOf'), 'oneOf input object reports isOneOf true';
  my $plain = type_field('PlainInput', 'isOneOf');
  ok defined $plain && !$plain, 'plain input object reports isOneOf false';
  ok !defined type_field('Query', 'isOneOf'), 'object type reports isOneOf null';
};

subtest '__Type.specifiedByURL surfaces the scalar spec URL' => sub {
  is type_field('DateTime', 'specifiedByURL'),
    'https://scalars.graphql.org/andimarek/date-time',
    'custom scalar exposes its URL';
  ok !defined type_field('String', 'specifiedByURL'), 'built-in scalar has no URL';
};

subtest '__Directive.isRepeatable and VARIABLE_DEFINITION location' => sub {
  my $result = execute($schema, '
    {
      __schema {
        directives { name isRepeatable locations }
      }
    }
  ');
  ok !exists $result->{errors}, 'no errors';
  my %directives = map { $_->{name} => $_ } @{ $result->{data}{__schema}{directives} };
  ok $directives{delay}{isRepeatable}, 'delay directive is repeatable';
  ok !$directives{skip}{isRepeatable}, 'skip directive is not repeatable';
  ok grep({ $_ eq 'VARIABLE_DEFINITION' } @{ $directives{delay}{locations} }),
    'VARIABLE_DEFINITION serializes through __DirectiveLocation';
};

subtest '__Directive.args supports includeDeprecated' => sub {
  my $result = execute($schema, '
    {
      __schema {
        directives {
          name
          args(includeDeprecated: true) { name isDeprecated deprecationReason }
        }
      }
    }
  ');
  ok !exists $result->{errors}, 'no errors';
  my ($delay) = grep { $_->{name} eq 'delay' } @{ $result->{data}{__schema}{directives} };
  my %args = map { $_->{name} => $_ } @{ $delay->{args} };
  ok $args{legacyMs}, 'deprecated arg visible with includeDeprecated';
  ok $args{legacyMs}{isDeprecated}, 'deprecated arg reports isDeprecated';
  is $args{legacyMs}{deprecationReason}, 'Use `ms` instead', 'reason preserved';

  my $hidden = execute($schema, '
    { __schema { directives { name args { name } } } }
  ');
  ok !exists $hidden->{errors}, 'no errors';
  my ($delay_hidden) = grep { $_->{name} eq 'delay' }
    @{ $hidden->{data}{__schema}{directives} };
  my @names = map { $_->{name} } @{ $delay_hidden->{args} };
  ok !grep({ $_ eq 'legacyMs' } @names), 'deprecated arg hidden by default';
  ok grep({ $_ eq 'ms' } @names), 'active arg still present';
};

subtest '__Schema.description' => sub {
  my $result = execute($schema, '{ __schema { description } }');
  ok !exists $result->{errors}, 'no errors';
  is $result->{data}{__schema}{description},
    'Example schema for modern introspection', 'schema description exposed';
};

subtest 'canonical introspection query executes cleanly' => sub {
  my $result = execute($schema, $GraphQL::Houtou::Introspection::QUERY);
  ok !exists $result->{errors}, 'no errors running the full IntrospectionQuery';
  ok $result->{data}{__schema}{types}, 'types are returned';
};

subtest 'native runtime handles the modern fields' => sub {
  my $runtime = $schema->build_native_runtime;
  my $program = $runtime->compile_program('
    {
      __type(name: "UserBy") { isOneOf }
      __schema {
        description
        directives { name isRepeatable }
      }
    }
  ');
  my $result = $runtime->execute_program($program);
  ok !exists $result->{errors}, 'no errors';
  ok $result->{data}{__type}{isOneOf}, 'isOneOf true through native runtime';
  is $result->{data}{__schema}{description},
    'Example schema for modern introspection', 'description through native runtime';
};

done_testing;
