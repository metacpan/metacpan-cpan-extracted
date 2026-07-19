package GraphQL::Houtou::Role::Abstract;

use 5.014;
use strict;
use warnings;

use Role::Tiny;

use GraphQL::Houtou::Error ();

# Runtime completion helpers for interfaces and unions.

sub _complete_value {
  my ($self) = @_;
  die "Abstract::_complete_value is part of the removed legacy execution path; use GraphQL::Houtou::Schema->build_runtime or ->build_native_runtime for abstract completion on '@{[$self->name]}'.\n";
}

sub _ensure_valid_runtime_type {
  my ($self, $runtime_type_or_name, $context, $nodes, $info, $result) = @_;
  my $runtime_type = ref($runtime_type_or_name)
    ? $runtime_type_or_name
    : $context->{schema}->name2type->{$runtime_type_or_name};

  die GraphQL::Houtou::Error->new(
    message => "Abstract type @{[$self->name]} must resolve to an " .
      "Object type at runtime for field @{[$info->{parent_type}->name]}." .
      "@{[$info->{field_name}]} with value $result, received '" .
      ($runtime_type ? $runtime_type->name : 'undef') . "'.",
    nodes => [ $nodes ],
  ) if !$runtime_type
      || !($runtime_type->isa('GraphQL::Houtou::Type::Object')
        || $runtime_type->isa('GraphQL::Type::Object'));

  die GraphQL::Houtou::Error->new(
    message => "Runtime Object type '@{[$runtime_type->name]}' is not a possible type for " .
      "'@{[$self->name]}'.",
    nodes => [ $nodes ],
  ) if !$context->{schema}->is_possible_type($self, $runtime_type);

  return $runtime_type;
}

sub _default_resolve_type {
  my ($value, $context, $info, $abstract_type) = @_;
  my $schema = ($info && $info->{schema}) || $context->{schema};
  my $tag_resolver = $abstract_type->can('tag_resolver') ? $abstract_type->tag_resolver : undef;

  if ($tag_resolver) {
    my $tag = $tag_resolver->($value, $context, $abstract_type);
    if (defined $tag) {
      my $declared_tag_map = $abstract_type->can('tag_map') ? $abstract_type->tag_map : undef;
      return $declared_tag_map->{$tag}
        if $declared_tag_map && exists $declared_tag_map->{$tag};

      my $runtime_cache = ($info && $info->{runtime_cache}) || $schema->runtime_cache || $schema->prepare_runtime;
      my $tag_map = ($runtime_cache->{runtime_tag_map} || {})->{ $abstract_type->name } || {};
      return $tag_map->{$tag} if exists $tag_map->{$tag};
    }
  }

  my $runtime_cache = ($info && $info->{runtime_cache}) || $schema->runtime_cache || $schema->prepare_runtime;
  my @possibles = @{ $runtime_cache->{possible_types}{ $abstract_type->name } || $schema->get_possible_types($abstract_type) };
  return (grep { $_->is_type_of->($value, $context, $info) } grep { $_->is_type_of } @possibles)[0];
}

1;
