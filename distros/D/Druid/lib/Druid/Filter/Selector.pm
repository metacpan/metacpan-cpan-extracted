package Druid::Filter::Selector;
use Moo;

extends 'Druid::Filter';

sub type { 'selector' }
has value => (is => 'ro');

sub build {
    my $self = shift;

    my $filter = {
        'type'      => $self->type,
        'dimension' => $self->dimension,
        'value'     => $self->value,
    };

    return $filter;
}

1;

