package Devel::Declare::Lexer::Token::EndOfStatement;

use base qw/ Devel::Declare::Lexer::Token /;

use v5;

sub new
{
    my ($caller, %arg) = @_;

    my $self = $caller->SUPER::new(
        value => ';',
        %arg,
    );

    return $self;
}

1;
