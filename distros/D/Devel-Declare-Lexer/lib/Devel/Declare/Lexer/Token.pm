package Devel::Declare::Lexer::Token;

use v5;

sub new
{
    my ($caller, %arg) = @_;

    my $self = bless { 
        %arg 
    }, $caller;

    return $self;
}

sub get
{
    my ($self) = @_;

    return $self->{value};
}

1;
