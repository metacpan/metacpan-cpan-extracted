package Jmespath::Expression;
use strict;
use warnings;

sub new {
  my ($class, $expression, $interpreter) = @_;
  my $self = bless {}, $class;
  $self->{expression} = $expression;
  $self->{interpreter} = $interpreter;
  return $self;
}

sub visit {
  my ($self, $node, $args) = @_;
  return $self->{interpreter}->visit($node, $args);
}

1;
