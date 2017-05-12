package Devel::Declare::Lexer::Token::LeftBracket;

use base qw/ Devel::Declare::Lexer::Token /;

use v5;

sub new
{
    my ($caller, %arg) = @_;

    my $self = $caller->SUPER::new(%arg);

    return $self;
}

1;
