#!/usr/bin/perl

use Lab::Instrument::DummySource;


my $src=new Lab::Instrument::DummySource({
    gate_protect            => 1,
    gp_max_volt_per_step    => 0.1,
    gp_max_volt_per_second  => 0.6,
    gp_max_step_per_second  => 10,
    gp_min_volt             => -10,
    gp_max_volt             => 10,
});

$src->set_voltage(-4,channel=>1);

sleep 2;
$src->set_voltage(5,channel=>3);


#
# old style
#
sleep 2;
my $src1=new Lab::Instrument::Source($src,1);
$src1->set_voltage(-2);


#
# new style
#
sleep 2;
my $src2=$src->create_subsource( channel=>15, gp_max_volt_per_step=>0.4 );
$src2->set_voltage(1.5);


sleep 2;
my $src3=new Lab::Instrument::Source($src, 4, {
    gate_protect            => 1,
    gp_max_volt_per_step    => 0.12,
    gp_max_volt_per_second  => 0.12,
    gp_max_step_per_second  => 1,
    gp_min_volt             => -10,
    gp_max_volt             => 10,

});
$src3->set_voltage(-1);

sleep 2;
my $src4=new Lab::Instrument::DummySource({
    gate_protect            => 1,
    gp_max_volt_per_step    => 0.1,
    gp_max_step_per_second  => 1,
    gp_min_volt             => -10,
    gp_max_volt             => 10,
});

$src4->set_voltage(-4);

