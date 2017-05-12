package My::Example::Superclass;
use namespace::autoclean;
use Moose;

extends 'My::Example::Baseclass';

with(
    'My::Example::Role::StarTrek',
    'My::Example::Role::Tribute' => { grohl => 1 },
);

has 'attribute_in_superclass' => (
    is => 'ro',
);

## no critic (ControlStructures::ProhibitYadaOperator)
sub method_in_superclass {
    return;
}

__PACKAGE__->meta->make_immutable;
1;
