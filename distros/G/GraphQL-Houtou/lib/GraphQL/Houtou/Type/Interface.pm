package GraphQL::Houtou::Type::Interface;

use 5.014;
use strict;
use warnings;

use parent 'GraphQL::Houtou::Type';
use Role::Tiny::With;
use GraphQL::Houtou::Error ();
use GraphQL::Houtou::Internal::TypeSupport qw(
  apply_fields_deprecation
  description_doc_lines
  from_ast_fields
  from_ast_maptype
  make_fieldtuples
  named_from_ast
);
use GraphQL::Houtou::Type::List ();
use GraphQL::Houtou::Type::NonNull ();

with qw(
  GraphQL::Houtou::Role::Output
  GraphQL::Houtou::Role::Composite
  GraphQL::Houtou::Role::Abstract
  GraphQL::Houtou::Role::Named
  GraphQL::Houtou::Role::FieldsOutput
  GraphQL::Houtou::Role::FieldsEither
);

sub list {
  $_[0]->{_houtou_list} ||= GraphQL::Houtou::Type::List->new(of => $_[0]);
}

sub non_null {
  $_[0]->{_houtou_non_null} ||= GraphQL::Houtou::Type::NonNull->new(of => $_[0]);
}

use constant DEBUG => $ENV{GRAPHQL_DEBUG};

sub new {
  my ($class, %args) = @_;
  die "GraphQL::Houtou::Type::Interface requires name" if !defined $args{name};
  die "GraphQL::Houtou::Type::Interface requires fields" if !exists $args{fields};
  my $self = $class->SUPER::new(%args);
  $self->{name} = $args{name};
  $self->{description} = $args{description};
  $self->{fields} = $args{fields};
  $self->{interfaces} = $args{interfaces} || [];
  $self->{resolve_type} = $args{resolve_type};
  $self->{tag_resolver} = $args{tag_resolver};
  $self->{tag_map} = $args{tag_map};
  return $self;
}

sub name { return $_[0]->{name} }
sub description { return $_[0]->{description} }
sub to_string { return $_[0]->{to_string} ||= $_[0]->name }
sub resolve_type { return $_[0]->{resolve_type} }
sub tag_resolver { return $_[0]->{tag_resolver} }
sub tag_map { return $_[0]->{tag_map} }

sub interfaces {
  my ($self) = @_;
  if (ref($self->{interfaces}) eq 'CODE') {
    $self->{interfaces} = $self->{interfaces}->();
  }
  return $self->{interfaces};
}

sub from_ast {
  my ($class, $name2type, $ast_node) = @_;
  return $class->new(
    named_from_ast($ast_node),
    from_ast_maptype($name2type, $ast_node, 'interfaces'),
    from_ast_fields($name2type, $ast_node, 'fields'),
  );
}

sub fields {
  my ($self) = @_;
  if (ref($self->{fields}) eq 'CODE') {
    $self->{fields} = $self->{fields}->();
  }
  if (!$self->{_fields_deprecation_applied}) {
    $self->{fields} = apply_fields_deprecation($self->{fields});
    $self->{_fields_deprecation_applied} = 1;
  }
  return $self->{fields};
}

sub to_doc {
  my ($self) = @_;
  return $self->{to_doc} if exists $self->{to_doc};
  my @fieldlines = map {
    my ($main, @description) = @$_;
    (@description, $main);
  } make_fieldtuples($self->fields);
  return $self->{to_doc} = join '', map "$_\n",
    description_doc_lines($self->description),
    "interface @{[$self->name]}"
      . (@{ $self->interfaces } ? ' implements ' . join(' & ', map $_->name, @{ $self->interfaces }) : '')
      . " {",
    (map length() ? "  $_" : "", @fieldlines),
    "}";
}

sub _ensure_valid_runtime_type {
  my ($self, $runtime_type_or_name, $context, $nodes, $info, $result) = @_;
  my $schema = $context->{schema};
  my $runtime_cache = $context->{runtime_cache} || $schema->runtime_cache || $schema->prepare_runtime;
  my $name2type = $runtime_cache->{name2type} || $schema->name2type;
  my $possible_type_map = $runtime_cache->{possible_type_map} ||= {};
  my $runtime_type = ref($runtime_type_or_name)
    ? $runtime_type_or_name
    : $name2type->{$runtime_type_or_name};

  die GraphQL::Houtou::Error->new(
    message => "Abstract type @{[$self->name]} must resolve to an " .
      "Object type at runtime for field @{[$info->{parent_type}->name]}." .
      "@{[$info->{field_name}]} with value $result, received '@{[$runtime_type->name]}'.",
    nodes => [ $nodes ],
  ) if !$runtime_type
      || !($runtime_type->isa('GraphQL::Type::Object') || $runtime_type->isa('GraphQL::Houtou::Type::Object'));

  die GraphQL::Houtou::Error->new(
    message => "Runtime Object type '@{[$runtime_type->name]}' is not a possible type for " .
      "'@{[$self->name]}'.",
    nodes => [ $nodes ],
  ) if !(
    (exists $possible_type_map->{ $self->name }
      ? $possible_type_map->{ $self->name }{ $runtime_type->name }
      : $schema->is_possible_type($self, $runtime_type))
  );

  return $runtime_type;
}

1;

__END__

=encoding utf-8

=head1 NAME

GraphQL::Houtou::Type::Interface - GraphQL interface type

=head1 SYNOPSIS

    my $Node = GraphQL::Houtou::Type::Interface->new(
      name   => 'Node',
      fields => { id => { type => $ID->non_null } },
      resolve_type => sub { my ($value) = @_; $value->{kind} },
    );

=head1 DESCRIPTION

An abstract output type. C<resolve_type> receives the resolved value and
returns the concrete object type name; alternatively implementing types
may define C<is_type_of>. Objects declare membership through their
C<interfaces> list, and concrete types reachable only through an
interface must be listed in the schema's C<types>.

=head1 SEE ALSO

L<GraphQL::Houtou::Type::Union>, L<GraphQL::Houtou::Schema>

=cut
