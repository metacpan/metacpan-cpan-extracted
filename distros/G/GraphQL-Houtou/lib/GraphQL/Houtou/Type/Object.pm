package GraphQL::Houtou::Type::Object;

use 5.014;
use strict;
use warnings;

use parent 'GraphQL::Houtou::Type';
use Role::Tiny::With;
use GraphQL::Houtou::Directive ();
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
  GraphQL::Houtou::Role::Named
  GraphQL::Houtou::Role::FieldsOutput
  GraphQL::Houtou::Role::HashMappable
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
  die "GraphQL::Houtou::Type::Object requires name" if !defined $args{name};
  die "GraphQL::Houtou::Type::Object requires fields" if !exists $args{fields};
  my $self = $class->SUPER::new(%args);
  $self->{name} = $args{name};
  $self->{description} = $args{description};
  $self->{fields} = $args{fields};
  $self->{interfaces} = $args{interfaces} || [];
  $self->{is_type_of} = $args{is_type_of};
  $self->{runtime_tag} = $args{runtime_tag};
  return $self;
}

sub name { return $_[0]->{name} }
sub description { return $_[0]->{description} }
sub to_string { return $_[0]->{to_string} ||= $_[0]->name }
sub is_type_of { return $_[0]->{is_type_of} }
sub runtime_tag { return $_[0]->{runtime_tag} }

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

sub graphql_to_perl {
  my ($self, $item) = @_;
  my $fields = $self->fields;

  return $item if !defined $item;
  $item = $self->uplift($item);
  return $self->hashmap($item, $fields, sub {
    my ($key, $value) = @_;
    return $fields->{$key}{type}->graphql_to_perl($value // $fields->{$key}{default_value});
  });
}

sub _collect_fields {
  my ($self, $context, $selections, $fields_got, $visited_fragments) = @_;

  for my $selection (@$selections) {
    my $node = $selection;
    next if !_should_include_node($context->{variable_values}, $node);

    if ($selection->{kind} eq 'field') {
      my $use_name = $node->{alias} || $node->{name};
      my ($field_names, $nodes_defs) = @$fields_got;
      $field_names = [ @$field_names, $use_name ] if !exists $nodes_defs->{$use_name};
      $nodes_defs = {
        %$nodes_defs,
        $use_name => [ @{ $nodes_defs->{$use_name} || [] }, $node ],
      };
      $fields_got = [ $field_names, $nodes_defs ];
      next;
    }

    if ($selection->{kind} eq 'inline_fragment') {
      next if !$self->_fragment_condition_match($context, $node);
      ($fields_got, $visited_fragments) = $self->_collect_fields(
        $context,
        $node->{selections},
        $fields_got,
        $visited_fragments,
      );
      next;
    }

    if ($selection->{kind} eq 'fragment_spread') {
      my $frag_name = $node->{name};
      my $fragment;
      next if $visited_fragments->{$frag_name};
      $visited_fragments = { %$visited_fragments, $frag_name => 1 };
      $fragment = $context->{fragments}{$frag_name};
      next if !$fragment;
      next if !$self->_fragment_condition_match($context, $fragment);
      ($fields_got, $visited_fragments) = $self->_collect_fields(
        $context,
        $fragment->{selections},
        $fields_got,
        $visited_fragments,
      );
    }
  }

  return ($fields_got, $visited_fragments);
}

sub _fragment_condition_match {
  my ($self, $context, $node) = @_;
  my $condition_type;
  my $schema = $context->{schema};
  my $runtime_cache = $context->{runtime_cache} || $schema->runtime_cache || $schema->prepare_runtime;
  my $name2type = $runtime_cache->{name2type} || $schema->name2type;
  my $possible_type_map = $runtime_cache->{possible_type_map} ||= {};

  return 1 if !$node->{on};
  return 1 if $node->{on} eq $self->name;
  $condition_type = $name2type->{ $node->{on} }
    // die GraphQL::Houtou::Error->new(
      message => "Unknown type for fragment condition '$node->{on}'."
    );
  return '' if !$condition_type->DOES('GraphQL::Houtou::Role::Abstract')
    && !$condition_type->DOES('GraphQL::Role::Abstract');
  return $possible_type_map->{ $condition_type->name }{ $self->name }
    if exists $possible_type_map->{ $condition_type->name };
  return $schema->is_possible_type($condition_type, $self);
}

sub _should_include_node {
  my ($variables, $node) = @_;
  my $skip = $GraphQL::Houtou::Directive::SKIP->_get_directive_values($node, $variables);
  return '' if $skip && $skip->{if};
  my $include = $GraphQL::Houtou::Directive::INCLUDE->_get_directive_values($node, $variables);
  return '' if $include && !$include->{if};
  return 1;
}

sub _complete_value {
  my ($self) = @_;
  die "Type::Object->_complete_value is part of the removed legacy execution path; use GraphQL::Houtou::Schema->build_runtime or ->build_native_runtime for object completion on '@{[$self->name]}'.\n";
}

sub to_doc {
  my ($self) = @_;
  return $self->{to_doc} if exists $self->{to_doc};
  my @fieldlines = map {
    my ($main, @description) = @$_;
    (@description, $main);
  } make_fieldtuples($self->fields);
  my $implements = join ' & ', map $_->name, @{ $self->interfaces || [] };
  $implements &&= 'implements ' . $implements . ' ';
  return $self->{to_doc} = join '', map "$_\n",
    description_doc_lines($self->description),
    "type @{[$self->name]} $implements\{",
    (map length() ? "  $_" : "", @fieldlines),
    "}";
}

1;

__END__

=encoding utf-8

=head1 NAME

GraphQL::Houtou::Type::Object - GraphQL object type

=head1 SYNOPSIS

    my $User = GraphQL::Houtou::Type::Object->new(
      name   => 'User',
      fields => {
        id   => { type => $ID },
        name => { type => $String },
        posts => {
          type => $Post->non_null->list,
          args => { first => { type => $Int } },
          resolve => sub {
            my ($user, $args, $context, $info) = @_;
            $context->{posts}->load($user->{id});
          },
        },
      },
      interfaces => [ $Node ],
    );

=head1 DESCRIPTION

An output object type. Each field takes C<type>, optional C<args>
(C<< name => { type => ..., default_value => ... } >>), an optional
C<resolve> callback receiving C<($source, $args, $context, $info)>, and
optional C<description> / C<deprecation_reason>. Fields without
C<resolve> use the default resolver. A blessed source method named for the
field is called with C<($args, $context, $info)>. Otherwise a source hash key
is read; when that value is a coderef, it is called with the same arguments.
Other hash values are returned directly. Resolvers may return
L<Promise::XS> promises; see
L<GraphQL::Houtou/Batching resolvers (DataLoader / the on_stall hook)>.
Method lookup follows normal Perl inheritance, so fields named C<can>, C<isa>,
or C<DOES> should use explicit resolvers when the source is blessed.

C<< $type->list >> and C<< $type->non_null >> wrap any type in
L<GraphQL::Houtou::Type::List> / L<GraphQL::Houtou::Type::NonNull>.

=head1 SEE ALSO

L<GraphQL::Houtou>, L<GraphQL::Houtou::Schema>

=cut
