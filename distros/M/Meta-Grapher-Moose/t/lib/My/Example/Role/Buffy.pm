package My::Example::Role::Buffy;
use namespace::autoclean;
use Moose::Role;

with 'My::Example::Role::TVSeries';

has buffy  => ( is => 'ro' );
has willow => ( is => 'ro' );
has xander => ( is => 'ro' );
has giles  => ( is => 'ro' );

## no critic (ControlStructures::ProhibitYadaOperator)
sub slay {
    return;
}

1;
