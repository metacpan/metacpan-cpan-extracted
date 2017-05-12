package Jmespath::IncompleteExpressionException;
use Moose;
extends 'Jmespath::ParseException';
with 'Throwable';

has expression => ( is => 'rw' );
has lex_position => ( is => 'ro' );
has token_type => ( is => 'ro' );
has token_value => ( is => 'ro' );

override 'to_string', sub {
  my ( $self ) = @_;
  my $underline = ( ' ' x ( $self->{ lex_position } + 1 )) . '^';
  return "Invalid jmespath expression: Incomplete expression:\n" .
    '"' . $self->{expression} . '"' . "\n" . $underline;
};

no Moose;
1;
