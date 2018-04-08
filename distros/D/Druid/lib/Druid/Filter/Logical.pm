package Druid::Filter::Logical;
use Moo;

extends 'Druid::Filter';

has fields => (is => 'ro', default => sub { [] });

sub build {
    my $self = shift;

    my $filter = {
        'type'   => $self->type,
        'fields' => []
    };

    push @{ $filter->{'fields'} }, $_->build
        for @{ $self->fields };

return $filter;
}

1;

