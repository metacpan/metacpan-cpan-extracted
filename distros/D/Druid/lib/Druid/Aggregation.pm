package Druid::Aggregation;

use Moo;

has type        => (is  => 'ro');
has name        => (is  => 'ro');
has fieldName   => (is  => 'ro');

sub build {
    my $self = shift;

    my $aggregation = {
        'type'      => $self->type,
        'name'      => $self->name,
        'fieldName' => $self->fieldName,
    };

    return $aggregation;
}

1;
