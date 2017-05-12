package My::Example::Role::StarTrek;
use namespace::autoclean;
use Moose::Role;

with 'My::Example::Role::TVSeries';

has kirk    => ( is => 'ro' );
has spock   => ( is => 'ro' );
has mccoy   => ( is => 'ro' );
has scotty  => ( is => 'ro' );
has uhura   => ( is => 'ro' );
has sulu    => ( is => 'ro' );
has checkov => ( is => 'ro' );

## no critic (ControlStructures::ProhibitYadaOperator)
sub beam_me_up {
    return;
}

1;
