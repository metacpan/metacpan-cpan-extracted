#!/usr/bin/perl

use Lab::Instrument::HP83732A;
use Lab::Instrument::U2000;
use Time::HiRes qw(usleep);

my $signal=new Lab::Instrument::HP83732A(
    connection_type=>'USBtmc',
    visa_name => 'USB::0x0AAD::0x0054::12345::INSTR'
);

my $powermeter=new Lab::Instrument::U2000(
    connection_type=>'USBtmc',
);

sub set_freq
{
    my $freq = shift;
    $signal->set_cw($freq);
    $powermeter->set_frequency($freq);
    $signal->query("*OPC?");
}

my $error = $powermeter->get_error();
if ($error)
{
    print "Device reported error: $error\nPress Enter to continue";
    <STDIN>
}

$signal->power_on();
set_freq(10e6);
$powermeter->set_average("4");
$powermeter->set_sample_rate("40");
$powermeter->set_trigger("AUTO");


$signal->set_power(0);

for (my $freq=10e6; $freq < 18e9; $freq *= 1.01)
{
    set_freq($freq);
    $read_power = $powermeter->read();
    printf("%10.0f %6.2f\n", $freq, $read_power);

}


1;
