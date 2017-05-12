package Devel::Declare::Lexer::Token::Raw;

use base qw/ Devel::Declare::Lexer::Token /;

use v5;

sub new
{
    my ($caller, %arg) = @_;

    my $self = $caller->SUPER::new(%arg);

    return $self;
}

sub get
{
    my ($self) = @_;

    return $self->{value};
}

1;
