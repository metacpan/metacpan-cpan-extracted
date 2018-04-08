package Druid::PostAggregator::Constant;
use Moo;

extends 'Druid::PostAggregator';

has value => (is  => 'ro');

sub type { 'constant' }

sub build {
    my $self = shift;

    my $filter = {
        'type'  => $self->type,
        'name'  => $self->name,
        'value' => $self->value,
    };

    return $filter;
}

1;

