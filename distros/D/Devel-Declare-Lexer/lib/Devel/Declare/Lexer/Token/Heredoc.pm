package Devel::Declare::Lexer::Token::Heredoc;

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

#    return '<<' . $self->{name} . "\n" . $self->{value}; # value currently contains end name
    my $v = $self->{value};
    $v =~ s/\n/\\n/g;
    return '"' . $v . '"'; # value currently contains end name
}

1;
