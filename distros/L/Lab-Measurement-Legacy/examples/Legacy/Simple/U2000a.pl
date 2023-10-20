#!/usr/bin/perl

use strict;
use Lab::Instrument::U2000;
use Lab::Bus::USBtmc;
use Time::HiRes;

################################

my $powermeter = new Lab::Instrument::U2000(
    connection_type => 'USBtmc',
    tmc_address     => 0,
);

my $error = $powermeter->get_error();
if ($error) {
    print "Device reported error: $error\nPress Enter to continue";
    <STDIN>;
}
print "ID: " . $powermeter->id();
$powermeter->set_power_unit("dBm");
$powermeter->set_trigger("IMM");

# $powermeter->set_trigger("INT", {level=>-8});
$powermeter->set_average("AUTO");
$powermeter->set_step_detect("ON");
$powermeter->set_frequency("250MHz");
$powermeter->set_sample_rate("20");
my $start = Time::HiRes::gettimeofday();
for ( my $i = 0 ; ; $i++ ) {
    my $start2 = Time::HiRes::gettimeofday();
    my $power  = $powermeter->read();
    my $end    = Time::HiRes::gettimeofday();
    printf(
        "\nRead: %+9.5fdBm Measurements per second: %.1f/%.1f",
        $power,
        $i / ( $end - $start ),
        1 / ( $end - $start2 )
    );
}
1;

=pod

=encoding utf-8

=head1 U2000a.pl

Continuously reads out a power values from U2000A power meter.

=head2 Usage example

  $ perl U2000a.pl

=head2 Author / Copyright

  (c) Hermann Kraus 2012

=cut
