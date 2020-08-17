package Lox::Token;
use strict;
use warnings;
use Lox::TokenType ();
our $VERSION = 0.02;

sub new {
  my ($class, $args) = @_;
  return bless {
    literal => $args->{literal},
    lexeme  => $args->{lexeme},
    column  => $args->{column},
    type    => $args->{type},
    line    => $args->{line},
  }, $class;
}

sub to_string {
  my $self = shift;
  return sprintf '%3d:%3d %-12s %s %s',
    $self->{line},
    $self->{column},
    Lox::TokenType::type($self->{type}),
    $self->{lexeme},
    $self->{literal};
}

sub literal { $_[0]->{literal} }
sub lexeme { $_[0]->{lexeme} }
sub column { $_[0]->{column} }
sub type { $_[0]->{type} }
sub line { $_[0]->{line} }

sub accept {
  my ($self, $caller) = @_;
  $caller->visit_token($self);
}

1;
