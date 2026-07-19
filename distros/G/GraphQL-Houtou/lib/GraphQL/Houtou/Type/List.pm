package GraphQL::Houtou::Type::List;

use 5.014;
use strict;
use warnings;

use Carp qw(croak);
use parent 'GraphQL::Houtou::Type';
use Role::Tiny ();

sub new {
  my ($class, %args) = @_;
  croak "Type::List->new requires 'of'\n" if !exists $args{of};

  my $self = bless {
    of => $args{of},
    is_introspection => $args{is_introspection} ? 1 : 0,
  }, $class;

  my $of = $self->{of};
  my @roles;
  push @roles, 'GraphQL::Houtou::Role::Input'
    if $of->DOES('GraphQL::Houtou::Role::Input') || $of->DOES('GraphQL::Role::Input');
  push @roles, 'GraphQL::Houtou::Role::Output'
    if $of->DOES('GraphQL::Houtou::Role::Output') || $of->DOES('GraphQL::Role::Output');
  Role::Tiny->apply_roles_to_object($self, @roles) if @roles;

  return $self;
}

sub list {
  $_[0]->{_houtou_list} ||= __PACKAGE__->new(of => $_[0]);
}

sub non_null {
  require GraphQL::Houtou::Type::NonNull;
  $_[0]->{_houtou_non_null} ||= GraphQL::Houtou::Type::NonNull->new(of => $_[0]);
}

sub of {
  return $_[0]->{of};
}

sub name {
  return $_[0]->of->name;
}

sub to_string {
  $_[0]->{to_string} ||= '[' . $_[0]->of->to_string . ']';
}

sub is_valid {
  my ($self, $item) = @_;
  my $of = $self->of;

  return 1 if !defined $item;
  return if grep { !$of->is_valid($_) } @{ $self->uplift($item) };
  return 1;
}

sub uplift {
  my ($self, $item) = @_;
  return $item if ref($item) eq 'ARRAY' || !defined $item;
  return [ $item ];
}

sub graphql_to_perl {
  my ($self, $item) = @_;
  my $of = $self->of;
  my $i = 0;
  my @errors;
  my @values;

  return $item if !defined $item;
  $item = $self->uplift($item);
  @values = map {
    my $value = eval { $of->graphql_to_perl($_) };
    push @errors, qq{In element #$i: $@} if $@;
    $i++;
    $value;
  } @$item;
  die @errors if @errors;
  return \@values;
}

sub perl_to_graphql {
  my ($self, $item) = @_;
  my $of = $self->of;
  my $i = 0;
  my @errors;
  my @values;

  return $item if !defined $item;
  $item = $self->uplift($item);
  @values = map {
    my $value = eval { $of->perl_to_graphql($_) };
    push @errors, qq{In element #$i: $@} if $@;
    $i++;
    $value;
  } @$item;
  die @errors if @errors;
  return \@values;
}

sub _complete_value {
  my ($self) = @_;
  die "Type::List->_complete_value is part of the removed legacy execution path; use GraphQL::Houtou::Schema->build_runtime or ->build_native_runtime for list completion on '@{[$self->to_string]}'.\n";
}

1;

__END__

=encoding utf-8

=head1 NAME

GraphQL::Houtou::Type::List - GraphQL list wrapper type

=head1 DESCRIPTION

Wraps any type as a GraphQL list: C<< GraphQL::Houtou::Type::List->new(of
=> $type) >>, or more commonly C<< $type->list >>. Chain with
C<non_null> for C<[T!]!> shapes: C<< $type->non_null->list->non_null >>.

=head1 SEE ALSO

L<GraphQL::Houtou::Type::NonNull>

=cut
