package Lox::Environment;
use strict;
use warnings;
our $VERSION = 0.02;

sub new {
  my ($class, $args) = @_;
  return bless {
    values => {},
    %$args,
  }, $class;
}

sub enclosing { $_[0]->{enclosing} }
sub values { $_[0]->{values} }

sub define {
  my ($self, $name, $value) = @_;
  $self->values->{$name} = $value;
}

sub ancestor {
  my ($self, $distance) = @_;
  my $environment = $self;
  for (1..$distance) {
    $environment = $environment->enclosing;
  }
  return $environment;
}

sub get_at {
  my ($self, $distance, $token_lexeme) = @_;
  return $self->ancestor($distance)->values->{$token_lexeme};
}

sub assign_at {
  my ($self, $distance, $token, $value) = @_;
  $self->ancestor($distance)->values->{$token->lexeme} = $value;
}

sub get {
  my ($self, $token) = @_;
  if (exists $self->values->{$token->lexeme}) {
    my $v = $self->values->{$token->lexeme};
    return $v if defined $v;
    Lox::runtime_error($token, sprintf 'Uninitialized variable \'%s\'', $token->lexeme);
  }
  if ($self->enclosing) {
    return $self->enclosing->get($token);
  }
  Lox::runtime_error($token, sprintf 'Undefined variable \'%s\'', $token->lexeme);
}

sub assign {
  my ($self, $token, $value) = @_;
  if (exists $self->values->{$token->lexeme}) {
    $self->values->{$token->lexeme} = $value;
    return;
  }

  if ($self->enclosing) {
    return $self->enclosing->assign($token, $value);
  }
  Lox::runtime_error($token, sprintf 'Undefined variable "%s"', $token->lexeme);
}

1;
