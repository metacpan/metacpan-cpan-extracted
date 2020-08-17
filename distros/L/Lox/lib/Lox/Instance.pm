package Lox::Instance;
use Lox::Bool;
use overload (
  '""' => sub { $_[0]->klass->name . ' instance' },
  'bool' => sub { $True },
  '!' => sub { $False },
  fallback => 0,
);
use strict;
use warnings;
our $VERSION = 0.02;

sub new {
  my ($class, $args) = @_;
  return bless { %$args }, $class;
}

sub fields { $_[0]->{fields} }
sub klass { $_[0]->{klass} }

sub get {
  my ($self, $name) = @_;
  if (my $field = $self->fields->{$name->lexeme}) {
    return $field;
  }
  elsif (my $method = $self->klass->find_method($name->lexeme)) {
    return $method->bind($self);
  }
  Lox::runtime_error($name, sprintf 'Undefined property \'%s\'', $name->lexeme);
}

sub set {
  my ($self, $name, $value) = @_;
  $self->fields->{$name->lexeme} = $value;
}

1;
