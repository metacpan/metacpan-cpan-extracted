package GraphQL::Houtou::Internal::TypeSupport;

use 5.014;
use strict;
use warnings;

use Exporter 'import';
use JSON::MaybeXS;

our @EXPORT_OK = qw(
  named_from_ast
  description_doc_lines
  apply_fields_deprecation
  from_ast_field_deprecate
  to_doc_field_deprecate
  make_field_def
  from_ast_fields
  from_ast_maptype
  make_fieldtuples
);

my $JSON_noutf8 = JSON::MaybeXS->new->utf8(0)->allow_nonref;

sub named_from_ast {
  my ($ast_node) = @_;
  return (
    name => $ast_node->{name},
    ($ast_node->{description} ? (description => $ast_node->{description}) : ()),
  );
}

sub description_doc_lines {
  my ($description) = @_;
  return if !$description;

  my @lines = split /\n/, $description;
  return if !@lines;
  if (@lines == 1) {
    return '"' . ($lines[0] =~ s#"#\\"#gr) . '"';
  }

  return (
    '"""',
    (map { s#"""#\\"""#gr } @lines),
    '"""',
  );
}

sub apply_fields_deprecation {
  my ($values) = @_;
  my $copy = { %{$values || {}} };
  for my $name (keys %$copy) {
    my $field = $copy->{$name};
    my %new = %$field;
    $new{is_deprecated} = 1 if defined $field->{deprecation_reason};
    $new{args} = apply_fields_deprecation($field->{args}) if $field->{args};
    $copy->{$name} = \%new;
  }
  return $copy;
}

sub from_ast_field_deprecate {
  my ($key, $values) = @_;
  my $value = +{ %{ $values->{$key} } };
  my $directives = delete $value->{directives};
  return $values if !$directives || !@$directives;

  my ($deprecated) = grep { $_->{name} eq 'deprecated' } @$directives;
  return $values if !$deprecated;
  my @remaining = grep { $_->{name} ne 'deprecated' } @$directives;
  $value->{directives} = \@remaining if @remaining;

  require GraphQL::Houtou::Directive;
  my $reason = $deprecated->{arguments}{reason}
    // $GraphQL::Houtou::Directive::DEPRECATED->args->{reason}{default_value};
  return +{
    %$values,
    $key => { %$value, deprecation_reason => $reason },
  };
}

sub to_doc_field_deprecate {
  my ($line, $value) = @_;
  return $line if !$value->{is_deprecated};

  require GraphQL::Houtou::Directive;
  $line .= ' @deprecated';
  $line .= '(reason: ' . $JSON_noutf8->encode($value->{deprecation_reason}) . ')'
    if $value->{deprecation_reason} ne
      $GraphQL::Houtou::Directive::DEPRECATED->args->{reason}{default_value};
  return $line;
}

sub make_field_def {
  my ($name2type, $field_name, $field_def) = @_;
  require GraphQL::Houtou::Schema;

  my %args;
  if ($field_def->{args}) {
    my $arg_defs = $field_def->{args};
    $arg_defs = from_ast_field_deprecate($_, $arg_defs) for keys %$arg_defs;
    %args = (
      args => +{
        map { make_field_def($name2type, $_, $arg_defs->{$_}) }
          keys %$arg_defs
      },
    );
  }

  return (
    $field_name => {
      %$field_def,
      type => GraphQL::Houtou::Schema::lookup_type($field_def, $name2type),
      %args,
    }
  );
}

sub from_ast_maptype {
  my ($name2type, $ast_node, $key) = @_;
  my $names = $ast_node->{$key} || [];
  return (
    $key => sub { [
      map { $name2type->{$_} // die "Unknown type '$_' in $key.\n" } @$names
    ] },
  );
}

sub from_ast_fields {
  my ($name2type, $ast_node, $key) = @_;
  my $fields = $ast_node->{$key} || {};
  $fields = from_ast_field_deprecate($_, $fields) for keys %$fields;

  return (
    $key => sub { +{
      map {
        my @pair = eval {
          make_field_def($name2type, $_, $fields->{$_})
        };
        die "Error in field '$_': $@" if $@;
        @pair;
      } keys %$fields
    } },
  );
}

sub make_fieldtuples {
  my ($fields) = @_;

  return map {
    my $field = $fields->{$_};
    my @argtuples = map { $_->[0] } make_fieldtuples($field->{args} || {});
    my $type = $field->{type};
    my $line = $_;
    $line .= '(' . join(', ', @argtuples) . ')' if @argtuples;
    $line .= ': ' . $type->to_string;
    $line .= ' = ' . $JSON_noutf8->encode(
      $type->perl_to_graphql($field->{default_value})
    ) if exists $field->{default_value};
    my @directives = map {
      my $args = $_->{arguments};
      my @pairs = map { "$_: " . $JSON_noutf8->encode($args->{$_}) } keys %$args;
      '@' . $_->{name} . (@pairs ? '(' . join(', ', @pairs) . ')' : '');
    } @{ $field->{directives} || [] };
    $line .= join(' ', ('', @directives)) if @directives;
    [
      to_doc_field_deprecate($line, $field),
      description_doc_lines($field->{description}),
    ]
  } sort keys %$fields;
}

1;
