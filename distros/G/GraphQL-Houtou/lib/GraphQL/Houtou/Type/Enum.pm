package GraphQL::Houtou::Type::Enum;

use 5.014;
use strict;
use warnings;

use parent 'GraphQL::Houtou::Type';
use Role::Tiny::With;
use GraphQL::Houtou::Internal::TypeSupport qw(
  apply_fields_deprecation
  description_doc_lines
  from_ast_field_deprecate
  named_from_ast
  to_doc_field_deprecate
);
use GraphQL::Houtou::Type::List ();
use GraphQL::Houtou::Type::NonNull ();

with qw(
  GraphQL::Houtou::Role::Input
  GraphQL::Houtou::Role::Output
  GraphQL::Houtou::Role::Leaf
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
  my $self = $class->SUPER::new(%args);
  $self->{name} = $args{name};
  $self->{description} = $args{description};
  my $values = apply_fields_deprecation($args{values} || {});
  for my $name (keys %$values) {
    $values->{$name}{value} = $name if !exists $values->{$name}{value};
  }
  $self->{values} = $values;
  return bless $self, $class;
}

sub name { $_[0]->{name} }
sub description { $_[0]->{description} }
sub to_string { $_[0]->{to_string} ||= $_[0]->name }
sub values { $_[0]->{values} }

sub from_ast {
  my ($class, $name2type, $ast_node) = @_;
  my $values = +{ %{ $ast_node->{values} || {} } };
  $values = from_ast_field_deprecate($_, $values) for keys %$values;
  return $class->new(
    named_from_ast($ast_node),
    values => $values,
  );
}

sub to_doc {
  my ($self) = @_;
  return $self->{to_doc} if exists $self->{to_doc};
  my $values = $self->values;
  my @valuelines = map {
    (
      description_doc_lines($values->{$_}{description}),
      to_doc_field_deprecate($_, $values->{$_}),
    )
  } sort keys %$values;
  return $self->{to_doc} = join '', map "$_\n",
    description_doc_lines($self->description),
    "enum @{[$self->name]} {",
    (map length() ? "  $_" : "", @valuelines),
    "}";
}

sub _name2value {
  my ($self) = @_;
  return $self->{_name2value} ||= do {
    my $v = $self->values;
    +{ map { ($_ => $v->{$_}{value}) } keys %$v };
  };
}

sub _value2name {
  my ($self) = @_;
  return $self->{_value2name} ||= do {
    my $n2v = $self->_name2value;
    +{ reverse %$n2v };
  };
}

sub is_valid {
  my ($self, $item) = @_;
  return 1 if !defined $item;
  return !!$self->_value2name->{$item};
}

sub graphql_to_perl {
  my ($self, $item) = @_;
  return undef if !defined $item;
  $item = $$$item if ref($item) eq 'REF';
  return $self->_name2value->{$item} // die "Expected type '@{[$self->to_string]}', found $item.\n";
}

sub perl_to_graphql {
  my ($self, $item) = @_;
  return undef if !defined $item;
  return $self->_value2name->{$item}
    // die "Expected a value of type '@{[$self->to_string]}' but received: @{[ref($item)||qq{'$item'}]}.\n";
}

1;

__END__

=encoding utf-8

=head1 NAME

GraphQL::Houtou::Type::Enum - GraphQL enum type

=head1 SYNOPSIS

    my $Episode = GraphQL::Houtou::Type::Enum->new(
      name   => 'Episode',
      values => {
        NEWHOPE => { value => 4 },
        EMPIRE  => { value => 5, description => 'ESB' },
        JEDI    => {},   # value defaults to the name itself
      },
    );

=head1 DESCRIPTION

Enum values map a GraphQL name to an internal C<value> (defaulting to the
name). C<deprecation_reason> on a value marks it C<@deprecated>.

=head1 SEE ALSO

L<GraphQL::Houtou>

=cut
