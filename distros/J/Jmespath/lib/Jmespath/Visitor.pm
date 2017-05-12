package Jmespath::Visitor;
use strict;
use warnings;
#no strict 'refs';

sub new {
  my ($class) = @_;
  my $self = bless {}, $class;
  $self->{_method_cache} = {};
  return $self;
}

sub visit {
  my ($self, $node, $args) = @_;
  my $node_type = $node->{type};
  my $method = 'visit_' . $node->{type};
  return &$method;
}

sub default_visit {
  my ($self, $node, @args) = @_;
  Jmespath::NotImplementedException->new($node->{type})->throw;
  return;
}

1;
