package Jmespath::ParseException;
use Moose;
extends 'Jmespath::JMESPathException';
with 'Throwable';

has message => ( is => 'ro',
                 default => 'Invalid jmespath expression' );
has expression => ( is => 'rw' );
has lex_position => ( is => 'ro' );
has token_type => ( is => 'ro' );
has token_value => ( is => 'ro' );

override 'to_string', sub {
  my $self = shift;
  my $underline = ( ' ' x ( $self->lex_position + 1 ) ) . '^';
  my $mf = '%s : Parse error at column %s token "%s" (%s), ' .
    'for expression:' . "\n" . '"%s"' . "\n" . '%s' . "\n";
  return sprintf $mf,
    $self->message,
    $self->lex_position,
    $self->token_value,
    $self->token_type,
    $self->expression,
    $underline;
};

no Moose;
1;
