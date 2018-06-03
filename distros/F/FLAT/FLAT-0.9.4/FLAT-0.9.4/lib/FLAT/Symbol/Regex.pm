package FLAT::Symbol::Regex;

use parent 'FLAT::Symbol';
use FLAT::Regex::WithExtraOps;

use strict;

sub new {
    my ($pkg, $label) = @_;
    bless {
        COUNT  => 1,
        OBJECT => $label !~ m/^\s*$/g ? FLAT::Regex::WithExtraOps->new($label) : FLAT::Regex::WithExtraOps->new('[epsilon]'),
        LABEL  => $label,
    }, $pkg;
}

sub as_string {
    my $self = shift;
    return $self->{OBJECT}->as_string;
}

# provided interface to merging labels

sub union {
    my $self = shift;
    $self->{OBJECT} = $self->{OBJECT}->union($_[0]->{OBJECT});
    # update label
    $self->{LABEL} = $self->{OBJECT}->as_string;
}

sub concat {
    my $self = shift;
    $self->{OBJECT} = $self->{OBJECT}->concat($_[0]->{OBJECT});
    # update label
    $self->{LABEL} = $self->{OBJECT}->as_string;
}

sub kleene {
    my $self = shift;
    $self->{OBJECT} = $self->{OBJECT}->kleene();
    # update label
    $self->{LABEL} = $self->{OBJECT}->as_string;
}

sub shuffle {
    my $self = shift;
    $self->{OBJECT} = $self->{OBJECT}->shuffle($_[0]->{OBJECT});
    # update label
    $self->{LABEL} = $self->{OBJECT}->as_string;
}

1;
