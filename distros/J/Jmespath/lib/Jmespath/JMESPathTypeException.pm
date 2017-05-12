package Jmespath::JMESPathTypeException;
use Moose;
with 'Throwable';
extends 'Jmespath::JMESPathException';

has function_name => ( is => 'ro' );
has current_value => ( is => 'ro' );
has actual_type => ( is => 'ro' );
has expected_types => ( is => 'ro' );

sub to_string {
  my ( $self ) = @_;

  return 'In function ' .
    $self->{function_name} . '(), invalid type for value: ' .
    $self->{current_value} . ', expected one of: ' .
    $self->{expected_types} . ', received: "' .
    $self->{actual_type} . '"';
}

no Moose;
1;
