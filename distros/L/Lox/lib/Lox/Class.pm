package Lox::Class;
use Lox::Bool;
use overload (
  '""' => sub { $_[0]->name },
  'bool' => sub { $True },
  '!' => sub { $False },
  fallback => 0,
);
use parent 'Lox::Callable';
use strict;
use warnings;
use Lox::Instance;
our $VERSION = 0.02;

sub new {
  my ($class, $args) = @_;
  return bless { %$args }, $class;
}

sub superclass { $_[0]->{superclass} }
sub methods    { $_[0]->{methods} }
sub name       { $_[0]->{name} }

sub call {
  my ($self, $interpreter, @args) = @_;
  my $instance = Lox::Instance->new({ klass => $self, fields => {} });
  my $initializer = $self->find_method('init');
  if ($initializer) {
    $initializer->bind($instance)->call($interpreter, @args);
  }
  return $instance;
}

sub arity {
  my $self = shift;
  my $initializer = $self->find_method('init');
  return $initializer ? $initializer->arity : 0;
}

sub find_method {
  my ($self, $lexeme) = @_;
  if (my $method = $self->methods->{$lexeme}) {
    return $method;
  }
  elsif ($self->superclass) {
    return $self->superclass->find_method($lexeme);
  }
  return undef;
}

1;
