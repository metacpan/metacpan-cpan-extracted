package GraphQL::Houtou::Type::NonNull;

use 5.014;
use strict;
use warnings;

use Carp qw(croak);
use parent 'GraphQL::Houtou::Type';
use Role::Tiny ();

sub new {
  my ($class, %args) = @_;
  croak "Type::NonNull->new requires 'of'\n" if !exists $args{of};

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
  require GraphQL::Houtou::Type::List;
  $_[0]->{_houtou_list} ||= GraphQL::Houtou::Type::List->new(of => $_[0]);
}

sub of {
  return $_[0]->{of};
}

sub name {
  return $_[0]->of->name;
}

sub to_string {
  $_[0]->{to_string} ||= $_[0]->of->to_string . '!';
}

sub is_valid {
  my ($self, $item) = @_;
  return if !defined $item || !$self->of->is_valid($item);
  return 1;
}

sub graphql_to_perl {
  my ($self, $item) = @_;
  my $value = $self->of->graphql_to_perl($item);
  return defined($value) ? $value : die $self->to_string . " given null value.\n";
}

1;

__END__

=encoding utf-8

=head1 NAME

GraphQL::Houtou::Type::NonNull - GraphQL non-null wrapper type

=head1 DESCRIPTION

Wraps any type as non-nullable: C<< GraphQL::Houtou::Type::NonNull->new(of
=> $type) >>, or more commonly C<< $type->non_null >>. A null produced
for a non-null field propagates to the nearest nullable ancestor, per the
GraphQL spec.

=head1 SEE ALSO

L<GraphQL::Houtou::Type::List>

=cut
