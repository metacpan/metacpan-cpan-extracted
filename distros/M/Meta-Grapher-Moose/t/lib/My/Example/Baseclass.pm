package My::Example::Baseclass;
use namespace::autoclean;
use Moose;

with(
    'My::Example::Role::ShedColor' => {
        default_color   => 'green',
        enable_painting => 1,
    },

    # this role is listed twice because it's parameterized
    'My::Example::Role::PickRandom' => {
        name   => 'dice_roll',
        values => [ 1 .. 6 ],
    },
    'My::Example::Role::PickRandom' => {
        name   => 'coin_flip',
        values => [qw( heads tails )],
    },
);

## no critic (ControlStructures::ProhibitYadaOperator)
sub method_in_baseclass {
    return;
}

__PACKAGE__->meta->make_immutable;
1;
