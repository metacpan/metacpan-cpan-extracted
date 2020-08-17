package Lox::Callable;
use strict;
use warnings;
use Lox::Bool;
use overload
  '""' => sub { '<native fn>' },
  '!'  => sub { $False },
  'bool' => sub { $True }, # only false and nil are untrue in Lox
  fallback => 0;

our $VERSION = 0.02;

sub new {
  my ($class, $args) = @_;
  return bless { %$args }, $class;
}

sub arity { $_[0]->{arity} }

sub call {
  my ($self, $interpreter, @args) = @_;
  my $sub = sub { $self->{call}->($interpreter, @args) };
  return $self->call_catch_return($interpreter, $sub);
}

sub call_catch_return {
  my ($self, $interpreter, $sub) = @_;
  my $retval = eval { $sub->() };
  if ($@) {
    if ($@ =~ /^return/) {
      return delete $interpreter->{returning};
    }
    else {
      die $@; # we don't handle this exception
    }
  }
  return $retval;
}

1;
