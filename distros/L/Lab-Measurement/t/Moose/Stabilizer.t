#!perl

use warnings;
use strict;
use 5.010;
use Test::More;

use Lab::Moose::Stabilizer;

package Dummy_Instr {
    use Moose;
    my $time = 0;

    sub get {
        my $self = shift;
        return exp( -$time++ );
    }
};

my $inst = Dummy_Instr->new();

stabilize(
    instrument           => $inst,
    setpoint             => 0,
    getter               => 'get',
    tolerance_setpoint   => 0.01,
    tolerance_std_dev    => 0.01,
    measurement_interval => 0.1,
    observation_time     => 1,
    verbose              => 0,
);

ok( $inst->get() < 0.01, "value is stabilized" );

done_testing();

