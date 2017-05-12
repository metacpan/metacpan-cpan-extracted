package Jmespath::ArityException;
use Moose;
with 'Throwable';

has expected_arity => ( is => 'ro' );
has actual_arity   => ( is => 'ro' );
has function_name  => ( is => 'ro' );
has expression     => ( is => 'ro' );

sub to_string {
  my ( $self ) = @_;
  return 'Expected ' . $self->expected_arity . ' ' . $self->pluralize('argument', $self->{expected_arity} ). ' for function ' . $self->{ function_name } . '(), received ' . $self->{ actual_arity };

}

sub _pluralize {
  my ( $self, $word, $count ) = @_;
  if ( $count == 1 ) {
    return $word;
  }
  else {
    return $word . 's';
  }
}

no Moose;
1;
