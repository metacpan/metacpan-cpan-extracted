package Devel::Declare::Lexer::Token::String;

use base qw/ Devel::Declare::Lexer::Token /;

use Devel::Declare::Lexer::Token::String::Interpolator;

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

    my $v = $self->{value};
    $v =~ s/\n/\\n/g;

    return $self->{start} . $v . $self->{end};
}

sub deinterpolate
{
    my ($self) = @_;

    return Devel::Declare::Lexer::Token::String::Interpolator::deinterpolate($self->{value});
}

sub interpolate
{
    my ($self, @args) = @_;
    return Devel::Declare::Lexer::Token::String::Interpolator::interpolate($self->{value}, @args);
}

1;
