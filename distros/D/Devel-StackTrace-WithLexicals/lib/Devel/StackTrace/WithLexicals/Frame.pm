package Devel::StackTrace::WithLexicals::Frame;
use strict;
use warnings;
use Devel::StackTrace;
use base 'Devel::StackTrace::Frame';

sub new {
    my $class = shift;

    my $self = $class->SUPER::new(@_);

    $self->{lexicals} = $_[6];

    return $self;
}

sub lexicals { shift->{lexicals} }

sub lexical {
    my $self = shift;
    return $self->lexicals->{$_[0]};
}

1;

