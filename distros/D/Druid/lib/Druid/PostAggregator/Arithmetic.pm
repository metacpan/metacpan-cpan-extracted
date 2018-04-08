package Druid::PostAggregator::Arithmetic;
use Moo;

extends 'Druid::PostAggregator';

has fn       => (is => 'ro');
has fields   => (is => 'ro', default => sub { [] });
has ordering => (is => 'ro', default => 'null');

sub type { 'arithmetic' }

sub build {
    my $self = shift;

    my $aggregation = {
        'type'      => $self->type,
        'name'      => $self->name,
        'fn'        => $self->fn,
        'fields'    => [],
        'ordering'  => $self->ordering,
    };

    push @{ $aggregation->{'fields'} }, $_->build
        for @{ $self->fields };

    return $aggregation;
}

1;

