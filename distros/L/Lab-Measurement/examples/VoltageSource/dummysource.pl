#!/usr/bin/perl

use Lab::Instrument::DummySource;


my $src=new Lab::Instrument::DummySource({
    gate_protect            => 1,
    gp_max_volt_per_step    => 0.1,
    gp_max_volt_per_second  => 10,
    gp_max_step_per_second  => 2,
    gp_min_volt             => -10,
    gp_max_volt             => 10,
});

$src->set_voltage(-4);

$src->set_voltage(5);

my $src3=new Lab::Instrument::DummySource({
    gate_protect            => 1,
    gp_max_volt_per_step    => 0.2,
    gp_max_volt_per_second  => 0.5,
    gp_max_step_per_second  => 1,
    gp_min_volt             => -10,
    gp_max_volt             => 10,
});

$src3->set_voltage(-4);

