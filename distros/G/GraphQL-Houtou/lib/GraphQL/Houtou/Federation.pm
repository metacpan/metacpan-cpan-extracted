package GraphQL::Houtou::Federation;

use 5.024;
use strict;
use warnings;

use Exporter 'import';
use GraphQL::Houtou ();
use GraphQL::Houtou::Schema ();
use GraphQL::Houtou::Promise::PromiseXS qw(is_promise_xs_value);

our $VERSION = $GraphQL::Houtou::VERSION;
our @EXPORT_OK = qw(build_subgraph_schema);

my $FEDERATION_SDL = <<'SDL';
scalar _Any
scalar federation__FieldSet
scalar federation__Scope
scalar federation__Policy
scalar federation__ContextFieldValue
scalar link__Import

enum link__Purpose {
  SECURITY
  EXECUTION
}

directive @link(
  url: String!
  as: String
  for: link__Purpose
  import: [link__Import]
) repeatable on SCHEMA
directive @key(fields: federation__FieldSet!, resolvable: Boolean = true) repeatable on OBJECT | INTERFACE
directive @external on FIELD_DEFINITION | OBJECT
directive @requires(fields: federation__FieldSet!) on FIELD_DEFINITION
directive @provides(fields: federation__FieldSet!) on FIELD_DEFINITION
directive @shareable repeatable on OBJECT | FIELD_DEFINITION
directive @inaccessible on FIELD_DEFINITION | OBJECT | INTERFACE | UNION | ARGUMENT_DEFINITION | SCALAR | ENUM | ENUM_VALUE | INPUT_OBJECT | INPUT_FIELD_DEFINITION
directive @tag(name: String!) repeatable on FIELD_DEFINITION | INTERFACE | OBJECT | UNION | ARGUMENT_DEFINITION | SCALAR | ENUM | ENUM_VALUE | INPUT_OBJECT | INPUT_FIELD_DEFINITION
directive @override(from: String!) on FIELD_DEFINITION
directive @composeDirective(name: String!) repeatable on SCHEMA
directive @interfaceObject on OBJECT
directive @authenticated on FIELD_DEFINITION | OBJECT | INTERFACE | SCALAR | ENUM
directive @requiresScopes(scopes: [[federation__Scope!]!]!) on FIELD_DEFINITION | OBJECT | INTERFACE | SCALAR | ENUM
directive @policy(policies: [[federation__Policy!]!]!) on FIELD_DEFINITION | OBJECT | INTERFACE | SCALAR | ENUM
directive @context(name: String!) repeatable on INTERFACE | OBJECT | UNION
directive @fromContext(field: federation__ContextFieldValue) on ARGUMENT_DEFINITION

type _Service {
  sdl: String!
}
SDL

sub build_subgraph_schema {
  my ($document, %opts) = @_;
  die "build_subgraph_schema requires an SDL document\n"
    if !defined($document) || ref($document) || $document !~ /\S/;

  my $entity_resolvers = delete($opts{entity_resolvers}) || {};
  my $max_representations = exists($opts{max_representations})
    ? delete($opts{max_representations}) : 100;
  die "max_representations must be a positive integer\n"
    if !defined($max_representations)
      || $max_representations !~ /\A[1-9][0-9]*\z/;
  die "entity_resolvers must be a hash reference\n"
    if ref($entity_resolvers) ne 'HASH';

  my $ast = GraphQL::Houtou::parse($document);
  my ($query_name, $entities) = _subgraph_shape($ast);
  my @entity_names = sort keys %$entities;

  my $entity_sdl = '';
  if (@entity_names) {
    $entity_sdl .= "union _Entity = " . join(' | ', @entity_names) . "\n\n";
  }
  $entity_sdl .= "extend type $query_name {\n  _service: _Service!\n";
  $entity_sdl .= "  _entities(representations: [_Any!]!): [_Entity]!\n"
    if @entity_names;
  $entity_sdl .= "}\n";

  my $user_resolvers = delete($opts{resolvers}) || {};
  die "resolvers must be a hash reference\n"
    if ref($user_resolvers) ne 'HASH';
  my %resolvers = map {
    my $spec = $user_resolvers->{$_};
    ($_ => ref($spec) eq 'HASH' ? { %$spec } : $spec)
  } keys %$user_resolvers;
  _reserve_resolver(
    \%resolvers, '_Any', 'parse_value',
    sub {
      my ($value) = @_;
      die "Federation representation must be an object\n"
        if ref($value) ne 'HASH';
      return $value;
    },
  );
  _reserve_resolver(\%resolvers, '_Any', 'serialize', sub { $_[0] });
  _reserve_resolver(
    \%resolvers, '_Service', 'sdl', sub { return $document },
  );
  _reserve_resolver(
    \%resolvers, $query_name, '_service', sub { return {} },
  );

  if (@entity_names) {
    for my $name (@entity_names) {
      die "Missing entity resolver for '$name'\n"
        if ref($entity_resolvers->{$name}) ne 'CODE';
    }
    for my $name (sort keys %$entity_resolvers) {
      die "Entity resolver provided for non-entity type '$name'\n"
        if !$entities->{$name};
    }
    _reserve_resolver(
      \%resolvers, '_Entity', 'resolve_type',
      sub {
        my ($value) = @_;
        return ref($value) eq 'HASH' ? $value->{__typename} : undef;
      },
    );
    _reserve_resolver(
      \%resolvers, $query_name, '_entities',
      sub {
        my (undef, $args, $context) = @_;
        my $representations = $args->{representations};
        die "Federation representations must be an array\n"
          if ref($representations) ne 'ARRAY';
        die "Federation representations exceed max_representations ($max_representations)\n"
          if @$representations > $max_representations;
        return [ map {
          _resolve_representation($_, $context, $entities, $entity_resolvers)
        } @$representations ];
      },
    );
  }

  my $schema = GraphQL::Houtou::Schema->from_doc(
    "$FEDERATION_SDL\n$document\n$entity_sdl",
    %opts,
    resolvers => \%resolvers,
  );
  $entities = _validate_entity_keys($schema, $entities);
  $schema->{_federation_subgraph_sdl} = $document;
  $schema->{_federation_max_representations} = 0 + $max_representations;
  return $schema;
}

sub _reserve_resolver {
  my ($resolvers, $type, $field, $callback) = @_;
  my $spec = $resolvers->{$type};
  die "Resolvers for '$type' must be a hash reference\n"
    if defined($spec) && ref($spec) ne 'HASH';
  $spec ||= ($resolvers->{$type} = {});
  die "Resolver '$type.$field' is reserved by Federation\n"
    if exists $spec->{$field};
  $spec->{$field} = $callback;
  return;
}

sub _subgraph_shape {
  my ($ast) = @_;
  my $query_name = 'Query';
  my %types;
  my %entities;
  for my $node (@$ast) {
    my $kind = $node->{kind} || '';
    $query_name = $node->{query}
      if $kind eq 'schema' && defined $node->{query};
    next if $kind ne 'type' && $kind ne 'interface';
    $types{ $node->{name} } = 1 if !$node->{extension};
    next if $kind ne 'type';
    for my $directive (@{ $node->{directives} || [] }) {
      next if ($directive->{name} || '') ne 'key';
      my $resolvable = $directive->{arguments}{resolvable};
      next if defined($resolvable) && !$resolvable;
      my $fields = $directive->{arguments}{fields};
      die "Federation \@key on '$node->{name}' requires a string fields argument\n"
        if !defined($fields) || ref($fields) || $fields eq '';
      push @{ $entities{ $node->{name} } }, $fields;
    }
  }
  die "Federation query root type '$query_name' is not defined\n"
    if !$types{$query_name};
  return ($query_name, \%entities);
}

sub _validate_entity_keys {
  my ($schema, $entities) = @_;
  my $name2type = $schema->name2type;
  my %compiled;
  for my $entity_name (sort keys %$entities) {
    my $entity_type = $name2type->{$entity_name};
    for my $fieldset (@{ $entities->{$entity_name} }) {
      my $document = eval { GraphQL::Houtou::parse("{ $fieldset }") };
      my $error = $@;
      if ($error || ref($document) ne 'ARRAY' || @$document != 1) {
        $error ||= 'invalid FieldSet';
        $error =~ s/\s+\z//;
        die "Invalid \@key FieldSet on '$entity_name': $error\n";
      }
      _validate_fieldset_selections(
        $entity_name, $entity_type, $document->[0]{selections} || [],
      );
      push @{ $compiled{$entity_name} }, $document->[0]{selections};
    }
  }
  return \%compiled;
}

sub _validate_fieldset_selections {
  my ($coordinate, $type, $selections) = @_;
  die "Invalid \@key FieldSet on '$coordinate': fields must not be empty\n"
    if ref($selections) ne 'ARRAY' || !@$selections;
  my $fields = $type->can('fields') ? $type->fields : undef;
  die "Invalid \@key FieldSet on '$coordinate': type is not composite\n"
    if !$fields;
  for my $selection (@$selections) {
    die "Invalid \@key FieldSet on '$coordinate': only fields are allowed\n"
      if ($selection->{kind} || '') ne 'field'
        || $selection->{alias}
        || keys %{ $selection->{arguments} || {} }
        || @{ $selection->{directives} || [] };
    my $name = $selection->{name};
    my $field = $fields->{$name}
      or die "Invalid \@key FieldSet: field '$coordinate.$name' does not exist\n";
    my $field_type = $field->{type};
    $field_type = $field_type->of while ref($field_type) && $field_type->can('of');
    my $children = $selection->{selections} || [];
    if (@$children) {
      _validate_fieldset_selections("$coordinate.$name", $field_type, $children);
    }
    elsif ($field_type->can('fields')) {
      die "Invalid \@key FieldSet: composite field '$coordinate.$name' requires a selection\n";
    }
  }
  return;
}

sub _resolve_representation {
  my ($representation, $context, $entities, $entity_resolvers) = @_;
  die "Federation representation must be an object\n"
    if ref($representation) ne 'HASH';
  my $typename = $representation->{__typename};
  die "Federation representation requires a string __typename\n"
    if !defined($typename) || ref($typename) || $typename eq '';
  die "Unknown Federation entity type '$typename'\n"
    if !$entities->{$typename};
  die "Federation representation for '$typename' does not satisfy any \@key\n"
    if !grep { _representation_has_fields($representation, $_) }
      @{ $entities->{$typename} };
  my $value = $entity_resolvers->{$typename}->($representation, $context);
  if (is_promise_xs_value($value)) {
    return $value->then(sub { _tag_entity_result($typename, $_[0]) });
  }
  return _tag_entity_result($typename, $value);
}

sub _representation_has_fields {
  my ($representation, $selections) = @_;
  return 0 if ref($representation) ne 'HASH';
  for my $selection (@$selections) {
    my $name = $selection->{name};
    return 0 if !exists $representation->{$name};
    my $children = $selection->{selections} || [];
    return 0 if @$children
      && !_representation_has_fields($representation->{$name}, $children);
  }
  return 1;
}

sub _tag_entity_result {
  my ($typename, $value) = @_;
  return undef if !defined $value;
  die "Federation entity resolver for '$typename' must return a hash reference or undef\n"
    if ref($value) ne 'HASH';
  return { %$value, __typename => $typename };
}

1;

__END__

=encoding utf-8

=head1 NAME

GraphQL::Houtou::Federation - build an Apollo Federation 2 subgraph schema

=head1 SYNOPSIS

  use GraphQL::Houtou::Federation qw(build_subgraph_schema);

  my $schema = build_subgraph_schema(
    $sdl,
    entity_resolvers => {
      Product => sub {
        my ($representation, $context) = @_;
        return $context->{products}->load($representation->{upc});
      },
    },
    max_representations => 100,
  );

=head1 DESCRIPTION

Builds a Federation 2 subgraph schema for use behind an Apollo-compatible
Gateway or Router. It adds C<_service>, C<_entities>, Federation scalar and
directive definitions, and an entity union derived from resolvable C<@key>
applications. Gateway and supergraph composition are intentionally outside
this module.

Subgraph endpoints expose schema and entity lookup facilities and should only
be reachable by the trusted Router. C<max_representations> defaults to 100 and
limits work performed by one C<_entities> field.

C<entity_resolvers> maps each resolvable entity type to a callback. The
callback receives C<($representation, $context)> and returns a hash reference,
C<undef>, or a C<Promise::XS> for either. Results are emitted in representation
order, so callbacks can return request-scoped DataLoader promises to batch
database access.

Every representation must contain a string C<__typename> and satisfy at least
one resolvable C<@key> declared for that type. FieldSet syntax and field paths
are validated once when the schema is built. Request dispatch is a single
linear pass with constant-time type lookup.

The authored SDL returned by C<_service.sdl> is preserved verbatim. Include a
Federation 2 C<@link> application and imports in that SDL so the Router can
compose it. Directive renaming through C<< @link(as:) >> is not yet supported;
use the standard imported directive names. Houtou validates entity keys, but
semantic validation of composition directives such as C<@external>,
C<@requires>, and C<@override> remains the responsibility of Rover or the
deployment's composition pipeline.

=head1 SECURITY

Do not expose a subgraph directly to untrusted clients. C<_service> publishes
the service SDL and C<_entities> provides a cross-type lookup surface. Restrict
network access to the Router, authenticate Router-to-subgraph requests, keep
C<max_representations> bounded, and apply the ordinary Houtou body, depth,
node, cost, timeout, and rate limits.

=cut
