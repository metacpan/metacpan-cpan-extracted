package Druid::Filter::Logical::Not;
use Moo;

extends 'Druid::Filter::Logical';

sub type { 'not' }

sub build {
    my $self = shift;

    if( scalar @{$self->fields} != 1 ){
        die $self. " can only have one fields attribute"
    }

    my $filter = {
        'type'  => $self->type,
        'field' => @{$self->fields}[0]->build
    };

    return $filter;
}

1;
