use strict;
use warnings;

use Test::More;
use FindBin qw($Bin);
use File::Spec;

BEGIN {
  my $root = File::Spec->catdir($Bin, '..');
  for my $path (
    File::Spec->catdir($root, 'lib'),
    File::Spec->catdir($root, 'local', 'lib', 'perl5'),
    File::Spec->catdir($root, 'local', 'lib', 'perl5', 'darwin-2level'),
  ) {
    unshift @INC, $path if -d $path;
  }
}

use GraphQL::Houtou qw(execute);
use GraphQL::Houtou::Schema;
use GraphQL::Houtou::Type::Object;
use GraphQL::Houtou::Type::InputObject;
use GraphQL::Houtou::Type::Scalar qw($String $Int $Boolean);
use GraphQL::Houtou::Directive;

# ------------------------------------------------------------------
# Schema with deprecated args and input fields
# ------------------------------------------------------------------
my $SearchInput = GraphQL::Houtou::Type::InputObject->new(
  name   => 'SearchInput',
  fields => {
    query     => { type => $String->non_null },
    legacyTag => {
      type               => $String,
      deprecation_reason => 'Use `query` instead',
    },
  },
);

my $schema = GraphQL::Houtou::Schema->new(
  query => GraphQL::Houtou::Type::Object->new(
    name   => 'Query',
    fields => {
      greet => {
        type => $String->non_null,
        args => {
          name => { type => $String->non_null },
          formal => {
            type               => $Boolean,
            deprecation_reason => 'Formality is automatic now',
            default_value      => 0,
          },
        },
        resolve => sub { 'hello' },
      },
      search => {
        type => $String,
        args => {
          input => { type => $SearchInput },
        },
        resolve => sub { 'results' },
      },
    },
  ),
);

# ------------------------------------------------------------------
subtest '@deprecated locations include ARGUMENT_DEFINITION and INPUT_FIELD_DEFINITION' => sub {
  my %locs = map { $_ => 1 } @{ $GraphQL::Houtou::Directive::DEPRECATED->locations };
  ok $locs{FIELD_DEFINITION},        'FIELD_DEFINITION present';
  ok $locs{ENUM_VALUE},              'ENUM_VALUE present';
  ok $locs{ARGUMENT_DEFINITION},     'ARGUMENT_DEFINITION present';
  ok $locs{INPUT_FIELD_DEFINITION},  'INPUT_FIELD_DEFINITION present';
};

subtest 'deprecated arg has is_deprecated and deprecation_reason set' => sub {
  my $runtime = $schema->build_native_runtime;
  $schema->build_runtime;
  my $fields = $schema->query->fields;
  my $formal = $fields->{greet}{args}{formal};
  ok $formal->{is_deprecated}, 'formal arg is_deprecated is true';
  is $formal->{deprecation_reason}, 'Formality is automatic now',
    'formal arg deprecation_reason correct';
};

subtest 'non-deprecated arg does not have is_deprecated' => sub {
  my $fields = $schema->query->fields;
  my $name = $fields->{greet}{args}{name};
  ok !$name->{is_deprecated}, 'name arg is not deprecated';
};

subtest 'deprecated input field has is_deprecated set' => sub {
  my $fields = $SearchInput->fields;
  ok $fields->{legacyTag}{is_deprecated},   'legacyTag is_deprecated is true';
  is $fields->{legacyTag}{deprecation_reason}, 'Use `query` instead',
    'legacyTag deprecation_reason correct';
  ok !$fields->{query}{is_deprecated}, 'query field is not deprecated';
};

subtest 'introspection: __Field.args exposes isDeprecated for deprecated args' => sub {
  my $result = execute($schema, '
    {
      __type(name: "Query") {
        fields {
          name
          args(includeDeprecated: true) {
            name
            isDeprecated
            deprecationReason
          }
        }
      }
    }
  ');
  ok !exists $result->{errors}, 'no errors';

  my ($greet) = grep { $_->{name} eq 'greet' }
    @{ $result->{data}{__type}{fields} };
  my %args = map { $_->{name} => $_ } @{ $greet->{args} };

  ok  $args{formal}{isDeprecated},   'formal arg isDeprecated true in introspection';
  is  $args{formal}{deprecationReason}, 'Formality is automatic now',
      'formal arg deprecationReason correct in introspection';
  ok !$args{name}{isDeprecated},     'name arg not deprecated in introspection';
};

subtest 'native runtime codegen handles includeDeprecated on __Field.args' => sub {
  my $runtime = $schema->build_native_runtime;
  my $program = $runtime->compile_program(q(
    {
      __type(name: "Query") {
        fields {
          name
          args(includeDeprecated: true) {
            name
            isDeprecated
            deprecationReason
          }
        }
      }
    }
  ));
  my $result = $runtime->execute_program($program);
  ok !exists $result->{errors}, 'no errors';

  my ($greet) = grep { $_->{name} eq 'greet' }
    @{ $result->{data}{__type}{fields} };
  my %args = map { $_->{name} => $_ } @{ $greet->{args} };

  ok  $args{formal}{isDeprecated},   'formal arg isDeprecated true in native runtime';
  is  $args{formal}{deprecationReason}, 'Formality is automatic now',
      'formal arg deprecationReason correct in native runtime';
  ok !$args{name}{isDeprecated},     'name arg not deprecated in native runtime';
};

subtest 'introspection: deprecated args hidden by default' => sub {
  my $result = execute($schema, '
    {
      __type(name: "Query") {
        fields {
          name
          args {
            name
          }
        }
      }
    }
  ');
  ok !exists $result->{errors}, 'no errors';

  my ($greet) = grep { $_->{name} eq 'greet' }
    @{ $result->{data}{__type}{fields} };
  my @arg_names = map { $_->{name} } @{ $greet->{args} };
  ok !grep { $_ eq 'formal' } @arg_names,
    'deprecated arg excluded from args without includeDeprecated';
  ok  grep { $_ eq 'name'   } @arg_names,
    'non-deprecated arg still present';
};

subtest 'introspection: __Type.inputFields exposes isDeprecated' => sub {
  my $result = execute($schema, '
    {
      __type(name: "SearchInput") {
        inputFields(includeDeprecated: true) {
          name
          isDeprecated
          deprecationReason
        }
      }
    }
  ');
  ok !exists $result->{errors}, 'no errors';

  my %fields = map { $_->{name} => $_ }
    @{ $result->{data}{__type}{inputFields} };

  ok  $fields{legacyTag}{isDeprecated},   'legacyTag isDeprecated true';
  is  $fields{legacyTag}{deprecationReason}, 'Use `query` instead',
      'legacyTag deprecationReason correct';
  ok !$fields{query}{isDeprecated},       'query not deprecated';
};

subtest 'native runtime codegen handles includeDeprecated on __Type.inputFields' => sub {
  my $runtime = $schema->build_native_runtime;
  my $program = $runtime->compile_program(q(
    {
      __type(name: "SearchInput") {
        inputFields(includeDeprecated: true) {
          name
          isDeprecated
          deprecationReason
        }
      }
    }
  ));
  my $result = $runtime->execute_program($program);
  ok !exists $result->{errors}, 'no errors';

  my %fields = map { $_->{name} => $_ }
    @{ $result->{data}{__type}{inputFields} };

  ok  $fields{legacyTag}{isDeprecated},   'legacyTag isDeprecated true in native runtime';
  is  $fields{legacyTag}{deprecationReason}, 'Use `query` instead',
      'legacyTag deprecationReason correct in native runtime';
  ok !$fields{query}{isDeprecated},       'query not deprecated in native runtime';
};

subtest 'introspection: deprecated inputFields hidden by default' => sub {
  my $result = execute($schema, '
    {
      __type(name: "SearchInput") {
        inputFields {
          name
        }
      }
    }
  ');
  ok !exists $result->{errors}, 'no errors';

  my @names = map { $_->{name} } @{ $result->{data}{__type}{inputFields} };
  ok !grep { $_ eq 'legacyTag' } @names,
    'deprecated input field excluded by default';
  ok  grep { $_ eq 'query' } @names,
    'non-deprecated input field present';
};

subtest 'execution still works with deprecated args present in query' => sub {
  my $result = execute($schema, '{ greet(name: "world", formal: false) }');
  ok !exists $result->{errors}, 'no errors';
  is $result->{data}{greet}, 'hello', 'correct result';
};

subtest 'native runtime codegen materializes boolean literals for deprecated args' => sub {
  my $runtime = $schema->build_native_runtime;
  my $program = $runtime->compile_program(q({ greet(name: "world", formal: false) }));
  my $result = $runtime->execute_program($program);

  ok !exists $result->{errors}, 'no errors';
  is $result->{data}{greet}, 'hello', 'correct result';
};

subtest 'execution works with deprecated input field omitted' => sub {
  my $result = execute($schema, '{ search(input: { query: "foo" }) }');
  ok !exists $result->{errors}, 'no errors';
  is $result->{data}{search}, 'results', 'correct result';
};

subtest 'required arguments and input fields cannot be deprecated' => sub {
  my $RequiredInput = GraphQL::Houtou::Type::InputObject->new(
    name => 'RequiredInput',
    fields => {
      value => {
        type => $String->non_null,
        deprecation_reason => 'cannot omit this field',
      },
    },
  );
  my $invalid = GraphQL::Houtou::Schema->new(
    query => GraphQL::Houtou::Type::Object->new(
      name => 'InvalidQuery',
      fields => {
        lookup => {
          type => $String,
          args => {
            key => {
              type => $String->non_null,
              deprecation_reason => 'cannot omit this argument',
            },
          },
        },
      },
    ),
    types => [ $RequiredInput ],
    directives => [
      GraphQL::Houtou::Directive->new(
        name => 'required',
        locations => ['FIELD'],
        args => {
          key => {
            type => $String->non_null,
            deprecation_reason => 'cannot omit this directive argument',
          },
        },
      ),
    ],
  );
  my $errors = join "\n", @{ $invalid->validation_errors };
  like $errors, qr/Required argument InvalidQuery\.lookup\(key:\) cannot be deprecated/,
    'programmatic required field argument rejected';
  like $errors, qr/Required input field RequiredInput\.value cannot be deprecated/,
    'programmatic required input field rejected';
  like $errors, qr/Required argument \@required\(key:\) cannot be deprecated/,
    'programmatic required directive argument rejected';

  my $sdl = GraphQL::Houtou::Schema->from_doc(<<'SDL');
directive @required(key: String! @deprecated) on FIELD
input RequiredInput { value: String! @deprecated }
type Query { lookup(key: String! @deprecated): String }
SDL
  my $sdl_errors = join "\n", @{ $sdl->validation_errors };
  like $sdl_errors, qr/Required argument Query\.lookup\(key:\) cannot be deprecated/,
    'SDL required field argument rejected';
  like $sdl_errors, qr/Required input field RequiredInput\.value cannot be deprecated/,
    'SDL required input field rejected';
  like $sdl_errors, qr/Required argument \@required\(key:\) cannot be deprecated/,
    'SDL required directive argument rejected';
};

subtest 'deprecated non-null definitions with defaults are optional' => sub {
  my $valid = GraphQL::Houtou::Schema->from_doc(<<'SDL');
directive @legacy(flag: Boolean! = false @deprecated) on FIELD
input Options { legacy: Boolean! = false @deprecated }
type Query { value(legacy: Boolean! = false @deprecated): String }
SDL
  is_deeply $valid->validation_errors, [],
    'non-null arguments and input fields with defaults may be deprecated';
};

done_testing;
