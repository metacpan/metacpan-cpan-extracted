package My::Example::Class;
use namespace::autoclean;
use Moose;

extends 'My::Example::Superclass';

with 'My::Example::Role::Buffy', 'My::Example::Role::Flintstones';

has 'attribute_in_class' => (
    is => 'ro',
);

## no critic (ControlStructures::ProhibitYadaOperator)
sub method_in_example_class {
    return;
}

__PACKAGE__->meta->make_immutable;
1;
