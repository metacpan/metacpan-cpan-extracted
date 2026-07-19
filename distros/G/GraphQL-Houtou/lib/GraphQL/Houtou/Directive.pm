package GraphQL::Houtou::Directive;

use 5.014;
use strict;
use warnings;

use parent 'GraphQL::Houtou::Type';
use Role::Tiny::With;
use GraphQL::Houtou::Internal::TypeSupport qw(apply_fields_deprecation description_doc_lines from_ast_fields make_fieldtuples named_from_ast);

use GraphQL::Houtou::Type::Scalar qw($Boolean $String);

with qw(
  GraphQL::Houtou::Role::Input
);

use constant DEBUG => $ENV{GRAPHQL_DEBUG};

my @LOCATIONS = qw(
  QUERY
  MUTATION
  SUBSCRIPTION
  FIELD
  FRAGMENT_DEFINITION
  FRAGMENT_SPREAD
  INLINE_FRAGMENT
  VARIABLE_DEFINITION
  SCHEMA
  SCALAR
  OBJECT
  FIELD_DEFINITION
  ARGUMENT_DEFINITION
  INTERFACE
  UNION
  ENUM
  ENUM_VALUE
  INPUT_OBJECT
  INPUT_FIELD_DEFINITION
);

sub new {
  my ($class, %args) = @_;
  my $self = $class->SUPER::new(%args);
  $self->{name} = $args{name};
  $self->{description} = $args{description};
  $self->{locations} = $args{locations} || [];
  $self->{args} = apply_fields_deprecation($args{args} || {});
  $self->{repeatable} = $args{repeatable} ? 1 : 0;
  $self->{resolve_field} = $args{resolve_field};
  $self->{apply_field_result} = $args{apply_field_result};
  return bless $self, $class;
}

sub name { $_[0]->{name} }
sub description { $_[0]->{description} }
sub locations { $_[0]->{locations} }
sub args { $_[0]->{args} }
sub repeatable { $_[0]->{repeatable} }
sub resolve_field { $_[0]->{resolve_field} }
sub apply_field_result { $_[0]->{apply_field_result} }
sub to_string { $_[0]->{to_string} ||= $_[0]->name }

sub from_ast {
  my ($class, $name2type, $ast_node) = @_;
  my (undef, $lazy_args) = from_ast_fields($name2type, $ast_node, 'args');
  return $class->new(
    named_from_ast($ast_node),
    locations => $ast_node->{locations} || [],
    ($ast_node->{repeatable} ? (repeatable => 1) : ()),
    args => $lazy_args->(),
  );
}

sub has_executable_location {
  my ($self) = @_;
  return !!grep {
    $_ eq 'FIELD' || $_ eq 'FRAGMENT_SPREAD' || $_ eq 'INLINE_FRAGMENT'
  } @{ $self->locations || [] };
}

sub has_runtime_hook {
  my ($self) = @_;
  return ($self->resolve_field || $self->apply_field_result) ? 1 : 0;
}

sub to_doc {
  my ($self) = @_;
  return $self->{to_doc} ||= do {
    my @argtuples = make_fieldtuples($self->args);
    my $end = @argtuples ? ')' : '';
    $end .= ' repeatable' if $self->repeatable;
    $end .= ' on ' . join(' | ', @{ $self->locations });
    if (!@argtuples) {
      join '', map "$_\n",
        description_doc_lines($self->description),
        "directive \@@{[$self->name]}$end";
    }
    else {
      my @start = (
        description_doc_lines($self->description),
        "directive \@@{[$self->name]}(",
      );
      if (!grep $_->[1], @argtuples) {
        join("\n", @start) . join(', ', map $_->[0], @argtuples) . $end . "\n";
      }
      else {
        join '', map "$_\n",
          @start,
          (map {
            my ($main, @description) = @$_;
            (map length() ? "  $_" : "", @description, $main)
          } @argtuples),
          $end;
      }
    }
  };
}

sub _get_directive_values {
  my ($self) = @_;
  die "Directive->_get_directive_values is part of the removed legacy execution path; use GraphQL::Houtou::Schema->compile_program / ->compile_native_bundle for directive evaluation on '$self->{name}'.\n";
}

our $DEPRECATED = __PACKAGE__->new(
  name => 'deprecated',
  description => 'Marks an element of a GraphQL schema as no longer supported.',
  locations => [ qw(FIELD_DEFINITION ENUM_VALUE ARGUMENT_DEFINITION INPUT_FIELD_DEFINITION) ],
  args => {
    reason => {
      type => $String,
      description =>
        'Explains why this element was deprecated, usually also including ' .
        'a suggestion for how to access supported similar data. Formatted ' .
        'in [Markdown](https://daringfireball.net/projects/markdown/).',
      default_value => 'No longer supported',
    },
  },
);

our $INCLUDE = __PACKAGE__->new(
  name => 'include',
  description => 'Directs the executor to include this field or fragment only when the `if` argument is true.',
  locations => [ qw(FIELD FRAGMENT_SPREAD INLINE_FRAGMENT) ],
  args => {
    if => {
      type => $Boolean->non_null,
      description => 'Included when true.',
    },
  },
);

our $SKIP = __PACKAGE__->new(
  name => 'skip',
  description => 'Directs the executor to skip this field or fragment when the `if` argument is true.',
  locations => [ qw(FIELD FRAGMENT_SPREAD INLINE_FRAGMENT) ],
  args => {
    if => {
      type => $Boolean->non_null,
      description => 'Skipped when true.',
    },
  },
);

our $SPECIFIED_BY = __PACKAGE__->new(
  name => 'specifiedBy',
  description => 'Exposes a URL that specifies the behavior of this scalar.',
  locations => [ qw(SCALAR) ],
  args => {
    url => {
      type => $String->non_null,
      description => 'The URL that specifies the behavior of this scalar.',
    },
  },
);

our $ONE_OF = __PACKAGE__->new(
  name => 'oneOf',
  description => 'Indicates exactly one field must be supplied and this field must not be `null`.',
  locations => [ qw(INPUT_OBJECT) ],
  args => {},
);

our @SPECIFIED_DIRECTIVES = (
  $INCLUDE,
  $SKIP,
  $DEPRECATED,
  $SPECIFIED_BY,
  $ONE_OF,
);

1;

=head1 NAME

GraphQL::Houtou::Directive - Directive definitions for GraphQL::Houtou

=head1 SYNOPSIS

  use GraphQL::Houtou::Directive;
  use GraphQL::Houtou::Schema;
  use GraphQL::Houtou::Type::Object;
  use GraphQL::Houtou::Type::Scalar qw($Boolean $String);

  my $Upper = GraphQL::Houtou::Directive->new(
    name => 'upper',
    locations => [qw(FIELD FRAGMENT_SPREAD INLINE_FRAGMENT)],
    apply_field_result => sub {
      my ($value) = @_;
      return undef if !defined $value;
      return uc $value;
    },
  );

  my $Mask = GraphQL::Houtou::Directive->new(
    name => 'mask',
    locations => [qw(FIELD FRAGMENT_SPREAD INLINE_FRAGMENT)],
    args => {
      enabled => { type => $Boolean->non_null },
    },
    apply_field_result => sub {
      my ($value, $source, $field_args, $context, $info, $return_type, $directive_args) = @_;
      return $directive_args->{enabled} ? '***' : $value;
    },
  );

  my $RequireRole = GraphQL::Houtou::Directive->new(
    name => 'requireRole',
    locations => [qw(FIELD_DEFINITION)],
    args => {
      role => { type => $String->non_null },
    },
    resolve_field => sub {
      my ($next, $source, $field_args, $context, $info, $return_type, $directive_args) = @_;
      die "forbidden\n" if (($context || {})->{role} || '') ne ($directive_args->{role} || '');
      return $next->();
    },
  );

  my $schema = GraphQL::Houtou::Schema->new(
    query => GraphQL::Houtou::Type::Object->new(
      name => 'ExampleQuery',
      fields => {
        hello => {
          type => $String,
          resolver_mode => 'native',
          resolve => sub { 'hello' },
        },
        secret => {
          type => $String,
          directives => [
            { name => 'requireRole', arguments => { role => 'admin' } },
          ],
        },
      },
    ),
    directives => [
      @GraphQL::Houtou::Directive::SPECIFIED_DIRECTIVES,
      $Upper,
      $Mask,
      $RequireRole,
    ],
  );

  my $result = $schema->execute(
    'query Q($enabled: Boolean!) { hello @upper @mask(enabled: $enabled) secret }',
    root_value => { secret => 'classified' },
    context => { role => 'admin' },
    variables => { enabled => 0 },
  );

=head1 DESCRIPTION

L<GraphQL::Houtou::Directive> represents a directive definition that can be
registered in C<< GraphQL::Houtou::Schema->new(directives => [...]) >>.

Executable directives can be implemented in two ways.

=over 4

=item * C<apply_field_result>

Use this for directives that transform an already-resolved field value.
This is the lighter-weight hook for query directives such as formatting,
masking, or string rewriting.

The callback receives:

  ($value, $source, $field_args, $context, $info, $return_type, $directive_args, $directive)

=item * C<resolve_field>

Use this for middleware-style directives that need to control whether the
field resolver runs at all, wrap the default resolver, or short-circuit
execution. This is the right hook for C<FIELD_DEFINITION> directives such as
authorization checks.

The callback receives:

  ($next, $source, $field_args, $context, $info, $return_type, $directive_args, $directive)

=back

If both are present, C<apply_field_result> is preferred for executable runtime
directives. In practice, C<apply_field_result> should be the default choice
for query/fragment directives, and C<resolve_field> should be reserved for
true resolver middleware.

For a runnable reference, see F<examples/custom-directives.pl>.

=cut
