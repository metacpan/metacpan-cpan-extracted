package FLAT::Transition::Simple;

use parent 'FLAT::Transition';

use strict;
use Carp;

sub new {
    my ($pkg, @things) = @_;
    bless {map {$_ => 1} @things}, $pkg;
}

sub does {
    my ($self, @things) = @_;
    return 1 if @things == 0;
    return !!grep $self->{$_}, @things;
}

sub add {
    my ($self, @things) = @_;
    @$self{@things} = (1) x @things;
}

sub delete {
    my ($self, @things) = @_;
    delete $self->{$_} for @things;
}

sub alphabet {
    my $self = shift;
    sort {$a cmp $b} keys %$self;
}

sub as_string {
    my $self = shift;
    join ",", map {length $_ ? $_ : "epsilon"} $self->alphabet;
}

1;
