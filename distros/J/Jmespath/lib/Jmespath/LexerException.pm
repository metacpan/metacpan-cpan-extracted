package Jmespath::LexerException;
use Moose;
extends qw(Jmespath::ParseException);
with 'Throwable';

has lexer_position => ( is => 'ro' );
has lexer_value => ( is => 'ro' );
has message => ( is => 'ro' );
has expression => ( is => 'rw' );

sub to_string {
  my ( $self ) = @_;
  my $underline = ( ' ' x ( $self->{ lexer_position } + 1 ) ) . '^';
  return 'Bad jmespath expression: ' . $self->{message} . "\n" . $self->{ expression } . "\n" . $underline;
}

no Moose;
1;
