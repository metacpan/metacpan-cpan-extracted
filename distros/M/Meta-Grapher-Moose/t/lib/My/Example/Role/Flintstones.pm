package My::Example::Role::Flintstones;
use namespace::autoclean;
use Moose::Role;

with 'My::Example::Role::TVSeries';

has fred  => ( is => 'ro' );
has wilma => ( is => 'ro' );

## no critic (ControlStructures::ProhibitYadaOperator)
sub have_a_yabba_do_time {
    return;
}

1;
