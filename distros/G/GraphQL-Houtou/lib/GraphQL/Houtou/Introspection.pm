package GraphQL::Houtou::Introspection;

use 5.014;
use strict;
use warnings;

use Exporter 'import';
use JSON::MaybeXS;

use GraphQL::Houtou::Type::Object;
use GraphQL::Houtou::Type::Enum;
use GraphQL::Houtou::Type::Scalar qw($String $Boolean);

our @EXPORT_OK = qw(
  $QUERY
  $TYPE_KIND_META_TYPE
  $DIRECTIVE_LOCATION_META_TYPE
  $ENUM_VALUE_META_TYPE
  $INPUT_VALUE_META_TYPE
  $FIELD_META_TYPE
  $DIRECTIVE_META_TYPE
  $TYPE_META_TYPE
  $SCHEMA_META_TYPE
  $SCHEMA_META_FIELD_DEF
  $TYPE_META_FIELD_DEF
  $TYPE_NAME_META_FIELD_DEF
);

# Responsibility: own Houtou's introspection surface without depending on the
# upstream GraphQL::Introspection package name.

my $JSON_noutf8 = JSON::MaybeXS->new->utf8(0)->allow_nonref;

our $QUERY = '
  query IntrospectionQuery {
    __schema {
      description
      queryType { name }
      mutationType { name }
      subscriptionType { name }
      types {
        ...FullType
      }
      directives {
        name
        description
        isRepeatable
        locations
        args(includeDeprecated: true) {
          ...InputValue
        }
      }
    }
  }
  fragment FullType on __Type {
    kind
    name
    description
    fields(includeDeprecated: true) {
      name
      description
      args(includeDeprecated: true) {
        ...InputValue
      }
      type {
        ...TypeRef
      }
      isDeprecated
      deprecationReason
    }
    inputFields(includeDeprecated: true) {
      ...InputValue
    }
    interfaces {
      ...TypeRef
    }
    enumValues(includeDeprecated: true) {
      name
      description
      isDeprecated
      deprecationReason
    }
    possibleTypes {
      ...TypeRef
    }
    specifiedByURL
    isOneOf
  }
  fragment InputValue on __InputValue {
    name
    description
    type { ...TypeRef }
    defaultValue
    isDeprecated
    deprecationReason
  }
  fragment TypeRef on __Type {
    kind
    name
    ofType {
      kind
      name
      ofType {
        kind
        name
        ofType {
          kind
          name
          ofType {
            kind
            name
            ofType {
              kind
              name
              ofType {
                kind
                name
                ofType {
                  kind
                  name
                }
              }
            }
          }
        }
      }
    }
  }
';

sub _make_moo_field {
  my ($field_name, $type) = @_;
  return (
    $field_name => {
      resolve => sub {
        my ($root_value, $args) = @_;
        return undef unless $root_value->can($field_name);
        my @passon = %$args ? ($args) : ();
        return $root_value->$field_name(@passon);
      },
      type => $type,
    }
  );
}

sub _make_hash_bool_field {
  my ($field_name, $type, $real) = @_;
  return (
    $field_name => {
      resolve => sub {
        my ($root_value) = @_;
        return !!$root_value->{$real};
      },
      type => $type,
    }
  );
}

sub _make_hash_field {
  my ($field_name, $type, $real) = @_;
  return (
    $field_name => {
      resolve => sub {
        my ($root_value) = @_;
        return $root_value->{$real};
      },
      type => $type,
    }
  );
}

sub _hash2array {
  my ($hash) = @_;
  return [ map { +{ name => $_, %{ $hash->{$_} } } } sort keys %$hash ];
}

sub _isa_any {
  my ($value, @classes) = @_;
  return !!grep { $value->isa($_) } @classes;
}

sub _does_any {
  my ($value, @roles) = @_;
  return !!grep { $value->DOES($_) } @roles;
}

use constant CLASS2KIND => {
  'GraphQL::Type::Enum' => 'ENUM',
  'GraphQL::Type::Interface' => 'INTERFACE',
  'GraphQL::Type::List' => 'LIST',
  'GraphQL::Type::Object' => 'OBJECT',
  'GraphQL::Type::Union' => 'UNION',
  'GraphQL::Type::InputObject' => 'INPUT_OBJECT',
  'GraphQL::Type::NonNull' => 'NON_NULL',
  'GraphQL::Type::Scalar' => 'SCALAR',
  'GraphQL::Houtou::Type::Enum' => 'ENUM',
  'GraphQL::Houtou::Type::Interface' => 'INTERFACE',
  'GraphQL::Houtou::Type::List' => 'LIST',
  'GraphQL::Houtou::Type::Object' => 'OBJECT',
  'GraphQL::Houtou::Type::Union' => 'UNION',
  'GraphQL::Houtou::Type::InputObject' => 'INPUT_OBJECT',
  'GraphQL::Houtou::Type::NonNull' => 'NON_NULL',
  'GraphQL::Houtou::Type::Scalar' => 'SCALAR',
};

our $TYPE_KIND_META_TYPE = GraphQL::Houtou::Type::Enum->new(
  name => '__TypeKind',
  is_introspection => 1,
  description => 'An enum describing what kind of type a given `__Type` is.',
  values => {
    SCALAR => { description => 'Indicates this type is a scalar.' },
    OBJECT => { description => 'Indicates this type is an object. `fields` and `interfaces` are valid fields.' },
    INTERFACE => { description => 'Indicates this type is an interface. `fields` and `possibleTypes` are valid fields.' },
    UNION => { description => 'Indicates this type is a union. `possibleTypes` is a valid field.' },
    ENUM => { description => 'Indicates this type is an enum. `enumValues` is a valid field.' },
    INPUT_OBJECT => { description => 'Indicates this type is an input object. `inputFields` is a valid field.' },
    LIST => { description => 'Indicates this type is a list. `ofType` is a valid field.' },
    NON_NULL => { description => 'Indicates this type is a non-null. `ofType` is a valid field.' },
  },
);

our $DIRECTIVE_LOCATION_META_TYPE = GraphQL::Houtou::Type::Enum->new(
  name => '__DirectiveLocation',
  is_introspection => 1,
  description =>
    'A Directive can be adjacent to many parts of the GraphQL language, a ' .
    '__DirectiveLocation describes one such possible adjacencies.',
  values => {
    QUERY => { description => 'Location adjacent to a query operation.' },
    MUTATION => { description => 'Location adjacent to a mutation operation.' },
    SUBSCRIPTION => { description => 'Location adjacent to a subscription operation.' },
    FIELD => { description => 'Location adjacent to a field.' },
    FRAGMENT_DEFINITION => { description => 'Location adjacent to a fragment definition.' },
    FRAGMENT_SPREAD => { description => 'Location adjacent to a fragment spread.' },
    INLINE_FRAGMENT => { description => 'Location adjacent to an inline fragment.' },
    VARIABLE_DEFINITION => { description => 'Location adjacent to a variable definition.' },
    SCHEMA => { description => 'Location adjacent to a schema definition.' },
    SCALAR => { description => 'Location adjacent to a scalar definition.' },
    OBJECT => { description => 'Location adjacent to an object type definition.' },
    FIELD_DEFINITION => { description => 'Location adjacent to a field definition.' },
    ARGUMENT_DEFINITION => { description => 'Location adjacent to an argument definition.' },
    INTERFACE => { description => 'Location adjacent to an interface definition.' },
    UNION => { description => 'Location adjacent to a union definition.' },
    ENUM => { description => 'Location adjacent to an enum definition.' },
    ENUM_VALUE => { description => 'Location adjacent to an enum value definition.' },
    INPUT_OBJECT => { description => 'Location adjacent to an input object type definition.' },
    INPUT_FIELD_DEFINITION => { description => 'Location adjacent to an input object field definition.' },
  },
);

our $ENUM_VALUE_META_TYPE = GraphQL::Houtou::Type::Object->new(
  name => '__EnumValue',
  is_introspection => 1,
  description =>
    'One possible value for a given Enum. Enum values are unique values, not ' .
    'a placeholder for a string or numeric value. However an Enum value is ' .
    'returned in a JSON response as a string.',
  fields => {
    name => { type => $String->non_null },
    description => { type => $String },
    _make_hash_bool_field(isDeprecated => $Boolean->non_null, 'isDeprecated'),
    _make_hash_field(deprecationReason => $String, 'deprecationReason'),
  },
);

our $TYPE_META_TYPE;

our $INPUT_VALUE_META_TYPE = GraphQL::Houtou::Type::Object->new(
  name => '__InputValue',
  is_introspection => 1,
  description =>
    'Arguments provided to Fields or Directives and the input fields of an ' .
    'InputObject are represented as Input Values which describe their type ' .
    'and optionally a default value.',
  fields => sub { {
    name => { type => $String->non_null },
    description => { type => $String },
    type => { type => $TYPE_META_TYPE->non_null },
    defaultValue => {
      type => $String,
      description =>
        'A GraphQL-formatted string representing the default value for this ' .
        'input value.',
      resolve => sub {
        return unless defined(my $value = $_[0]->{default_value});
        my $gql = $_[0]->{type}->perl_to_graphql($value);
        return $gql if _isa_any($_[0]->{type}, 'GraphQL::Houtou::Type::Enum', 'GraphQL::Type::Enum');
        return $JSON_noutf8->encode($gql);
      },
    },
    _make_hash_bool_field(isDeprecated => $Boolean->non_null, 'is_deprecated'),
    _make_hash_field(deprecationReason => $String, 'deprecation_reason'),
  } },
);

our $FIELD_META_TYPE = GraphQL::Houtou::Type::Object->new(
  name => '__Field',
  is_introspection => 1,
  description =>
    'Object and Interface types are described by a list of Fields, each of ' .
    'which has a name, potentially a list of arguments, and a return type.',
  fields => sub { {
    name => { type => $String->non_null },
    description => { type => $String },
    args => {
      type => $INPUT_VALUE_META_TYPE->non_null->list->non_null,
      args => { includeDeprecated => { type => $Boolean, default_value => 0 } },
      resolve => sub {
        my ($field, $args) = @_;
        my $field_args = $field->{args} || {};
        if (!$args->{includeDeprecated}) {
          $field_args = { map { ($_ => $field_args->{$_}) }
            grep { !$field_args->{$_}{is_deprecated} } keys %$field_args };
        }
        return _hash2array($field_args);
      },
    },
    type => { type => $TYPE_META_TYPE->non_null },
    _make_hash_bool_field(isDeprecated => $Boolean->non_null, 'isDeprecated'),
    _make_hash_field(deprecationReason => $String, 'deprecationReason'),
  } },
);

our $DIRECTIVE_META_TYPE = GraphQL::Houtou::Type::Object->new(
  name => '__Directive',
  is_introspection => 1,
  description =>
    'A Directive provides a way to describe alternate runtime execution and ' .
    'type validation behavior in a GraphQL document.' .
    "\n\nIn some cases, you need to provide options to alter GraphQL's " .
    'execution behavior in ways field arguments will not suffice, such as ' .
    'conditionally including or skipping a field. Directives provide this by ' .
    'describing additional information to the executor.',
  fields => {
    _make_moo_field(name => $String->non_null),
    _make_moo_field(description => $String),
    isRepeatable => {
      type => $Boolean->non_null,
      resolve => sub { $_[0]->can('repeatable') ? !!$_[0]->repeatable : 0 },
    },
    _make_moo_field(locations => $DIRECTIVE_LOCATION_META_TYPE->non_null->list->non_null),
    args => {
      type => $INPUT_VALUE_META_TYPE->non_null->list->non_null,
      args => { includeDeprecated => { type => $Boolean, default_value => 0 } },
      resolve => sub {
        my ($directive, $args) = @_;
        my $directive_args = $directive->args || {};
        if (!$args->{includeDeprecated}) {
          $directive_args = { map { ($_ => $directive_args->{$_}) }
            grep { !$directive_args->{$_}{is_deprecated} } keys %$directive_args };
        }
        return _hash2array($directive_args);
      },
    },
  },
);

$TYPE_META_TYPE = GraphQL::Houtou::Type::Object->new(
  name => '__Type',
  is_introspection => 1,
  description =>
    'The fundamental unit of any GraphQL Schema is the type. There are ' .
    'many kinds of types in GraphQL as represented by the `__TypeKind` enum.' .
    "\n\nDepending on the kind of a type, certain fields describe " .
    'information about that type. Scalar types provide no information ' .
    'beyond a name and description, while Enum types provide their values. ' .
    'Object and Interface types provide the fields they describe. Abstract ' .
    'types, Union and Interface, provide the Object types possible ' .
    'at runtime. List and NonNull types compose other types.',
  fields => sub { {
    kind => {
      type => $TYPE_KIND_META_TYPE->non_null,
      resolve => sub {
        my $class = ref $_[0];
        $class =~ s#__.*##;
        return CLASS2KIND->{$class} // die "Unknown kind of type => " . ref $_[0];
      },
    },
    name => {
      resolve => sub {
        my ($root_value, $args) = @_;
        return undef if $root_value->can('of');
        my @passon = %$args ? ($args) : ();
        return $root_value->name(@passon);
      },
      type => $String,
    },
    _make_moo_field(description => $String),
    fields => {
      type => $FIELD_META_TYPE->non_null->list,
      args => { includeDeprecated => { type => $Boolean, default_value => 0 } },
      resolve => sub {
        my ($type, $args) = @_;
        my $map;
        return undef if !_does_any($type,
          'GraphQL::Houtou::Role::FieldsOutput',
          'GraphQL::Role::FieldsOutput',
        );
        $map = $type->fields;
        if (!$args->{includeDeprecated}) {
          $map = { map { ($_ => $map->{$_}) } grep { !$map->{$_}{deprecation_reason} } keys %$map };
        }
        return [
          map {
            +{
              name => $_,
              description => $map->{$_}{description},
              args => $map->{$_}{args},
              type => $map->{$_}{type},
              isDeprecated => $map->{$_}{is_deprecated},
              deprecationReason => $map->{$_}{deprecation_reason},
            }
          } sort keys %$map
        ];
      },
    },
    interfaces => {
      type => $TYPE_META_TYPE->non_null->list,
      resolve => sub {
        my ($type) = @_;
        return if !_isa_any($type, 'GraphQL::Houtou::Type::Object', 'GraphQL::Type::Object');
        return $type->interfaces || [];
      },
    },
    possibleTypes => {
      type => $TYPE_META_TYPE->non_null->list,
      resolve => sub {
        return if !_does_any($_[0], 'GraphQL::Houtou::Role::Abstract', 'GraphQL::Role::Abstract');
        return $_[3]->{schema}->get_possible_types($_[0]);
      },
    },
    enumValues => {
      type => $ENUM_VALUE_META_TYPE->non_null->list,
      args => { includeDeprecated => { type => $Boolean, default_value => 0 } },
      resolve => sub {
        my ($type, $args) = @_;
        my $values;
        return if !_isa_any($type, 'GraphQL::Houtou::Type::Enum', 'GraphQL::Type::Enum');
        $values = $type->values;
        if (!$args->{includeDeprecated}) {
          $values = { map { ($_ => $values->{$_}) } grep { !$values->{$_}{is_deprecated} } keys %$values };
        }
        return [
          map {
            +{
              name => $_,
              description => $values->{$_}{description},
              isDeprecated => $values->{$_}{is_deprecated},
              deprecationReason => $values->{$_}{deprecation_reason},
            }
          } sort keys %$values
        ];
      },
    },
    inputFields => {
      type => $INPUT_VALUE_META_TYPE->non_null->list,
      args => { includeDeprecated => { type => $Boolean, default_value => 0 } },
      resolve => sub {
        my ($type, $args) = @_;
        return if !_isa_any($type, 'GraphQL::Houtou::Type::InputObject', 'GraphQL::Type::InputObject');
        my $fields = $type->fields || {};
        if (!$args->{includeDeprecated}) {
          $fields = { map { ($_ => $fields->{$_}) }
            grep { !$fields->{$_}{is_deprecated} } keys %$fields };
        }
        return _hash2array($fields);
      },
    },
    ofType => {
      type => $TYPE_META_TYPE,
      resolve => sub {
        return unless $_[0]->can('of');
        return $_[0]->of;
      },
    },
    specifiedByURL => {
      type => $String,
      resolve => sub {
        return unless $_[0]->can('specified_by_url');
        return $_[0]->specified_by_url;
      },
    },
    isOneOf => {
      type => $Boolean,
      resolve => sub {
        return if !_isa_any($_[0], 'GraphQL::Houtou::Type::InputObject', 'GraphQL::Type::InputObject');
        return $_[0]->can('is_one_of') ? !!$_[0]->is_one_of : 0;
      },
    },
  } },
);

our $SCHEMA_META_TYPE = GraphQL::Houtou::Type::Object->new(
  name => '__Schema',
  is_introspection => 1,
  description =>
    'A GraphQL Schema defines the capabilities of a GraphQL server. It ' .
    'exposes all available types and directives on the server, as well as ' .
    'the entry points for query, mutation, and subscription operations.',
  fields => {
    _make_moo_field(description => $String),
    types => {
      description => 'A list of all types supported by this server.',
      type => $TYPE_META_TYPE->non_null->list->non_null,
      resolve => sub { [ sort { $a->name cmp $b->name } values %{ $_[0]->name2type } ] },
    },
    queryType => {
      description => 'The type that query operations will be rooted at.',
      type => $TYPE_META_TYPE->non_null,
      resolve => sub { $_[0]->query },
    },
    mutationType => {
      description => 'If this server supports mutation, the type that mutation operations will be rooted at.',
      type => $TYPE_META_TYPE,
      resolve => sub { $_[0]->mutation },
    },
    subscriptionType => {
      description => 'If this server support subscription, the type that subscription operations will be rooted at.',
      type => $TYPE_META_TYPE,
      resolve => sub { $_[0]->subscription },
    },
    directives => {
      description => 'A list of all directives supported by this server.',
      type => $DIRECTIVE_META_TYPE->non_null->list->non_null,
      resolve => sub { $_[0]->directives },
    },
  },
);

our $SCHEMA_META_FIELD_DEF = {
  name => '__schema',
  type => $SCHEMA_META_TYPE->non_null,
  description => 'Access the current type schema of this server.',
  resolve => sub { $_[3]->{schema} },
};

our $TYPE_META_FIELD_DEF = {
  name => '__type',
  type => $TYPE_META_TYPE,
  description => 'Request the type information of a single type.',
  args => { name => { type => $String->non_null } },
  resolve => sub { $_[3]->{schema}->name2type->{ $_[1]->{name} } },
};

our $TYPE_NAME_META_FIELD_DEF = {
  name => '__typename',
  type => $String->non_null,
  description => 'The name of the current Object type at runtime.',
  resolve => sub { $_[3]->{parent_type}->name },
};

1;

__END__

=encoding utf-8

=head1 NAME

GraphQL::Houtou::Introspection - Houtou-owned introspection types

=head1 DESCRIPTION

This module owns Houtou's introspection query string, meta types, and meta
field definitions. It keeps compatibility with upstream GraphQL objects
during transition, but the exported introspection objects themselves are
now created from Houtou type classes.

=cut
