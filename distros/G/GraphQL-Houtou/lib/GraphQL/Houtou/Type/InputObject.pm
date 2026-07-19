package GraphQL::Houtou::Type::InputObject;

use 5.014;
use strict;
use warnings;

use parent 'GraphQL::Houtou::Type';
use Role::Tiny::With;
use GraphQL::Houtou::Internal::TypeSupport qw(description_doc_lines named_from_ast apply_fields_deprecation from_ast_fields make_fieldtuples);
use GraphQL::Houtou::Type::List ();
use GraphQL::Houtou::Type::NonNull ();

with qw(
  GraphQL::Houtou::Role::Input
  GraphQL::Houtou::Role::FieldsInput
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
  my $self = $class->SUPER::new(%args);
  $self->{name} = $args{name};
  $self->{description} = $args{description};
  $self->{fields} = $args{fields};
  $self->{is_one_of} = $args{is_one_of} ? 1 : 0;
  return bless $self, $class;
}

sub name { $_[0]->{name} }
sub description { $_[0]->{description} }
sub is_one_of { $_[0]->{is_one_of} }
sub to_string { $_[0]->{to_string} ||= $_[0]->name }

sub from_ast {
  my ($class, $name2type, $ast_node) = @_;
  my $one_of = grep { ($_->{name} || q()) eq 'oneOf' } @{ $ast_node->{directives} || [] };
  return $class->new(
    named_from_ast($ast_node),
    from_ast_fields($name2type, $ast_node, 'fields'),
    ($one_of ? (is_one_of => 1) : ()),
  );
}

sub to_doc {
  my ($self) = @_;
  return $self->{to_doc} if exists $self->{to_doc};
  my @fieldlines = map {
    my ($main, @description) = @$_;
    (@description, $main);
  } make_fieldtuples($self->fields);
  my $one_of = $self->is_one_of ? ' @oneOf' : '';
  return $self->{to_doc} = join '', map "$_\n",
    description_doc_lines($self->description),
    "input @{[$self->name]}$one_of {",
    (map length() ? "  $_" : "", @fieldlines),
    "}";
}

sub fields {
  my ($self) = @_;
  my $fields = $self->{fields};
  if (ref($fields) eq 'CODE') {
    $fields = $fields->();
    $self->{fields} = $fields;
  }
  if (!$self->{_fields_deprecation_applied}) {
    $self->{fields} = apply_fields_deprecation($self->{fields});
    $self->{_fields_deprecation_applied} = 1;
  }
  return $self->{fields};
}

sub is_valid {
  my ($self, $item) = @_;
  my $fields = $self->fields;

  return 1 if !defined $item;
  return if grep { !$fields->{$_}{type}->is_valid($item->{$_} // $fields->{$_}{default_value}) } keys %$fields;
  return 1;
}

sub uplift {
  my ($self, $item) = @_;
  my $fields = $self->fields;

  return $item if !defined $item;
  die "found not an object" if ref($item) ne 'HASH';
  _assert_known_fields($item, $fields);
  my %uplifted;
  for my $key (sort keys %$fields) {
    next if !exists $item->{$key} && !exists $fields->{$key}{default_value};
    my $value = exists $item->{$key} ? $item->{$key} : $fields->{$key}{default_value};
    $uplifted{$key} = $fields->{$key}{type}->uplift($value);
  }
  return \%uplifted;
}

sub _assert_one_of {
  my ($self, $item) = @_;
  return if !$self->{is_one_of};
  my @keys = keys %$item;
  die "OneOf Input Object '@{[$self->name]}' must specify exactly one key.\n"
    if @keys != 1;
  die "OneOf Input Object '@{[$self->name]}' field '$keys[0]' must be non-null.\n"
    if !defined $item->{ $keys[0] };
  return;
}

sub graphql_to_perl {
  my ($self, $item) = @_;
  my $fields = $self->fields;

  return $item if !defined $item;
  die "found not an object" if ref($item) ne 'HASH';
  $self->_assert_one_of($item);
  $item = $self->uplift($item);
  my %value;
  for my $key (sort keys %$fields) {
    next if !exists $item->{$key} && !exists $fields->{$key}{default_value};
    my $raw = exists $item->{$key} ? $item->{$key} : $fields->{$key}{default_value};
    $value{$key} = $fields->{$key}{type}->graphql_to_perl($raw);
  }
  return \%value;
}

sub perl_to_graphql {
  my ($self, $item) = @_;
  my $fields = $self->fields;

  return $item if !defined $item;
  die "found not an object" if ref($item) ne 'HASH';
  $item = $self->uplift($item);
  my %value;
  for my $key (sort keys %$fields) {
    next if !exists $item->{$key} && !exists $fields->{$key}{default_value};
    my $raw = exists $item->{$key} ? $item->{$key} : $fields->{$key}{default_value};
    $value{$key} = $fields->{$key}{type}->perl_to_graphql($raw);
  }
  return \%value;
}

sub _assert_known_fields {
  my ($item, $fields) = @_;
  my @unknown = grep { !exists $fields->{$_} } sort keys %{$item || {}};
  die join '', map qq{In field "$_": Unknown field.\n}, @unknown if @unknown;
  return;
}

1;

__END__

=encoding utf-8

=head1 NAME

GraphQL::Houtou::Type::InputObject - GraphQL input object type

=head1 SYNOPSIS

    my $Filter = GraphQL::Houtou::Type::InputObject->new(
      name   => 'Filter',
      fields => {
        name_like => { type => $String },
        limit     => { type => $Int, default_value => 10 },
      },
    );

=head1 DESCRIPTION

A structured argument/variable type. C<is_one_of =E<gt> 1> makes it a
C<@oneOf> input object: exactly one field must be provided and it must
not be null.

=head1 SEE ALSO

L<GraphQL::Houtou>

=cut
