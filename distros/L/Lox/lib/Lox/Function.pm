package Lox::Function;
use parent 'Lox::Callable';
use strict;
use warnings;
use Lox::Bool;
use Lox::Environment;
use overload
  '""' => sub { sprintf '<fn %s>',  $_[0]->declaration->can('name')
                  ? $_[0]->declaration->name->lexeme : 'lambda' },
  '!'  => sub { $False },
  'bool' => sub { $True }, # only false and nil are untrue in Lox
  fallback => 0;

our $VERSION = 0.02;

sub new {
  my ($class, $args) = @_;
  return bless { %$args }, $class;
}

sub declaration { $_[0]->{declaration} }
sub closure { $_[0]->{closure} }
sub arity { scalar $_[0]->params->@* }
sub params { $_[0]->declaration->params }
sub body { $_[0]->declaration->body }

sub call {
  my ($self, $interpreter, $args) = @_;
  my $environment = Lox::Environment->new({ enclosing => $self->closure });
  for (my $i = 0; $i < $self->params->@*; $i++) {
    $environment->define($self->params->[$i]->lexeme,$args->[$i]);
  }
  my $sub = sub {
    $interpreter->execute_block($self->body, $environment);
  };
  my $retval = $self->call_catch_return($interpreter, $sub);
  return $self->{is_initializer} ? $self->closure->get_at(0, 'this')
                                 : $retval;
}

sub bind {
  my ($self, $instance) = @_;
  my $environment = Lox::Environment->new({ enclosing => $self->closure });
  $environment->define('this', $instance);
  return Lox::Function->new({
      is_initializer => $self->{is_initializer},
      declaration    => $self->declaration,
      closure        => $environment,
  });
}

1;
