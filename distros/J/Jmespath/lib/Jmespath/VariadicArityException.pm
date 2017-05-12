package Jmespath::VariadicArityException;
use Moose;
extends 'Jmespath::ArityException';
with 'Throwable';

has expected_arity => ( is => 'ro' );
has actual_arity => ( is => 'ro' );
has name => ( is => 'ro' );

sub new {
  my ( $class, $expected, $actual, $name ) = @_;
  my $self = $class->SUPER::new( $expected, $actual, $name );
  return $self;
}

sub to_string {
  my ( $self ) = @_;

  return 'Expected at least '
    . $self->{ expected_arity } . ' '
    . $self->pluralize('argument', $self->{expected_arity}) . ' for function '
    . $self->{ function_name } . '(), received ' . $self->{ actual_arity };
}

no Moose;
1;
