package Devel::Declare::Lexer::Token::Newline;

use base qw/ Devel::Declare::Lexer::Token /;

use v5;

sub new
{
    my ($caller, %arg) = @_;

    my $self = $caller->SUPER::new(
        value => "\n",
        %arg,
    );

    return $self;
}

1;
