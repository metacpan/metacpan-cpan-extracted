package My::Example::Role::TVSeries;
use namespace::autoclean;
use Moose::Role;

has actor_factory => ( is => 'ro' );

## no critic (ControlStructures::ProhibitYadaOperator)
sub get_actor_for_character {
    return;
}

1;
