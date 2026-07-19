use strict;
use warnings;

use Test::More;

use GraphQL::Houtou qw(build_schema print_schema);
use GraphQL::Houtou::Schema;
use GraphQL::Houtou::Type::Object;
use GraphQL::Houtou::Type::Scalar qw($String);

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
  dog(id: ID = "1", legacyId: ID @deprecated(reason: "use id")): Dog
  pets: [Pet!]
  find(by: LookupBy): String
  color: Color
  thing: Thing
  now: DateTime
  old: String @deprecated(reason: "gone")
}

enum Color {
  RED @deprecated(reason: "no red")
  "green things"
  GREEN
}

union Thing = Dog

input LookupBy @oneOf {
  id: ID
  email: String
  legacyName: String @deprecated(reason: "use email")
}

"""A point in time"""
scalar DateTime @specifiedBy(url: "https://example.com/dt")

directive @slow(ms: Int, legacyMs: Int @deprecated(reason: "use ms")) repeatable on FIELD | VARIABLE_DEFINITION

directive @pure on FIELD
SDL

subtest 'print_schema renders every type kind' => sub {
  my $printed = print_schema(build_schema($SDL));

  like $printed, qr/^"A pet"\ninterface Pet \{\n  name: String!\n\}/m,
    'interface with description';
  like $printed, qr/^type Dog implements Pet \{/m, 'implements clause';
  like $printed,
    qr/^  dog\(id: ID = "1", legacyId: ID \@deprecated\(reason: "use id"\)\): Dog$/m,
    'argument defaults and deprecation are printed';
  like $printed, qr/^  old: String \@deprecated\(reason: "gone"\)$/m,
    'deprecated field with reason';
  like $printed, qr/^enum Color \{$/m, 'enum header';
  like $printed, qr/^  RED \@deprecated\(reason: "no red"\)$/m, 'deprecated enum value';
  like $printed, qr/^  "green things"\n  GREEN$/m, 'enum value description';
  like $printed, qr/^union Thing = Dog$/m, 'union members';
  like $printed, qr/^input LookupBy \@oneOf \{$/m, 'oneOf input object';
  like $printed,
    qr/^  legacyName: String \@deprecated\(reason: "use email"\)$/m,
    'deprecated input field is printed';
  like $printed, qr/^"A point in time"\nscalar DateTime \@specifiedBy\(url: "https:\/\/example\.com\/dt"\)$/m,
    'scalar with description and specifiedBy';
  like $printed,
    qr/^directive \@slow\(legacyMs: Int \@deprecated\(reason: "use ms"\), ms: Int\) repeatable on FIELD \| VARIABLE_DEFINITION$/m,
    'repeatable directive with deprecated args';
  like $printed, qr/^directive \@pure on FIELD$/m,
    'argument-less directive omits empty parens';

  unlike $printed, qr/^scalar (?:Int|Float|String|Boolean|ID)$/m,
    'built-in scalars omitted';
  unlike $printed, qr/__Type|__Schema/, 'introspection meta types omitted';
  unlike $printed, qr/^directive \@(?:include|skip|deprecated|specifiedBy)/m,
    'specified directives omitted';
  unlike $printed, qr/^schema \{/m,
    'schema block omitted when roots use default names';
};

subtest 'schema block is printed for non-default roots and description' => sub {
  my $printed = print_schema(build_schema('
    "the api"
    schema { query: RootQ mutation: RootM }
    type RootQ { ping: String }
    type RootM { bump: String }
  '));
  like $printed, qr/^"the api"\nschema \{\n  query: RootQ\n  mutation: RootM\n\}/m,
    'schema block with description and roots';
};

subtest 'print -> build -> print is stable' => sub {
  my $first = print_schema(build_schema($SDL));
  my $second = print_schema(build_schema($first));
  is $second, $first, 'round trip reaches a fixed point';
};

subtest 'schemas assembled from Perl type objects also print' => sub {
  my $schema = GraphQL::Houtou::Schema->new(
    query => GraphQL::Houtou::Type::Object->new(
      name => 'Query',
      fields => {
        hello => { type => $String, resolve => sub { 'world' } },
      },
    ),
  );
  my $printed = $schema->to_doc;
  like $printed, qr/^type Query \{\n  hello: String\n\}$/m,
    'programmatic schema prints its SDL';
};

done_testing;
